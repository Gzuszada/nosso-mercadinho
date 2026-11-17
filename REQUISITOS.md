# Especificação proposta: app de mercado

## Natureza deste documento

Especificação de produto para desenvolvimento com IA, não descrição de um app existente. As regras abaixo são propostas de implementação que detalham os requisitos do usuário. Decisões sugeridas devem ser apresentadas no plano e aprovadas antes da implementação correspondente.

O produto inicial é individual, Android, offline. O usuário já utiliza VS Code/IA, mas precisa de ajuda para ferramentas, código e instalação. Não é um projeto de publicação pública neste momento.

## Dados iniciais do Excel

Origem: `Mercado.xlsx`, aba `112026`. Foram extraídos 139 nomes não vazios. Há nove categorias, 13 produtos após o primeiro total sem classificação explícita, seis linhas numeradas sem nome e numeração 103 repetida. Não usar numeração visual como chave primária.

Os campos “Precisa?” e “No carrinho?” representam estados separados. A planilha tem três pares de preço/quantidade por produto e total calculado pela soma dos três pares. O app elimina esse limite e usa linhas vinculadas.

Não há preços/quantidades preenchidos que sustentem importação de compras históricas. Importar catálogo, não compras. O nome `112026` não autoriza criar gasto, quantidade, preço nem uma compra histórica.

O arquivo `catalogo-inicial.json` preserva a origem e deixa `measurement_mode` como `null`. Isso é estado de revisão da migração, não autorização para comprar sem forma definida. O app deve permitir definir unidade, pacote ou peso ao editar o produto.

## Escopo obrigatório

| Código | Requisito | Aceite observável |
|---|---|---|
| R01 | Criar/editar/ordenar/arquivar categorias e subcategorias | Produto aparece no grupo correto e pode ser reclassificado |
| R02 | Criar/editar/pesquisar/arquivar produtos | Catálogo persiste após reiniciar |
| R03 | Definir unidade, pacote ou peso por produto | Quantidades e preços exibem unidades sem ambiguidade |
| R04 | Montar lista com quantidade planejada | Editar planejamento não muda o passado |
| R05 | Adicionar/remover produtos da lista | Remover não apaga o produto ou histórico |
| R06 | Carrinho com quantidade e preço reais | Total atualiza ao salvar, editar ou remover linha |
| R07 | Botão para outra linha do mesmo produto | Três, quatro ou mais preços distintos funcionam |
| R08 | Consultar preço no mês anterior e última compra | Ausência no mês anterior é explícita |
| R09 | Estimar lista futura com histórico | Origem/data do preço e itens sem estimativa são visíveis |
| R10 | Consultar gasto e produtos por mês | Somente compras concluídas no mês real entram |
| R11 | Meses comprados e tempo sem comprar por produto | Datas reais e linhas históricas consultáveis |
| R12 | Mostrar frequência observada | Dados insuficientes não geram certeza falsa |
| R13 | Backup completo, restauração e CSV | Recuperação mantém dados e totais |
| R14 | Funcionar sem internet | Ciclo completo validado em modo avião |

Categorias e subcategorias são obrigatórias como capacidade de cadastro, mas um produto pode ficar sem subcategoria. Subcategoria sempre pertence a uma categoria. Não criar hierarquia recursiva ilimitada na primeira versão.

## Fora da primeira entrega

Sem login, sincronização multiusuário, servidor, assinatura, integração bancária, captura de preços online, OCR de cupom ou publicação obrigatória na Play Store. Orçamento, avisos, estoque, validade e código de barras são módulos propostos, a aprovar separadamente.

## Fluxos principais

### Cadastro

Criar categoria e subcategoria opcional; criar produto com nome, forma de compra e classificação. Campos opcionais: descrição, marca, conteúdo da embalagem e observação. Produtos comercialmente distintos podem ser separados ou vinculados como variantes de um produto-base; não misturar preços incompatíveis.

