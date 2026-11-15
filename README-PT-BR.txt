D'WX-78 IMPROVED CIRCUITS — DST 0.1.40
======================================

REVISÃO DE COMPATIBILIDADE
- Corrigida a chave do TUNING usada pela regeneração de escudo do Beanbooster.
- Preservados os nutrientes do Moistened Nutribrick definidos pelo mod original.
- Redigestion agora calcula módulos de digestão realmente ativados, em vez de
  depender de uma variável nunca preenchida.
- Range Booster valida no servidor o WX-78, o circuito, a habilidade, a carga,
  o raio e a frequência das solicitações de revelação do mapa. A compensação
  original de alcance nas Cavernas foi preservada.
- As chamadas frágeis a GLOBAL.pcall/GLOBAL.tostring foram removidas da
  implementação da Ressonância.
- O controlador Thermal mantém a tarefa ativa quando a temperatura chega a
  zero e utiliza a API do componente; os efeitos continuam exigindo carga.
- Refrigerant revalida habilidade, módulos, carga e umidade enquanto produz gelo.
- Processing reavalia periodicamente as condições para não deixar a tag
  fastbuilder presa quando a carga ou os circuitos mudam.
- Hardy e Spatializer usam contagens de módulos efetivamente ativados.
- Chorusbox remove apenas as tags que ele próprio adicionou.
- Illumination tenta preservar os parâmetros de luz originais antes de aplicar
  o visual do circuito.
- Blocking e Screech reduzem seus cooldowns por jogador, sem alterar os valores
  globais de TUNING e afetar outros WX-78.
- Quickplugging restaura a velocidade de animação mesmo que a habilidade mude
  durante a animação e preserva callbacks de reparo existentes.
- O extrator não consome um módulo quando a receita não rende Scandata; também
  valida os itens gerados antes de remover o módulo.
- Hooks do mapa e do drone passam a verificar métodos antes de substituí-los.
- Os overrides do Scrapbook e da árvore de habilidades toleram entradas ausentes.

INSTALAÇÃO LOCAL
1. Feche o DST.
2. Desative o mod antigo da Workshop "D'WX-78 Improved Circuits" (ID 3722018231)
   nos Server Mods do mundo/cluster.
3. Extraia a pasta dwx78_improved_circuits para:
   Documents/Klei/DoNotStarveTogether/mods/
   (ou a pasta Klei equivalente que seu jogo usa).
4. Ative a cópia local na lista Server Mods.
5. Como o mod exige os arquivos também nos clientes, todos os jogadores devem
   instalar a mesma versão local.
6. Confirme que o mod está ativo no Master e nas Caves.

CONFIGURAÇÃO
- Circuit Resonance controla o sistema de pares.
- Resonance HUD controla apenas o painel visual.
- As opções individuais dos circuitos continuam controlando seus respectivos
  efeitos. Uma ressonância só fica disponível se as duas opções de circuito
  correspondentes estiverem habilitadas.

VALIDAÇÃO
- Os quatro arquivos de localização contêm as seis entradas de ressonância.
- Os imports locais do modmain apontam para arquivos existentes no pacote.
- As chamadas pcall/tostring da Ressonância não são mais usadas.
- A validação estática não substitui um teste em servidor DST real. Antes de
  usar no mundo principal, teste uma cópia do cluster com Master e Caves.
- Fuel Oil permanece fora do pacote: os arquivos necessários para esse recurso
  não estavam presentes no arquivo original completo.
