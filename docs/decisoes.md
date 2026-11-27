# Decisões técnicas e funcionais

Atualizado em 17/11/2026. Este registro documenta decisões aprovadas para a Etapa 4; não autoriza funcionalidades extras. A PWA usa Dart2JS para a interface e SQLite WebAssembly no worker do Drift (`flutter build web --release --no-pub`), preservando compatibilidade com Safari sem WasmGC e evitando bindings FFI nativos no navegador. O `sqlite3.wasm` é compatível com a versão resolvida do pacote e o Hosting usa cache `no-cache` para entrypoints e WASM.

- O schema Drift 6 adiciona `purchase_lines.is_label_total`. O valor pago de uma linha é sempre `total_cents`; quando o total vem da etiqueta, `unit_price_cents` guarda apenas o preço por base derivado necessário para a interface e para a conversão de unidade.
- O backup usa formato 6 e aceita formatos 1 a 6. `formatVersion` é encaminhado à restauração para que esquema do banco e versão do formato sejam validados de modo independente.
- `ShoppingPlan.status = open` significa lista explicitamente mantida aberta para nova compra, distinta de uma compra em andamento (`in_progress`). Concluir uma compra não força imediatamente o encerramento do planejamento.
- O fluxo pós-compra é em duas fases: a compra é concluída transacionalmente; depois, havendo itens restantes, o usuário escolhe manter a lista aberta, mover o restante para uma nova lista ou encerrar o planejamento.
- A criação da lista restante preserva a forma de compra e o snapshot de estimativa do item de origem. A inserção é feita diretamente no banco, sem depender do modo atual do cadastro do produto.
- “Último pago” usa a linha válida mais recente da compra concluída mais recente: `total_cents` dividido pela quantidade da própria linha e convertido para a unidade padrão da forma. Linhas de etiqueta não são combinadas com outras linhas do mesmo produto na viagem de referência.
- O rodapé do carrinho limita a área expandida e oferece rolagem; a barra compacta permanece visível. Isso preserva as ações com fonte ampliada sem reduzir a escala da interface.
- Versão atual `1.0.4+12` (build 12). APK release assinado gerado e verificado com assinatura v2 válida; tamanho `61.184.588` bytes e SHA-256 `1C59AA5CEE7222210C5C7FBEF5DB86F68EF68689A4DFF36A30A95EFC96118699`. A versão anterior `1.0.2+10` permanece disponível para atualização e consulta.
- O nome de usuário é o campo nativo `displayName` do Firebase Auth; o e-mail continua sendo o identificador de login. O nome é validado, pode ser editado em **Ajustes → Conta e sincronização** e é espelhado de forma best-effort no campo `displayName` dos documentos `members`, sem alterar `uid` nem `role`.

## Stack e ambiente

