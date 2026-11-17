# Nosso Mercadinho

Aplicativo Android pessoal com dados locais, também publicado como PWA. Abra `app\` no VS Code. O identificador Android está definido como `br.com.nocorre.mercado`; a versão atual é `1.0.4+12`. A entrada no mercado exige uma conta autorizada; depois do login, o banco local continua disponível para operação offline. O app também descobre as casas vinculadas à conta, restaura o nome da casa selecionada e permite trocar a casa em **Ajustes → Conta e sincronização**.

## Download do APK

A release assinada está disponível em [nosso-mercadinho-1.0.4.apk](https://github.com/Gzuszada/nosso-mercadinho/releases/download/v1.0.4/nosso-mercadinho-1.0.4.apk). SHA-256: `E3BA094D346F302E9A8B9C8D76B643AB73DE03BA3B9F5355941BA46C75FCC196`.

## O que já funciona

- Catálogo local persistente, categorias/subcategorias, importação revisável e backup/restauração.
- Exportação Android abre o seletor de documento do sistema para escolher onde salvar o JSON. A restauração lê diretamente o fluxo do documento, sem depender do tamanho informado pelo provedor Android. Aceita backups válidos do Mercado nos formatos 1 a 6, mostra os dados que serão substituídos e exige salvar uma cópia de segurança antes da troca. O catálogo inicial permanece incluído no app e pode ser importado pelo menu **Dados e backup**.
- Produtos podem ser apagados pelo menu do catálogo se não houver compra concluída nem vínculo ativo com lista/carrinho; retire-os da lista primeiro. Produtos com histórico concluído devem ser arquivados para preservar o histórico.
- A forma de compra aparece como somente leitura ao adicionar um produto à lista e vem do cadastro. Produtos pendentes precisam ser definidos no catálogo. A forma pode ser alterada no cadastro mesmo após vínculos; listas e compras existentes mantêm suas unidades registradas.
- Listas de compra por mês planejado e quantidades planejadas.
- Compras com data real, opcionalmente ligadas a uma lista.
- Linhas repetidas por produto, preço real em centavos, peso em gramas, carrinho persistente, edição/remoção e cancelamento.
- Cancelamento preserva listas, compras e suas linhas. Listas e compras canceladas ficam em seções recolhíveis; cancelar uma lista não cancela uma compra já iniciada.
- Na tela de compras, as seções de compras concluídas e canceladas são recolhíveis.
- Em **Listas**, os planos são separados em **Novas**, **Em andamento**, **Listas abertas**, **Realizadas** e **Canceladas**. As seções **Realizadas** e **Canceladas** são recolhíveis. Uma compra pode concluir e manter a lista aberta para iniciar outra compra; uma lista realizada não pode ser alterada nem iniciar outra compra.
- No carrinho, **Adicionar item da lista** e **Adicionar outro item** são ações separadas, sem sobrepor **Conferir e concluir compra**.
- Linhas do carrinho são agrupadas por categoria e subcategoria; dentro dos grupos, as vinculadas a itens planejados ficam azuis e as avulsas usam o fundo normal. Em compras por lista, a projeção separa total da lista (itens no carrinho mais estimativa do restante), itens fora da lista com preço conhecido e total geral projetado.
- Conclusão explícita transacional; só compras concluídas aparecem como histórico. Linhas sem preço bloqueiam a conclusão.
- Progresso de quantidade para listas parcialmente atendidas e proteção contra duas compras ativas da mesma lista.
- Histórico mensal por data real da compra, comparação com o mês civil anterior e histórico/frequência observada por produto.
- Estimativa fotografada a partir da última compra compatível anterior ao mês planejado, preço estimado manual e projeção separada do valor conhecido no carrinho.
- Ao adicionar uma linha a uma compra iniciada por lista, os produtos planejados aparecem destacados em azul; selecionar um associa a linha ao item planejado. A quantidade real comprada continua sendo informada separadamente.
- No carrinho iniciado por lista, **Adicionar item da lista** e **Adicionar outro item** são ações separadas. A primeira mostra apenas os itens planejados, agrupados por categoria; ao atingir a quantidade planejada, o produto fica cinza na seção **Já inserido no carrinho**. Se ultrapassar o planejado, a quantidade no carrinho fica vermelha. A segunda ação lista produtos que não estão na lista. Em compra sem lista, permanece a ação única **Adicionar item**.
- Compras iniciadas por lista têm selo azul **Da lista · nome**; compras avulsas ficam sem selo. A origem permanece visível mesmo depois de apagar a lista.
- Aba **Ajustes** (tela **Configurações**) com tema claro/escuro persistido localmente e reset seletivo da base.
- Limpeza mostra contagens e efeitos, pede confirmação em duas etapas (a última exige digitar a frase exibida) e executa em transação. Produtos vinculados a planejamento/histórico são arquivados, não apagados.
- Backup formato 6; restauração aceita formatos 1 a 6. O schema Drift atual é 6.

Compras concluídas continuam somente leitura. Estimativas não são preços pagos; projeções podem ser parciais. Produtos por peso podem registrar o total real da etiqueta; esse total é o valor pago autoritativo da linha.

## Abrir e executar no Android físico

O caminho original contém `Área de Trabalho`. Flutter/ADB já mostraram incompatibilidade de codificação nesse caminho. Para os comandos Android, use uma junction ASCII. No PowerShell, execute uma vez:

```powershell
$link = Join-Path $env:USERPROFILE 'MercadoApp'
$target = 'C:\Users\Usuario\OneDrive\Área de Trabalho\Mercado\app'
if (-not (Test-Path $link)) {
  New-Item -ItemType Junction -Path $link -Target $target
}
Set-Location $link
$flutter = Join-Path $env:LOCALAPPDATA 'Programs\flutter\bin\flutter.bat'
& $flutter devices
```

Se a junction já existir, confirme com `Get-Item $link | Format-List FullName,LinkType,Target` que `Target` aponta para a pasta `app`; não a recrie se apontar para outro lugar. Com o Android conectado, Depuração USB ativa e autorização aceita, copie o ID exibido e rode:

```powershell
& $flutter run --debug -d ID_DO_APARELHO
```

Se aparecer `INSTALL_FAILED_VERIFICATION_FAILURE`, confira no aparelho a opção **Instalar via USB** e aceite a confirmação de instalação. Não desative as proteções gerais do Android.

## Roteiro manual de regressão (base fictícia ou protegida)

Este roteiro cobre o comportamento existente da Etapa 3. Use dados fictícios ou uma instalação/base de teste isolada; não registre compras fictícias nem use opções de limpeza numa base com dados reais. Para migração de instalação, siga as instruções específicas da Etapa 4 abaixo: o novo `applicationId` instala como app separado e não deve substituir a instalação antiga.

1. Exporte um backup e, no Android, escolha o destino pelo seletor do sistema. Confirme que o arquivo existe e pode ser aberto como JSON; guarde-o em local privado.
2. Abra a versão de teste sem substituir nem desinstalar a instalação que contém dados reais.
3. Abra **Histórico** e consulte um mês com compras concluídas. Confira total, data real e comparação com o mês anterior; carrinhos em andamento e compras canceladas não devem entrar no gasto.
4. No histórico, abra um produto e confira datas/meses observados, última compra e frequência. Com menos de três datas distintas, o app deve indicar dados insuficientes para periodicidade.
5. No planejamento, abra as ações de um item e escolha **Definir preço estimado**. Confira que a origem/data estão identificadas como estimativa e que nenhum gasto ou compra é criado.
6. Se já houver histórico compatível anterior ao mês planejado, use **Atualizar estimativa pelo histórico** e confira que a referência/data mudam somente após essa ação.
7. Confira a projeção de um carrinho em andamento: valor conhecido do carrinho fica separado da estimativa das quantidades restantes; dados sem preço devem tornar a projeção parcial, nunca zero ou garantida.
8. Ao adicionar item numa compra iniciada por lista, confira que os produtos planejados aparecem destacados em azul com a quantidade planejada. Selecione um, informe a quantidade realmente comprada e verifique que ela pode ser diferente da planejada.
9. Em **Compras**, confirme o selo azul **Da lista · nome** nas compras vinculadas; compras avulsas ficam sem selo.
10. Em **Configurações**, alterne o modo escuro, feche e reabra o app e confirme que a preferência foi mantida.
11. Só teste uma limpeza seletiva com dados claramente fictícios e backup verificado. Confira primeiro as contagens; a primeira confirmação mostra o resumo, e a segunda exige digitar a frase exibida. Não use **Limpar tudo** com dados reais.
12. Numa instalação/base isolada, restaure um backup de teste: confira o aviso, cancele uma vez e confirme que nada mudou; depois confirme e verifique que o backup de segurança foi criado antes da substituição.
13. Ainda nessa base isolada, restaure um backup vazio e use **Dados e backup → Importar catálogo inicial**. Confirme que o catálogo inicial pode ser importado novamente.
14. Não conclua compras fictícias nem restaure backup sobre dados reais. Para exercitar conclusão/histórico e **Limpar tudo**, use somente uma instalação/base de teste isolada.

Informe qualquer diferença observada e o modelo/versão Android. A suíte automatizada cobre cálculos e migração, mas não substitui esse teste físico.

## Verificações de desenvolvimento

Abra o terminal PowerShell na junction ASCII (`$link`) para evitar os problemas de codificação do caminho:

```powershell
$flutter = Join-Path $env:LOCALAPPDATA 'Programs\flutter\bin\flutter.bat'
& $flutter test
& $flutter analyze
& $flutter build apk --debug
```

O APK debug fica em `build\app\outputs\flutter-apk\app-debug.apk`. Ele não é APK release assinado.

O banco está no schema 5. A migração 3→4 adiciona a fotografia da origem da compra e a tabela local de preferências; a versão 5 não altera a estrutura das tabelas. As migrações 1→5 e 2→5 também são testadas. O backup está no formato 5 e mantém leitura dos formatos 1 a 5. A preferência de tema não faz parte do backup e não é removida pelo reset. No Android, a gravação abre o seletor de documentos do sistema; a restauração exige confirmação e uma cópia de segurança antes de substituir os dados. O arquivo `android\gradle.properties` mantém `android.overridePathCheck=true` para o caminho Windows original. Para regenerar Drift após alterar o schema:

```powershell
& $flutter pub run build_runner build --force-jit
```

Não edite `lib\data\app_database.g.dart` manualmente. Verificações e decisões estão em [docs/progresso.md](../docs/progresso.md) e [docs/decisoes.md](../docs/decisoes.md).

## Nosso Mercado na Web (PWA)

A versão Web é publicada em `https://nosso-mercado-casa.web.app`. No iPhone (Safari), abra esse endereço, toque em **Compartilhar** e depois em **Adicionar à Tela de Início**. O app instalado abre em tela cheia. A tela de entrada exige uma conta autorizada; após autenticar, o app continua usando o Drift local quando a internet está indisponível.

