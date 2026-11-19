# Progresso

## Estado atual — 19/11/2026

- Tela de sincronização corrigida na Web e no APK: os contadores da tela **Conta e sincronização** não exibem mais nomes internos de tabelas como `shoppingPlans`, `plannedItems`, `shoppingTrips`, `purchaseLines`, `importBatches` ou `importEntries`. Agora são usados os mesmos termos do aplicativo: **categorias**, **subcategorias**, **produtos**, **importações**, **itens importados**, **listas**, **itens das listas**, **compras** e **itens das compras**, com pluralização correta. O identificador de build `2026-11-18-sync-v2` também foi removido do cabeçalho e os erros de validação remota usam rótulos amigáveis. As chaves internas do protocolo e do banco não foram alteradas. `flutter analyze --no-pub` passou sem problemas; os 17 testes direcionados e a suíte completa com 96 testes passaram. A build Web release foi publicada no Firebase Hosting e validada publicamente com HTTP 200 e `Cache-Control: no-cache`. O APK release assinado `1.0.7+15` (`br.com.nocorre.mercado`, versionCode 15) tem assinatura v2 válida, 66.232.364 bytes e SHA-256 `7B43417F77CB74288DA73020C0E07EDF05524B71571B8DC79448C392E4311DB7`; o certificado permanece compatível com as releases anteriores. Não havia aparelho Android conectado para instalação e teste físico.

- Recuperação de senha no APK: a tela de entrada agora oferece **Esqueci minha senha** na Web e no Android. O serviço usa `sendPasswordResetEmail`, o template padrão do Firebase Authentication e a URL autorizada `https://nosso-mercado-casa.web.app`; a troca é concluída no navegador e retorna ao site. A resposta de sucesso é genérica, sem revelar se o e-mail possui conta. `flutter analyze --no-pub` passou sem problemas; a suíte completa passou com 96 testes; o build release assinado `1.0.6+14` (`br.com.nocorre.mercado`, versionCode 14) foi gerado com assinatura APK v2 válida, 66.232.360 bytes e SHA-256 `421B2E7E7118188CF95367EC863FADADF021C3B6239892A0A0007B8CB63BED57`. O certificado é idêntico ao das releases anteriores, permitindo atualização sem desinstalação. Não havia aparelho Android conectado para instalação e teste físico.

## Estado anterior — 17/11/2026

- Correção da PWA travada: a build JavaScript padrão acionava bindings FFI nativos incompatíveis com WebAssembly. A build oficial agora é `flutter build web --release --no-pub`: a interface usa Dart2JS, sem exigir WasmGC, e o Drift é executado em `drift_worker.js` com o `sqlite3.wasm` oficial do `sqlite3 3.5.2` (SHA-256 `13D3F11D05B39BA0618A7115FB41640A5D48B6300F5D3F325F554B42BD6688A4`). O bundle não contém ``sqlite3_temp_directory`` nem ``DynamicLibrary``; smoke test no Chrome confirmou abertura do worker e criação do banco IndexedDB sem exceções. Essa combinação cobre o erro do Android e a página branca do iPhone 11/Safari sem WasmGC. `flutter analyze` passou sem problemas e os 86 testes foram aprovados. O APK `1.0.4+12` não foi alterado.

