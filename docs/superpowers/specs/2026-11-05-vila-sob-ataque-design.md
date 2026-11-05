# Design: Vila sob Ataque (Godot)

Data: 2026-11-05  
Engine: Godot 4.7.x  
Substitui o loop de arena única por vilarejo defensivo com loja entre ciclos.

## Objetivo

O jogador defende o poço da praça da vila contra hordas. A cada 4 ondas há um intervalo de loja com NPCs. Inimigos dropam moedas. Vitória ao completar a onda 12. Derrota se o herói ou o poço chegar a 0 de vida.

## Loop de jogo

1. Partida começa na onda 1 no mapa da vila, HUD visível.
2. Movimento WASD, ataque com setas (direção do golpe).
3. Inimigos spawnam nas bordas e caminham em direção ao poço.
4. Contato com inimigo causa dano ao herói. Inimigo que alcançar o poço causa dano ao poço.
5. Ao limpar a onda, se a onda for múltiplo de 4: entra intervalo de loja. Senão: próxima onda após breve pausa.
6. Na loja: compra upgrades/poções com ouro; botão “Próxima onda” retoma o combate.
7. Onda 12 limpa: vitória. Herói ou poço a 0 HP: derrota + Reiniciar.

## Controles

- WASD: mover
- Setas: atacar na direção
- 1: usar poção pequena
- 2: usar poção grande
- E: interagir/comprar perto do NPC (no intervalo)
- UI: botões da loja e Reiniciar

## Mapa

- Tamanho aproximado: 20×15 tiles (tile 16×16 escalado 2× no jogo, ou TileMap nativo 16px com câmera).
- Arte: Kenney Tiny Town (chão, casas, cercas, árvores, poço).
- Objetivo central: poço com HP inicial 20.
- Spawns: Marker2D nas quatro bordas (e cantos).
- Colisão: casas/cercas bloqueiam movimento; caminhos e grama andáveis.

## Inimigos

Sprites Tiny Dungeon (escala 2×). Pool libera tipos gradualmente.

| ID tile | Tipo | HP | Dano contato | Moedas | Liberado a partir da onda |
|---|---|---|---|---|---|
| 108 | slime | 2 | 1 | 1 | 1 |
| 123 / 124 | rato | 2 | 1 | 1 | 2 |
| 120 | morcego | 2 | 1 | 2 | 3 |
| 122 | aranha | 3 | 1 | 2 | 5 |
| 121 | fantasma | 3 | 1 | 3 | 6 |
| 112 | arqueiro | 3 | 1 | 3 | 7 |
| 111 | cultista | 4 | 1 | 4 | 8 |
| 110 | caranguejo | 5 | 1 | 4 | 9 |
| 109 | ogro | 6 | 2 | 5 | 10 |

### Progressão de hordas

- Ondas 1–2: quase só slime; onda 2 introduz pouco rato.
- Ondas 3–4: entra morcego; contagens sobem.
- Após cada loja: +1 tipo novo elegível na pool (respeitando a tabela), mais inimigos por onda, velocidade levemente maior.
- Contagem base sugerida: onda `n` spawna `4 + n` inimigos (ajustável no balanceamento).
- Drop: 100% das moedas da tabela ao morrer; após onda 8, 10% de chance de +1 moeda bônus.

## Jogador

- HP inicial 5, dano de espada 1, alcance conforme swing atual.
- I-frames 0,6 s após dano.
- Inventário: contagem de poção pequena e grande.
- Upgrades permanentes na run: max HP, dano de ataque, arma melhor (sprite + bônus).

## Loja (a cada 4 ondas)

Combate pausado. NPCs na praça. Comprar com ouro.

| Item | Efeito | Preço base |
|---|---|---|
| Poção pequena | +2 HP (não passa do máximo) | 5 |
| Poção grande | +5 HP | 12 |
| +1 vida máx | max HP +1 e cura 1 | 15 |
| +1 ataque | dano da espada +1 | 18 |
| Espada melhor | troca sprite da arma; +1 dano ou +alcance (escolher um e fixar: +1 dano) | 25 |

- Preços sobem ~20% a cada ciclo de loja (arredondado para cima).
- Espada melhor: compra única por run.
- Botão “Próxima onda” encerra o intervalo.

## Arquitetura

| Unidade | Responsabilidade |
|---|---|
| `Main` / mapa | TileMap da vila, spawns, poço, wiring |
| `Player` | Movimento, ataque, inventário, ouro, upgrades |
| `Enemy` (base + tipos) | Stats por tipo, chase só do poço, drop de moedas, sinal `died` |
| `Well` / objetivo | HP, sinal `destroyed` |
| `WaveManager` | Ondas 1–12, pool por onda, intervalo a cada 4, sinais de loja/vitória |
| `Shop` / NPCs | UI e compra no intervalo |
| `HUD` | Vida herói, vida poço, ouro, onda, poções, overlays |

### Sinais principais

- `Enemy.died(coins)` → Player ganha ouro; WaveManager decrementa vivos.
- `WaveManager.shop_started` → pausa spawns, mostra loja.
- `WaveManager.wave_started` / `all_waves_cleared` → HUD / vitória.
- `Well.destroyed` / `Player.died` → derrota.

## Arte

- Tiny Town: tiles do mapa e props.
- Tiny Dungeon: herói, inimigos 108–112 e 120–124, armas, poções, moeda se houver tile adequado (senão círculo/UI simples).
- Packs em `assets/third_party/kenney/` (`.gdignore`); cópias usadas em `assets/sprites/` ou TileSet do projeto.

## Critérios de sucesso

- Mapa de vila jogável com poço central e colisões.
- 12 ondas com intervalo de loja a cada 4.
- Pool de inimigos cresce conforme a tabela; primeiras ondas com pouca variação.
- Drops de moeda e compras funcionando.
- Poções 1/2, upgrades permanentes na run.
- Vitória na onda 12; derrota por herói ou poço.

## Fora de escopo

- Sons/música
- Save entre runs
- Skill tree / múltiplas vilas
- Projéteis de arqueiro (nesta versão o arqueiro é só contato, como os outros)