A build web oficial usa Dart2JS para a interface e mantém o Drift em SQLite WebAssembly dentro de `drift_worker.js`:

```powershell
Set-Location app
flutter build web --release --no-pub
firebase deploy --only hosting --project nosso-mercado-casa
```

Essa combinação permite que o app inicialize em navegadores sem WasmGC, como Safari mais antigo no iPhone 11, sem resolver bindings FFI nativos no navegador. A pasta `web/` deve conter `sqlite3.wasm` e `drift_worker.js`; o `sqlite3.wasm` deve ser o asset oficial da versão resolvida em `pubspec.lock` (`sqlite3 3.5.2` para o asset Web, SHA-256 `13D3F11D05B39BA0618A7115FB41640A5D48B6300F5D3F325F554B42BD6688A4`). Não substitua esse arquivo por uma build SQLite diferente sem validar o smoke test no navegador. O Hosting usa `Cache-Control: no-cache` para que atualizações do PWA não fiquem presas em um WASM ou bundle antigo.

## Nosso Mercado na Web e sincronização da casa

A versão Web é publicada em `https://nosso-mercado-casa.web.app`. No iPhone (Safari), abra esse endereço, toque em **Compartilhar** e depois em **Adicionar à Tela de Início**. O app instalado abre em tela cheia. A tela de entrada exige uma conta autorizada; após autenticar, o app continua usando o Drift local quando a internet está indisponível.