Arquivar produto não remove compras antigas. Renomear/reclassificar atualiza o catálogo, mas não deve alterar as cópias históricas das linhas concluídas. No filtro por produto, ligar as linhas antigas ao identificador estável; nos relatórios por categoria, usar a categoria histórica por padrão e documentar esse critério.

### Planejar

Criar lista para mês/ano; incluir produtos; definir quantidades; marcar necessidade; remover produtos não necessários; copiar composição e quantidades de uma lista anterior, sem copiar estados de carrinho ou valores pagos como se fossem novas compras.

A lista pode ter estados rascunho, ativa, encerrada e arquivada, se útil. O planejamento pode existir para um mês futuro enquanto o usuário consulta ou conclui uma compra do mês atual. Não resetar todo o aplicativo na virada do mês.

### Comprar

Abrir uma compra vinculada opcionalmente à lista, com data local real e mercado opcional. Para cada produto, registrar quantidade e preço reais e colocar no carrinho. Adicionar outra linha do mesmo produto por “+ outra compra deste item”.

Oferecer edição e exclusão por linha, confirmação para ações destrutivas e desfazer quando simples. Persistir cada alteração salva; fechamento forçado não pode eliminar o carrinho todo. Estados de edição inválidos podem ficar em formulário temporário, mas não podem alimentar totais.

Um toque em “no carrinho” deve abrir/preencher a linha com valores reais, ou explicitamente marcar preço pendente. Não copiar preço estimado para preço pago sem confirmação. Mostrar valores pendentes e bloquear a conclusão até resolver as linhas incluídas.

A lista pode originar várias compras em diferentes dias/mercados. Cada linha de compra pode apontar para um item planejado, permitindo deduzir atendimento parcial. Também se pode comprar algo não planejado, sem exigir planejamento retroativo.

### Concluir

Exibir resumo, itens não comprados, total e possibilidade de conferir com o caixa. Não concluir automaticamente só porque todas as caixas foram marcadas. Não chamar o total do carrinho de gasto definitivo.

Na conclusão, validar dados e salvar estado/linhas/cópias históricas em transação. A ação deve ser idempotente: toque duplo não cria duas compras. Itens não comprados permanecem explicitamente pendentes ou são descartados por decisão do usuário.

Compra cancelada não alimenta gasto nem preço/frequência. Uma edição posterior de compra concluída requer fluxo explícito e recálculo consistente; se esse recurso não entrar no primeiro corte, mostrar como somente leitura e documentar a limitação, sem apagar histórico para corrigir o banco.

## Regras de números

### Moeda

Persistir BRL em centavos inteiros. Não usar `double` como fonte de verdade para dinheiro. Converter texto com vírgula/ponto por parser explícito, com testes; evitar remover separadores sem considerar milhares. A interface deve guiar a digitação para evitar ambiguidades.

Exibir BRL em pt-BR. Toda regra de arredondamento deve ficar em serviço testado e ser aplicada uma vez por linha; o total é soma dos totais arredondados das linhas.

### Unidade

Produto por unidade usa quantidade inteira positiva. A forma “Por pacote” registra quantidade inteira de pacotes e preço por pacote; pacotes não são somados como unidades avulsas. “Uma unidade” pode ser garrafa ou caixa identificada. Conteúdo da embalagem não é quantidade de unidades compradas. Dois litros em cada garrafa não viram dois itens comprados.

Para suportar embalagens variadas, permitir produtos/variantes diferentes ou conteúdo conhecido. Sem conteúdo compatível, não comparar preço por unidade com preço por pacote nem calcular variação percentual entre embalagens diferentes.

### Peso

Peso é persistido em gramas inteiras positivas e informado em kg ou g. Preço é centavos por kg. Total bruto em centavos é preço_por_kg_centavos multiplicado por peso_em_gramas, dividido por 1000, com arredondamento half-up para valores não negativos.

Permitir selecionar “informar total da etiqueta” quando o usuário possuir o total exato cobrado. Nesse caso, persistir esse total como valor pago autoritativo e mostrar que o preço normalizado é derivado; nunca substituir silenciosamente o total da etiqueta pelo recálculo. Esta opção pode entrar como melhoria curta se não couber na primeira compra funcional.