- Aplicativo Android offline em Flutter/Dart, Material 3 e interface em pt-BR.
- Estado da interface com Riverpod; persistência SQLite por Drift.
- Versões usadas: Flutter 3.47.9 estável, Dart 3.13.7, Riverpod 3.4.3, Drift 2.35.3, drift_flutter 0.3.1, file_selector 1.1.0 e intl 0.20.3. `app\pubspec.lock` registra as versões resolvidas.
- Ferramentas Android disponíveis: JDK 21 e Android SDK 36.1.0. ID estável aprovado: `br.com.nocorre.mercado`. Foi alterado de `com.example.mercado`, portanto a versão release instala como app separado; transferência de dados deve ser feita por backup JSON, sem desinstalar a instalação antiga até verificar a restauração.
- O projeto fica na subpasta `app\`. No Windows, Gradle exigiu `android.overridePathCheck=true` porque o caminho de trabalho contém caracteres não ASCII; o build debug passou com essa configuração.
- Neste caminho Unicode, `dart analyze` funciona diretamente. `flutter analyze` foi validado por uma junction temporária com caminho ASCII. A geração Drift funcionou com `flutter pub run build_runner build --force-jit`; `dart run build_runner` não conseguiu gerar o snapshot AOT nesse caminho. Não editar `app_database.g.dart` manualmente.

## Modelo implementado na Etapa 1

- Produtos, categorias e subcategorias são registros distintos. Categoria/subcategoria podem ser arquivadas; relações com dados existentes não são apagadas em cascata.
- Produtos importados não recebem forma de compra presumida: `measurementMode` fica pendente. Produtos sem categoria explícita permanecem sem categoria e sinalizados para revisão.
- O banco começou na versão de schema 1 e evoluiu de forma aditiva até a versão 5. A versão 5 reconhece a forma “Por pacote” sem alterar tabelas; os registros anteriores são preservados.
- Catálogo não é planejamento, carrinho nem compra concluída. A Etapa 1 não cria preço, quantidade comprada, gasto ou histórico de compra.
- A origem inicial tem 139 produtos, nove categorias sugeridas e 13 produtos sem categoria; o arquivo não prova compras passadas. Não foi encontrado `Mercado.xlsx` na pasta durante o diagnóstico inicial.

## Importação e backup

- O JSON incluído em `app\assets\catalogo-inicial.json` é uma cópia do catálogo revisável; seu hash foi conferido contra o original.
- Importação é identificada pela origem e idempotente. Dados ambíguos continuam pendentes de revisão.
- Backup JSON versionado atual está no formato 5, inclui as entidades existentes, versão do app/schema e moeda BRL, e continua aceitando formatos 1 a 5. O formato 5 aceita a forma “Por pacote”. A validação acontece antes da restauração; a substituição é transacional. No Android, a leitura do JSON usa o fluxo do `ContentResolver`, sem confiar no tamanho informado pelo provedor do documento.
- A interface pede que o usuário salve um backup de segurança antes da restauração. Como restauração substitui dados locais, teste-a com dados fictícios ou em instalação de teste.
- Versões futuras devem ampliar o formato do backup e migrar o banco sem apagar dados. Nenhuma compra real deve ser usada em teste destrutivo.

## Etapa 2: planejamento e primeira compra

- `ShoppingPlan` guarda mês planejado e nome; `PlannedItem` separa produto, modo de compra e quantidade desejada.
- `ShoppingTrip` guarda data civil real (`YYYY-MM-DD`), mercado opcional e estado `in_progress`, `completed` ou `canceled`. Compra vinculada e compra avulsa são permitidas.
- `PurchaseLine` guarda produto e item planejado opcionais, modo e quantidade fotografados, preço unitário em centavos, total calculado, estado de preço e snapshots de nome/categoria/subcategoria gravados ao concluir.
- Quantidade por unidade ou pacote é inteira; peso é gramas inteiras. Preço por pacote é por pacote, e preço por peso é centavos/kg; o total é arredondado half-up uma vez por linha. Pacotes e unidades avulsas não são comparados como mesma base.
- A interface aceita moeda decimal pt-BR, ponto decimal inequívoco e agrupamento brasileiro validado. Um campo de preço vazio é pendente (`null`), nunca zero; linhas pendentes não entram no total conhecido e impedem a conclusão.
- Uma compra ativa por lista (e uma compra sem lista por vez) evita dupla alocação do planejamento. Uma lista pode ter compras concluídas em datas diferentes; o progresso desconta quantidades concluídas e no carrinho, com mínimo zero.
- A confirmação explícita atualiza linhas/snapshots e estado da compra numa transação. Repetir a confirmação não duplica o histórico. Compra cancelada fica preservada, mas não é conclusão.
- A forma de compra pode ser alterada no cadastro mesmo após vínculos; cada item planejado e linha de compra preserva sua forma fotografada e os cálculos/histórico usam esse snapshot.
- Na Etapa 2, compras concluídas eram somente leitura; não há edição de conclusão, descontos ou entrada de total de etiqueta independente do preço/kg.
- O backup foi ampliado para formato 2 na Etapa 2, incluindo listas, itens, compras e linhas; evoluiu até o formato 6 e mantém leitura independente dos formatos 1 a 6.
- Nenhum histórico foi inferido do catálogo. Testes usam nomes/valores fictícios; a base manual do usuário não deve receber compras de teste sem backup verificado.

## Etapa 3: histórico, estimativas e frequência

- Relatórios agrupam compras concluídas pela data civil real `YYYY-MM-DD`; lista de origem, carrinho em andamento e compra cancelada não mudam o mês de gasto. Compras e linhas históricas continuam usando snapshots.
- Comparação mensal usa somente o mês civil imediatamente anterior. “Não comprado neste mês” é distinto da última compra disponível, que recebe sua própria data e nunca é apresentada como compra do mês anterior.
- Previsão de um item planejado usa a compra concluída compatível mais recente estritamente anterior ao primeiro dia do mês planejado. Assim, compras do próprio mês e posteriores não vazam para uma previsão retrospectiva. Uma compra de referência é uma ida ao mercado; todas as linhas compatíveis do produto naquela compra compõem a taxa ponderada.
- Compatibilidade de preço exige o mesmo produto estável e modo de compra (`unit` ou `weight`). Como o modelo ainda não tem variantes/conteúdo de embalagem, não se tenta normalizar embalagens nem comparar produtos diferentes.
- A taxa de referência é persistida como razão exata entre soma dos centavos pagos e soma das quantidades da última compra compatível. Estimativa para a quantidade planejada ou restante arredonda half-up uma única vez no total final; a taxa unitária mostrada é apenas uma apresentação arredondada.
- Ao incluir um produto no planejamento, a referência disponível é fotografada. Uma atualização posterior depende de ação explícita. Sem histórico compatível, o valor permanece ausente; o usuário pode registrar preço manual identificado como estimativa, sem convertê-lo em preço pago.
- Projeção de lista soma apenas os valores conhecidos do carrinho atual e a estimativa das quantidades ainda necessárias. Comprado e no carrinho são descontados do planejamento para calcular pendência; itens sem preço conhecido tornam a projeção parcial, nunca zero ou garantida.
- Frequência usa somente datas civis distintas de compras concluídas válidas, exclui datas futuras em relação ao relógio informado e conta múltiplas linhas/compras no mesmo dia uma vez. Com pelo menos três datas, mostra mediana dos intervalos em dias como aproximação observada; abaixo disso não afirma periodicidade.
- `DateTime` atual/data de referência são entradas dos cálculos e consultas para permitir testes com relógio controlado. O schema evoluiu de 2 para 3 com colunas de fotografia de estimativa e de 3 para 4 com origem fotografada da compra e preferências locais; backup evoluiu de formato 2 para 4 mantendo leitura dos formatos anteriores.

## Ajustes aprovados antes da Etapa 4: configurações, limpeza e origem da compra

- A aba Configurações oferece escolha clara/escura. O tema claro permanece padrão; a preferência é persistida no SQLite e mantida tanto ao limpar os dados quanto ao restaurar backup. A preferência não é exportada no backup.
- Em Compras, uma compra iniciada por lista mostra selo azul “Da lista · nome da lista”; compra avulsa não mostra selo. O nome de origem fica fotografado no início da compra para continuar visível se a lista for apagada ou renomeada.
- O reset seletivo apresenta listas, carrinhos em andamento/cancelados, histórico (compras concluídas), produtos e categorias. É possível combinar áreas ou escolher Limpar tudo.
- Limpar listas remove listas e itens planejados, mas preserva compras/linhas/histórico; remove os vínculos com os registros planejados e guarda a fotografia do nome da lista na compra.
- Limpar carrinhos apaga compras em andamento e canceladas; compras concluídas permanecem. Limpar histórico apaga somente compras concluídas/linhas correspondentes e as estimativas históricas que dependiam dessas compras; estimativas manuais permanecem. Selecionar ambos remove todos os estados de compra.
- Limpar produtos arquiva produtos ainda referenciados por listas ou compras/histórico e exclui somente produtos sem vínculos. Limpar categorias/subcategorias preserva produtos e compras, remove a classificação atual e marca para revisão os produtos que perderam categoria.
- Limpar tudo remove catálogo, importações/metadados, listas, compras e histórico, mas mantém a preferência de tema.
- Cada limpeza exibe contagens/efeitos, pede uma confirmação de revisão e uma segunda confirmação digitando a frase indicada. A operação é transacional e a interface recomenda exportar backup verificado antes da ação irreversível.
- O schema evolui de 3 para 4 com fotografia da origem e tabela de preferência; a versão 5 adiciona a forma “Por pacote” sem alteração estrutural. Backup evolui de 4 para 5, mantém leitura de formatos 1–4 e aceita a forma de compra nova.

## Etapa 4: confiabilidade e APK pessoal

- Distribuição aprovada: Android Developer Console **Limited distribution**, fora da Google Play, com autorização do dispositivo pessoal. Requer conta Google, autenticação em duas etapas e perfil de pagamentos; o usuário fará cadastro e verificação diretamente com Google, sem compartilhar credenciais.
- O `applicationId` aprovado é `br.com.nocorre.mercado`; versão atual `1.0.7+15` (build 15).
- Backup automático Android/Google Drive e regras de transferência de dispositivo foram explicitamente desativados. A recuperação depende do JSON manual do app, que contém dados pessoais; documentado no README.
- Release só pode usar uma chave própria carregada de `android/key.properties`; build release falha se a chave ou propriedades não estiverem disponíveis. O arquivo de chave permanece fora do projeto e nunca deve ser compartilhado.
- APK release e debug usam assinaturas diferentes. A release usa `MercadoRelease.jks`, cuja assinatura é compatível com a instalação release anterior; atualizações futuras do mesmo pacote devem usar essa mesma chave. Dados pessoais devem continuar protegidos por backup JSON manual e não versionados.
- Android exige registro de pacotes em dispositivos certificados no Brasil desde 30/09/2026. A rota escolhida é distribuição limitada, sem publicação ou listagem na Play Store. O limite de dispositivos publicado nas páginas oficiais não é necessário para o uso individual.
- A recuperação de senha está disponível na Web e no APK desde a versão `1.0.6+14`. O botão **Esqueci minha senha** envia o template do Firebase Authentication; o link de redefinição usa `https://nosso-mercado-casa.web.app`, com `handleCodeInApp: false`, para concluir a troca no navegador e retornar ao site. A confirmação de sucesso é genérica e não revela se o e-mail possui conta.
- Identificadores técnicos de tabelas e do protocolo de sincronização não devem aparecer na interface. A camada de apresentação traduz `categories`, `subcategories`, `products`, `importBatches`, `importEntries`, `shoppingPlans`, `plannedItems`, `shoppingTrips` e `purchaseLines` para os mesmos termos usados no restante do aplicativo, preservando as chaves internas usadas pelo Drift, pelo backup e pelo Firestore.

