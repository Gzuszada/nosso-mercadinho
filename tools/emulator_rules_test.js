const { spawn } = require('child_process');

const projectId = 'demo-mercado-casa';
const firestoreBase = `http://127.0.0.1:8080/v1/projects/${projectId}/databases/(default)/documents`;
const authBase = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';

async function request(url, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
  });
  const body = await response.text();
  let parsed;
  try {
    parsed = body ? JSON.parse(body) : {};
  } catch {
    parsed = { raw: body };
  }
  return { status: response.status, body: parsed };
}

async function signUp(email) {
  const result = await request(`${authBase}/accounts:signUp?key=fake-api-key`, {
    method: 'POST',
    body: JSON.stringify({ email, password: 'Teste@12345', returnSecureToken: true }),
  });
  if (result.status !== 200) throw new Error(`Falha no cadastro ${email}: ${JSON.stringify(result)}`);
  return {
    uid: result.body.localId,
    email: result.body.email,
    idToken: result.body.idToken,
  };
}

function auth(user) {
  return { Authorization: `Bearer ${user.idToken}` };
}

async function commit(user, writes) {
  return request(`${firestoreBase}:commit`, {
    method: 'POST',
    headers: auth(user),
    body: JSON.stringify({ writes }),
  });
}

async function runQuery(user, structuredQuery) {
  return request(`${firestoreBase}:runQuery`, {
    method: 'POST',
    headers: auth(user),
    body: JSON.stringify({ structuredQuery }),
  });
}

function set(document, fields) {
  const name = document.startsWith('projects/')
    ? document
    : `projects/${projectId}/databases/(default)/documents/${document}`;
  return { update: { name, fields }, updateMask: { fieldPaths: Object.keys(fields) } };
}