- PWA **Nosso Mercado** publicada em `https://nosso-mercado-casa.web.app`, no novo projeto Firebase `nosso-mercado-casa`. Os aplicativos Android (`br.com.nocorre.mercado`) e Web foram registrados nesse projeto.
- A versão `1.0.1+9` mantém o mesmo `applicationId` e a mesma chave de assinatura, permitindo atualização do APK sem perda do banco Drift local.
- A validação HTTP pública confirmou `index.html`, manifesto, service worker, ícones, `drift_worker.js`, `sqlite3.wasm` e `main.dart.js` com HTTP 200 e tipos adequados. O bundle publicado não contém o limite inteiro de 64 bits que causava problemas de interoperabilidade no SQLite web.
- Firestore `(default)` criado e publicado em `southamerica-east1` no novo projeto; as regras compilaram e foram liberadas. O fluxo de convite e acesso já foi validado no Emulator.
- Sync compartilhado implementado por `catalog`, `imports` e `shopping`, com hash SHA-256 canônico, revisão e conflitos tipados. “Usar remota” restaura a área no Drift sem sobrescrever silenciosamente os hashes-base locais.
- A Interface resolve múltiplos conflitos sequencialmente e os códigos de convite usam `Random.secure()`. Backup aceita schema 7 mantendo compatibilidade de leitura.
- `flutter analyze`: sem problemas. `flutter test --no-pub`: 81 testes aprovados, incluindo o gate de autenticação, a troca segura de casa e o estado-base da sincronização. Functions: build TypeScript e 3 testes da allowlist aprovados. Build Web release e Hosting da versão `1.0.1+9` concluídos; o bundle público contém o gate e não contém e-mails ou hashes.
- Cadastro restrito no servidor: blocking function `beforeCreateUser` com allowlist privada de hashes SHA-256, regras públicas negando a leitura da configuração e falha fechada quando a lista ou a Function estiver ausente. A allowlist de produção contém dois hashes únicos: o e-mail principal e o e-mail confirmado da Iasmim.
- O Identity Platform foi inicializado, o provedor E-mail/Senha foi habilitado e a blocking function `beforeCreateUser` foi publicada e vinculada ao evento `beforeCreate`. Teste real: e-mail fora da allowlist foi recusado com `PERMISSION_DENIED`; e-mail temporariamente autorizado foi aceito, com a conta de teste excluída e a lista restaurada para um hash.
- Cadastro da Iasmim: o e-mail foi confirmado e a allowlist foi atualizada com dois hashes. A Iasmim está autorizada para criar a conta; no Identity Platform há apenas uma conta, pois o novo login ainda não foi criado.
- Pendência de validação: executar o fluxo real com duas contas, inclusive criação da casa, convite, sincronização, alterações nos dois dispositivos e resolução de conflito.
- Versão do app: `1.0.4+12` (Android build 12). O login é obrigatório antes de acessar qualquer área do mercado; após autenticar, o Drift local continua funcionando offline. APK release assinado gerado (`br.com.nocorre.mercado`, assinatura v2 válida), tamanho `61.184.588` bytes e SHA-256 `1C59AA5CEE7222210C5C7FBEF5DB86F68EF68689A4DFF36A30A95EFC96118699`. A versão anterior `1.0.2+10` permanece disponível.
- Diagnóstico da sincronização entre dispositivos: a conta do proprietário está no projeto correto e possui 3 casas no Firestore, todas com nome; 2 casas possuem tabelas e metadados remotos. A versão anterior consultava apenas o `householdId` salvo no Drift e não descobria memberships pelo UID, portanto um PC com banco novo não restaurava o nome. A `1.0.2+10` consulta os próprios documentos `members`, lê os nomes das casas, restaura a seleção local e permite escolha explícita quando há mais de uma casa. A regra publicada permite apenas listar registros de membro do próprio UID.
- Nome de usuário: o cadastro aceita um nome opcional e a tela de conta/sincronização permite editá-lo. O valor é salvo no campo nativo `displayName` do Firebase Auth, com validação de 2–40 caracteres, fallback `Usuário` para contas antigas e espelhamento best-effort nos documentos `members`. As regras do Firestore permitem ao membro alterar somente o próprio `displayName`, preservando `uid` e `role`; regras de produção compiladas e publicadas. A suíte inclui testes do nome e da proteção dos demais campos. Validação da entrega: `flutter analyze` sem problemas, 86 testes aprovados e Emulator aprovado para as regras de dono, convite, membro, não-membro e allowlist privada.
- Releases `1.0.2` e `1.0.2+10` publicadas no GitHub com APK assinado e source zip. Os assets baixados das próprias releases foram verificados: APK com 66.390.904 bytes, assinatura v2 válida e SHA-256 `D8A92164E0AC9EF73060DEA9D933AA796E4F168AE5A70E0033BED59C76A45C77`; source zips sem caminhos de credencial/build, e-mail do proprietário ou chave privada. O backup e o relatório de build indevidos foram removidos do clone aberto e a tag `v1.0.2+10` foi recriada sobre o commit saneado (`4e1509c`).
- Releases `1.0.3` (`v1.0.3`) e `1.0.4+12` (`v1.0.4+12`) publicadas no GitHub com APK assinado e source zip. Os assets foram baixados pelo endpoint oficial e verificados: APK com 61.184.588 bytes, assinatura v2 válida e SHA-256 `1C59AA5CEE7222210C5C7FBEF5DB86F68EF68689A4DFF36A30A95EFC96118699`; source zips sem caminhos de credencial/build, e-mail do proprietário ou chave privada. As regras do Firestore e os três documentos `members` do proprietário foram verificados em produção, preservando `uid` e `role`. Os repositórios são privados, portanto os assets exigem autenticação GitHub, assim como nas releases anteriores.
- Schema Drift 6: `purchase_lines.is_label_total` identifica linhas cujo total pago veio da etiqueta. `total_cents` é autoritativo; `unit_price_cents` é o valor derivado necessário para exibir a base de cálculo.
- Backup formato 6, com `formatVersion` encaminhado na restauração; formatos 1 a 6 são aceitos de forma independente. Listas com status `open` são preservadas.
- Compras por peso aceitam o total real da etiqueta. O “último pago” usa o total e a quantidade da linha válida mais recente, sem agregar outras linhas do mesmo produto na viagem de referência.
- A lista pode permanecer `open` após uma compra parcial. A conclusão continua em duas fases: primeiro conclui a compra; depois o usuário decide entre manter a lista aberta, mover o restante para uma nova lista ou encerrá-la.
- A lista restante é criada por inserção direta, preservando a forma de compra e o snapshot de estimativa do item original, inclusive quando a origem está `open`.
- No carrinho, os controles em lote por categoria oferecem **Unidade**, **Pacote** e **Peso** e afetam somente produtos pendentes. O rodapé expandido tem altura limitada e rolagem, sem overflow com fonte ampliada.
- `flutter analyze`: sem problemas. `flutter test --no-pub`: 71 testes aprovados. `widget_test.dart`: 15 testes aprovados, incluindo fonte ampliada 1,8×.
- APK release assinado gerado em `app\\build\\app\\outputs\`flutter-apk\\app-release.apk` (63.596.843 bytes); assinatura APK v2 verificada. A atualização `1.0.0+6` → `1.0.0+7` foi instalada por cima no aparelho Android físico, preservando os dados locais; o app iniciou sem crash.
- Pendente de teste manual: exportação/restauração do backup no aparelho, acentuação no dispositivo, operação offline e revisão visual completa do tema escuro e da sugestão de mês/ano.

