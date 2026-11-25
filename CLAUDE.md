# Regras permanentes do projeto

## Objetivo e contexto
App Android pessoal de mercado, offline. Requisitos completos em `REQUISITOS.md`; etapas em `PROMPTS-POR-ETAPA.md`. Comunicação e interface em pt-BR.

## Stack proposta
Flutter/Dart estável, Material 3, Riverpod, SQLite/Drift. Verificar versões compatíveis; manter `pubspec.lock`. Não mudar a stack ou adicionar backend sem aprovação.

## Invariantes
- Catálogo != planejamento != carrinho != compra concluída.
- Planejado != comprado. Mês planejado != data real da compra.
- Várias linhas por produto, sem limite artificial.
- Somente compra concluída alimenta gastos, preços reais e frequência.
- Centavos inteiros; peso em gramas; arredondamento explícito e testado.
- Ausência de preço não equivale a zero. Histórico importado não pode ser inventado.
- Comparar apenas preços com unidades/embalagens compatíveis.
- Arquivar produtos com histórico; preservar dados históricos e suas descrições.
- Migrações versionadas e testadas. Nunca resetar banco para resolver migração.
- Persistir alterações do carrinho sem depender da conclusão da compra.
- Sem dependência de internet, login ou serviço remoto para o núcleo.
- Não implementar extras não aprovados.

## Verificação
Depois que houver projeto Flutter:
- Dependências: `flutter pub get`
- Código gerado Drift, quando necessário: `dart run build_runner build --delete-conflicting-outputs`
- Formatação: `dart format --output=none --set-exit-if-changed lib test`
- Análise: `flutter analyze`
- Testes: `flutter test`
- Dispositivo: `flutter devices`; execução: `flutter run`
- APK de produção: `flutter build apk --release --flavor production`, apenas após configurar e conferir assinatura.
- APK piloto: `flutter build apk --debug --flavor pilot`; não substitui a release de produção.

Ajustar os comandos de diretório se o projeto ficar em subpasta, documentando isso. Código gerado não deve ser editado à mão. Rodar geração antes dos testes se houver mudanças que a exijam.

## Fluxo
Planejar antes de alterações grandes. Uma etapa por vez. Informar comandos efetivamente executados e separar teste automatizado de teste manual. Não inventar resultados. Ao encerrar, atualizar progresso e orientar teste no Android.

Não executar comandos destrutivos, limpar dados reais, desinstalar, fazer commit/push, instalar ferramentas globalmente ou alterar assinatura sem aprovação. Não expor backups pessoais, planilha real, chaves ou senhas em repositório público. Dados de teste devem ser claramente fictícios e isolados.
