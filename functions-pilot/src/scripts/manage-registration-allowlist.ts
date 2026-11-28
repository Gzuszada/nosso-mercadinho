import {readFile} from 'node:fs/promises';
import {homedir} from 'node:os';
import {join, resolve} from 'node:path';

const projectId =
  process.env.MERCADO_PILOT_PROJECT_ID ?? 'nosso-mercado-casa-pilot';
const region = process.env.MERCADO_PILOT_FUNCTIONS_REGION ?? 'us-central1';
const credentialPath =
  process.env.MERCADO_ADMIN_CREDENTIALS_FILE ??
  join(homedir(), '.config', 'mercado-pilot-admin.json');

type AdminCredentials = {
  projectId?: string;
  email?: string;
  password?: string;
};

async function readCredentials(): Promise<AdminCredentials> {
  const fromEnvironment = {
    projectId,
    email: process.env.MERCADO_ADMIN_EMAIL?.trim(),
    password: process.env.MERCADO_ADMIN_PASSWORD,
  };
  if (fromEnvironment.email && fromEnvironment.password) {
    return fromEnvironment;
  }
  try {
    const credentials = JSON.parse(
      await readFile(credentialPath, 'utf8'),
    ) as AdminCredentials;
    if (credentials.email && credentials.password) return credentials;
  } catch {
    // A mensagem abaixo explica como autenticar sem arquivo local.
  }
  return {};
}

const credentials = await readCredentials();
const adminEmail = credentials.email;
const adminPassword = credentials.password;
const action = process.argv[2] ?? 'list';
const email = process.argv[3]?.trim();

if (!adminEmail || !adminPassword) {
  throw new Error(
    `Autentique definindo MERCADO_ADMIN_EMAIL e MERCADO_ADMIN_PASSWORD ou usando ${credentialPath}.`,
  );
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

async function signIn(): Promise<string> {
  const apiKey = await readWebApiKey();
  const response = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(apiKey)}`,
    {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        email: adminEmail,
        password: adminPassword,
        returnSecureToken: true,
      }),
    },
  );
  const payload = (await response.json()) as {
    idToken?: string;
    error?: {message?: string};
  };
  if (!response.ok || !payload.idToken) {
    throw new Error(
      `Falha na autenticação administrativa: ${payload.error?.message ?? response.status}`,
    );
  }
  return payload.idToken;
}

async function call(
  idToken: string,
  data: Record<string, string>,
): Promise<unknown> {
  const response = await fetch(
    `https://${region}-${projectId}.cloudfunctions.net/manageRegistrationAllowlist`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${idToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({data}),
    },
  );
  const payload = (await response.json()) as {
    result?: unknown;
    error?: {message?: string};
  };
  if (!response.ok) {
    throw new Error(
      `Falha na administração: ${payload.error?.message ?? response.status}`,
    );
  }
  return payload.result;
}

const idToken = await signIn();
if (action === 'list') {
  console.log(JSON.stringify(await call(idToken, {action}), null, 2));
} else if (action === 'history') {
  console.log(JSON.stringify(await call(idToken, {action}), null, 2));
} else if (action === 'add' || action === 'remove' || action === 'promote') {
  if (!email) throw new Error('Informe o e-mail da operação.');
  const role = action === 'promote' ? 'admin' : 'member';
  console.log(
    JSON.stringify(
      await call(idToken, {action, email, role}),
      null,
      2,
    ),
  );
} else {
  throw new Error(
    'Uso: npm run allowlist -- <list|add|remove|promote|history> [e-mail]',
  );
}
