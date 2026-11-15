D'WX-78 IMPROVED CIRCUITS — DST 0.1.39
======================================

CORREÇÃO DESTA VERSÃO
- Corrigido o crash de inicialização em resonance_circuit.lua:
  pcall e tostring eram chamados como globais do ambiente do mod, mas
  pcall não é exposto nesse ambiente do DST. Agora as chamadas protegidas
  usam GLOBAL.pcall e GLOBAL.tostring.
- O mesmo acesso explícito a GLOBAL foi aplicado às rotinas compartilhadas
  de definições e ao painel HUD da Ressonância.
- Mantido o conjunto de bônus de ressonância e os valores de balanceamento
  da versão anterior.
- Fuel Oil continua desativado/removido: os arquivos desse recurso não
  estavam presentes no pacote original completo.

INSTALAÇÃO LOCAL
1. Feche o DST.
2. Desative o mod da Workshop "D'WX-78 Improved Circuits" (ID 3722018231)
   nos Server Mods do mundo/cluster.
3. Extraia a pasta dwx78_improved_circuits para:
   Documents/Klei/DoNotStarveTogether/mods/
   (ou a pasta Klei equivalente que seu jogo usa).
4. Ative "D'WX-78 Improved Circuits" na lista de Server Mods.
5. Como o mod exige os arquivos também nos clientes, todos os jogadores
   devem instalar a mesma versão local 0.1.39.
6. Faça a ativação no Master e confirme que também está ativa nas Caves.

COMO CONFIRMAR QUE A CÓPIA NOVA ESTÁ EM USO
No master_server_log.txt, a linha de ativação/carregamento deve identificar
o mod local como "dwx78_improved_circuits" e mostrar Version:0.1.39.
Se continuar aparecendo "workshop-3722018231" ou Version:0.1.38,
a cópia antiga da Workshop ainda está habilitada.

TESTES / LIMITAÇÕES
- Integridade do ZIP e referências a arquivos verificadas.
- As chamadas pcall/tostring da Ressonância foram verificadas para usar
  GLOBAL explicitamente.
- Não foi possível iniciar um servidor DST real neste ambiente; valide
  primeiro em um mundo de teste/cópia do cluster.
