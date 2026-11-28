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

O APK piloto release anterior, validado em 25/11/2026, usava o package
`br.com.nocorre.mercado.pilot`, versionCode `16`, versionName `1.0.8-pilot`,
assinatura APK v2 válida e SHA-256
`E23086D99E94B5EBD7B861AA17C3D6C3580CAE2BEF171886BC6D45E870A26E27`.
Ele instala lado a lado com a produção e não pode substituir uma instalação
piloto debug, pois as chaves de assinatura são diferentes.

O APK piloto release collaboration gerado após a implementação do schema 8/backup 7
usa o package `br.com.nocorre.mercado.pilot`, versionCode `17`, versionName
`1.0.9-pilot`, assinatura APK v2 válida e SHA-256
`A1134A7B258B599D0A50BEC9846FD6A00296DAA51E38D9157CF39253F65274C5`.
Ele pode atualizar a release piloto `1.0.8-pilot+16` por `adb install -r`
quando ambas usarem a mesma chave de assinatura.

O APK piloto release com autoria e revisão, gerado em 25/11/2026, usa o
package `br.com.nocorre.mercado.pilot`, versionCode `18`, versionName
`1.0.10-pilot`, assinatura APK v2 válida, tamanho `67.953.188` bytes e
SHA-256 `6780925BBA38E98650A370E852E018E5DAE5637EC6D35222B502FED186D32F7A`.
Ele foi instalado com `adb install -r` e abriu sem crash no emulador Android.

A correção do fluxo de revisão usa o APK piloto release `1.0.11-pilot+19`,
também assinado com APK Signature Scheme v2 válido, tamanho `67.953.188` bytes
e SHA-256 `192F4B6FE776DD6338C500A28A76AD3505AC2D520F8C6A70BE8AD5014D2485B4`.
Ele foi instalado por cima da versão `+18` com `adb install -r` e abriu sem
crash no emulador Android.

A entrega após a correção da descoberta de pendências pelo owner usa o
APK piloto release `1.0.12-pilot+20`, assinatura APK v2 válida, tamanho
`67.953.188` bytes e SHA-256
`AF8BA3F6F43A24D4B363A21ED4C205E3F1D4040F5FD9124ACCBFDAB216661A1B`. Ele foi
instalado por cima da release anterior com `adb install -r` e abriu sem crash
no emulador Android.

A correção do conflito falso causado por IDs locais de compras e histórico usa
o APK piloto release `1.0.12-pilot+21`, assinatura APK v2 válida, tamanho
`67.953.188` bytes e SHA-256
`C2A386BFDD86B2E14B004AF21CA5F86396702B2E7B08C1AF56D4C655ABF0C158`.

A correção final da re-addição após remoção usa o APK piloto release
`1.0.12-pilot+23`, assinatura APK v2 válida, tamanho `67.969.572` bytes e
SHA-256 `17300C93F2A74BC3C10FEB447A9C383BFE2F76F48EA20F4C49EC08F01BD5C6D4`.
Ele foi instalado com `adb install -r` nos emuladores `emulator-5554` e
`emulator-5556` e validado no fluxo real membro → owner → membro.

A entrega com a correção do estado local × Firebase usa o APK piloto release
`1.0.13-pilot+24`, assinatura APK v2 válida, tamanho `67.985.956` bytes e
SHA-256 `A8DE1D30C23D8CB3BFE33C03B2F689263D581DF8703685C715E222B2EEDC4B19`.
Ele foi gerado em 26/11/2026 e ainda não foi instalado em aparelho: a
validação manual no fluxo real membro → owner → membro continua pendente.

## Entrega 1.0.14+25 — regras de segurança, Web piloto e APK

A entrega de 27/11/2026 aplica o reforço das regras do Firestore ao piloto e
atualiza os dois artefatos do piloto. Ela não modifica nem republica produção.

### APK piloto

- Package: `br.com.nocorre.mercado.pilot`
- versionName: `1.0.14-pilot`
- versionCode: `25`
- Tamanho: `67.985.956` bytes
- SHA-256: `28DFA189E100F8F01BAE664D623A267151CE07F98F52C69B4A625BA22B8EE58D`
- APK Distribution: `C:\Dev\Mercado\release-assets\nosso-mercadinho-1.0.14-pilot.apk`
- Checksum: `C:\Dev\Mercado\release-assets\nosso-mercadinho-1.0.14-pilot.apk.sha256`
- Source: `C:\Dev\Mercado\release-assets\nosso-mercadinho-v1.0.14-source.zip`