Correção adicional: o diálogo de edição do produto agora é dono do ciclo de vida dos próprios campos e controladores. O teste de widget cobre a troca de **Por peso** para **Por unidade** sem exceção durante a interação ou o fechamento do diálogo.

Na tela de categorias, é possível apagar uma categoria somente quando não há produtos vinculados; categorias com produtos exibem um aviso e não são apagadas. A exclusão de categorias livres exige confirmação e remove também suas subcategorias. A verificação é repetida dentro da transação para preservar os vínculos.

**Validação desta correção:** `dart format --output=none --set-exit-if-changed lib test` sem alterações pendentes; `flutter test --no-pub` passou com 57 testes; `flutter analyze` sem problemas. Teste manual no Android não executado.

**Versão do app:** atualizada de `1.0.0+3` para `1.0.0+4`; o nome permanece `1.0.0` e o código de versão Android sobe para 4. A versão registrada nos novos backups também foi atualizada.

Na tela de produtos, o menu permite apagar produtos sem compras concluídas após confirmação. Se o produto ainda estiver numa lista, o app pede para removê-lo primeiro; histórico concluído e linhas de compras em andamento ou canceladas são preservados e impedem a exclusão. Após remover o item da lista, o produto pode ser apagado.

**Validação desta correção:** `flutter analyze` sem problemas; `dart format --output=none --set-exit-if-changed lib test` sem alterações pendentes; `flutter test --no-pub` passou com 62 testes. Teste manual no Android não executado.

Exportação de backup no Android usa o seletor de documentos do sistema para criar o JSON, em vez do `getSavePath()` não implementado pelo plugin nessa plataforma. A restauração explica que o JSON substituirá catálogo, listas, compras e histórico, salva primeiro um backup de segurança e só então substitui os dados em transação. As preferências de tema são preservadas. O `catalogo-inicial.json` segue empacotado no app e pode ser importado novamente depois de uma restauração vazia.

Correção na leitura Android: o seletor `file_selector_android` usava o tamanho informado pelo provedor Android para ler o documento; se o provedor reportava zero, o plugin podia fornecer conteúdo vazio. A restauração Android agora lê o fluxo `ContentResolver` até o fim, sem depender desse metadado. O backup enviado pelo usuário foi validado e restaurado com sucesso pelo validador real do app (formato 5, 9 categorias, 25 subcategorias e 4 produtos). Arquivos vazios agora geram mensagem explícita, e a cópia de segurança impede escolher a mesma URI do arquivo de origem.