Não permitir valores negativos no fluxo normal. Descontos e devoluções não são quantidades negativas improvisadas. Se descontos forem aprovados, especificar separadamente desconto por linha/compra e sua alocação antes de implementar.

### Comparação de preços

Um preço observado precisa de data, produto/variante, base de cobrança e origem. Mostrar claramente R$/unidade ou R$/kg. Para normalizar embalagem, exigir dimensão e conteúdo conhecidos, como massa ou volume. Nunca converter kg em litro sem regra de domínio específica, nem assumir equivalência entre pacotes de tamanhos desconhecidos.

Marca, corte ou embalagem diferentes podem ser agrupados visualmente pelo produto-base, mas referências de preço devem ter compatibilidade explicitada. Não inventar precisão usando produtos agregados como “Alface / rúcula / couve” sem revisão.

## Totais e projeções

### Totais exibidos

1. Estimativa original do planejamento: fotografia do que foi planejado, com fontes/data e versão.
2. Valor conhecido no carrinho da compra atual: somente linhas efetivamente incluídas com valores válidos.
3. Estimativa dos itens pendentes: somente quantidades ainda necessárias e com referência compatível.
4. Projeção desta compra: valor conhecido no carrinho mais estimativa dos pendentes, rotulada parcial se faltarem preços.
5. Gasto histórico mensal: somente compras concluídas com data real dentro do mês.

Não somar carrinho em andamento ao gasto histórico como se já tivesse sido pago. Se houver orçamento opcional, separar gasto concluído, carrinho e previsão restante na interface.

### Atendimento parcial

Para cada item planejado, quantidade atendida é a soma de linhas vinculadas em compras concluídas; quantidade no carrinho atual é separada. Quantidade pendente para a projeção é o máximo entre zero e planejada menos atendida menos carrinho atual, desde que unidades sejam compatíveis.

Se houver mais de um carrinho ativo ligado à mesma lista, evitar dupla alocação. Solução inicial preferida: permitir só uma compra em andamento por lista, sem impedir várias compras concluídas. Exibir claramente esse limite proposto no plano.

Não impedir comprar acima do planejado. Nesse caso, pendência é zero e o excesso é visível. Produto não planejado entra com seu valor real no carrinho e não precisa de estimativa residual.

### Referência de estimativa

Prioridade proposta:
- Preço manual específico do item planejado, marcado como estimado.
- Preço médio ponderado da última compra concluída compatível anterior ao limite temporal definido.
- Sem referência: pedir preço manual ou deixar estimativa incompleta.

“Última compra” pode conter várias linhas do produto. A referência é soma dos valores pagos compatíveis dividida pela soma das quantidades compatíveis. Não tirar média simples dos preços por linha quando quantidades diferem. Manter precisão suficiente como razão/decimal exato e arredondar na produção do total estimado, sem arredondamentos intermediários desnecessários.

No planejamento novo, mostrar a data de referência da estimativa. Salvar o valor/origem usados como fotografia. “Atualizar estimativa com histórico mais recente” deve ser ação explícita. Se calcular retrospectivamente uma previsão, não usar dados posteriores ao corte escolhido.

Itens sem preço não entram como zero. Mostrar quantidade de itens sem referência e “estimativa parcial”. Mês sem histórico não gera valores falsos. Margem de segurança e média de vários meses são extras opcionais.

## Histórico mensal

Usar data local da compra, armazenada de forma não ambígua, para agrupar por mês. Preservar o significado de dia/mês mesmo com mudança de fuso. Separar data civil de compra de timestamps técnicos de criação/edição.

Compras concluídas dentro do mês somam o gasto mensal, independentemente de sua lista de origem. Um mês pode conter várias idas ao mercado. Mostrar detalhamento por compra e visão agregada por produto; ao expandir, exibir todas as linhas e quantidades/preços.

