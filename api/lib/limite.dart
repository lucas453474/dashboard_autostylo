// Limite de requisições por IP, feito com Map simples.
// Para cada IP guardamos: quantas requisições fez e quando começou a contagem.

const int maximoLoginPorMinuto = 5;
const int maximoGeralPorMinuto = 60;
const int umMinuto = 60000; // em milissegundos

Map<String, int> contagemLogin = {};
Map<String, int> inicioLogin = {};
Map<String, int> contagemGeral = {};
Map<String, int> inicioGeral = {};

// Soma mais uma requisição do IP e diz se ele passou do máximo
bool passouDoLimite(
  Map<String, int> contagem,
  Map<String, int> inicio,
  String ip,
  int maximo,
) {
  int agora = DateTime.now().millisecondsSinceEpoch;
  int? comeco = inicio[ip];

  // Primeira requisição do IP, ou já passou 1 minuto: começa a contar de novo
  if (comeco == null || agora - comeco >= umMinuto) {
    inicio[ip] = agora;
    contagem[ip] = 1;
    return false;
  }

  // Ainda dentro do mesmo minuto: soma 1
  int? atual = contagem[ip];
  int total = 1;
  if (atual != null) {
    total = atual + 1;
  }
  contagem[ip] = total;
  return total > maximo;
}

// No máximo 5 tentativas de login por minuto
bool limiteLoginEstourado(String ip) {
  return passouDoLimite(contagemLogin, inicioLogin, ip, maximoLoginPorMinuto);
}

// No máximo 60 requisições por minuto (qualquer rota)
bool limiteGeralEstourado(String ip) {
  return passouDoLimite(contagemGeral, inicioGeral, ip, maximoGeralPorMinuto);
}
