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

## Deploy exclusivo do piloto

```powershell
firebase deploy --config firebase.pilot.json --only firestore:rules --project nosso-mercado-casa-pilot
firebase deploy --config firebase.pilot.json --only functions --project nosso-mercado-casa-pilot
```

As regras de produção continuam em `firestore.rules` e são publicadas com `firebase.json`. O backend v2 fica em `functions-pilot/`; o source `functions/` continua exclusivo de produção.

### Publicação das Functions em 27/11/2026

As três Functions do projeto `nosso-mercado-casa-pilot` foram atualizadas em
27/11/2026 com `firebase deploy --config firebase.pilot.json --only functions
--project nosso-mercado-casa-pilot`. `beforeCreateUser`, `moderatePlannedItem`
e `publishSyncV2` ficaram `ACTIVE`, runtime nodejs22, timeout 60 s, revisão
`moderateplanneditem-00002-guz` e `firebase-functions-hash`
`90efaddf6af6c6d0a4c1f9739db8cddc586fdf92`. O `roles/run.invoker` foi
preservado (as chamadas sem token chegam à função e respondem
`INVALID_ARGUMENT`, e não com `PERMISSION_DENIED` do IAM) e o artefato baixado
do bucket `gcf-v2-sources` contém `lib/sync_v2_moderation.js` com a regra
`isHouseholdOwner`: a hierarquia de moderação está no ar.

Antes da publicação foi guardado o backup em
`C:\Dev\Mercado\release-assets\functions-pilot-backup-2026-11-27-0845.zip`, com
o código exato que estava rodando (commit `6e78b18`, o último a alterar
`functions-pilot` antes do deploy de 25/11), os metadados da API, as políticas
IAM, a configuração do projeto e o procedimento de rollback.

## Protocolo v2 implementado

- O schema persistente é Drift 9. Produtos, listas e itens planejados possuem `syncId`, `logicalKey`, autoria, estado de revisão, `deletedAt` e `syncRevision`; as configurações de sincronização memorizam o último owner confirmado para um fallback offline conservador.
- A migração 7 → 9 preenche IDs e chaves legadas de forma determinística e tolera bancos com layout parcial.
- O backup atual é formato 7, serializa os metadados de colaboração e preserva tombstones. Backups 1–6 continuam aceitos e recebem defaults legadas durante o restore.
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

- Plano Blaze ativo; o projeto aceita deploy de Cloud Functions.
- Identity Platform/GCIP inicializado no projeto piloto, com E-mail/Senha habilitado e `passwordRequired=true`.
- `beforeCreateUser`, `publishSyncV2` e `moderatePlannedItem` publicadas e ativas em `us-central1`, Node.js 22 (2nd Gen). As duas callables de sincronização compartilham o source validado com as proteções de autoria e decisão do owner.
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
