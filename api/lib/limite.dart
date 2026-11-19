// limite de requisicoes por ip
Map<String, int> contagemLogin = {};
Map<String, int> inicioLogin = {};
Map<String, int> contagemGeral = {};
Map<String, int> inicioGeral = {};

bool passouDoLimite(Map<String, int> contagem, Map<String, int> inicio, String ip, int maximo) {
  int agora = DateTime.now().millisecondsSinceEpoch;
  int? comeco = inicio[ip];

  if (comeco == null || agora - comeco >= 60000) {
    inicio[ip] = agora;
    contagem[ip] = 0;
  }

  int total = contagem[ip]! + 1;
  contagem[ip] = total;
  return total > maximo;
}
