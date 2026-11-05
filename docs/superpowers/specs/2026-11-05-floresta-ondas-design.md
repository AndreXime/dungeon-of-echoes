# Design: Arena de Floresta com Ondas (Godot)

Data: 2026-11-05  
Engine: Godot 4.7.x  
Escopo: jogo 2D top-down simples, tema floresta/aventura

## Objetivo

O jogador limpa uma arena derrotando todos os inimigos em 3 ondas. Mira com o mouse e atira projéteis. Contato com slime causa dano. Vitória ao zerar a onda 3. Derrota ao zerar a vida.

## Loop de jogo

1. Partida começa na onda 1 com HUD visível.
2. Jogador move (WASD), mira (mouse), atira (clique esquerdo ou Espaço).
3. Slimes perseguem o jogador e causam 1 de dano no contato (com i-frames curtos).
4. Ao morrer todos os inimigos da onda, WaveManager aguarda um breve intervalo e spawna a próxima.
5. Após limpar a onda 3: tela de vitória com botão Reiniciar.
6. Se a vida do jogador chegar a 0: tela de derrota com botão Reiniciar.

## Arquitetura

### Cenas e scripts

| Unidade | Tipo | Responsabilidade |
|---|---|---|
| `Main` | Node2D / cena raiz | Arena (tiles, paredes), instancia WaveManager e HUD, escuta vitória/derrota |
| `Player` | CharacterBody2D | Movimento, mira, disparo, vida, i-frames |
| `Enemy` | CharacterBody2D | Perseguição ao jogador, HP, sinal `died` |
| `Bullet` | Area2D | Movimento em linha, dano 1, some ao colidir com inimigo ou parede |
| `WaveManager` | Node | Conta inimigos vivos, spawna ondas 1→2→3, emite `all_waves_cleared` |
| `HUD` | CanvasLayer | Vida, onda atual, inimigos restantes, overlays vitória/derrota |

### Fluxo de sinais

- `Enemy.died` → WaveManager decrementa contagem; se zero e há próxima onda, agenda spawn; se era a última, emite `all_waves_cleared`.
- `Player.died` → Main mostra derrota e pausa gameplay.
- `WaveManager.all_waves_cleared` → Main mostra vitória e pausa gameplay.
- Botão Reiniciar → recarrega a cena `Main`.

### Dependências entre unidades

- `Player` não conhece WaveManager.
- `Enemy` só precisa de referência ao Player (grupo ou export).
- `Bullet` detecta corpos no grupo `enemies` e paredes estáticas.
- `WaveManager` instancia `Enemy` em pontos de spawn definidos na Main.
- `HUD` observa Player e WaveManager via sinais ou referências exportadas na Main.

## Arte

Geração offline de PNG a partir de SVG (ImageMagick `convert`), estilo pixel art simples:

| Asset | Tamanho | Uso |
|---|---|---|
| `player.png` | 32×32 | Sprite do herói (vista top-down) |
| `enemy_slime.png` | 32×32 | Slime verde |
| `bullet.png` | 16×16 | Projétil (cristal/energia) |
| `tile_grass.png` | 32×32 | Chão da arena |
| `tile_wall.png` | 32×32 | Paredes / limites |

Script Python ou shell em `tools/generate_sprites.sh` (ou `.py`) regenera os PNGs em `assets/sprites/`.

## Balanceamento inicial

| Entidade | Valores |
|---|---|
| Jogador | 5 HP, velocidade média, cooldown de tiro ~0,25 s, i-frames ~0,6 s após dano |
| Projétil | 1 dano, velocidade alta, some na parede ou no inimigo |
| Slime | 2 HP, mais lento que o jogador, 1 dano no contato |
| Ondas | Onda 1: 4 inimigos; Onda 2: 6; Onda 3: 8 |
| Spawn | Pontos nas bordas internas da arena, longe do centro onde o jogador nasce |

## Controles

- WASD / setas: movimento
- Mouse: direção de mira
- Clique esquerdo ou Espaço: atirar
- UI: botão Reiniciar nas telas finais

## Fora de escopo

- Mapa com múltiplas salas
- Itens, upgrades, inventário
- Sons/música (podem ser adicionados depois)
- Multiplayer, save, menu elaborado além de vitória/derrota
- IA avançada (apenas perseguição direta)

## Critérios de sucesso

- Abrir o projeto no Godot 4.7 e rodar a cena Main sem erros.
- Completar as 3 ondas e ver a tela de vitória.
- Morrer por contato e ver a tela de derrota com Reiniciar funcional.
- Sprites visíveis e distintos (jogador, slime, projétil, chão, parede).