As duas pessoas da casa podem:

1. entrar ou criar uma conta autorizada com e-mail e senha na tela inicial;
2. criar a casa no primeiro dispositivo em **Configurações → Conta e sincronização**;
3. gerar um código de convite para o e-mail da segunda pessoa;
4. entrar com o código no segundo dispositivo;
5. tocar em **Sincronizar agora**.

A primeira sincronização publica os dados locais da casa. Se os dois dispositivos já tiverem alterações divergentes, o app mostra o conflito por área (catálogo, importações ou listas/compras) e permite manter a versão local ou aplicar a remota. Firestore é o espelho compartilhado; o banco Drift local continua sendo a fonte imediata e offline.

O projeto Firebase `nosso-mercado-casa` (nome de exibição **Nosso Mercado**) usa o banco `(default)` em `southamerica-east1`. O Identity Platform está inicializado, o provedor **Authentication → Email/Password** está habilitado e a blocking function `beforeCreateUser` está publicada em `us-central1`. O Firestore, as regras e a operação offline permanecem disponíveis mesmo se o cadastro em nuvem estiver indisponível.


### Cadastro restrito por e-mail

A criação de contas é validada no servidor pela Identity Platform blocking function `beforeCreateUser`. A lista privada fica em `privateConfig/registrationAllowlist`, contém apenas hashes SHA-256 dos e-mails autorizados e é negada explicitamente pelas regras públicas do Firestore. Se a configuração estiver ausente ou a Function estiver indisponível, o cadastro falha fechado: nenhuma conta nova é criada.