**Versão atual do app:** `1.0.0+6` (build 6). O nome de versão continua `1.0.0`; formato de backup continua 5 e lê formatos 1 a 5.

**Validação desta correção:** `flutter analyze --no-pub` sem problemas; `dart format --output=none --set-exit-if-changed lib test` sem alterações; `flutter test --no-pub --reporter compact` passou com 66 testes; `flutter build apk --debug` gerou o APK debug com a implementação nativa. A seleção do provedor Android precisa ser confirmada manualmente no aparelho.

**Validação desta entrega:** `flutter analyze --no-pub` sem problemas; `dart format --output=none --set-exit-if-changed lib test` sem alterações; `flutter test --no-pub --reporter compact` passou com 65 testes; `flutter build apk --debug` gerou o APK debug. Teste manual de salvar/cancelar/restaurar arquivo com o seletor do Android ainda deve ser feito num aparelho ou emulador. Não foi instalado no dispositivo.

Na inclusão à lista, a forma de compra é somente leitura e vem do cadastro. Produto com forma pendente não pode ser adicionado à lista nem ao carrinho sem definição no catálogo. A forma pode ser alterada no cadastro mesmo após vínculos; itens planejados e linhas de compras já registrados preservam a forma fotografada, e uma compra vinculada a um item antigo continua usando essa fotografia.

No carrinho, as linhas ficam agrupadas por categoria e subcategoria; as linhas ligadas a itens da lista ficam azuis, e as outras ficam no fundo normal, dentro dos mesmos grupos. A projeção mostra o valor da lista (parte no carrinho + estimativa do que falta), valor conhecido dos itens fora da lista e total projetado combinado.

Na tela de compras, a seção **Compras concluídas** agora também pode ser recolhida, inicialmente fechada, como **Compras canceladas**.

## Estado

**Forma de compra por pacote:** cadastrada como opção própria, com quantidade em pacotes e preço por pacote no planejamento, carrinho, estimativas e históricos. O backup usa o formato 5, mantém leitura dos formatos 1 a 5 e não houve alteração estrutural das tabelas nesta versão.

**Validação desta mudança:** `flutter analyze` sem problemas; `dart format --output=none --set-exit-if-changed lib test` sem alterações pendentes; `flutter test --reporter expanded` passou com 53 testes. Inclui escolha no cadastro, cálculo/estimativa, histórico e backup por pacote. Teste manual em Android não executado.

**Versão anterior à correção de leitura:** `1.0.0+5` (build 5). O nome de versão continua `1.0.0`. O formato de backup 5 mantém restauração de arquivos nos formatos 1 a 5.

**Etapa 3 — histórico, estimativas e frequência:** implementada e validada localmente. Antes das alterações da Etapa 4, a suíte tinha 48 testes passando, análise estática limpa e APK debug gerado; esses resultados são o baseline anterior e não validam o código atual. A conferência manual da Etapa 3 no Android não foi feita pelo assistente.

**Etapa 4 — confiabilidade e APK pessoal:** validações automatizadas concluídas. O identificador foi definido como `br.com.nocorre.mercado` e a versão passou para `1.0.0+2`; o app antigo com `com.example.mercado` permanece separado. O Auto Backup e a transferência automática Android foram desativados por decisão do usuário. O carrinho persistiu após fechar/reabrir o banco em teste isolado e o backup restaurou em outro banco; fonte ampliada foi testada e levou à correção do rodapé do carrinho para permitir rolagem sem overflow.

O build debug foi gerado. A tentativa de build release sem configuração local falhou deliberadamente com a mensagem de assinatura própria obrigatória; `android/key.properties` não existe e nenhuma chave foi criada. `flutter devices` detectou o dispositivo Android `2511FPC34G` (Android 16), mas o assistente não instalou nem executou o app nele. O usuário não deve instalar por cima da instalação com dados reais nem removê-la durante a migração. Antes, deve exportar e guardar um backup JSON fora do app; instalar a nova identidade como app separado; restaurar e conferir o backup; manter a instalação antiga até confirmar os dados. O teste físico no telefone continua pendente.

No carrinho iniciado por lista, há ações distintas para **Adicionar item da lista** e **Adicionar outro item**. Os itens planejados aparecem agrupados pela ordem das categorias; ao atingir a quantidade planejada, o item passa para **Já inserido no carrinho** e fica cinza. Se a quantidade adicionada ultrapassar o planejado, a quantidade real no carrinho fica vermelha. O outro seletor não inclui produtos que já constem na lista. Compras sem lista mantêm uma única ação de adicionar.

