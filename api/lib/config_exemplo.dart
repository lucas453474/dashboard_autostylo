// MODELO do arquivo de configuração.
// Copie este arquivo para "config.dart" (na mesma pasta) e coloque a senha real.
// O config.dart NÃO vai para o Git (está no .gitignore), porque tem a senha do banco.

// Dados de conexão com o MySQL (como o define(...) do PHP)
const String bancoHost = '127.0.0.1';
const int bancoPorta = 3306;
const String bancoUsuario = 'root';
const String bancoSenha = 'COLOQUE_A_SENHA_AQUI';
const String bancoNome = 'auto_stylo_bi';

// Porta em que a API vai rodar
const int apiPorta = 8080;