A assinatura APK Signature Scheme v2 foi validada com o certificado
`4576ea958c127b5a3fa0a671d47b65307d64b925032a04d99225087f39942035`
(RSA 2048). O APK foi instalado por cima da versão piloto anterior com
`adb install -r` e aberto sem crash nos emuladores `emulator-5554` e
`emulator-5556`; ambos reportaram `versionName=1.0.14-pilot` e `versionCode=25`.

O source zip contém o código Dart, Android, Web, regras e Functions, mas exclui
`.git`, builds, dependências, bibliotecas geradas, chaves e `key.properties`.

### Site Web piloto

O bundle foi gerado com:

```powershell
flutter build web --release --no-wasm-dry-run --base-href=/ --dart-define=MERCADO_PILOT_WEB=true
node tools/prepare_pilot_web.js
```

`--no-wasm-dry-run` desliga somente o dry-run de Wasm do compilador Flutter; o
bundle continua sendo JavaScript e mantém `sqlite3.wasm` e `drift_worker.js` para
o banco local. A inspeção do `main.dart.js` encontrou o App ID piloto
`1:1055183366543:web:94b3a4699576ce33cac3fa` uma vez e nenhum App ID de
produção. O SHA-256 do bundle local e remoto é:

```text
127667C0BCC56A24609BA28BBCD5C20EE6314D6839A457809C3FE3D88D9C7946
```

O Hosting piloto foi publicado somente em `nosso-mercado-casa-pilot`, no release
`1795824304934000`, versão `97e6983cd6df6b51`, status `FINALIZED`. A URL
`https://nosso-mercado-casa-pilot.web.app` respondeu HTTP 200 e o bundle remoto
teve o mesmo hash do bundle local.

## Entrega 1.0.18+29 — expiração de convites

A entrega de 28/11/2026 corrige o ciclo de vida dos convites somente no piloto:

- `expiresAt` contém um timestamp sete dias no futuro;
- as regras do piloto validam a expiração com `request.time` e limitam o prazo máximo;
- claim, associação e consumo do convite acontecem em uma transação atômica;
- revogação pelo owner permanece disponível;
- a interface mostra **expira em X dias**;
- erros de convite ausente, expirado, consumido ou destinado a outro e-mail são apresentados como **Convite inválido ou expirado.**

O protocolo e as regras de produção não foram alterados. A versão do app é
`1.0.18+29`.

### APK piloto

- Package: `br.com.nocorre.mercado.pilot`
- versionName: `1.0.18-pilot`
- versionCode: `29`
- Tamanho: `68.231.944` bytes
- SHA-256: `8DFCABA01352C246097627F467FC2C8EA0FD961D5A9E3D17F5F45CC90D466A33`
- Distribuição: `C:\Dev\Mercado\release-assets\nosso-mercadinho-1.0.18-pilot.apk`
- Checksum: `C:\Dev\Mercado\release-assets\nosso-mercadinho-1.0.18-pilot.apk.sha256`

A assinatura APK Signature Scheme v2 foi validada com o certificado release
`4576ea958c127b5a3fa0a671d47b65307d64b925032a04d99225087f39942035`
(RSA 2048). O APK não foi instalado em um aparelho.

### Site Web piloto

O bundle foi publicado somente em `nosso-mercado-casa-pilot`, em
`https://nosso-mercado-casa-pilot.web.app`. O SHA-256 do `main.dart.js` local e
remoto é `686D66AB7DA69DF88430607D730AC343C6941CF813FE2F47B160E51D27EFB0BE`.

### Backend e validação

As regras piloto e as Functions já foram publicadas em
`nosso-mercado-casa-pilot`. O callable `transferHouseholdOwnership` valida o
owner atual e o destino member, e usa Admin SDK para trocar `ownerUid` e papéis
em uma transação atômica; clientes não podem alterar esses campos diretamente.

Validação desta entrega:

- Emulator Firestore/Auth piloto: `REGRAS_OK`;
- Functions piloto: 26/26 testes Node;
- Flutter: 133/133 testes;
- `flutter analyze`: sem problemas;
- APK: assinatura v2 válida, instalação e abertura em dois emuladores;
- Web: HTTP 200, somente App ID piloto e hash local/remoto idêntico.

## Entrega 1.0.15+26 — diagnóstico de sincronização

A entrega de 27/11/2026 melhora o diagnóstico da sincronização no APK e na Web
do piloto. O painel passa a mostrar a última tentativa, a última sincronização
bem-sucedida, o dispositivo atual, a plataforma que fez a última publicação
oficial, o resultado por área e uma falha acionável. As ações contextuais são
**Tentar novamente**, **Verificar internet**, **Verificar acesso à casa** e
**Exportar backup**. A revisão técnica foi movida para **Detalhes técnicos**.

