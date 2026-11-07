# Dungeon Of Echoes

Roguelike de ação em primeira pessoa. Você entra numa masmorra que muda a cada run, luta, coleta ouro e relíquias, sobe andares por biomas, e volta ao acampamento para melhorar o personagem.

Projeto em **Godot 4.7** (Forward+).

## Requisitos

- [Godot 4.7+](https://godotengine.org/) no `PATH` (testado com `4.7.2`)
- Opcional: Blender (para editar/gerar modelos `.glb`)

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
| E | Interagir (NPCs, portal, relíquias) |
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
| 1–3 | Catacumbas Esquecidas | Esqueleto, morcego, slime (+ chefe esqueleto) |
| 4–6 | Minas de Fogo-Fátuo | Minerador, autômato, aranha (+ chefe autômato) |
| 7–9 | Jardim Sem Sol | Guardião, golem, atirador (+ chefe golem) |

## Hub (meta)

- **Ferreiro:** reforça espada (ouro), desbloqueia adaga/besta (minério), escolhe arma inicial. Cada E cicla a oferta.
- **Alquimista:** +HP, +capacidade de poções, sorte de relíquia. Cada E cicla a oferta.
- **Cartógrafo:** sobe nível do mapa (revela mais salas no HUD).
- **Portal:** inicia run.

## Combate e exploração

- Escudo bloqueia melee frontal e **projéteis**
- Empurrar no escudo joga inimigos (útil em espinhos)
- Poços, cordas, espinhos, vinhas cortáveis (Jardim)
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
scenes/hub.tscn
scenes/dungeon_run.tscn
scenes/player.tscn
scenes/enemies/          # inimigos EnemyBase (KayKit)
scripts/autoload/        # MetaProgress, RunState, Sfx, Juice
scripts/kaykit_paths.gd  # paths centralizados KayKit
assets/kaykit/           # packs KayKit extraídos (gltf/glb)
assets/*.zip             # zips originais KayKit (fonte)
```

Assets visuais vêm do KayKit (Dungeon, Adventurers, Skeletons, Forest, Weapons, Tools, Mixed Bag, Block Bits).