As listas agora aparecem em grupos **Novas**, **Em andamento**, **Realizadas** e **Canceladas**. **Realizadas** e **Canceladas** são recolhíveis. Uma lista fica em andamento ao existir uma compra aberta vinculada e passa a realizada após conclusão explícita. A lista realizada fica fechada para edição e não permite iniciar nova compra. O status concluído é salvo no campo de status já existente, sem nova coluna/migração; listas antigas com compras concluídas também são classificadas pelo vínculo existente.

Antes de atualizar uma instalação com dados reais, exportar e verificar um backup. Não instalar/abrir esta versão sobre dados reais sem essa salvaguarda.

Correção adicional durante o teste manual: na seleção de produtos de uma compra iniciada por lista, os itens planejados agora aparecem destacados em azul com a quantidade do planejamento. Selecionar um associa a linha ao item planejado, mas não presume a quantidade comprada; ela continua sendo informada pelo usuário.

Para a limpeza de listas, compras concluídas e suas linhas históricas são preservadas, com a lista desvinculada e o nome de origem mantido. A limpeza de carrinhos remove compras em andamento/canceladas; a limpeza de histórico remove compras concluídas. Produtos com vínculos são arquivados em vez de apagados. Limpar tudo mantém a preferência de tema.

- Release `1.0.4` (`v1.0.4`) publicada no GitHub com APK release assinado e source zip. O APK tem 66.132.844 bytes, assinatura APK v2 válida, SHA-256 `E3BA094D346F302E9A8B9C8D76B643AB73DE03BA3B9F5355941BA46C75FCC196`, pplicationId r.com.nocorre.mercado, ersionName 1.0.4 e ersionCode 12. A correção do SQLite Android foi validada em build debug e release no emulador: o banco `mercado.sqlite` foi criado e o logcat não continha `sqlite3_temp_directory`, `DynamicLibrary`, `Invalid argument` ou `FATAL EXCEPTION`. Os assets baixados da própria release foram verificados e coincidiram por hash com os arquivos locais.
- Índice Firestore corrigido: a descoberta de casas consulta o collection group `members` por `uid`. O índice single-field `members.uid` com escopo `COLLECTION_GROUP` e ordem `ASCENDING` foi publicado no banco `(default)` do projeto `nosso-mercado-casa` e está READY. A mesma query em produção passou a retornar as três casas do proprietário, eliminando o FAILED_PRECONDITION exibido na tela Android.
- Sincronização completa e bidirecional: a casa agora publica e recupera catálogo, subcategorias, produtos, importações, listas, planejados, compras e linhas como um snapshot consistente. A tela Conta e sincronização mostra o estado local versus Firebase por área, permite enviar todos os dados locais, usar todos os dados remotos ou resolver divergências. Resetes podem propagar a limpeza aos outros Android e ao PWA, e a exclusão explícita da casa remove seus documentos compartilhados do Firebase.
## Entregue