async function main() {
  const owner = await signUp('owner@example.com');
  const member = await signUp('member@example.com');
  const outsider = await signUp('outsider@example.com');
  const household = `households/house-${Date.now()}`;

  const createHousehold = await commit(owner, [
    set(household, { name: { stringValue: 'Casa de teste' }, ownerUid: { stringValue: owner.uid } }),
    set(`${household}/members/${owner.uid}`, { uid: { stringValue: owner.uid }, role: { stringValue: 'owner' } }),
  ]);
  if (createHousehold.status !== 200) throw new Error(`Dono não criou a casa: ${JSON.stringify(createHousehold)}`);

  const invite = 'householdInvites/ABCDEFGH';
  const createInvite = await commit(owner, [
    set(invite, {
      householdId: { stringValue: household.split('/')[1] },
      email: { stringValue: member.email },
      createdBy: { stringValue: owner.uid },
    }),
  ]);
  if (createInvite.status !== 200) throw new Error(`Membro não criou convite: ${JSON.stringify(createInvite)}`);

  const claim = await commit(member, [
    set(`${household}/inviteClaims/${member.uid}`, {
      uid: { stringValue: member.uid },
      email: { stringValue: member.email },
      inviteCode: { stringValue: 'ABCDEFGH' },
    }),
    set(`${household}/members/${member.uid}`, { uid: { stringValue: member.uid }, role: { stringValue: 'member' } }),
  ]);
  if (claim.status !== 200) throw new Error(`Convite não vinculou o segundo usuário: ${JSON.stringify(claim)}`);

  const createMetadata = await commit(owner, [
    set(`${household}/metadata/sync`, { revision: { integerValue: '1' } }),
  ]);
  if (createMetadata.status !== 200) throw new Error(`Dono não criou metadata: ${JSON.stringify(createMetadata)}`);

  const read = await request(`${firestoreBase}/${household}/metadata/sync`, { headers: auth(member) });
  if (read.status !== 200) throw new Error(`Membro não leu metadata: ${JSON.stringify(read)}`);

  const secondHousehold = `households/house-second-${Date.now()}`;
  const createSecondHousehold = await commit(owner, [
    set(secondHousehold, { name: { stringValue: 'Segunda casa' }, ownerUid: { stringValue: owner.uid } }),
    set(`${secondHousehold}/members/${owner.uid}`, { uid: { stringValue: owner.uid }, role: { stringValue: 'owner' } }),
  ]);
  if (createSecondHousehold.status !== 200) {
    throw new Error(`Dono não criou a segunda casa: ${JSON.stringify(createSecondHousehold)}`);
  }

  const memberships = await runQuery(owner, {
    from: [{ collectionId: 'members', allDescendants: true }],
    where: {
      fieldFilter: {
        field: { fieldPath: 'uid' },
        op: 'EQUAL',
        value: { stringValue: owner.uid },
      },
    },
  });
  if (memberships.status !== 200) {
    throw new Error(`Consulta de members falhou: ${JSON.stringify(memberships)}`);
  }
  const membershipRows = Array.isArray(memberships.body) ? memberships.body : [];
  const membershipDocuments = membershipRows
    .map((row) => row.document)
    .filter(Boolean);
  if (membershipDocuments.length !== 2) {
    throw new Error(
      `Duas casas do mesmo proprietário deveriam ser descobertas: ${JSON.stringify(membershipDocuments)}`,
    );
  }

  const updateOwnDisplayName = await commit(member, [
    set(`${household}/members/${member.uid}`, {
      displayName: { stringValue: 'Membro Teste' },
    }),
  ]);
  if (updateOwnDisplayName.status !== 200) {
    throw new Error(
      `Membro não atualizou o próprio nome: ${JSON.stringify(updateOwnDisplayName)}`,
    );
  }

  const changeOwnUid = await commit(member, [
    set(`${household}/members/${member.uid}`, {
      uid: { stringValue: outsider.uid },
    }),
  ]);
  if (changeOwnUid.status !== 403) {
    throw new Error(
      `Membro não deveria alterar o próprio UID: ${JSON.stringify(changeOwnUid)}`,
    );
  }

  const changeOwnRole = await commit(member, [
    set(`${household}/members/${member.uid}`, {
      role: { stringValue: 'owner' },
    }),
  ]);
  if (changeOwnRole.status !== 403) {
    throw new Error(
      `Membro não deveria alterar o próprio papel: ${JSON.stringify(changeOwnRole)}`,
    );
  }

  const foreignMemberships = await runQuery(outsider, {
    from: [{ collectionId: 'members', allDescendants: true }],
    where: {
      fieldFilter: {
        field: { fieldPath: 'uid' },
        op: 'EQUAL',
        value: { stringValue: owner.uid },
      },
    },
  });
  if (foreignMemberships.status !== 403) {
    throw new Error(
      `Não-membro não deveria consultar membros de outro UID: ${JSON.stringify(foreignMemberships)}`,
    );
  }

  const denied = await request(`${firestoreBase}/${household}/metadata/sync`, { headers: auth(outsider) });
  if (denied.status !== 403) throw new Error(`Não-membro deveria receber 403: ${JSON.stringify(denied)}`);

  const readPrivateConfig = await request(
    `${firestoreBase}/privateConfig/registrationAllowlist`,
    { headers: auth(outsider) },
  );
  if (readPrivateConfig.status !== 403) {
    throw new Error(
      `Configuração privada deveria receber 403: ${JSON.stringify(readPrivateConfig)}`,
    );
  }

  const wrongEmail = await signUp('wrong@example.com');
  const wrongClaim = await commit(wrongEmail, [
    set(`${household}/inviteClaims/${wrongEmail.uid}`, {
      uid: { stringValue: wrongEmail.uid },
      email: { stringValue: wrongEmail.email },
      inviteCode: { stringValue: 'ABCDEFGH' },
    }),
  ]);
  if (wrongClaim.status !== 403) throw new Error(`E-mail errado deveria receber 403: ${JSON.stringify(wrongClaim)}`);

  console.log(
    'REGRAS_OK: dono, convite, membro, não-membro e allowlist privada validados.',
  );
}

main().catch((error) => {
  console.error(error.stack || error);
  process.exitCode = 1;
});

void spawn;
