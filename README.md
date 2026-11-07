# Dungeon Of Echoes

Roguelike de ação em primeira pessoa. Você entra numa masmorra que muda a cada run, luta, coleta ouro e relíquias, sobe andares por biomas, e volta ao acampamento para melhorar o personagem.

Projeto em **Godot 4.7** (Forward+).

## Requisitos

- [Godot 4.7+](https://godotengine.org/) no `PATH` (testado com `4.7.2`)

## Como rodar

```bash
godot --path /home/andre/Projetos/newgame
```

Cena principal: `scenes/hub.tscn`.

### Abrir só a masmorra (debug)

```bash
godot --path /home/andre/Projetos/newgame --scene res://scenes/dungeon_run.tscn
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
scenes/                  # hub, dungeon, player, enemies…
scripts/autoload/        # MetaProgress, RunState, Sfx, Juice, Music
scripts/player/          # player e projéteis
scripts/enemies/         # EnemyBase e variantes
scripts/world/           # hub, dungeon, floresta, gerador
scripts/interactables/   # baús, traps, relíquias
scripts/ui/              # pause menu
scripts/kaykit/          # paths e animações KayKit
scripts/util/            # helpers
assets/models/           # packs KayKit (gltf/glb)
assets/fonts/            # Lilita One (OFL) — UI e Label3D
assets/audio/            # BGM e SFX
```

Assets visuais vêm do KayKit (Dungeon, Adventurers, Skeletons, Forest, Weapons, Tools, Mixed Bag, Block Bits, Halloween).

Tipografia: **Lilita One** (SIL OFL). UI em pergaminho (Kenney RPG UI, CC0) via `assets/ui/game_theme.tres`. Lojas de NPC abrem lista de ofertas (paginada).

Áudio em `assets/audio/` (hub, dungeon e SFX). Gerado com o `music-studio` em Downloads (`just run dungeon_echoes_*.py` / `sfx_dungeon_echoes.py`).
