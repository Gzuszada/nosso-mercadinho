import {readFile} from 'node:fs/promises';
import {createInterface} from 'node:readline/promises';
import {stdin, stdout} from 'node:process';
import {homedir} from 'node:os';
import {join} from 'node:path';

import {
  REGISTRATION_ALLOWLIST_DOCUMENT,
  hashEmail,
  normalizeEmail,
} from '../allowlist.js';

const projectId = process.env.GCLOUD_PROJECT ?? 'nosso-mercado-casa-pilot';
const configPath = join(
  homedir(),
  '.config',
  'configstore',
  'firebase-tools.json',
);

type FirebaseCliConfig = {
  tokens?: {
    access_token?: string;
    expires_at?: number;
  };
};

async function readAccessToken(): Promise<string> {
  const config = JSON.parse(
    await readFile(configPath, 'utf8'),
  ) as FirebaseCliConfig;
  const token = config.tokens?.access_token;
  const expiresAt = config.tokens?.expires_at ?? 0;

  if (!token || expiresAt <= Date.now() + 60_000) {
    throw new Error(
      'A sessão do Firebase CLI expirou. Execute `firebase login:list` e tente novamente.',
    );
  }
  return token;
}

async function promptForEmails(): Promise<string[]> {
  const fromEnvironment = process.env.REGISTRATION_ALLOWED_EMAILS?.trim();
  if (fromEnvironment) {
    return fromEnvironment
      .split(/[\n,;]/)
      .map((email) => email.trim())
      .filter(Boolean);
  }

  const terminal = createInterface({input: stdin, output: stdout});
  try {
    const emails: string[] = [];
    while (true) {
      const email = (
        await terminal.question('E-mail autorizado (linha vazia para finalizar): ')
      ).trim();
      if (!email) {
        break;
      }
      if (!email.includes('@') || /\s/.test(email)) {
        console.error('E-mail inválido. Tente novamente.');
        continue;
      }
      emails.push(email);
    }
    return emails;
  } finally {
    terminal.close();
  }
}

const emails = await promptForEmails();
if (emails.length === 0) {
  throw new Error('Informe ao menos um e-mail autorizado.');
}

const normalizedEmails = emails.map(normalizeEmail);
const emailHashes = [...new Set(normalizedEmails.map(hashEmail))].sort();
const accessToken = await readAccessToken();
const documentName = REGISTRATION_ALLOWLIST_DOCUMENT;
const endpoint = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${documentName}`;
const body = {
  fields: {
    emailHashes: {arrayValue: {values: emailHashes.map((value) => ({stringValue: value}))}},
    updatedAt: {timestampValue: new Date().toISOString()},
  },
};

const response = await fetch(endpoint, {
  method: 'PATCH',
  headers: {
    Authorization: `Bearer ${accessToken}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify(body),
});

if (!response.ok) {
  const details = await response.text();
  throw new Error(`Falha ao atualizar a allowlist (${response.status}): ${details}`);
}

console.log(`Allowlist atualizada com ${emailHashes.length} e-mail(s).`);