O diagnóstico é persistido como JSON versionado em `cloud_sync_settings.sync_diagnostics`.
O schema Drift evoluiu de 9 para 10 com migração aditiva; a troca de casa limpa
o histórico anterior e atualizações de revisão/hash preservam o diagnóstico da
casa atual. O backup continua no formato 7 e aceita schemas 1 a 10.

### APK piloto

- Package: `br.com.nocorre.mercado.pilot`
- versionName: `1.0.15-pilot`
- versionCode: `26`
- Tamanho: `68.068.056` bytes
- SHA-256: `BDF03A8260DC102F2001825B86BF1CEE5A3595E1DFDBED245C80E6E9F85C8D6B`
- APK Distribution: `C:\Dev\Mercado\release-assets\nosso-mercadinho-1.0.15-pilot.apk`
- Checksum: `C:\Dev\Mercado\release-assets\nosso-mercadinho-1.0.15-pilot.apk.sha256`

A assinatura APK Signature Scheme v2 foi validada com o certificado
`4576ea958c127b5a3fa0a671d47b65307d64b925032a04d99225087f39942035`
(RSA 2048). O APK foi instalado por cima da versão piloto anterior com
`adb install -r` e aberto sem crash nos emuladores `emulator-5554` e
`emulator-5556`; ambos reportaram `versionName=1.0.15-pilot` e `versionCode=26`.

### Site Web piloto

O bundle foi gerado com:

```powershell
flutter build web --release --no-wasm-dry-run --base-href=/ --dart-define=MERCADO_PILOT_WEB=true
node tools/prepare_pilot_web.js
```

A inspeção do `main.dart.js` encontrou o App ID piloto
`1:1055183366543:web:94b3a4699576ce33cac3fa` uma vez e nenhum App ID de
produção. O Hosting do projeto `nosso-mercado-casa-pilot` foi atualizado e
respondeu HTTP 200 com `Cache-Control: no-cache`. O SHA-256 do bundle local e
remoto é:

```text
12598598D6B7F5C46B6C74AFCEDC68D2A64820A000F28C6885308939BFA3C271
```

### Backend e validação

Nenhum backend, regra do Firestore ou manifesto remoto foi alterado ou
republicado. A origem oficial exibida pela tela vem dos campos existentes
`deviceId`, `authorName` e `createdAt` do manifesto v2.

Validação desta entrega:

- Flutter: 139/139 testes;
- Functions piloto: 26/26 testes Node;
- Functions de produção: 7/7 testes Node, sem alteração de código;
- `flutter analyze`: sem problemas;
- APK: assinatura v2 válida, instalação e abertura em dois emuladores;
- Web: HTTP 200, somente App ID piloto e hash local/remoto idêntico;
- Emulator: execução impedida porque o `firebase-tools` desta máquina exige
  JDK 21 e só há JDK 17 instalado; as regras não foram alteradas nesta entrega.

## Deploy exclusivo do piloto

```powershell
firebase deploy --config firebase.pilot.json --only firestore:rules --project nosso-mercado-casa-pilot
firebase deploy --config firebase.pilot.json --only functions --project nosso-mercado-casa-pilot
```

As regras de produção continuam em `firestore.rules` e são publicadas com `firebase.json`. O backend v2 fica em `functions-pilot/`; o source `functions/` continua exclusivo de produção.

### Site Web piloto

O Hosting do piloto usa o projeto `nosso-mercado-casa-pilot`, o Web App
`1:1055183366543:web:94b3a4699576ce33cac3fa` e o protocolo sync-v2. A build
precisa da flag explícita para nunca selecionar o projeto piloto por engano:

```powershell
flutter build web --release --base-href=/ --dart-define=MERCADO_PILOT_WEB=true
node tools/prepare_pilot_web.js
firebase deploy --config firebase.pilot.json --only hosting --project nosso-mercado-casa-pilot
```

O site publicado está em `https://nosso-mercado-casa-pilot.web.app`. A build Web
normal, sem `MERCADO_PILOT_WEB=true`, continua apontando para o App Web e as
regras de produção.

### Publicação das Functions em 27/11/2026

As Functions do projeto `nosso-mercado-casa-pilot` foram atualizadas em
27/11/2026. `beforeCreateUser`, `moderatePlannedItem`, `publishSyncV2` e
`transferHouseholdOwnership` ficaram `ACTIVE`, runtime nodejs22 e timeout 60 s.
O `roles/run.invoker` foi preservado: chamadas sem token chegam à função e
recebem `UNAUTHENTICATED`, e não `PERMISSION_DENIED` do IAM.

