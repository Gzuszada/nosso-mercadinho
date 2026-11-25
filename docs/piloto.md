# Piloto Android de sincronização v2

## Identidade

- Projeto Firebase: `nosso-mercado-casa-pilot`
- App Android: `1:1055183366543:android:8f96bffb2bc03b07cac3fa`
- Package: `br.com.nocorre.mercado.pilot`
- Firestore: `(default)`
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
`br.com.nocorre.mercado.pilot`, versionCode `15`, versionName `1.0.7-pilot`,
assinatura APK v2 válida e SHA-256
`21A03C4852583EDD93F2B5C3002934F5589E7DA93145FCEFAAA2FA5A3630428A`.
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

O APK release piloto foi instalado e aberto com sucesso em um emulador Android
17, sem crash, e a tela de autenticação foi renderizada. Isso valida empacotamento,
assinatura, instalação e inicialização, mas não substitui o teste cooperativo.

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

## Próxima camada

- IDs estáveis e autoria por item no Drift/backup.
- Merge por `logicalKey` entre itens não sobrepostos.
- Tombstones e proteção contra remoção remota.
- Revisão de duplicatas e moderação pelo owner.
- Comparação visual das publications concorrentes.