Para gerenciar os e-mails autorizados:

```powershell
Set-Location functions
npm run allowlist
```

Informe um e-mail por linha e pressione Enter em uma linha vazia para finalizar. Os endereços são usados apenas para calcular os hashes e não são gravados nem exibidos pelo script. Para adicionar ou remover alguém, execute o comando novamente com a nova lista completa. Enquanto o e-mail da Iasmim não estiver confirmado, mantenha a lista somente com o e-mail principal conhecido. Nunca publique os e-mails em arquivos do app, no `README` ou em commits.


Regras locais podem ser verificadas com:

```powershell
$env:JAVA_HOME='C:\Program Files\Android\Android Studio1\jbr'
$env:PATH="$env:JAVA_HOME\bin;$env:PATH"
firebase emulators:exec --only firestore,auth --project demo-nosso-mercado "node tools/emulator_rules_test.js"
```

## Etapa 4: instalação pessoal, backup e APK release

Este aplicativo não será publicado na Google Play. O Android passou a exigir registro de pacotes para instalações em dispositivos certificados no Brasil a partir de 30/09/2026. A rota escolhida é a conta gratuita **Limited distribution** do Android Developer Console, fora da Play Store, para registrar o pacote e autorizar o telefone. Ela exige uma conta Google com verificação em duas etapas e perfil de pagamentos com nome/endereço; não exige documento oficial de identidade conforme a documentação atual. O usuário precisa concluir esse cadastro diretamente com Google; não compartilhe credenciais com o assistente. Consulte [Android developer verification](https://developer.android.com/developer-verification) e [Limited distribution](https://developer.android.com/developer-verification/guides/limited-distribution).

O ID foi alterado de `com.example.mercado` para `br.com.nocorre.mercado`, com versão atual `1.0.4+12`. A release usa uma chave própria e pode atualizar a instalação release anterior do mesmo pacote, preservando os dados locais. Builds debug e release têm assinaturas diferentes e não podem substituir um ao outro como atualização; por isso, a primeira instalação da release deve ser feita sem desinstalar a versão anterior.

### Política de backup Android

O app desativa o Auto Backup do Android para Google Drive e as regras de transferência do dispositivo. O backup oficial para recuperação é a exportação JSON manual dentro do app. Esse arquivo contém catálogo e histórico pessoal: guarde-o em local privado, de preferência em mais de um local escolhido por você; não o envie nem o adicione ao projeto. Para trocar de telefone ou instalação, exporte na origem, instale a nova versão, restaure o JSON e confira categorias, listas e totais antes de considerar concluída a transferência. A política do sistema está configurada por `android:allowBackup="false"` e regras explícitas para cópia em nuvem/transferência; ainda assim, confira as opções do fabricante durante a migração do telefone.

### Preparar a assinatura própria (sem Google Play)

Android exige que o APK seja assinado. Gere uma chave própria com Android Studio/`keytool` no seu computador, fora da pasta do projeto (por exemplo `%USERPROFILE%\MercadoRelease.jks`). A senha e o arquivo da chave são privados; não os envie ao chat e não os adicione ao projeto. Guarde uma cópia segura da chave: futuras atualizações do mesmo pacote precisam da mesma chave.

Crie localmente `app\android\key.properties` (já ignorado pelo Git) com os caminhos e segredos locais:

```properties
storeFile=C:/Users/SEU_USUARIO/MercadoRelease.jks
storePassword=SENHA_LOCAL_DO_KEYSTORE
keyAlias=mercado
keyPassword=SENHA_LOCAL_DA_CHAVE
```

Substitua os exemplos na sua máquina; não copie senhas para código versionado. A configuração Gradle recusa tarefas release sem keystore/propriedades válidas e nunca usa a chave debug para release. Depois que a chave for criada, registre o pacote e a chave assinante no Android Developer Console conforme o fluxo limitado; então execute na junction ASCII:

```powershell
& $flutter build apk --release
```

O APK fica em `build\app\outputs\flutter-apk\app-release.apk`. APK release é a versão de uso pessoal assinada; APK debug serve para desenvolvimento e usa outra chave. Preserve o `applicationId` e a chave da release para atualizar sem desinstalar. A versão/build number em `pubspec.yaml` deve aumentar a cada atualização.

Ainda dependem do usuário: criar e guardar a chave, configurar `key.properties` localmente, completar o Android Developer Console/autorizar o telefone, instalar/restaurar o APK no aparelho e executar a conferência física. Não instale sobre a base atual sem exportar e verificar primeiro o backup JSON.