Antes da primeira publicação foi guardado o backup em
`C:\Dev\Mercado\release-assets\functions-pilot-backup-2026-11-27-0845.zip`, com
o código exato que estava rodando (commit `6e78b18`, o último a alterar
`functions-pilot` antes do deploy de 25/11), os metadados da API, as políticas
IAM, a configuração do projeto e o procedimento de rollback.

## Segurança do Firestore piloto

As regras endurecidas foram publicadas exclusivamente em
`nosso-mercado-casa-pilot` com `firestore.pilot.rules`. A política vigente é:

- **sincronizar**: membros leem o estado oficial e criam chunks candidatos
  imutáveis; manifesto, geração, hashes oficiais, revisões e conflitos são
  gravados exclusivamente pelas Functions com Admin SDK;
- **metadados e snapshot legado**: `tables` e `metadata` são somente leitura
  para membros; clientes não criam nem atualizam revision, hashes ou conteúdo;
- **convidar**: somente o owner cria e cancela convites; a pessoa destinada
  pode consultar/cancelar o próprio convite;
- **remover membros**: somente o owner remove membros comuns; o owner só é
  removido como parte da exclusão atômica da casa;
- **transferir propriedade**: somente o owner atual, por meio do callable
  `transferHouseholdOwnership`; o backend confirma que o destino é um membro
  comum e troca `ownerUid` e os papéis em uma transação atômica;
- **excluir a casa**: somente o owner; a limpeza dos documentos legados e da
  árvore sync-v2 permanece autorizada para essa operação.

A suíte do Emulator cobre owner, member, outsider, criação/claim de convite,
escrita direta indevida em manifesto e metadata, chunks imutáveis, remoção de
membros, transferência, exclusão e acesso ao estado v2. A validação local ficou
verde com 26 testes Node, 133 testes Flutter, `flutter analyze` sem problemas e
`REGRAS_OK` no Emulator.

## Protocolo v2 implementado

