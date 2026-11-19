# Dashboard Auto Stylo

Dashboard em Flutter Web com os indicadores da Auto Stylo (funilaria e pintura), lendo do MySQL por uma API em Dart. Tem login, as páginas Operação e Financeiro, filtros e cadastro de novo atendimento.

## Banco

Rodar os scripts da pasta `banco/` no MySQL, nesta ordem: `001_criar_banco.sql`, o script de importação do BI e `002_usuario.sql`.

## API

```
cd api
copy config_exemplo.txt config.txt
dart pub get
dart run bin/servidor.dart
```

No `config.txt`, colocar a senha do MySQL. A API roda em http://127.0.0.1:8080.

## App

```
cd app
flutter pub get
flutter run -d chrome
```

## Usuário de teste

- usuário: `admin`
- senha: `autostylo123`