Comparação do mês anterior usa exatamente o mês civil anterior ao selecionado. Sem compras nesse mês, mostrar “não comprado neste mês”; oferecer “última compra disponível” como informação diferente. Não preencher o mês anterior com o último preço de qualquer data sem rótulo.

Para produto/embalagem compatível, permitir quantidade total, gasto total e preço médio ponderado do mês. Não somar quantidades incompatíveis na mesma célula sem discriminar unidades.

## Frequência de compra

Consultar apenas compras concluídas válidas. Para cada produto, ordenar datas civis distintas em que foi comprado. Várias linhas ou compras no mesmo dia contam como uma data para intervalos.

Exibir meses/anos observados, última data, dias sem comprar e número de eventos/datas usados. Proposta: exigir no mínimo três datas distintas para sugerir frequência; usar mediana dos intervalos em dias e mostrar “intervalo observado aproximado”. Com histórico menor, apresentar dados existentes e “ainda sem histórico suficiente”.

Não inventar frequência exata em meses a partir de dias. Datas em janeiro, abril e julho podem ser mostradas como meses observados; qualquer aproximação em meses deve vir rotulada. Sem histórico importado, os primeiros meses do app terão recomendações limitadas.

Relógio/data atual devem ser injetáveis nos testes. Não contar listas planejadas, carrinhos cancelados ou marcações como compras. A sugestão de recompra pede revisão humana; não afirma estoque, consumo ou risco zero de faltar.

## Persistência e entidades

Identificadores internos estáveis, independentes da numeração do Excel. Proposta de tabelas:

| Entidade | Campos/conceitos principais |
|---|---|
| Category | id, nome, ordem, arquivada |
| Subcategory | id, categoryId, nome, ordem, arquivada |
| Product | id, nome, categoria, subcategoria opcional, modo unidade/pacote/peso ou pendente de revisão, arquivado, descrição |
| ProductVariant, se necessária | id, productId, descrição, marca, conteúdo/dimensão opcionais, códigos locais futuros |
| ShoppingPlan | id, mês/ano de referência, status, criado/editado |
| PlannedItem | id, planId, productId, variantId opcional, quantidade/unidade desejada, estimativa e origem, ordem |
| ShoppingTrip | id, data civil, status, mercado opcional, planId opcional, criado/editado/concluído |
| PurchaseLine | id, tripId, productId, variantId opcional, plannedItemId opcional, quantidade/base, preço, total, estado, snapshots históricos |
| ImportBatch/ImportEntry | origem, lote, referência estável por aba/linha, vínculo para entidade criada |
| Settings | preferências e parâmetros versionados |

Não exigir todas as tabelas opcionais imediatamente. Não persistir contadores calculados que possam divergir sem definir atualização transacional. Declarar relações, índices, integridade e política de exclusão no plano técnico.

Snapshots históricos: nome do produto/variante, categoria/subcategoria e base de cobrança no momento da compra. A referência estável ao catálogo permanece para consultar evolução do mesmo produto. Produto arquivado continua aparecendo no passado.

Estados mínimos da compra: em andamento, concluída e cancelada. Estado de linha deve permitir distinguir rascunho/pendente de preço e incluída com valores válidos. “Remover do carrinho” não apaga compras históricas.

Toda evolução de schema precisa aumentar versão, migrar e testar preservação. Não usar “apague o app e reinstale” como solução após começar a usar dados reais. Desenvolver/testar com banco separado e dados fictícios identificados.

## Importação do catálogo

1. Ler `catalogo-inicial.json` como dados de catálogo, não como backup.
2. Conferir estrutura, nomes e origem; oferecer prévia antes de salvar.
3. Criar categorias existentes e produtos com IDs próprios.
4. Preservar nomes, sem usar numeração original como chave.
5. Marcar os 13 sem categoria como “A classificar” na interface; não criar uma decisão de classificação definitiva.
6. Todos os modos de compra ficam pendentes de revisão; oferecer escolha ao primeiro uso, sem bloquear consulta do catálogo.
7. Ignorar as seis linhas sem nome, subtotais, totais e fórmulas.
8. Não importar valores vazios como zero; não criar compras concluídas.
9. Detectar uma repetição da mesma importação por referência estável de origem e lote. Não comparar apenas nomes para mesclar produtos distintos.
10. Registrar relatório de importação, pendências e itens ignorados.