- O schema persistente é Drift 10. Produtos, listas e itens planejados possuem `syncId`, `logicalKey`, autoria, estado de revisão, `deletedAt` e `syncRevision`; as configurações de sincronização memorizam o último owner confirmado para um fallback offline conservador e o diagnóstico JSON da última tentativa.
- As migrações 7 → 9 preenchem IDs e chaves legadas de forma determinística e tolera bancos com layout parcial; a migração 9 → 10 adiciona `sync_diagnostics` sem alterar os dados de mercado.
- O backup atual é formato 7, serializa os metadados de colaboração e preserva tombstones. Backups 1–6 continuam aceitos e recebem defaults legadas durante o restore; o validador aceita schemas 1 a 10.
- Itens criados por membro entram como `pending_review`; o owner pode confirmar ou remover explicitamente pela central **Conta e sincronização → Revisão do owner**. O owner cria itens já aprovados.
- A decisão do owner é gravada por `moderatePlannedItem` em `syncV2/{householdId}/reviews/{itemSyncId}` após validar `households/{householdId}.ownerUid` e a autoria publicada. O cliente aplica essas revisões antes do merge; o backend impede publicação que reverta uma decisão ou um tombstone.
- A hierarquia de moderação é uma regra pura e testada (`findModerationViolation` em `functions-pilot/src/sync_v2_moderation.ts`): somente o owner confirmado da casa decide, a decisão é sempre sobre um item publicado e de outro membro, e um item do próprio owner não passa por revisão. Um membro que não é o owner recebe `permission-denied`.
- O owner remove um item da lista de um membro pela central **Conta e sincronização → Revisão do owner → Remover da lista**. A remoção vira tombstone no item (`reviewState=rejected`, `isRemoved=true`, `deletedAt` e `reviewedAt` gravados) e o item deixa de aparecer nas consultas normais do membro, inclusive no histórico de revisões.
- A decisão do owner é aplicada de forma idempotente: repetir a mesma decisão não avança `syncRevision` de novo, de modo que dois aparelhos com o mesmo conteúdo não pareçam diferentes. O instante gravado usa a precisão de segundos em UTC, a mesma que sobrevive ao banco local e ao backup.
- Toda publicação carrega as decisões do owner: tanto a sincronização quanto a ação **Enviar todos os dados deste dispositivo** aplicam as revisões antes de publicar, e a decisão também é gravada no banco local do aparelho que publica. Sem isso, o backend recusaria a publicação do membro com `reviewed_state_mismatch` depois de uma remoção do owner.
- A comparação entre o estado local e o estado publicado é feita por conteúdo (hash semântico), e não por bytes: identificadores inteiros locais, contadores de revisão e a representação textual dos instantes são ignorados. Dois aparelhos com o mesmo conteúdo são vistos como "em dia", e a base semântica de cada área é memorizada sob a chave própria `semantic:<área>`, ao lado do hash de bytes histórico.
- A confirmação ou remoção na central do owner é uma operação isolada: ela grava a decisão e atualiza somente o item local, sem reconciliar listas, compras e histórico. Conflitos preexistentes entre dispositivos continuam sendo tratados explicitamente pela ação de sincronização, sem fazer a decisão do owner aparecer como falha.
- O painel do owner combina as pendências locais com os itens `pending_review` publicados oficialmente na casa, deduplicados por `syncId`. Assim, uma pendência publicada pelo membro aparece mesmo antes de um pull completo, e deixa de aparecer depois de uma decisão registrada.
- Quando o papel não pode ser resolvido offline, o autor é conservadoramente tratado como membro e o item permanece pendente; somente uso local sem casa selecionada mantém o fallback local.
- A identidade cross-device usa `syncId`; `logicalKey` é a chave semântica e pode permanecer duplicada para permitir detecção e decisão do owner.
- Uma re-addição posterior à remoção cria uma nova identidade (`syncId`) e uma nova revisão, sem reutilizar o `syncId` do tombstone. A compatibilidade separa também as re-addições pendentes originadas por builds piloto anteriores.
- A exclusão lógica preserva linhas como tombstone. O tombstone vence um item vivo durante o merge e impede ressurreição por publicação antiga. O tombstone original e a re-addição posterior coexistem como linhas distintas.
- O merge por área é atômico para tabelas não colaboráveis e por item para as tabelas colaboráveis. Uniões sem sobreposição são republicadas; conflitos reais permanecem em `CloudSyncConflictException`. A comparação de itens usa representação JSON canônica, portanto a ordem das chaves reconstruída pelo Firestore não gera falso conflito. Para compras e histórico, a igualdade é comparada semanticamente, ignorando IDs inteiros e referências internas que existem apenas no dispositivo; mudanças reais de quantidade, produto, mercado, data ou valores continuam sendo conflitos.
- A restauração normaliza colisões de PK inteira entre dispositivos usando os `syncId` dos pais e remapeia as referências de itens planejados, importações e compras.
- Cada área é dividida em chunks imutáveis de até 700 KiB.
- Cada chunk possui hash SHA-256 canônico e contagem de linhas.
- O manifesto aponta para todos os chunks e informa hashes e contagens por tabela.
- A Function `publishSyncV2` valida os chunks e executa compare-and-swap atômico por `generation` e `manifestHash`.
- O estado oficial do piloto é um manifesto v2 em `syncV2/{householdId}/state/current`, composto por chunks imutáveis. A publicação usa compare-and-swap atômico sobre `generation` e `manifestHash`; uma candidate concorrente rejeitada permanece em `syncV2/{householdId}/candidates` e é preservada em `syncV2/{householdId}/conflicts` para decisão do owner. Regras e backend do piloto ficam em `firestore.pilot.rules`/`firebase.pilot.json`, sem alteração do arquivo de regras de produção.
- Retry da mesma publication é idempotente.
- O cliente detecta pull, push e conflito por área sem alterar o banco local quando há conflito.

## Estado operacional

### Administração da allowlist do piloto — 28/11/2026

A allowlist do piloto deixou de depender do script que substituía a lista
completa. A nova ferramenta administrativa é a CLI
`functions-pilot/src/scripts/manage-registration-allowlist.ts`, publicada
somente no backend de `nosso-mercado-casa-pilot`:

- `npm run allowlist -- list`: lista e-mails mascarados, papel, data da última
  alteração e conta que executou a mudança;
- `npm run allowlist -- add EMAIL`: valida, normaliza e adiciona o e-mail;
- `npm run allowlist -- remove EMAIL`: revoga a autorização;
- `npm run allowlist -- promote EMAIL`: promove uma conta Auth existente a
  administrador;
- `npm run allowlist -- history`: mostra as últimas 50 operações de auditoria.

A CLI autentica a conta administrativa no Identity Platform e chama a
`manageRegistrationAllowlist`. O servidor confere o token e exige uma entrada
com papel `admin`; clientes não leem nem alteram a configuração privada. A
documentação privada e sua subcoleção de auditoria são negadas pelas regras
pilot, e somente o Admin SDK usado pela Function grava os dados. E-mails
completos não são gravados nem exibidos: a configuração continua baseada em
hash SHA-256, com uma máscara adicional para listagem e auditoria. A remoção do
último administrador é recusada na transação.

A conta administrativa inicial é separada da conta usada pela família. O
bootstrap é feito uma única vez, com sessão local do Firebase CLI e variáveis
de ambiente:

