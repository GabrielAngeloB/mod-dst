D'WX-78 IMPROVED CIRCUITS — DST 0.1.41
======================================

CORREÇÃO DE HOTFIX 0.1.41
- Corrigido o carregamento das definições de Ressonância em ambientes
  com verificação estrita: o arquivo agora obtém o ambiente global por _G,
  sem tentar ler GLOBAL antes de ele estar declarado.

REVISÃO DE COMPATIBILIDADE E CORREÇÕES
- O helper compartilhado diferencia módulos instalados de módulos realmente
  ativados, respeitando a carga/slots atualmente disponíveis.
- Beanbooster usa o tuning atual do DST:
  TUNING.SKILLS.WX78.BEE_SHIELD_REGEN_PER_SECOND.
  A regeneração foi ajustada para 0,5 por segundo e continua podendo ocorrer
  durante combate, mas não enquanto WX-78 estiver ferido.
- Redigestion usa a quantidade de módulos digestion realmente ativados;
  não depende mais de uma variável nunca preenchida.
- Range Booster valida no servidor skill, módulo, carga, MapExplorer e
  parâmetros do RPC; limita raio, passo e frequência das revelações.
- Thermal usa os métodos do componente temperature para aplicar calor/frio
  e mantém o controlador ativo quando a temperatura chega a 0 °C.
- Refrigerant cancela a produção de gelo quando qualquer requisito deixa de
  ser atendido e reavalia skill/módulo/carga mesmo sem evento de umidade.
- Processing reavalia condições periodicamente e só remove fastbuilder
  quando a tag foi adicionada por este próprio sistema.
- Hardy e Spatializer contam módulos ativos, não apenas módulos instalados.
- Blocking e Screech aplicam suas constantes globais no carregamento do
  respectivo sistema, não durante eventos de jogadores.
- Blocking e Chorusbox preservam tags que já existiam antes dos seus efeitos.
- Illumination captura os valores reais da luz antes de aplicar o efeito e
  restaura cor, raio, intensidade, falloff e estado anteriores.
- A extração de Bio Data valida receita, jogador e itens gerados; não remove
  o módulo quando nenhuma Bio Data pode ser recuperada.
- As chamadas protegidas da Ressonância evitam tentar chamar pcall/tostring
  diretamente como globais ausentes do sandbox.
- O manifesto binário antigo foi removido do pacote-fonte.
- Incluído GitHub Actions para verificar sintaxe Lua 5.1 em todos os
  arquivos .lua do repositório.

RESSONÂNCIAS E BALANCEAMENTO
- Os seis pares e seus valores de balanceamento foram preservados.
- Nenhuma ressonância foi adicionada ou removida.
- Fuel Oil permanece desativado porque seus três arquivos de implementação
  não existem no pacote-fonte.

INSTALAÇÃO LOCAL
1. Desative a versão antiga da Workshop (ID 3722018231).
2. Extraia a pasta dwx78_improved_circuits para:
   Documents/Klei/DoNotStarveTogether/mods/
   (ou a pasta Klei equivalente que seu jogo usa).
3. Ative o mod em Server Mods no Master e também nas Caves.
4. Como all_clients_require_mod = true, todos os jogadores precisam ter
   exatamente a mesma versão local instalada.
5. Teste primeiro em uma cópia do cluster, não no mundo principal.

VALIDAÇÃO
- Revisão estática dos sistemas, módulos, definições de ressonância,
  painel HUD, helpers e arquivos de localização.
- O workflow do GitHub Actions valida sintaxe Lua 5.1 em todos os arquivos.
- Validação estática não substitui um teste em sessão real do DST. Ainda é
  necessário testar Master + Caves, HUD, cada circuito e multiplayer antes
  de considerar esta versão totalmente aprovada.