Unidade/peso é escolha obrigatória antes de confirmar a primeira linha de compra desse produto. Quando já houver histórico, mudar o modo de compra exige nova variante/produto ou migração explícita, não reinterpretar quantidades antigas.

## Backup e exportação

Backup completo em JSON com `formatVersion`, versão do app/schema, data de exportação, moeda, registros, IDs e relações. Exportar catálogo, variantes, categorias, listas, itens, compras, linhas, preferências e metadados necessários à consistência. Não limitar backup ao CSV de produtos.

Usar o seletor de arquivos do sistema para salvar fora da pasta privada. Lembrar da exportação após compras, mostrar data da última exportação bem-sucedida e permitir copiar o arquivo para outro dispositivo. Não chamar arquivo temporário na pasta privada de backup seguro contra desinstalação.

CSV serve para análise humana de compras concluídas, com data, produto, unidade, quantidade, preço, total, compra e categoria. CSV não substitui backup completo. Considerar escape de fórmulas em células de texto ao exportar para planilhas.

Restauração inicial por substituição completa com confirmação, não mesclagem. Validar sintaxe, versão, tipos, limites, IDs, vínculos e moeda antes de modificar o banco. Gerar cópia de segurança anterior, restaurar de forma atômica e não destruir banco funcional se houver erro. Definir e testar comportamento de backups de versões anteriores.

Documentar se o backup Android do sistema estará habilitado, em vez de prometer que offline significa ausência absoluta de cópia em nuvem. Arquivos de backup exportados podem conter dados pessoais e não devem entrar em repositório público.

## Telas propostas

- Início/listas: mês selecionado, listas e situação, acesso a histórico e catálogo.
- Planejamento: grupos recolhíveis, busca, seleção, quantidade, estimativa e referência.
- Compra: carrinho/pendentes, formulário rápido, “+ outra compra deste item”, totais fixos sem esconder os avisos.
- Histórico: seleção de mês/ano, gasto, compras e itens detalhados.
- Produto: cadastro, última compra, preços, meses observados e frequência.
- Configurações: exportar/restaurar backup, exportar CSV, versão e preferências.

Preferir fluxos rápidos para uso em pé no mercado. Botões identificáveis, fonte legível, áreas de toque adequadas, contraste, suporte a fonte ampliada, teclado numérico com decimal quando apropriado, rolagem sem perder formulário e ação de salvar explícita. Acessibilidade e modo escuro são desejáveis, sem sobrepor requisitos de dados.

Não exigir um menu separado para toda entidade. Agrupar cadastro e detalhe com simplicidade. Não criar login ou onboarding longo.

## Etapas e portões de qualidade

### Etapa 0: plano e diagnóstico

Somente leitura. Explicar arquitetura, ambiente, riscos, decisões e pendências. Não criar o projeto antes da aprovação. Identificar OS do computador e versão Android quando necessário, sem presumir. Não pedir extras agora se não bloqueiam o núcleo.

### Etapa 1: projeto e base persistente

Após aprovação, configurar projeto, banco, categorias/subcategorias/produtos, catálogo revisável, backup/restauração e testes da base. Fazer primeira execução física. Mostrar CRUD e persistência após reiniciar. Sem carrinho fictício disfarçado de funcional.

### Etapa 2: primeira compra completa

Planejamento com quantidade desejada, compra com data real, linhas múltiplas unidade/pacote/peso, totais e conclusão. Persistência imediata, validações, finalização idempotente e compra parcial. Mostrar histórico mínimo de uma compra para comprovar fechamento do ciclo.

### Etapa 3: histórico e previsões

Histórico mensal completo, mês anterior versus última compra, preço ponderado, fotografias de estimativa, pendência parcial, detalhe do produto e frequência. Testar falta de dados, unidades e limites de mês.

