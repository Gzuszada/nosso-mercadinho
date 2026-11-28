const { spawn } = require('child_process');

const projectId = 'demo-mercado-casa';
const firestoreBase = `http://127.0.0.1:8080/v1/projects/${projectId}/databases/(default)/documents`;
const authBase = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';

process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.GCLOUD_PROJECT = projectId;
const {initializeApp} = require('../functions-pilot/node_modules/firebase-admin/lib/app/index.js');
const {getFirestore} = require('../functions-pilot/node_modules/firebase-admin/lib/firestore/index.js');
initializeApp({projectId});
const adminDb = getFirestore();

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

function deleteDocument(document) {
  const name = document.startsWith('projects/')
    ? document
    : `projects/${projectId}/databases/(default)/documents/${document}`;
  return { delete: name };
}

async function main() {
  const owner = await signUp('owner@example.com');
  const member = await signUp('member@example.com');
  const outsider = await signUp('outsider@example.com');
  const household = `households/house-${Date.now()}`;

  const createHousehold = await commit(owner, [
    set(household, { name: { stringValue: 'Casa de teste' }, ownerUid: { stringValue: owner.uid } }),
    set(`${household}/members/${owner.uid}`, {
      uid: { stringValue: owner.uid },
      email: { stringValue: owner.email },
      displayName: { stringValue: 'Dono Teste' },
      role: { stringValue: 'owner' },
      joinedAt: { timestampValue: '2026-01-01T00:00:00Z' },
    }),
  ]);
  if (createHousehold.status !== 200) throw new Error(`Dono não criou a casa: ${JSON.stringify(createHousehold)}`);

  const invite = 'householdInvites/ABCDEFGH';
  const createInvite = await commit(owner, [
    set(invite, {
      code: { stringValue: 'ABCDEFGH' },
      householdId: { stringValue: household.split('/')[1] },
      email: { stringValue: member.email },
      createdBy: { stringValue: owner.uid },
      createdAt: { timestampValue: new Date().toISOString() },
      expiresAt: { timestampValue: new Date(Date.now() + 7 * 86400000).toISOString() },
    }),
  ]);
  if (createInvite.status !== 200) throw new Error(`Membro não criou convite: ${JSON.stringify(createInvite)}`);

  const claim = await commit(member, [
    set(`${household}/inviteClaims/${member.uid}`, {
      uid: { stringValue: member.uid },
      email: { stringValue: member.email },
      inviteCode: { stringValue: 'ABCDEFGH' },
      claimedAt: { timestampValue: '2026-01-01T00:00:00Z' },
    }),
    set(`${household}/members/${member.uid}`, {
      uid: { stringValue: member.uid },
      email: { stringValue: member.email },
      displayName: { stringValue: 'Membro Teste' },
      role: { stringValue: 'member' },
      joinedAt: { timestampValue: '2026-01-01T00:00:00Z' },
    }),
  ]);
  if (claim.status !== 200) throw new Error(`Convite não vinculou o segundo usuário: ${JSON.stringify(claim)}`);

  await adminDb.doc(`${household}/metadata/sync`).set({ revision: 1 });

  const directMetadataWrite = await commit(member, [
    set(`${household}/metadata/sync`, { revision: { integerValue: '99' } }),
  ]);
  if (directMetadataWrite.status !== 403) {
    throw new Error(`Membro não deveria escrever metadata: ${JSON.stringify(directMetadataWrite)}`);
  }

  const directTableWrite = await commit(member, [
    set(`${household}/tables/catalog`, { payload: { stringValue: 'produtos' } }),
  ]);
  if (directTableWrite.status !== 403) {
    throw new Error(`Membro não deveria escrever tables: ${JSON.stringify(directTableWrite)}`);
  }

  const read = await request(`${firestoreBase}/${household}/metadata/sync`, { headers: auth(member) });
  if (read.status !== 200) throw new Error(`Membro não leu metadata: ${JSON.stringify(read)}`);

  const secondHousehold = `households/house-second-${Date.now()}`;
  const createSecondHousehold = await commit(owner, [
    set(secondHousehold, { name: { stringValue: 'Segunda casa' }, ownerUid: { stringValue: owner.uid } }),
    set(`${secondHousehold}/members/${owner.uid}`, {
      uid: { stringValue: owner.uid },
      email: { stringValue: owner.email },
      displayName: { stringValue: 'Dono Teste' },
      role: { stringValue: 'owner' },
      joinedAt: { timestampValue: '2026-01-01T00:00:00Z' },
    }),
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

  const v2Root = `syncV2/${household.split('/')[1]}`;
  const chunkPath = `${v2Root}/candidates/publication-1/areas/catalog/parts/0`;
  const createChunk = await commit(member, [
    set(chunkPath, {
      payload: { stringValue: 'products' },
      hash: { stringValue: 'a'.repeat(64) },
      count: { integerValue: '1' },
    }),
  ]);
  if (createChunk.status !== 200) {
    throw new Error(`Membro não criou chunk v2: ${JSON.stringify(createChunk)}`);
  }

  const updateChunk = await commit(member, [
    set(chunkPath, {
      payload: { stringValue: 'alterado' },
      hash: { stringValue: 'b'.repeat(64) },
      count: { integerValue: '1' },
    }),
  ]);
  if (updateChunk.status !== 403) {
    throw new Error(`Chunk v2 deveria ser imutável: ${updateChunk.status}`);
  }

  const statePath = `${v2Root}/state/current`;
  const writeState = await commit(member, [
    set(statePath, { generation: { integerValue: '99' } }),
  ]);
  if (writeState.status !== 403) {
    throw new Error(`Membro não deveria escrever o state v2: ${writeState.status}`);
  }

  const readChunk = await request(`${firestoreBase}/${chunkPath}`, {
    headers: auth(member),
  });
  if (readChunk.status !== 200) {
    throw new Error(`Membro não leu o chunk v2: ${readChunk.status}`);
  }

  const outsiderChunk = await request(`${firestoreBase}/${chunkPath}`, {
    headers: auth(outsider),
  });
  if (outsiderChunk.status !== 403) {
    throw new Error(`Não-membro leu o chunk v2: ${outsiderChunk.status}`);
  }

  const reviewPath = `${v2Root}/reviews/item-1`;
  await adminDb.doc(reviewPath).set({
    itemSyncId: 'item-1',
    action: 'approve',
    authorUid: member.uid,
    reviewedByUid: owner.uid,
  });
  const memberReadReview = await request(`${firestoreBase}/${reviewPath}`, {
    headers: auth(member),
  });
  if (memberReadReview.status !== 200) {
    throw new Error(`Membro não leu a revisão: ${memberReadReview.status}`);
  }
  const memberWriteReview = await commit(member, [
    set(reviewPath, { action: { stringValue: 'remove' } }),
  ]);
  if (memberWriteReview.status !== 403) {
    throw new Error(`Membro não deveria escrever a revisão: ${memberWriteReview.status}`);
  }
  const outsiderReadReview = await request(`${firestoreBase}/${reviewPath}`, {
    headers: auth(outsider),
  });
  if (outsiderReadReview.status !== 403) {
    throw new Error(`Não-membro leu a revisão: ${outsiderReadReview.status}`);
  }

  const memberDelete = await commit(member, [deleteDocument(chunkPath)]);
  if (memberDelete.status !== 403) {
    throw new Error(`Membro não deveria excluir chunk v2: ${memberDelete.status}`);
  }
  const ownerDelete = await commit(owner, [deleteDocument(chunkPath)]);
  if (ownerDelete.status !== 200) {
    throw new Error(`Owner não excluiu chunk v2: ${ownerDelete.status}`);
  }

  const successor = await signUp('successor@example.com');
  const transferHousehold = `households/house-transfer-${Date.now()}`;
  const createTransferHousehold = await commit(owner, [
    set(transferHousehold, {
      name: { stringValue: 'Casa para transferência' },
      ownerUid: { stringValue: owner.uid },
    }),
    set(`${transferHousehold}/members/${owner.uid}`, {
      uid: { stringValue: owner.uid },
      email: { stringValue: owner.email },
      displayName: { stringValue: 'Dono Teste' },
      role: { stringValue: 'owner' },
      joinedAt: { timestampValue: '2026-01-01T00:00:00Z' },
    }),
  ]);
  if (createTransferHousehold.status !== 200) {
    throw new Error(`Dono não criou a casa de transferência: ${JSON.stringify(createTransferHousehold)}`);
  }

  await adminDb.doc('householdInvites/SUCCESSOR').set({
    code: 'SUCCESSOR',
    householdId: transferHousehold.split('/')[1],
    email: successor.email,
    createdBy: owner.uid,
    createdAt: new Date('2026-01-01T00:00:00Z'),
    expiresAt: new Date('2027-01-01T00:00:00Z'),
  });
  const claimSuccessor = await commit(successor, [
    set(`${transferHousehold}/inviteClaims/${successor.uid}`, {
      uid: { stringValue: successor.uid },
      email: { stringValue: successor.email },
      inviteCode: { stringValue: 'SUCCESSOR' },
      claimedAt: { timestampValue: '2026-01-01T00:00:00Z' },
    }),
    set(`${transferHousehold}/members/${successor.uid}`, {
      uid: { stringValue: successor.uid },
      email: { stringValue: successor.email },
      displayName: { stringValue: 'Sucessor Teste' },
      role: { stringValue: 'member' },
      joinedAt: { timestampValue: '2026-01-01T00:00:00Z' },
    }),
  ]);
  if (claimSuccessor.status !== 200) {
    throw new Error(`Sucessor não entrou na casa: ${JSON.stringify(claimSuccessor)}`);
  }

  const ownerRemovesMember = await commit(owner, [
    deleteDocument(`${transferHousehold}/members/${successor.uid}`),
  ]);
  if (ownerRemovesMember.status !== 200) {
    throw new Error(`Owner não removeu membro comum: ${JSON.stringify(ownerRemovesMember)}`);
  }

  await adminDb.doc(`${transferHousehold}/members/${successor.uid}`).set({
    uid: successor.uid,
    email: successor.email,
    displayName: 'Sucessor Teste',
    role: 'member',
    joinedAt: new Date('2026-01-01T00:00:00Z'),
  });
  const directOwnershipTransfer = await commit(owner, [
    set(transferHousehold, { ownerUid: { stringValue: successor.uid } }),
  ]);
  if (directOwnershipTransfer.status !== 403) {
    throw new Error(`Cliente não deveria transferir ownerUid: ${directOwnershipTransfer.status}`);
  }

  // Simula o commit privilegiado do callable, que valida a transferência e
  // atualiza ownerUid e os papéis em uma transação atômica.
  await adminDb.runTransaction(async (transaction) => {
    transaction.update(adminDb.doc(transferHousehold), {ownerUid: successor.uid});
    transaction.update(adminDb.doc(`${transferHousehold}/members/${owner.uid}`), {role: 'member'});
    transaction.update(adminDb.doc(`${transferHousehold}/members/${successor.uid}`), {role: 'owner'});
  });

  const oldOwnerDeletesHousehold = await commit(owner, [
    deleteDocument(transferHousehold),
  ]);
  if (oldOwnerDeletesHousehold.status !== 403) {
    throw new Error(`Ex-owner não deveria excluir a casa: ${oldOwnerDeletesHousehold.status}`);
  }

  const newOwnerDeletesHousehold = await commit(successor, [
    deleteDocument(transferHousehold),
  ]);
  if (newOwnerDeletesHousehold.status !== 200) {
    throw new Error(`Novo owner não excluiu a casa: ${JSON.stringify(newOwnerDeletesHousehold)}`);
  }

  const memberInvite = await commit(member, [
    set('householdInvites/MEMBERCODE', {
      code: { stringValue: 'MEMBERCODE' },
      householdId: { stringValue: household.split('/')[1] },
      email: { stringValue: outsider.email },
      createdBy: { stringValue: member.uid },
      createdAt: { timestampValue: new Date().toISOString() },
      expiresAt: { timestampValue: new Date(Date.now() + 7 * 86400000).toISOString() },
    }),
  ]);
  if (memberInvite.status !== 403) {
    throw new Error(`Membro não deveria criar convite: ${memberInvite.status}`);
  }

  const memberDeletesOwner = await commit(member, [
    deleteDocument(`${household}/members/${owner.uid}`),
  ]);
  if (memberDeletesOwner.status !== 403) {
    throw new Error(`Membro não deveria remover o owner: ${memberDeletesOwner.status}`);
  }

  // Regressão da exclusão da casa: o owner precisa remover todos os dados
  // compartilhados, a árvore sync v2 e o documento principal.
  const deletionPaths = [
    `${household}/tables/catalog`,
    `${household}/metadata/sync`,
    `${household}/inviteClaims/${member.uid}`,
    `${v2Root}/candidates/publication-delete/areas/catalog/parts/0`,
    `${v2Root}/candidates/publication-delete`,
    `${v2Root}/conflicts/conflict-delete`,
    `${v2Root}/state/current-delete`,
    v2Root,
  ];
  await adminDb.doc(`${v2Root}/candidates/publication-delete`).set({
    status: 'committed',
    authorUid: owner.uid,
  });
  await adminDb.doc(`${v2Root}/conflicts/conflict-delete`).set({
    status: 'open',
  });
  await adminDb.doc(`${v2Root}/state/current-delete`).set({
    generation: 1,
  });
  await adminDb.doc(deletionPaths[0]).set({ payload: 'catalog' });
  await adminDb.doc(deletionPaths[1]).set({ revision: 1 });
  await adminDb.doc(deletionPaths[3]).set({
    payload: { products: [] },
    hash: 'c'.repeat(64),
    count: 0,
  });
  for (const path of deletionPaths) {
    const deletion = await commit(owner, [deleteDocument(path)]);
    if (deletion.status !== 200) {
      throw new Error(
        `Owner não excluiu ${path}: ${JSON.stringify(deletion)}`,
      );
    }
  }
  // Regressão: o app remove membros e casa no mesmo batch. Sem isso, o
  // documento da casa já não existiria ao excluir os membros (403).
  const deleteHouseholdAndMembers = await commit(owner, [
    deleteDocument(`${household}/members/${owner.uid}`),
    deleteDocument(`${household}/members/${member.uid}`),
    deleteDocument(household),
  ]);
  if (deleteHouseholdAndMembers.status !== 200) {
    throw new Error(
      `Owner não excluiu a casa e seus membros em um batch: ${JSON.stringify(deleteHouseholdAndMembers)}`,
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
    'REGRAS_OK: dono, convite, membro, não-membro, allowlist e sync v2 validados.',
  );
}

main().catch((error) => {
  console.error(error.stack || error);
  process.exitCode = 1;
});

void spawn;