```powershell
Set-Location functions-pilot
$env:MERCADO_ADMIN_EMAIL = 'ALIAS_ADMINISTRATIVO'
$env:MERCADO_ADMIN_PASSWORD = 'SENHA_FORTE_COM_NO_MINIMO_16_CARACTERES'
npm run allowlist:bootstrap
Remove-Item Env:MERCADO_ADMIN_EMAIL
Remove-Item Env:MERCADO_ADMIN_PASSWORD
```

O bootstrap cria a conta no Identity Platform, registra o hash na allowlist
com papel `admin` e salva as credenciais fora do repositório em
`%USERPROFILE%\.config\mercado-pilot-admin.json`. A CLI usa esse arquivo
automaticamente; alternativamente, `MERCADO_ADMIN_EMAIL` e
`MERCADO_ADMIN_PASSWORD` podem ser fornecidos pelo ambiente. E-mails, senhas e
hashes não são versionados.

Validação remota desta entrega, exclusivamente no projeto piloto:

- regras do Firestore compiladas e publicadas; a configuração privada e a
  auditoria permanecem inacessíveis aos clientes;
- `manageRegistrationAllowlist` publicada e ativa em `us-central1`, Node.js 22;
- `list` confirmou 1 administrador e 2 membros, sempre mascarados;
- inclusão e remoção de uma entrada temporária concluíram com sucesso;
- o histórico registrou ação, alvo mascarado, autor mascarado e instante;
- a remoção do único administrador foi recusada;
- Functions piloto: 31/31 testes Node aprovados.

A melhoria não altera o aplicativo Flutter, o APK `1.0.18+29`, o Web App ou
qualquer recurso de produção.

- Plano Blaze ativo; o projeto aceita deploy de Cloud Functions.
- Identity Platform/GCIP inicializado no projeto piloto, com E-mail/Senha habilitado e `passwordRequired=true`.
- `beforeCreateUser`, `publishSyncV2`, `moderatePlannedItem` e `transferHouseholdOwnership` publicadas e ativas em `us-central1`, Node.js 22 (2nd Gen). As Functions de sincronização e propriedade compartilham o source validado com as proteções de autoria, decisão do owner e transferência atômica.
- `beforeCreateUser` vinculada ao trigger `beforeCreate`; e-mails fora da allowlist são recusados com `PERMISSION_DENIED`.
- Allowlist privada do piloto em `privateConfig/registrationAllowlist`, com hashes SHA-256 e sem e-mails em texto aberto.
- Regras `firestore.pilot.rules` compiladas e publicadas em 25/11/2026; membros leem `reviews`, enquanto somente o Admin SDK usado pela Function pode escrevê-las.
- O índice Collection Group `members.uid` foi publicado e validado no Firestore piloto; consultas de descoberta das casas do usuário não exigem mais `FAILED_PRECONDITION`.
- E2E real no projeto piloto aprovado: cadastro autorizado e não autorizado, commit CAS, retry idempotente, retenção de candidate rejeitada, criação de conflito e negação para usuário sem vínculo com a casa. Todas as contas, casas, publications e entradas temporárias de allowlist foram removidas após o teste.
- O serviço `publishsyncv2` possui `roles/run.invoker` para `allUsers`, requisito de invocação das Cloud Functions callable. A proteção efetiva continua no backend: token Firebase, membro da casa e owner para moderação.

## Validação manual executada

O APK release piloto `1.0.12-pilot+23` foi verificado com assinatura APK v2
válida e instalado por cima da release anterior com `adb install -r` nos
emuladores `emulator-5554` e `emulator-5556`. A aplicação abriu sem
`FATAL EXCEPTION` e o fluxo cooperativo real foi executado com as contas
owner e membro da casa `Testezinho`:

1. o **membro** executou **Sincronizar agora** e publicou a re-addição sem o
   aviso `Este conflito precisa ser decidido pelo dono da casa`; a revisão do
   Firebase avançou de 23 para 24;
2. o **owner** atualizou o painel, recebeu a pendência nova separadamente da
   remoção anterior e a **Remover da lista** concluiu sem conflito;
3. o **membro** sincronizou novamente, recebeu a decisão e a pendência
   removida deixou de aparecer no painel;
4. o backup final preservou o tombstone original com `syncId` distinto e a
   re-addição com nova identidade, sem reutilização do `syncId` removido.

O logcat não registrou `FATAL EXCEPTION`, `permission-denied`, `data-loss` ou
`failed-precondition` durante o fluxo. Permanecem como validação futura os
cenários de publications concorrentes, resolução de duplicatas e exclusão da
árvore v2.

Se o APK piloto debug já estiver instalado, desinstalá-lo antes de instalar o
release, pois as duas variantes usam chaves de assinatura diferentes.

