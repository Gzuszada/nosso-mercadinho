# Piloto Android de sincronização v2

## Identidade

- Projeto Firebase: `nosso-mercado-casa-pilot`
- App Android: `1:1055183366543:android:8f96bffb2bc03b07cac3fa`
- Package: `br.com.nocorre.mercado.pilot`
- Firestore: `(default)`
- Região efetiva do Firestore: `nam5` (o roteiro ainda exige `southamerica-east1`; a localização do banco padrão não pode ser corrigida apenas trocando uma configuração)
- Região da Function callable: `us-central1`

O app de produção (`br.com.nocorre.mercado`) e a PWA não usam o protocolo v2.

## Builds

```powershell
# Produção, preservando package, Firebase e assinatura existentes
flutter build apk --release --flavor production

# Piloto debug, instalado lado a lado com produção
flutter build apk --debug --flavor pilot

# Piloto release, quando a chave local estiver configurada
flutter build apk --release --flavor pilot
```

APKs gerados:

- `build/app/outputs/flutter-apk/app-production-release.apk`
- `build/app/outputs/flutter-apk/app-pilot-release.apk`

O APK piloto release validado em 25/11/2026 usa o package
`br.com.nocorre.mercado.pilot`, versionCode `16`, versionName `1.0.8-pilot`,
assinatura APK v2 válida e SHA-256
`E23086D99E94B5EBD7B861AA17C3D6C3580CAE2BEF171886BC6D45E870A26E27`.
Ele instala lado a lado com a produção e não pode substituir uma instalação
piloto debug, pois as chaves de assinatura são diferentes.

## Deploy exclusivo do piloto

```powershell
firebase deploy --config firebase.pilot.json --only firestore:rules --project nosso-mercado-casa-pilot
firebase deploy --config firebase.pilot.json --only functions --project nosso-mercado-casa-pilot
```

As regras de produção continuam em `firestore.rules` e são publicadas com `firebase.json`. O backend v2 fica em `functions-pilot/`; o source `functions/` continua exclusivo de produção.

## Protocolo v2 implementado

- Cada área é dividida em chunks imutáveis de até 700 KiB.
- Cada chunk possui hash SHA-256 canônico e contagem de linhas.
- O manifesto aponta para todos os chunks e informa hashes e contagens por tabela.
- A Function `publishSyncV2` valida os chunks e executa compare-and-swap atômico por `generation` e `manifestHash`.
- O estado oficial do piloto é um manifesto v2 em `syncV2/{householdId}/state/current`, composto por chunks imutáveis. A publicação usa compare-and-swap atômico sobre `generation` e `manifestHash`; uma candidate concorrente rejeitada permanece em `syncV2/{householdId}/candidates` e é preservada em `syncV2/{householdId}/conflicts` para decisão do owner. Regras e backend do piloto ficam em `firestore.pilot.rules`/`firebase.pilot.json`, sem alteração do arquivo de regras de produção.
- Retry da mesma publication é idempotente.
- O cliente detecta pull, push e conflito por área sem alterar o banco local quando há conflito.

## Estado operacional

- Plano Blaze ativo; o projeto aceita deploy de Cloud Functions.
- Identity Platform/GCIP inicializado no projeto piloto, com E-mail/Senha habilitado e `passwordRequired=true`.
- `beforeCreateUser` e `publishSyncV2` publicadas e ativas em `us-central1`, Node.js 22 (2nd Gen).
- `beforeCreateUser` vinculada ao trigger `beforeCreate`; e-mails fora da allowlist são recusados com `PERMISSION_DENIED`.
- Allowlist privada do piloto em `privateConfig/registrationAllowlist`, com hashes SHA-256 e sem e-mails em texto aberto.
- Regras `firestore.pilot.rules` compiladas e publicadas.
- O índice Collection Group `members.uid` foi publicado e validado no Firestore piloto; consultas de descoberta das casas do usuário não exigem mais `FAILED_PRECONDITION`.
- E2E real no projeto piloto aprovado: cadastro autorizado e não autorizado, commit CAS, retry idempotente, retenção de candidate rejeitada, criação de conflito e negação para usuário sem vínculo com a casa. Todas as contas, casas, publications e entradas temporárias de allowlist foram removidas após o teste.
- O serviço `publishsyncv2` possui `roles/run.invoker` para `allUsers`, requisito de invocação das Cloud Functions callable. A proteção efetiva continua no backend: token Firebase, membro da casa e owner para moderação.

