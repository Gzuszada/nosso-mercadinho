import {mkdir, readFile, writeFile} from 'node:fs/promises';
import {homedir} from 'node:os';
import {dirname, join, resolve} from 'node:path';

import {hashEmail, normalizeEmail} from '../allowlist.js';
import {maskEmail} from '../allowlist_admin.js';

const projectId =
  process.env.MERCADO_PILOT_PROJECT_ID ?? 'nosso-mercado-casa-pilot';
const adminEmail = normalizeEmail(
  process.env.MERCADO_ADMIN_EMAIL ?? '',
);
const adminPassword = process.env.MERCADO_ADMIN_PASSWORD;
if (!adminEmail || !adminPassword) {
  throw new Error(
    'Defina MERCADO_ADMIN_EMAIL e MERCADO_ADMIN_PASSWORD para criar a conta administrativa.',
  );
}
if (adminPassword.length < 16) {
  throw new Error('A senha administrativa precisa ter ao menos 16 caracteres.');
}

const firebaseConfigPath = join(
  homedir(),
  '.config',
  'configstore',
  'firebase-tools.json',
);
const credentialPath =
  process.env.MERCADO_ADMIN_CREDENTIALS_FILE ??
  join(homedir(), '.config', 'mercado-pilot-admin.json');

type FirebaseCliConfig = {
  tokens?: {access_token?: string; expires_at?: number};
};

async function readAccessToken(): Promise<string> {
  const config = JSON.parse(
    await readFile(firebaseConfigPath, 'utf8'),
  ) as FirebaseCliConfig;
  const token = config.tokens?.access_token;
  const expiresAt = config.tokens?.expires_at ?? 0;
  if (!token || expiresAt <= Date.now() + 60_000) {
    throw new Error(
      'A sessão do Firebase CLI expirou. Execute `firebase login` e tente novamente.',
    );
  }
  return token;
}

async function readWebApiKey(): Promise<string> {
  const fromEnvironment = process.env.FIREBASE_WEB_API_KEY?.trim();
  if (fromEnvironment) return fromEnvironment;
  const servicesPath = resolve(
    process.cwd(),
    '..',
    'android',
    'app',
    'src',
    'pilot',
    'google-services.json',
  );
  const services = JSON.parse(await readFile(servicesPath, 'utf8')) as {
    client?: {api_key?: {current_key?: string}[]}[];
  };
  const key = services.client?.[0]?.api_key?.[0]?.current_key;
  if (!key) throw new Error('API key do Web App piloto não encontrada.');
  return key;
}

function firestoreFields(value: unknown): Record<string, unknown> {
  if (typeof value === 'string') return {stringValue: value};
  if (typeof value === 'boolean') return {booleanValue: value};
  if (typeof value === 'number') {
    return Number.isInteger(value)
      ? {integerValue: String(value)}
      : {doubleValue: value};
  }
  if (Array.isArray(value)) {
    return {arrayValue: {values: value.map(firestoreFields)}};
  }
  if (value && typeof value === 'object') {
    return {
      mapValue: {
        fields: Object.fromEntries(
          Object.entries(value).map(([key, item]) => [
            key,
            firestoreFields(item),
          ]),
        ),
      },
    };
  }
  throw new Error('Valor inválido para o Firestore.');
}

const accessToken = await readAccessToken();
const documentName = 'privateConfig/registrationAllowlist';
const endpoint = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${documentName}`;
const emailHash = hashEmail(adminEmail);
const now = new Date().toISOString();
const emailMask = maskEmail(adminEmail);

const existingResponse = await fetch(endpoint, {
  headers: {Authorization: `Bearer ${accessToken}`},
});
if (!existingResponse.ok) {
  throw new Error(
    `Falha ao consultar a allowlist (${existingResponse.status}): ${await existingResponse.text()}`,
  );
}
const existing = (await existingResponse.json()) as {
    fields?: Record<string, {arrayValue?: {values?: {stringValue?: string}[]}}>;
  };
if ((existing.fields?.entries?.arrayValue?.values?.length ?? 0) > 0) {
  throw new Error(
    'A allowlist já possui entradas administrativas. Use a CLI para promover outro administrador.',
  );
}
const hashes = new Set(
  existing.fields?.emailHashes?.arrayValue?.values?.map(
    (value) => value.stringValue ?? '',
  ) ?? [],
);
hashes.add(emailHash);
const body = {
  fields: {
    emailHashes: {arrayValue: {values: [...hashes].sort().map((value) => ({stringValue: value}))}},
    entries: {
      arrayValue: {
        values: [
          firestoreFields({
            emailHash,
            emailMask,
            role: 'admin',
            addedAt: now,
            updatedAt: now,
            updatedByMask: 'bootstrap administrativo',
          }),
        ],
      },
    },
    updatedAt: {timestampValue: now},
    updatedByMask: {stringValue: 'bootstrap administrativo'},
  },
};
const updateResponse = await fetch(
  `${endpoint}?updateMask.fieldPaths=emailHashes&updateMask.fieldPaths=entries&updateMask.fieldPaths=updatedAt&updateMask.fieldPaths=updatedByMask`,
  {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  },
);
if (!updateResponse.ok) {
  throw new Error(
    `Falha ao preparar a allowlist (${updateResponse.status}): ${await updateResponse.text()}`,
  );
}

const apiKey = await readWebApiKey();
const signUpResponse = await fetch(
  `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${encodeURIComponent(apiKey)}`,
  {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({email: adminEmail, password: adminPassword}),
  },
);
const signUp = (await signUpResponse.json()) as {
  localId?: string;
  error?: {message?: string};
};
if (!signUpResponse.ok || !signUp.localId) {
  throw new Error(
    `Falha ao criar a conta administrativa: ${signUp.error?.message ?? signUpResponse.status}`,
  );
}

// A conta administrativa é separada das contas de família. Depois da criação,
// seu hash sai de emailHashes (usado pelo bloqueio de cadastro), mas continua
// em entries com papel admin para autorizar a ferramenta.
const familyHashes = [...hashes].filter((hash) => hash !== emailHash);
const removeAdminHashResponse = await fetch(
  `${endpoint}?updateMask.fieldPaths=emailHashes`,
  {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      fields: {
        emailHashes: {
          arrayValue: {
            values: familyHashes.sort().map((value) => ({stringValue: value})),
          },
        },
      },
    }),
  },
);
if (!removeAdminHashResponse.ok) {
  throw new Error(
    `Falha ao separar a conta administrativa: ${removeAdminHashResponse.status}`,
  );
}

await mkdir(dirname(credentialPath), {recursive: true});
await writeFile(
  credentialPath,
  `${JSON.stringify(
    {
      projectId,
      email: adminEmail,
      password: adminPassword,
      uid: signUp.localId,
      createdAt: now,
    },
    null,
    2,
  )}\n`,
  {encoding: 'utf8', mode: 0o600},
);
console.log(
  `Conta administrativa criada (${emailMask}) e credenciais salvas em ${credentialPath}.`,
);