### Etapa 4: confiabilidade e uso diário

Migrações com dados preexistentes, exportação/restauração em instalação de teste separada, recuperação de carrinho, acessibilidade essencial, assinatura release e APK. Testar atualização sem desinstalar e guardar chave fora do repositório.

### Etapa 5: extras aprovados

Antes de cada extra, definir objetivo, telas, dados adicionais, esforço, migração e teste. Não transformar aprovação do núcleo em autorização genérica de todos os módulos.

## Testes de aceitação

Exemplos abaixo são fixtures fictícias de software, não dados da planilha nem estimativas de gasto real.

1. Produto por unidade: duas linhas, 2 unidades a R$ 8,00 e 3 unidades a R$ 7,50, totalizam R$ 38,50. A referência ponderada é R$ 7,70 por unidade, não R$ 7,75.
2. Produto por peso: 0,750 kg a R$ 39,90/kg resulta em R$ 29,93 com half-up por linha. Entrada equivalente em 750 g produz o mesmo resultado.
3. Outra linha de peso: 1,200 kg a R$ 42,90/kg gera R$ 51,48; junto com a linha anterior, total R$ 81,41.
4. Quatro ou mais linhas do mesmo produto são aceitas; editar/remover uma só muda sua parcela.
5. Planejar 5 unidades, ter 2 já compradas em compra concluída e 1 no carrinho atual deixa 2 unidades para a projeção residual. Não estimar outras 5.
6. Aumentar o carrinho acima da quantidade planejada zera a pendência sem gerar previsão negativa.
7. Um produto sem preço torna a estimativa parcial; não vira linha de custo zero.
8. Mês anterior sem compra mostra ausência, mesmo que haja preço de dois meses antes.
9. Compra concluída em dezembro ligada à lista de novembro entra no gasto de dezembro.
10. Carrinho em andamento não entra no gasto mensal concluído, preço histórico ou frequência.
11. Duas linhas no mesmo dia não geram duas datas de frequência; menos de três datas não gera periodicidade afirmada.
12. Renomear/arquivar produto conserva os rótulos e totais das compras antigas.
13. Fechar e reabrir app conserva carrinho salvo, planejamento e compras concluídas.
14. Toque duplo na conclusão não duplica compra nem total mensal.
15. Importação inicial cria 139 produtos nomeados, nove categorias, 13 classificações pendentes e nenhuma compra histórica; reimportação não duplica silenciosamente.
16. Antes da revisão, produto importado pede a forma de compra ao primeiro uso; não assume que todo produto é unitário.
17. Comparar garrafa de 2 L com garrafa de 1 L não produz variação por unidade sem explicar/normalizar o conteúdo.
18. Backup exportado/restaurado mantém IDs, relações, histórico, unidades, quantidades e totais; arquivo corrompido deixa banco atual intacto.
19. Migração entre versões conserva registros e não reinicializa o banco para contornar erro.
20. Negar câmera ou não ter internet não bloqueia o núcleo; câmera só será pedida se o módulo de código de barras for aprovado.
21. Todo o ciclo de planejamento, compra, histórico e exportação local funciona em modo avião.

## Verificação técnica esperada

Executar geração Drift quando necessária, `flutter analyze`, `flutter test` e verificação de formatação. Para interface e navegação, adicionar testes de widgets relevantes. Para persistência, testar banco real/in-memory conforme a finalidade, além de migrações com dados de versão anterior.

Ter relógio controlável nos testes de data e frequência. Fixtures de teste devem ser separadas dos dados reais; nunca gravá-las automaticamente no catálogo de produção ou apresentar números fictícios como compras reais.

A IA deve informar os comandos realmente executados, erros remanescentes e as verificações manuais que dependem do aparelho. Um build bem-sucedido não comprova sozinho usabilidade, restauração nem funcionamento no Android do usuário.

## Extras disponíveis para decisão posterior