## PWA, sincronização compartilhada e estado publicado

- A PWA **Nosso Mercado** foi migrada para `https://nosso-mercado-casa.web.app`, no novo projeto Firebase `nosso-mercado-casa` (nome de exibição `Nosso Mercado`). O identificador anterior era imutável e foi substituído para retirar nomes pessoais de toda a cadeia pública.
- Os aplicativos Android (`br.com.nocorre.mercado`) e Web foram registrados no novo projeto. Manter o mesmo `applicationId` e a mesma chave de assinatura permite atualizar o APK released anterior sem perder o banco Drift local.
- O Drift local permanece a fonte imediata e offline. O Firestore `(default)`, em `southamerica-east1`, funciona como espelho compartilhado entre os membros da casa, com sincronização separada nas áreas `catalog`, `imports` e `shopping`.
- A detecção de alterações usa hash SHA-256 canônico e revisão. Os hashes-base locais e os hashes remotos são persistidos separadamente para que uma escolha explícita de “usar remota” não produza sobrescrita silenciosa em uma sincronização posterior.
- Conflitos são tipados por área e a interface resolve múltiplos conflitos sequencialmente. Códigos de convite são gerados com `Random.secure()`.
- O snapshot remoto reutiliza o formato validado do `BackupService`; o schema 7 é aceito e as versões anteriores permanecem legíveis.
- O Identity Platform está inicializado, com E-mail/Senha habilitado e a blocking function `beforeCreateUser` publicada. O provedor só foi reaberto depois de o teste real confirmar que um e-mail não autorizado é bloqueado e que o trigger `beforeCreate` está vinculado.
- O cadastro público é restrito no servidor pela blocking function `beforeCreateUser`. A allowlist fica em Firestore privado como hashes SHA-256 dos e-mails autorizados; as regras públicas negam leitura e gravação. A ausência de configuração bloqueia o cadastro, e chamadas diretas à API de criação de conta também são recusadas.
- O acesso ao mercado exige autenticação: sem uma sessão válida, o `AuthGate` mostra somente **Entrar** e **Criar conta autorizada**. Se o Firebase não inicializar, o app falha fechado e mantém o mercado fechado. Depois do login, o Drift local permanece disponível para operação offline e o logout retorna à tela de entrada.
- O piloto Android usa o flavor Gradle `pilot`, o pacote `br.com.nocorre.mercado.pilot` e o projeto Firebase `nosso-mercado-casa-pilot`. O flavor `production` preserva `br.com.nocorre.mercado`, a configuração Firebase de produção, o banco local e a possibilidade de atualizar a release assinada existente. A PWA continua sendo exclusivamente produção.
- O estado oficial do piloto é um manifesto v2 em `syncV2/{householdId}/state/current`, composto por chunks imutáveis. A publicação usa compare-and-swap atômico sobre `generation` e `manifestHash`; uma candidate concorrente rejeitada permanece em `syncV2/{householdId}/candidates` e é preservada em `syncV2/{householdId}/conflicts` para decisão do owner. Regras e backend do piloto ficam em `firestore.pilot.rules`/`firebase.pilot.json`, sem alteração do arquivo de regras de produção.
- A hierarquia de moderação do piloto é uma regra pura do backend (`findModerationViolation`): decide quem pode revisar o quê, sem depender de Firestore em tempo de execução, e é coberta por teste. O owner confirmado da casa é o único autorizado a decidir, a decisão exige um item publicado e de outro membro, e um item do próprio owner não passa por revisão. O papel continua sendo resolvido pelo owner confirmado em `households/{householdId}.ownerUid`, com fallback offline conservador para membro.
- A decisão do owner é aplicada de forma idempotente e canônica no aparelho que a tomou: o mesmo resultado não conta duas vezes no `syncRevision` e o instante gravado usa segundos em UTC, a precisão que sobrevive ao banco local e ao backup. Isso elimina a divergência de um dígito entre aparelhos que possuíam exatamente o mesmo conteúdo.
- Toda publicação do piloto carrega as decisões do owner, inclusive a ação explícita **Enviar todos os dados deste dispositivo**. Publicar sem aplicar as revisões autoritativas seria recusado pelo backend e deixaria o membro sem conseguir publicar depois de uma remoção do owner.
- A comparação entre o estado local e o estado publicado é feita por conteúdo, com hash semântico por área: identificadores inteiros locais, referências internas, contadores de revisão e a representação textual dos instantes são ignorados, porque não descrevem o conteúdo. A base semântica é memorizada em chave própria (`semantic:<área>`), ao lado do hash de bytes histórico, para que as duas comparações nunca se confundam.
- A allowlist de produção contém dois hashes SHA-256 únicos: o e-mail principal e o e-mail confirmado da Iasmim. A Iasmim está autorizada para criar a conta, mas ainda não criou login no Identity Platform.
- Após o login, a descoberta de casas consulta os documentos `members` cujo campo `uid` é igual ao UID autenticado e lê o nome de cada `households/{id}`. A regra permite ao usuário listar apenas os próprios registros de membro. Se a conta pertence a uma única casa, ela é selecionada e persistida automaticamente; se pertence a várias, os nomes são exibidos para escolha explícita. Trocar de casa zera revisão e hash-base locais para impedir a mistura de bases de sincronização.

## Pendências para concluir a Etapa 4

- Testes automatizados executados: persistência do carrinho ao reabrir SQLite, restauração isolada, migrações, backup, lista `open`, total de etiqueta, “último pago” por linha, fluxo pós-compra, acessibilidade com fonte ampliada, sincronização em nuvem e gate de autenticação; suíte completa passou com 79 testes e análise limpa. As Functions passaram no build TypeScript e nos 3 testes da allowlist.
- Cadastro/registro do pacote no Android Developer Console e autorização do telefone são ações que o usuário deve executar em contas/dispositivos próprios.
- Teste manual de migração do backup e instalação do APK release no telefone, sem desinstalar a instalação atual até validar os dados.
- Validar o fluxo real com duas contas: criação da conta da Iasmim, criação da casa, convite, sincronização, alterações nos dois dispositivos e resolução de conflito.
- Nenhum extra (estoque, validade, código de barras ou OCR) foi aprovado ou implementado.