- Projeto Flutter em `app\`: Material 3, pt-BR, Riverpod e SQLite/Drift; execução principal offline.
- Catálogo, categorias/subcategorias, importação revisável/idempotente, arquivamento e backup/restauração.
- Listas por mês planejado e itens com quantidades separadas da compra real.
- Listas organizadas pelos estados novas, em andamento, abertas, realizadas e canceladas; uma compra parcial pode deixar a lista aberta para nova compra, sem perder seus itens.
- Compras com data civil real, carrinho persistente, várias linhas por produto, cancelamento e conclusão explícita.
- Preços ausentes continuam pendentes; dinheiro em centavos e quantidades inteiras/unidades ou pacotes, ou gramas para peso.
- Progresso do planejamento desconta quantidades concluídas e no carrinho sem dupla contagem.
- Histórico mensal considera compras concluídas por data real e compara com o mês civil anterior.
- Detalhe de produto apresenta meses/datas observados, última compra e frequência estimada pela mediana de intervalos entre ao menos três datas distintas.
- Estimativa histórica compatível é fotografada no planejamento; atualização exige ação explícita. Preço manual permanece identificado como estimativa.
- Projeção separa valor conhecido do carrinho e estimativa de quantidade restante; preço ausente não vira zero ou valor garantido.
- Schema Drift 6; `purchase_lines.is_label_total` preserva a origem do total de etiqueta. Migrações 1–5 são aceitas e atualizadas; schema 6 não executa alteração redundante. Backup formato 6 mantém leitura dos formatos 1 a 6.
- Configurações com modo escuro persistente e reset seletivo em transação, com prévia de impacto e dupla confirmação; registros históricos vinculados são preservados conforme as opções aprovadas.
- Compras iniciadas por lista exibem selo azul com o nome fotografado da lista; compras avulsas ficam sem selo. A origem continua recuperável em backup mesmo após limpar listas.
- No carrinho iniciado por lista, os botões separam itens planejados de outros produtos; a seleção planejada é agrupada por categoria e a opção de outros produtos exclui os já planejados.
- Rodapé do carrinho limita a altura e permite rolagem com fonte ampliada, preservando acesso às ações sem overflow.
- Arquivos do app e decisões de etapa atualizados. Não foi implementado nenhum extra não aprovado.

## Validações executadas antes da Etapa 4 (baseline da Etapa 3)

- `flutter test test\widget_test.dart --reporter expanded`: passou, 11 testes; inclui botões separados, agrupamento por categoria e exclusão dos produtos planejados da opção de outros itens.
- `flutter test --reporter expanded`: passou, 48 testes no total, incluindo agrupamento por categoria/subcategoria, cores por origem e subtotais da projeção.
- `flutter analyze`: sem problemas.
- `dart format --output=none --set-exit-if-changed lib test`: sem arquivos fora de formatação (26 arquivos verificados).
- `flutter build apk --debug`: APK debug gerado em `build\app\outputs`flutter-apk\app-debug.apk` na junction `C:\Users\Usuario\MercadoApp`.
- Não instalado no aparelho pelo assistente; aguarda teste manual do usuário.
- Nenhum teste manual desta etapa ou do modo avião foi feito; a validação automatizada não comprova comportamento no aparelho.
- Nenhuma compra fictícia foi gravada numa base do usuário; não houve restauração, limpeza de dados ou commit.

## Validações executadas na Etapa 4

- `dart format --output=none --set-exit-if-changed lib test`: sem mudanças de formatação; 26 arquivos verificados.
- `flutter test --reporter expanded`: passou, 51 testes. Inclui reabertura do SQLite com carrinho em andamento e linhas com/sem preço, preservação do progresso, bloqueio da conclusão com preço ausente e restauração do backup em outro banco temporário.
- `flutter analyze`: sem problemas.
- `flutter build apk --debug`: APK debug gerado em `build\app\outputs`flutter-apk\app-debug.apk`.
- `flutter build apk --release` sem chave: bloqueado como esperado por falta de `android/key.properties`; nenhuma chave debug foi usada para release.
- Manifesto Android mesclado debug confirma `allowBackup=false` e aplicação das regras XML de backup/extração. A permissão `INTERNET` aparece nas variantes debug/profile, adicionada pelos manifestos de desenvolvimento Flutter; o manifesto principal não declara essa permissão. Não foi construído/inspecionado manifesto de release porque o guard de assinatura interrompe o build antes dessa etapa.
- `flutter devices`: detectou um aparelho Android 16, Windows, Chrome e Edge. Nenhuma instalação foi feita.
- `test/widget_test.dart`: passou com teste de fonte ampliada (1,8×), incluindo acesso ao botão de conclusão após rolar o rodapé. Nenhum teste visual/físico foi realizado.

Para comandos Android, use a junction ASCII `C:\Users\Usuario\MercadoApp`, pois o caminho original inclui `Área de Trabalho` e já apresentou erros de codificação no AAPT/ADB.

## Ainda pendente na Etapa 4

- Concluir cadastro/registro do pacote e autorizar o telefone no Android Developer Console, se ainda não realizado.
- Testar exportação/restauração do backup e instalar o APK release no telefone, somente após backup verificado e sem remover a instalação antiga.
- Conferência manual da acessibilidade/fonte ampliada, acentuação no dispositivo, funcionamento offline, migração no aparelho e revisão visual do tema escuro/sugestão de mês/ano.
- Edição de compras concluídas não está disponível; telas históricas são somente leitura.

## Próximo passo

Realizar o checklist manual de instalação, backup/restauração, migração, acessibilidade e funcionamento offline no aparelho. Manter a instalação antiga até confirmar os dados; não alterar dados reais nem criar commit pelo assistente.
