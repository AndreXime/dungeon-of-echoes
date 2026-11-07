# Dungeon Of Echoes

Roguelike de ação em primeira pessoa. Você entra numa masmorra que muda a cada run, luta, coleta ouro e relíquias, sobe andares por biomas, e volta ao acampamento para melhorar o personagem.

Projeto em **Godot 4.7** (Forward+).

## Requisitos

- [Godot 4.7+](https://godotengine.org/) no `PATH` (testado com `4.7.2`)

## Como rodar

```bash
just run
# ou: godot --path .
```

Cena principal: `scenes/hub.tscn`. Editor: `just editor`.

### Abrir só a masmorra (debug)

```bash
godot --path . --scene res://scenes/dungeon_run.tscn
```

## Builds (`just`)

Requer Godot 4.7+ no `PATH` e export templates instalados.

```bash
just build-linux              # x86_64 + arm64 em build/linux/
just build-linux-x86_64
just build-linux-arm64
just build-windows            # x86_64 + arm64 em build/windows/
just build-windows-x86_64
just build-windows-arm64
just build-web                # single + multi em build/web/
just build-web-single         # sem threads (host HTTP simples)
just build-web-multi          # com threads (precisa COOP/COEP)
just build-all
just serve-web-single         # http://127.0.0.1:8080/
just serve-web-multi          # idem, com headers p/ SharedArrayBuffer
```

## Controles

| Tecla / botão | Ação |
|---------------|------|
| WASD | Andar |
| Mouse | Olhar |
| Espaço | Pular |
| Esc | Pausar / menu (abas Ficha e Controles) |
| F4 | Alternar tela cheia (preferência salva) |
| E | Interagir (abre loja do NPC, portal, relíquias) |
| 1 / 2 / 3 | Espada+escudo / Adaga / Besteira |
| LMB | Ataque (avançando = estocada) / adaga / besta |
| RMB | Escudo (espada) ou puxar adaga |
| Q | Usar poção |
| T | Alternar tocha ↔ escudo (só um por vez) |

## Loop de jogo

1. **Hub** — ferreiro, alquimista, cartógrafo e portal
2. **Masmorra** — andares 1–9 em três biomas (layout em grafo, não só corredor)
3. Salas com ramos, inimigos com aggro/visão, relíquias únicas por run
4. Andares 3 / 6 / 9 têm **chefe** (saída só após derrotar)
5. Vitória no andar 9 ou morte → volta ao hub com ouro e minério

Progresso permanente: `user://meta_save.cfg`.

## Biomas

| Andares | Bioma | Inimigos |
|---------|-------|----------|
| 1–3 | Catacumbas Esquecidas | Esqueleto guerreiro, ladino, minion (+ chefe mago) |
| 4–6 | Minas de Fogo-Fátuo | Bárbaro, minion bruto, minion à distância (+ chefe minion bruto) |
| 7–9 | Jardim Sem Sol | Ranger, ladino encapuzado, ranger arqueiro (+ chefe ladino encapuzado) |

## Hub (meta)

- **Ferreiro:** reforça espada (ouro), desbloqueia adaga/besta (minério), escolhe arma inicial. Cada E cicla a oferta.
- **Alquimista:** +HP, +capacidade de poções, sorte de relíquia. Cada E cicla a oferta.
- **Cartógrafo:** sobe nível do mapa (revela mais salas no HUD).
- **Portal:** inicia run.

## Combate e exploração

- Escudo bloqueia melee frontal e **projéteis**
- Empurrar no escudo joga inimigos (útil em espinhos)
- Cordas, espinhos, vinhas cortáveis (Jardim)
- Tocha na câmera como luz principal
- Mapa textual no HUD (salas reveladas pelo cartógrafo)

## Relíquias

| Relíquia | Efeito |
|----------|--------|
| Olho de Vidro | Projétil marca. Próximo melee causa dobro |
| Vampirismo Cristalino | Quebrar cenário cura |
| Essência Vulcânica | Impacto de lâmina explode em área |
| Núcleo Gravitacional | Ao puxar a adaga, inimigos são atraídos |

## Estrutura

```
scenes/
  hub.tscn / dungeon_run.tscn / player.tscn
  enemies/               # variantes por bioma
  props/                 # barris, caixas, vasos quebráveis
  ui/                    # pause_menu, npc_shop
scripts/
  autoload/              # MetaProgress, RunState, Sfx, Juice, Music, MouseCapture
  player/                # player e projéteis
  enemies/               # EnemyBase e variantes
  world/                 # hub, dungeon_run, dungeon_generator, dungeon_layout
  interactables/         # baús, traps, portas, relíquias
  ui/                    # pause, loja, HUD
  assets/                # KayKit paths (class_name KayKit) e animações
  util/                  # fontes e helpers
  dev/                   # serve_web e utilitários de build
assets/
  models/                # packs KayKit (gltf/glb) + skyboxes
  fonts/                 # Lilita One (OFL)
  audio/                 # BGM e SFX
  ui/                    # theme pergaminho (Kenney RPG UI, CC0)
```

### Packs KayKit em `assets/models/`

| Pasta | Uso |
|-------|-----|
| `dungeon/` | tiles, props e luzes da masmorra |
| `adventurers/` | herói e NPCs do hub |
| `skeletons/` | inimigos das catacumbas |
| `weapons/` | armas extras / variações |
| `tools/` | tocha, bigorna, mapa, corda |
| `forest/` | vegetação e rochas do hub |
| `mixed/` | traps e props (beartrap, mirror…) |
| `animations/` | rigs de animação KayKit |
| `skyboxes/` | céu do hub |
| `blocks/` | reserva (Block Bits, ainda sem uso in-game) |
| `halloween/` | reserva (Halloween Bits, ainda sem uso in-game) |

Tipografia: **Lilita One** (SIL OFL). UI em pergaminho via `assets/ui/game_theme.tres`. Lojas de NPC abrem lista de ofertas (paginada). Ouro do hub só aparece na loja.

Áudio em `assets/audio/` (hub, dungeon e SFX). Gerado com o `music-studio` em Downloads (`just run dungeon_echoes_*.py` / `sfx_dungeon_echoes.py`).