## Validação automatizada da revisão do owner e da comparação semântica

As correções descritas acima foram verificadas por teste automatizado, sem
depender de aparelho:

- `functions-pilot`: `npm test` passou com 21 testes, incluindo a hierarquia de
  moderação (`findModerationViolation`): o owner remove um item de outro
  membro, um membro sem o papel de owner é recusado, item não publicado e item
  legado sem autoria são recusados, e o owner não modera item próprio.
- `flutter test`: passou com 133 testes, incluindo o fluxo completo de remoção
  (membro cria item pendente → owner remove → item fica com tombstone no banco
  local, com autoria e instante canônicos, e a repetição da decisão não conta
  de novo), a publicação do membro carregando a decisão do owner, o
  reconhecimento de "em dia" para áreas com o mesmo conteúdo e identificadores
  locais diferentes, o status que não acusa divergência quando só a decisão do
  owner difere e o painel que detalha a diferença.
- `flutter analyze`: sem problemas.

Essas correções estão publicadas no APK piloto `1.0.13-pilot+24`, que ainda
não foi validado em aparelho. Antes de tratar o fluxo como validado em
aparelho, o novo build precisa ser instalado e exercitado no fluxo real
membro → owner → membro.

O Emulator foi validado com o JDK 25 já instalado em
`C:\Program Files\Android\Android Studio1\jbr`:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio1\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
firebase emulators:exec --config firebase.pilot.json --only firestore,auth --project demo-mercado-casa 'node tools/emulator_pilot_rules_test.js'
```

## Matriz de prontidão do roteiro cooperativo

A auditoria do código em 25/11/2026 separa o que o protocolo v2 realmente
implementa do roadmap ainda ausente. "Pronto" abaixo significa implementado,
coberto por teste e validado no fluxo cooperativo real de 26/11/2026.

| Cenário | Estado | Comportamento atual |
| --- | --- | --- |
| 1 — uso normal | Parcial | Criação da casa, convite, pull e push de snapshots completos existem; falta o teste real com dois dispositivos. |
| 2 — autoria e revisão | Pronto | Itens exibem “Adicionado por”; a central do owner mostra pendências e permite confirmar/remover; a decisão é validada, registrada no backend e validada com duas contas/dispositivos. A hierarquia é uma regra pura do backend: somente o owner decide, e somente sobre item publicado de outro membro. |
| 3 — remoção | Pronto | Remoções preservam tombstone e o item desaparece das consultas normais. A remoção decidida pelo owner chega ao aparelho do membro pela revisão autoritativa, inclusive quando o membro publica explicitamente os dados locais. |
| 4 — publicação concorrente sem sobreposição | Pronto | Alterações em `logicalKey` diferentes são unidas por item e republicadas. |
| 5 — publicação concorrente com sobreposição | Parcial | O conflito é detectado e o banco local não é alterado; falta uma tela central de comparação/decisão. |
| 6 — duplicata por `logicalKey` | Parcial | Duplicatas são detectadas no merge e preservadas para decisão; falta a UI de resolução pelo owner. |
| 7 — falha de rede | Parcial | Chunks imutáveis e retry da mesma publication são idempotentes, mas o `publicationId` não é persistido para retomar automaticamente a mesma publication após nova tentativa. |
| 8 — owner remove durante publication antiga | Pronto | O tombstone vence o item vivo e impede ressurreição por publicação antiga. |
| 9 — mesmo conteúdo em dois aparelhos | Pronto | A comparação entre o estado local e o publicado é feita por conteúdo (hash semântico): IDs locais, contadores de revisão e instantes escritos de outra forma não geram falso conflito nem republicação desnecessária. |

O schema persistente implementado é Drift 9 e o backup é formato 7. O APK
`1.0.10-pilot+18` inclui IDs estáveis entre dispositivos, autoria/revisão por
item, `logicalKey`, tombstones, merge por item e a central de moderação do owner.


## Limitações e próxima camada

- O cliente persiste apenas o hash da base, não o payload-base. Alterações concorrentes do mesmo item são, por isso, tratadas conservadoramente como conflito. A base é memorizada em duas chaves: o hash de bytes histórico e o hash semântico (`semantic:<área>`), que é o usado na comparação de conteúdo.
- As correções da revisão do owner (aplicação idempotente, publicação honrando a decisão e comparação semântica) e da comparação de estado local × Firebase estão publicadas no APK piloto `1.0.13-pilot+24`, que ainda não foi validado em aparelho. O build `1.0.12-pilot+23` continua sendo o último validado em aparelho.
- A separação entre uma remoção do owner e uma re-addição posterior do membro usa o instante local da linha e o instante servidor da decisão. Um aparelho com o relógio muito adiantado pode tratar um item como re-addição e manter a pendência; o item continua visível para o owner decidir de novo.
- Não existe UI central de conflitos/publicação consolidada; a decisão de duplicatas continua pendente. A moderação de autoria/revisão possui UI central própria.
- A migração do Firestore piloto para `southamerica-east1` exige uma operação destrutiva coordenada; o projeto permanece em `nam5`.
- A collaborative key (`syncId`) é validada como única por tabela no payload, mas não há índice UNIQUE físico no schema 9.
- O fluxo de re-addição e moderação foi validado com duas contas/dispositivos; publications concorrentes, duplicatas e exclusão da árvore v2 continuam como cenários futuros.

## Sincronização automática conservadora — 1.0.16+27

A versão `1.0.16+27` acrescenta sincronização automática ao APK e à Web do
piloto. A mudança é somente no cliente: `functions-pilot`, regras do Firestore,
manifesto v2 e formato de backup não foram alterados.

A automação só age quando existe rede, sessão Firebase válida e casa
selecionada. Cada área é comparada por hash local, remoto e hash-base:

- local e remoto iguais: **Em dia**, sem escrita;
- somente local diferente da base: publica a área local;
- somente remoto diferente da base: aplica a área remota;
- local e remoto diferentes da base: **Divergente**, sem merge, publicação ou
  sobrescrita.

No piloto, a divergência interrompe toda a sincronização automática. O aviso
**Há uma divergência pendente** pede que o usuário abra **Conta e
sincronização**. A resolução continua explícita: **Usar remota**,
**Enviar todos os dados deste dispositivo** ou a decisão de conflito/owner
exigida pelo fluxo v2. A automação não escolhe o relógio mais recente e não
substitui essa decisão.

Os gatilhos são entrada em primeiro plano, retorno do app ao primeiro plano,
alteração local com debounce de um segundo e, na Web, foco/visibilidade do
documento. Não há polling nem sincronização em background. Uma verificação HTTP
pública impede escrita quando a rede falha; sessões expiradas e falhas de
leitura remota também pausam a automação. Execuções simultâneas são ignoradas
e um cooldown evita loops de publicação.

O watcher local do Drift usa contagem e `updated_at` das tabelas
sincronizáveis. Ele somente agenda uma verificação; a decisão de escrever vem
sempre da comparação com a base. Em testes Flutter, a automação é desligada
pela variável `FLUTTER_TEST=true` exportada pelo runner.

Validação local desta entrega: `flutter analyze` sem problemas; 152 testes
Flutter aprovados; 26/26 testes Node do `functions-pilot`; build Web release
compilada com `MERCADO_PILOT_WEB=true`. O Emulator continua indisponível nesta
máquina por ausência de JDK 21 para a versão instalada do `firebase-tools`, e
nenhuma regra foi alterada. A validação em dois dispositivos e em aparelho
Android real permanece manual.

## Administração de pessoas da casa — 1.0.17+28

A versão `1.0.17+28` acrescenta ao APK e à Web do piloto a seção **Pessoas da
casa**, em **Conta e sincronização**. A interface lista o nome, o papel e a data
de entrada de cada pessoa, informa quantas pessoas pertencem à casa e mostra
**Você é o dono desta casa** ao owner.

O owner pode:

- remover uma pessoa comum, revogando sua associação e claim de entrada sem
  apagar os dados já compartilhados;
- revogar um convite pendente, depois de confirmar a ação;
- transferir a propriedade para outro membro por meio da Function
  `transferHouseholdOwnership`.

O owner não pode remover a própria associação. A propriedade precisa ser
transferida primeiro. Membros comuns veem a lista e os papéis, mas não veem os
e-mails dos demais, os convites pendentes nem as ações administrativas. No
build de produção, a seção não é exibida.

A implementação reutiliza `households/{id}/members`,
`householdInvites` e a Function de transferência já existentes. Nenhuma regra,
Function, dependência ou formato de sincronização foi alterado. A callable
`transferHouseholdOwnership` precisa estar publicada no projeto piloto antes
da validação manual da transferência; esta entrega de código não publica
Functions no Firebase.

Validação local desta entrega: `flutter analyze` sem problemas; 161/161 testes
Flutter aprovados, incluindo 9 testes novos de serviços e interface; 26/26
testes Node do `functions-pilot`; builds Web release piloto e produção e APKs
debug `pilot` e `production` compilados. O Emulator continua indisponível por
ausência de JDK 21 compatível com a versão instalada do `firebase-tools`; como
nenhuma regra mudou, não foi exigido para esta entrega. A validação das ações
administrativas em dois dispositivos reais e em aparelho Android permanece
manual.
