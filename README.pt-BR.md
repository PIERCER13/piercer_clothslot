# piercer_clothslot

[English](README.md)

Descobre em tempo real o slot global do GTA V, a coleção `addon`, o número local e a pasta exata no disco de cada
roupa vestida no personagem, além de buscar peças pelo nome da pasta e provar no corpo na hora. Tem **NUI in-game**
(`/clothslot` ou `/roupaslot`), **painel fixo na tela** (`/roupaslot painel`) e subcomandos rápidos no chat/F8.

## Instalação

```cfg
ensure vrp
ensure framezero_bridge
ensure piercer_clothslot
```

Permissão in-game: grupos em `Config.permissoesBridge` (via `framezero_bridge`), `Config.permissao` no vRP ou ACE
(`add_ace group.admin piercer.admin allow`). Funciona com peds freemode (`mp_m_freemode_01` e `mp_f_freemode_01`).

## Idioma

- O seletor `PT / EN` no topo da NUI troca o idioma na hora e salva a escolha naquele navegador.
- Os textos da NUI ficam em `I18N` no `web/app.js`; as mensagens do chat, F8 e painel na tela ficam em `Config.textos` (`config.lua`).

## O que faz

| Recurso | Como usar | Observação |
|---|---|---|
| **Equipadas no corpo** | Aba **No Corpo**, `/roupaslot atual` ou `/roupaslot painel` | Lê os componentes `0` a `11` (`jbib`, `lowr`, `feet`, `berd`, `accs`...), resolve a coleção + índice local de cada slot global e cruza com `data/index.lua` para mostrar a pasta. |
| **Busca por pasta** | Aba **Buscar Roupas** ou `/roupaslot buscar <texto>` | Procura no índice pelo nome da pasta (até 60 resultados), calcula o slot global atual no cliente e permite **Vestir** na hora ou copiar o slot. |
| **Coleções carregadas** | Aba **Coleções** ou `/roupaslot colecoes` | Lista todos os packs `addon` ativos no ped, quantidade de peças e faixa de slots globais que cada um ocupa. |
| **Conversão direta / reversa** | `/roupaslot <coleção> <peça> <nº>` e `/roupaslot slot <peça> <slot>` | Converte entre `coleção + número local` (ex.: `addon5 jbib 51`) e `slot global` (ex.: `slot jbib 500`) direto pelo chat. |
| **Vestir e navegar** | `/roupaslot vestir <coleção> <peça> <nº> [tex]`, `PageDown` / `PageUp` | Depois de vestir qualquer peça (pela NUI ou comando), `PageDown` e `PageUp` avançam ou voltam naquela mesma coleção. Teclas ajustáveis nas configurações do FiveM. |
| **Dump completo** | Botão **Gerar Dump** na NUI | Envia todas as roupas do ped atual em partes (`TriggerLatentServerEvent`), salva `data/dump_<modelo>.txt` e avisa o que mudou desde o último dump. |

## Índice de pastas (`tools/`)

O FiveM só conhece `coleção + componente + número`, nunca o nome da pasta original no Windows. Quem faz essa ponte é
o `data/index.lua`, gerado fora do jogo pelos scripts em PowerShell:

- **Atualizar o índice**: sempre que adicionar, remover ou renomear pastas na `stream`, rode:
  ```powershell
  powershell -ExecutionPolicy Bypass -File tools/gerar_indice.ps1
  ```
  Por padrão ele lê `[framezero-cloth]/style-cloth-addon/stream` (aceita `-Stream "<caminho>"` e `-Saida "<arquivo>"`). Reinicie o `piercer_clothslot` depois de gerar.
- **Numeração com buracos**: se uma coleção pular números (ex.: tem `000` e `002`, sem `001`), o slot carregado no jogo pode deslocar em relação ao nome do `.ydd`. O gerador marca o grupo em `duvidosos` e o painel avisa com `(!)` para conferir a pasta.
- **Auditoria da stream**: `tools/analisar_pastas.ps1` (aceita `-Cloth "<caminho>"`) gera a planilha `data/relatorio_roupas.csv` e lista no terminal números faltando na sequência, roupas sem textura (`.ytd`) e pastas `addon` sem `.meta`.

## Ajustes

- `config.lua`: comandos (`/clothslot`, `/roupaslot`), permissões, taxa de envio do dump (`velocidadeEnvio`), teclas padrão (`PAGEDOWN`/`PAGEUP`), posição e intervalo do HUD (`painel`), modelos aceitos, mapa de componentes `0–11` e textos de aviso.
