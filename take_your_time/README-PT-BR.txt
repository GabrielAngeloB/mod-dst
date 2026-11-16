TAKE YOUR TIME — atualização de compatibilidade DST 2.0.4

INSTALAÇÃO
1. Feche o Don't Starve Together.
2. Extraia o ZIP diretamente na pasta de mods locais do usuário (ele já cria a pasta take_your_time):
   %USERPROFILE%\Documents\Klei\DoNotStarveTogether\mods\take_your_time\
   (Crie a pasta "mods" caso ainda não exista.)
3. No jogo, ative o mod na aba Mods do servidor.
4. Reinicie o mundo depois de alterar as opções.
5. Como o mod altera regras de jogo no servidor e exige todos os clientes, todos os jogadores devem ter a mesma versão instalada/ativada.

CONFIGURAÇÃO
- Master Speed Control = Disabled: cada categoria usa seu próprio valor.
- Master Speed Control entre 3 e 99: substitui todas as categorias pelo mesmo valor.
- Importante: se você já tinha o mod instalado, o jogo pode manter salvo o antigo xspeed=21. Nesse caso, coloque Master Speed Control em Disabled para voltar a controlar cada categoria separadamente.
- Day Length é a duração do ciclo completo (dia + crepúsculo + noite), não apenas da parte clara.
- Os valores individuais começam em 21 para preservar o ritmo padrão da versão antiga; altere-os conforme desejar.
- Autosave mantém a opção antiga de 8 minutos como padrão.

CATEGORIAS
Day: relógio do mundo e duração do ciclo.
Hunger: consumo de fome.
Fire: combustíveis, fontes de luz e capacidade de combustível do Ice Flingomatic.
Growth: crescimento/regeneração, plantio, secagem e cozimento.
Insulation: duração de proteção térmica.
Spoilage: deterioração de alimentos e itens orgânicos, incluindo os tempos PERISH usados por comidas preparadas.
Equipment: deterioração de roupas e equipamentos, durabilidade de amuletos e reparos.
Creatures: regeneração, respawn, lealdade, ninhos, eventos de criaturas e timers de chefes.
Sanity: taxas de ganho e perda de sanidade.

OBSERVAÇÕES TÉCNICAS
- O pacote está organizado como uma pasta de mod normal do DST (modinfo.lua e modmain.lua na raiz).
- Os arquivos antigos de comandos de console foram removidos: o helper antigo chamava SetNormEraTime, API que não existe no componente clock atual do DST.
- Os timers novos foram adicionados por chave e caminho específico; tabelas que misturam temporizadores e atributos não temporais não são multiplicadas por inteiro.
- Mudanças nas opções exigem reiniciar o mundo para garantir que os componentes e temporizadores sejam criados com os novos valores.
- A validação executada inclui compilação dos arquivos Lua e testes automatizados com TUNING/configurações simulados; isso não substitui um teste dentro do DST.
- Mod testado por análise estática e verificação de consistência de configuração. Não foi possível iniciar uma sessão real do DST neste ambiente; teste primeiro em um mundo de cópia/backup.

CORREÇÃO 2.0.2
- Removidas todas as chamadas a tostring/table do modinfo.lua.
- Os rótulos numéricos das opções usam uma tabela local literal, compatível com o ambiente restrito de carregamento de metadados do DST.


CORREÇÃO 2.0.4
- Corrigido o carregamento no ambiente restrito do DST: as funções Lua padrão usadas pelo modmain.lua agora são obtidas através de GLOBAL.
- Adicionado teste de regressão que executa o modmain.lua em um sandbox sem acesso direto às funções globais padrão.