## Validação manual ainda necessária

O APK release piloto `1.0.8-pilot+16` foi atualizado sobre a release anterior
com `adb install -r` e aberto com sucesso em um emulador Android 17, sem crash.
A tela inicial e os dados da sessão foram preservados. Isso valida empacotamento,
assinatura, atualização, inicialização e smoke visual, mas não substitui o teste cooperativo.

Com dois dispositivos e duas contas autorizadas, executar:

1. instalar `app-pilot-release.apk` nos dois dispositivos;
2. criar a casa no primeiro dispositivo e convidar o segundo usuário;
3. validar pull inicial e push de alterações;
4. criar publications concorrentes e resolver o conflito pelo owner;
5. excluir a casa e confirmar a remoção da árvore v2.

Se o APK piloto debug já estiver instalado, desinstalá-lo antes de instalar o
release, pois as duas variantes usam chaves de assinatura diferentes.

O Emulator foi validado com o JDK 25 já instalado em
`C:\Program Files\Android\Android Studio1\jbr`:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio1\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
firebase emulators:exec --config firebase.pilot.json --only firestore,auth --project demo-mercado-casa 'node tools/emulator_pilot_rules_test.js'
```

## Matriz de prontidão do roteiro cooperativo

A auditoria do código em 25/11/2026 separa o que o protocolo v2 realmente
implementa do roadmap ainda ausente. "Pronto" abaixo significa implementado e
coberto por teste; a validação final com dois dispositivos continua pendente.

| Cenário | Estado | Comportamento atual |
| --- | --- | --- |
| 1 — uso normal | Parcial | Criação da casa, convite, pull e push de snapshots completos existem; falta o teste real com dois dispositivos. |
| 2 — autoria e revisão | Ausente | O manifesto identifica o autor da publication, não de cada item. Não há nome do autor no item, revisão nem confirmação pelo owner. |
| 3 — remoção | Parcial | A remoção pode ser propagada por snapshot completo; não há tombstone de sincronização. |
| 4 — publicação concorrente sem sobreposição | Ausente | O perdedor é preservado como candidate, mas não há merge por item. |
| 5 — publicação concorrente com sobreposição | Parcial | O conflito de generation é detectado e preservado, mas o owner não recebe uma tela de comparação/decisão das duas versões. |
| 6 — duplicata por `logicalKey` | Ausente | Não existe `logicalKey` nem revisão de duplicatas. |
| 7 — falha de rede | Parcial | Chunks imutáveis e retry da mesma publication são idempotentes, mas o `publicationId` não é persistido para retomar automaticamente a mesma publication após nova tentativa. |
| 8 — owner remove durante publication antiga | Ausente | Não existe tombstone que impeça a ressurreição do item removido. |

O schema real do piloto continua Drift 7 e o backup real é formato 6. O schema
8/backup 7, IDs estáveis entre dispositivos, autoria por item, `logicalKey`,
tombstones e fluxo de moderação do owner pertencem à próxima camada e ainda
não são parte do APK `1.0.8-pilot+16`.

A correção que permite a um membro usar "Enviar todos os dados deste
dispositivo" sem ser tratado como publicação exclusiva do owner foi aplicada
no código após a tag `v1.0.8-pilot`. Ela ainda precisa entrar em um próximo
APK piloto; a release `1.0.8-pilot+16` não deve ser considerada atualizada com
essa correção.


## Próxima camada

- IDs estáveis e autoria por item no Drift/backup.
- Merge por `logicalKey` entre itens não sobrepostos.
- Tombstones e proteção contra remoção remota.
- Revisão de duplicatas e moderação pelo owner.
- Comparação visual das publications concorrentes.
