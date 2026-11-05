# Vila sob Ataque

Jogo 2D top-down em Godot 4.7: defenda o poço da vila por 12 ondas.

## Rodar

```bash
godot --path .
```

Ou abra a pasta no Godot Editor e rode a cena Main.

## Controles

- WASD: mover
- Setas: atacar na direção
- 1 / 2: poção pequena / grande
- E: interagir (loja)
- UI: comprar, Próxima onda e Reiniciar

## Loop

Defenda o poço. Inimigos dropam ouro. A cada 4 ondas há loja com upgrades.
Vitória na onda 12. Derrota se herói ou poço chegar a 0 de vida.

## Sprites

```bash
./tools/apply_game_sprites.sh
```

Packs Kenney (CC0) em `assets/third_party/`. Veja `assets/third_party/ATTRIBUTION.md`.
