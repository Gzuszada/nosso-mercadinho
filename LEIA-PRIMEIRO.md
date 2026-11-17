# Seu app de mercado: estado e próximos passos

O projeto Flutter das Etapas 1 a 3 está em `app\`: catálogo local, planejamento, carrinho persistente, conclusão explícita, histórico mensal e estimativas. A Etapa 3 está implementada e aguarda teste manual no Android; exporte e verifique um backup antes de atualizar uma instalação com dados reais.

## Material

- `PROMPT-INICIAL.md`: copie o conteúdo para a IA no VS Code.
- `REQUISITOS.md`: escopo detalhado, modelo de dados, cálculos e critérios de aceite.
- `CLAUDE.md`: regras curtas para o Claude Code. Outros assistentes devem ser instruídos a ler o arquivo.
- `PROMPTS-POR-ETAPA.md`: instruções para liberar cada etapa depois da aprovação do plano.
- `catalogo-inicial.json`: 139 produtos nomeados extraídos do Excel; não é backup nem histórico de compras.
- `catalogo-revisao.csv`: os mesmos produtos, para conferir nomes e classificação. Não é necessário editá-lo para começar.

## Situação atual

- O computador é Windows 11 Pro 64 bits.
- Flutter 3.47.9 estável, Dart 3.13.7, JDK 21 e Android SDK 36.1.0 estão instalados localmente.
- Migrações do banco 1→4, 2→4 e 3→4, 42 testes automatizados, análise estática e formatação foram validados; o APK debug com Configurações foi gerado localmente.
- O teste físico das Etapas 2 e 3 e das Configurações continua pendente. Antes de atualizar dados reais, exporte e verifique um backup.
- O identificador Android atual é provisório (`com.example.mercado`); precisa ser decidido antes do APK pessoal de release.

Veja [docs/progresso.md](docs/progresso.md) para os comandos e resultados; [app/README.md](app/README.md) explica como abrir e testar o app.

## Próximo passo

1. Abra `app\` no VS Code.
2. Conecte o Android por USB, habilite Depuração USB e aceite a autorização do computador no aparelho.
3. No terminal do VS Code, execute `flutter devices`. Se o aparelho aparecer, execute `flutter run --debug -d ID_DO_APARELHO`, substituindo pelo identificador listado.
4. Siga o roteiro da Etapa 3 em [app/README.md](app/README.md). Ele evita compras fictícias e recomenda não alterar uma base real sem backup verificado.
5. Informe o resultado no Android antes de autorizar qualquer etapa posterior.

Não foi criado APK release nem configurada assinatura. Isso fica para a etapa de confiabilidade, após escolher o identificador definitivo e testar o fluxo no aparelho.

## O que foi definido

- Uso individual no Android.
- Funcionamento offline, inclusive planejamento, preços, carrinho e histórico.
- VS Code como editor, com ajuda da IA para programar e instalar.
- Todo o núcleo funcional solicitado faz parte do produto; as etapas só dividem a implementação.
- Não há aprovação inequívoca para estoque, validade ou códigos de barras. São expansões separadas, não condições para a primeira versão.

## O que revisar no catálogo

O arquivo tem uma aba, `112026`, e nove categorias. Há 139 produtos nomeados, porque a numeração 103 foi usada duas vezes. Os seis números finais sem nomes foram descartados da extração.

Treze produtos aparecem após o primeiro total e ficaram sem categoria na extração. Não foram classificados silenciosamente como “Úteis”. Todos os produtos estão com forma de compra pendente: o Excel não fornece metadados confiáveis para decidir unidade ou peso automaticamente.

Os nomes foram preservados, inclusive nomes comerciais e itens genéricos que talvez devam ser separados depois. Revise embalagens e variantes aos poucos na interface do app; não precisa decidir tudo antes de começar.

O nome da aba não prova a existência de compras em novembro de 2026. Não foram encontrados valores de compras preenchidos para importar como histórico. Preço vazio não vira zero e fórmula com total zero não vira compra.

## Cuidados

- Não entregue senhas, arquivos de assinatura nem dados de backup a repositórios públicos.
- Não deixe a IA desinstalar o aplicativo com dados reais para resolver problemas de banco.
- Durante o desenvolvimento, use uma instalação de teste separada da instalação com dados reais.
- Backup só dentro da pasta privada do app não protege contra desinstalação. Exporte também para um local escolhido por você.
- Guarde a chave de assinatura para conseguir atualizar o APK; não a regenere a cada versão.
- O catálogo inicial não inclui as compras feitas depois: exporte backups completos pelo app.

## Documentação técnica

- Flutter no VS Code: https://docs.flutter.dev/tools/vs-code
- Android e dispositivo físico: https://docs.flutter.dev/platform-integration/android/setup
- APK e assinatura: https://docs.flutter.dev/deployment/android
- Drift: https://drift.simonbinder.eu/setup/
- Migrações Drift: https://drift.simonbinder.eu/migrations/
- Claude Code: https://code.claude.com/docs/en/best-practices
- Verificação e distribuição Android: https://developer.android.com/developer-verification/guides

Consultar versões estáveis e compatíveis durante a implementação. A internet pode ser necessária para preparar o computador e baixar dependências; o aplicativo instalado deve funcionar offline.
