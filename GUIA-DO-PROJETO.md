# Da planilha ao app de mercado

## A recomendação

Criar um app Android individual, totalmente offline, e desenvolver uma etapa por vez no VS Code. A escolha proposta é Flutter/Dart com banco SQLite por Drift. Flutter dispõe de execução e depuração no VS Code e geração de APK Android.[cite:10][cite:30] Drift oferece persistência relacional, transações e ferramentas para migrações testáveis.[cite:64][cite:70][cite:14]

O produto não precisa de IA dentro do app para consultar preços, somar compras ou mostrar frequência. A IA será a ferramenta usada para programar. Login, servidor e publicação na Play Store não fazem parte da primeira entrega proposta.

O projeto Flutter das Etapas 1 e 2 está em `app\`. Catálogo, planejamento, carrinho e conclusão explícita foram implementados e validados localmente. O novo ciclo de compra ainda precisa do teste manual no celular. Consulte [docs/progresso.md](docs/progresso.md) e [app/README.md](app/README.md).

## O que foi aproveitado

A planilha tem uma aba `112026`, nove categorias, marcações “Precisa?” e “No carrinho?” e três pares de valor/quantidade por produto.[file:1] Foram identificados 139 produtos nomeados: 126 nas categorias e 13 depois do primeiro total, além de seis posições numeradas sem nome.[file:1]

| Categoria | Produtos |
|---|---:|
| Carnes e Frios | 25 |
| Hortifruti | 26 |
| Mercearia e Laticínios | 28 |
| Padaria | 7 |
| Bebidas | 9 |
| Temperos e Condimentos | 6 |
| Limpeza | 13 |
| Higiene | 9 |
| Úteis | 3 |
| Sem categoria explícita, após o total | 13 |

A tabela é uma contagem dos nomes do arquivo, não das compras feitas.[file:1] A numeração 103 aparece duas vezes, motivo para usar identificadores próprios no banco, e não a numeração visual da planilha.[file:1]

Não há preços e quantidades preenchidos que permitam reconstruir compras anteriores nesse arquivo.[file:1] O catálogo foi extraído para facilitar o começo, sem inventar histórico, forma de compra ou categoria dos itens finais. Nome da aba não é comprovação de compra em um mês.

## As quatro partes

**Proposta funcional:** separar quatro conceitos, em vez de reproduzir as colunas do Excel.

| Parte | Papel |
|---|---|
| Catálogo | Todos os produtos, categorias e subcategorias cadastrados |
| Planejamento | O que comprar e em qual quantidade, com referência de preço |
| Carrinho | Quantidades e preços reais informados durante a compra |
| Histórico | Compras explicitamente concluídas e seus valores pagos |

Remover um produto da lista não apaga o cadastro. Comprar parte de uma quantidade não apaga a quantidade planejada. Colocar no carrinho não conta como compra paga. A finalização explícita conecta o carrinho ao histórico.

O botão “+ outra compra deste item” cria outra linha do mesmo produto, com quantidade e preço independentes. Não haverá limite de três linhas por produto.

## Estimativa e preço anterior

Proposta: usar preço manual informado no planejamento ou preço médio ponderado da última compra concluída compatível. Se não existir referência, mostrar “sem estimativa”, não zero. Guardar origem/data e uma fotografia da previsão original, para não reescrevê-la silenciosamente.

Mostrar três valores durante a compra: total conhecido no carrinho, previsão dos itens ainda faltantes e projeção final. A projeção desconta quantidades já atendidas e no carrinho para não contar duas vezes.

O mês anterior e a última compra disponível são consultas diferentes. Se não houve compra no mês anterior, o app deve dizer isso, mesmo que exista preço mais antigo. Produtos de embalagens diferentes precisam de variantes ou normalização explícita para não comparar preços incompatíveis.

## Unidade e peso

Proposta: produto por unidade tem quantidade inteira; produto por peso aceita entrada em kg/g e armazena gramas. Dinheiro fica em centavos inteiros, com arredondamento testado por linha. Uma garrafa de dois litros comprada por unidade continua sendo uma unidade, não duas.

Embalagem, marca e conteúdo podem ajudar na comparação, mas não devem ser inventados a partir de nomes genéricos do Excel. Produtos importados terão a forma de compra pendente até a revisão ou o primeiro uso.

## Meses e frequência

Proposta: gasto mensal é agrupado pela data real de compras concluídas. Uma compra realizada em dezembro entra em dezembro, mesmo que tenha vindo de um planejamento de novembro. Listas futuras e várias idas ao mercado podem coexistir.

O detalhe de cada produto deve mostrar compras, meses observados, última data e tempo sem comprar. Para sugerir periodicidade, a proposta é usar a mediana dos intervalos entre datas distintas, exigir pelo menos três datas e mostrar quantos intervalos foram usados. Sem dados suficientes, informar a limitação.

Isso é frequência observada, não estoque. Sem registrar consumo ou confirmar que um produto acabou, o app não pode garantir que nada vai faltar.

## Extras sem inflar o começo

A resposta sobre combinar “item 3 e 4” não identifica inequivocamente um conjunto de extras. Portanto, o projeto mantém os recursos pedidos como núcleo e separa sugestões para aprovação, sem presumir autorização para todas.

| Sugestão | Ordem recomendada |
|---|---|
| Orçamento mensal e aviso de limite | Depois da primeira compra funcional |
| Favoritos, busca e ordem por corredor | Melhoria curta de uso |
| Preço por embalagem e estabelecimento | Após validar comparações |
| Sugestões de recompra | Quando houver histórico suficiente |
| Estoque simples “tem/está acabando/acabou” | Opcional, com atualização manual |
| Estoque quantitativo e validade | Módulo independente |
| Código de barras | Módulo independente |
| Foto/OCR de cupom | Futuro, com revisão dos dados |

Para códigos, há plugin Flutter com reconhecimento embarcado no Android, sem precisar baixar o modelo no primeiro uso.[cite:37] O escopo proposto associa o código a um cadastro local; não promete descobrir nome, preço ou validade de produto desconhecido sem cadastro ou integração separada.

## Preservar o histórico

Backup precisa entrar cedo: arquivos privados podem ser removidos ao desinstalar o aplicativo, enquanto documentos exportados pelo seletor do sistema não dependem da instalação para existir.[cite:35]

Proposta: backup completo em JSON versionado, salvo num local escolhido pelo usuário; CSV separado para consulta em planilha. Restauração valida o arquivo antes de substituir dados, exige confirmação e usa transação. Arquivo corrompido não deve destruir o banco atual.

Drift permite testar migrações e conferir preservação de dados entre versões.[cite:7] A IA não deve resolver mudança de banco mandando apagar o app depois que houver compras reais.

O Android também pode fazer backup pelo sistema conforme configuração e aparelho; a política deve ser documentada, pois “sem servidor próprio” não implica ausência de backup em nuvem pelo sistema operacional.[cite:68]

## Do VS Code ao Android

Flutter pode ser usado no VS Code, mas SDK e ferramentas Android também precisam ser configurados.[cite:10][cite:22] O guia oficial orienta conectar um Android com depuração USB, verificar `flutter devices` e validar o ambiente com `flutter doctor`.[cite:22]

A execução inicial pode ser feita com `flutter run`; depois, o projeto poderá gerar um APK de release e instalá-lo no aparelho conectado.[cite:30] Atualizações exigem identificador de app e assinatura compatíveis, por isso a chave de release deve ser guardada e não recriada a cada build.[cite:60]

A documentação Android atual descreve mudanças de verificação de distribuição no Brasil e informa que o fluxo ADB permanece disponível; também apresenta distribuição limitada para uso pessoal em até 20 dispositivos.[cite:17][cite:18] Começar pelo aparelho conectado não exige tratar publicação pública em loja como primeira tarefa.[cite:22][cite:17]

Internet pode ser necessária no computador para instalar ferramentas e dependências. O aplicativo instalado deve funcionar offline no ciclo inteiro de uso.

## Desenvolvimento por etapas

1. Diagnóstico e plano: concluído.
2. Base: implementada e validada por testes locais; o usuário informou que o primeiro teste no aparelho pareceu funcionar.
3. Compra completa: implementada e validada por testes locais; aguardando teste manual deste fluxo no Android.
4. Histórico e previsão: implementada e validada localmente; aguardando teste manual no Android.
5. Confiabilidade: migrações futuras, recuperação, teste offline, assinatura e APK release; ainda não iniciada.
6. Expansões: somente após escolha e aprovação.

Claude Code oferece um modo de planejamento para analisar antes de editar.[cite:31] Manter um `CLAUDE.md` curto com restrições e comandos de teste, e requisitos detalhados em arquivo separado, segue a orientação de contexto permanente enxuto.[cite:32][cite:36]

## Próximo passo prático

Abra `app\` no VS Code, conecte o aparelho Android com Depuração USB e siga o roteiro da Etapa 3 em [app/README.md](app/README.md). Use a junction ASCII para evitar os erros de codificação já observados no caminho Windows.

Antes de atualizar o banco local, exporte um backup para um local escolhido por você e verifique o arquivo. Restauração substitui os dados locais; use um backup verificado para remover registros de teste.