| Módulo | O que precisa ser definido antes |
|---|---|
| Orçamento e alerta | Limite por mês, carrinho versus gasto concluído e comportamento do aviso |
| Sugestão de recompra | Critério de intervalo, confiança e opção de ignorar/adiar |
| Estoque simples | Estado manual “tem/está acabando/acabou”, sem prometer saldo automático |
| Estoque quantitativo | Entrada, consumo, descarte, ajuste e unidade base compatível |
| Validade | Lotes, datas opcionais, saldo por lote, alertas e permissões de notificação |
| Código de barras | Associação local código/produto/variante, duplicidade, câmera e modo manual |
| Foto/OCR de cupom | Fonte, processamento, privacidade, conferência e resolução de erros |
| Preço por embalagem | Massa/volume/conteúdo conhecidos e normalização sem misturar dimensões |

Código de barras pode funcionar offline para identificar códigos e localizar cadastros já associados. O escopo não inclui descobrir nome, preço ou validade de um produto desconhecido sem cadastro ou serviço externo. Em Android, se usar `mobile_scanner`, verificar a opção com modelo embarcado para o primeiro uso offline, sem fixar versões antigas.

Estoque e validade não devem entrar como indicadores falsamente automáticos: compras registram entradas, mas consumo não é conhecido pelo app sem ação do usuário. Frequência observada não é cálculo confiável de saldo.

## Segurança, privacidade e manutenção

Sem telemetria obrigatória ou serviços remotos no núcleo. Solicitar apenas permissões necessárias à funcionalidade aprovada. Usar seletor do sistema para documentos, evitando acesso amplo a todos os arquivos.

Git deve rastrear código, especificações, testes e schemas de migração. Excluir senhas, keystores, configuração privada de assinatura, bancos reais, backups e material pessoal que não se queira publicar. Antes de subir catálogo ou planilha pessoais, confirmar intenção do usuário.

Usar uma chave de release estável e identificador de aplicativo estável para atualizações. Não confundir debug com release; se forem instalações separadas, explicar que não compartilham banco automaticamente e usar backup validado para transferência quando apropriado. Não desinstalar a instalação com dados reais para resolver conflito de assinatura.

A documentação oficial atual informa mudanças na verificação de distribuição Android no Brasil e manutenção do fluxo ADB. Consultar o estado vigente na hora de instalar/distribuir: https://developer.android.com/developer-verification/guides

O custo de ferramentas de IA, se houver, é separado do aplicativo. Não prometer custo zero de qualquer assinatura de assistente; o desenho do app evita infraestrutura remota paga obrigatória.

## Decisões abertas não bloqueantes

- Nome final e identificador do aplicativo: propor antes de fixar assinatura/distribuição.
- Aparência e ordem das categorias: manter simples e ajustável.
- Frequência: confirmar critério proposto de mediana e mínimo de três datas ao chegar nessa etapa.
- Referência de estimativa: confirmar última compra compatível e opção manual.
- Extras: aprovar módulo a módulo, sem interpretar resposta ambígua como autorização total.
- Edição de compra concluída, descontos e total da etiqueta: delimitar no plano para não implementar sem regras.
- Política de backup Android do sistema: explicitar e documentar.

## Documentação de apoio

- Flutter/VS Code: https://docs.flutter.dev/tools/vs-code
- Preparação Android: https://docs.flutter.dev/platform-integration/android/setup
- Release/assinatura: https://docs.flutter.dev/deployment/android
- Drift: https://drift.simonbinder.eu/setup/
- Transações: https://drift.simonbinder.eu/dart_api/transactions/
- Migrações: https://drift.simonbinder.eu/migrations/
- Testes de migração: https://drift.simonbinder.eu/migrations/tests/
- Boas práticas Claude: https://code.claude.com/docs/en/best-practices

Estas referências justificam ferramentas e procedimentos, não os requisitos de negócio propostos. Consultar versões atuais durante a implementação e manter escolhas registradas em `docs/decisoes.md` e andamento em `docs/progresso.md` quando esses arquivos forem criados após aprovação.
