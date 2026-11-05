# Vila sob Ataque — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transformar a arena de 3 ondas em vilarejo defensivo com poço (HP 20), 12 ondas, loja a cada 4 ondas, drops de ouro e upgrades.

**Architecture:** Dados puros em `EnemyCatalog`, `ShopCatalog` e `WaveConfig` (testáveis headless). `Enemy` recebe tipo no spawn e persegue só o poço. `Well` é o objetivo. `WaveManager` emite `shop_started` / `wave_started` / `all_waves_cleared`. `Shop`/`HUD` cuidam de UI e compras. Mapa da vila montado em `main.gd` com tiles Tiny Town (32×32).

**Tech Stack:** Godot 4.7.x, GDScript, ImageMagick `convert`, Kenney Tiny Town + Tiny Dungeon (CC0)

## Global Constraints

- Engine: Godot 4.7.x (`config_version=5`, features `4.7`)
- Idioma da UI, README e commits: português brasileiro
- Viewport: 640×480 (mapa ~20×15 tiles a 32 px)
- Controles: WASD mover, setas atacar, 1/2 poções, E comprar perto do NPC
- Vitória: limpar onda 12. Derrota: herói ou poço a 0 HP
- Poço: HP inicial 20. Herói: HP inicial 5, i-frames 0,6 s, dano espada base 1
- Loja a cada 4 ondas. Espada melhor: +1 dano, compra única. Preços sobem ~20% por ciclo (ceil)
- Arqueiro e demais inimigos: só dano de contato (sem projéteis)
- Sem sons, save entre runs, skill tree
- Arte de third_party com `.gdignore`. Sprites de jogo em `assets/sprites/`
- Commits Conventional Commits em PT-BR

## File Structure

| Path | Responsabilidade |
|---|---|
| `tools/apply_game_sprites.sh` | Copia/escala Tiny Town + Tiny Dungeon → `assets/sprites/` |
| `scripts/enemy_catalog.gd` | Stats e unlock por tipo de inimigo |
| `scripts/shop_catalog.gd` | Itens, preços base, preço por ciclo |
| `scripts/wave_config.gd` | 12 ondas, tamanho, intervalo, helpers de shop |
| `scripts/enemy.gd` + `scenes/enemy.tscn` | Chase do poço, tipo, drop, dano contato |
| `scripts/well.gd` + `scenes/well.tscn` | Objetivo com HP e `destroyed` |
| `scripts/player.gd` + `scenes/player.tscn` | Ouro, poções, upgrades, dano variável |
| `scripts/shop.gd` | UI de loja + compras no intervalo |
| `scripts/wave_manager.gd` | Spawn tipado, shop a cada 4, vitória |
| `scripts/hud.gd` | Vida herói/poço, ouro, onda, poções, overlays |
| `scripts/main.gd` + `scenes/main.tscn` | Mapa vila, wiring, NPC, win/lose |
| `tests/test_enemy_catalog.gd` | Asserts dos tipos |
| `tests/test_shop_catalog.gd` | Asserts de preços |
| `tests/test_wave_config.gd` | Asserts das 12 ondas / shop |
| `README.md` | Controles e loop atualizados |
| `project.godot` | Nome do jogo |

Remover uso de `bullet` do fluxo (cena pode ficar órfã; não é obrigatório deletar nesta entrega).

---

### Task 1: Pipeline de sprites do jogo

**Files:**
- Create: `tools/apply_game_sprites.sh`
- Modify: `tools/apply_tiny_dungeon_sprites.sh` (opcional: deixar chamando o novo script, ou manter e documentar o novo como canônico)
- Create (via script): PNGs em `assets/sprites/`

**Interfaces:**
- Consumes: `assets/third_party/kenney/tiny-{dungeon,town}/extracted/Tiles/*.png`, ImageMagick `convert`
- Produces: sprites 32×32 PNG32 listados abaixo

- [ ] **Step 1: Criar `tools/apply_game_sprites.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
D="$ROOT/assets/third_party/kenney/tiny-dungeon/extracted/Tiles"
T="$ROOT/assets/third_party/kenney/tiny-town/extracted/Tiles"
OUT="$ROOT/assets/sprites"
mkdir -p "$OUT"

to_sprite() {
  local src="$1"
  local dest="$2"
  convert "$src" -filter point -resize 200% -define png:color-type=6 -strip "PNG32:$dest"
}

# Personagem / combate
to_sprite "$D"/096_char_knight.png "$OUT/player.png"
to_sprite "$D"/105_sword_long_a.png "$OUT/sword.png"
to_sprite "$D"/107_sword_broad.png "$OUT/sword_better.png"
to_sprite "$D"/085_char_villager.png "$OUT/npc_villager.png"

# Inimigos
to_sprite "$D"/108_enemy_slime.png "$OUT/enemy_slime.png"
to_sprite "$D"/123_enemy_rat_brown.png "$OUT/enemy_rat.png"
to_sprite "$D"/120_enemy_bat.png "$OUT/enemy_bat.png"
to_sprite "$D"/122_enemy_spider.png "$OUT/enemy_spider.png"
to_sprite "$D"/121_enemy_ghost.png "$OUT/enemy_ghost.png"
to_sprite "$D"/112_enemy_archer.png "$OUT/enemy_archer.png"
to_sprite "$D"/111_enemy_cultist.png "$OUT/enemy_cultist.png"
to_sprite "$D"/110_enemy_crab.png "$OUT/enemy_crab.png"
to_sprite "$D"/109_enemy_ogre.png "$OUT/enemy_ogre.png"

# Itens HUD
to_sprite "$D"/115_potion_red.png "$OUT/potion_small.png"
to_sprite "$D"/114_potion_green.png "$OUT/potion_large.png"

# Vila (Tiny Town)
to_sprite "$T"/000_grass.png "$OUT/town_grass.png"
to_sprite "$T"/025_path_center_a.png "$OUT/town_path.png"
to_sprite "$T"/043_path_stone.png "$OUT/town_path_stone.png"
to_sprite "$T"/004_tree_round_green_top.png "$OUT/town_tree.png"
to_sprite "$T"/044_fence_h_a.png "$OUT/town_fence_h.png"
to_sprite "$T"/058_fence_v_a.png "$OUT/town_fence_v.png"
to_sprite "$T"/052_wall_orange_a.png "$OUT/town_house_wall.png"
to_sprite "$T"/048_roof_grey_a.png "$OUT/town_roof.png"
to_sprite "$T"/085_door_wood_closed.png "$OUT/town_door.png"
to_sprite "$T"/104_well.png "$OUT/town_well.png"

rm -f "$OUT"/*.import
if command -v godot >/dev/null 2>&1; then
  godot --headless --path "$ROOT" --import >/dev/null || true
fi

echo "Sprites do jogo aplicados em assets/sprites/"
ls "$OUT"/*.png | wc -l
```

- [ ] **Step 2: Tornar executável e rodar**

```bash
chmod +x tools/apply_game_sprites.sh
./tools/apply_game_sprites.sh
```

Expected: imprime contagem ≥ 20 e gera os PNGs listados.

- [ ] **Step 3: Commit**

```bash
git add tools/apply_game_sprites.sh assets/sprites/
git commit -m "$(cat <<'EOF'
chore: adiciona pipeline de sprites da vila e inimigos

EOF
)"
```

---

### Task 2: EnemyCatalog

**Files:**
- Create: `scripts/enemy_catalog.gd`
- Create: `tests/test_enemy_catalog.gd`

**Interfaces:**
- Consumes: nada
- Produces:
  - `EnemyCatalog.kinds() -> PackedStringArray`
  - `EnemyCatalog.stats(kind: String) -> Dictionary` com chaves `hp`, `damage`, `coins`, `speed`, `texture`, `unlock_wave`
  - `EnemyCatalog.kinds_unlocked_at(wave: int) -> PackedStringArray` (1-based wave)

- [ ] **Step 1: Escrever teste que falha**

`tests/test_enemy_catalog.gd`:

```gdscript
extends SceneTree

func _init() -> void:
	var kinds: PackedStringArray = EnemyCatalog.kinds()
	assert(kinds.size() == 9, "esperado 9 tipos")
	assert(kinds.has("slime"), "slime obrigatório")
	var slime: Dictionary = EnemyCatalog.stats("slime")
	assert(int(slime.hp) == 2)
	assert(int(slime.damage) == 1)
	assert(int(slime.coins) == 1)
	assert(int(slime.unlock_wave) == 1)
	assert(String(slime.texture).ends_with("enemy_slime.png"))
	var ogre: Dictionary = EnemyCatalog.stats("ogro")
	assert(int(ogre.hp) == 6)
	assert(int(ogre.damage) == 2)
	assert(int(ogre.coins) == 5)
	assert(int(ogre.unlock_wave) == 10)
	var w1: PackedStringArray = EnemyCatalog.kinds_unlocked_at(1)
	assert(w1.size() == 1 and w1[0] == "slime")
	var w2: PackedStringArray = EnemyCatalog.kinds_unlocked_at(2)
	assert(w2.has("slime") and w2.has("rato"))
	var w10: PackedStringArray = EnemyCatalog.kinds_unlocked_at(10)
	assert(w10.size() == 9)
	print("TEST_ENEMY_CATALOG_OK")
	quit(0)
```

- [ ] **Step 2: Rodar e confirmar falha**

```bash
godot --headless --path . -s res://tests/test_enemy_catalog.gd
```

Expected: erro de classe/script `EnemyCatalog` inexistente.

- [ ] **Step 3: Implementar `scripts/enemy_catalog.gd`**

```gdscript
class_name EnemyCatalog
extends RefCounted

const _TABLE := {
	"slime": {"hp": 2, "damage": 1, "coins": 1, "speed": 90.0, "texture": "res://assets/sprites/enemy_slime.png", "unlock_wave": 1},
	"rato": {"hp": 2, "damage": 1, "coins": 1, "speed": 100.0, "texture": "res://assets/sprites/enemy_rat.png", "unlock_wave": 2},
	"morcego": {"hp": 2, "damage": 1, "coins": 2, "speed": 110.0, "texture": "res://assets/sprites/enemy_bat.png", "unlock_wave": 3},
	"aranha": {"hp": 3, "damage": 1, "coins": 2, "speed": 95.0, "texture": "res://assets/sprites/enemy_spider.png", "unlock_wave": 5},
	"fantasma": {"hp": 3, "damage": 1, "coins": 3, "speed": 85.0, "texture": "res://assets/sprites/enemy_ghost.png", "unlock_wave": 6},
	"arqueiro": {"hp": 3, "damage": 1, "coins": 3, "speed": 90.0, "texture": "res://assets/sprites/enemy_archer.png", "unlock_wave": 7},
	"cultista": {"hp": 4, "damage": 1, "coins": 4, "speed": 88.0, "texture": "res://assets/sprites/enemy_cultist.png", "unlock_wave": 8},
	"caranguejo": {"hp": 5, "damage": 1, "coins": 4, "speed": 80.0, "texture": "res://assets/sprites/enemy_crab.png", "unlock_wave": 9},
	"ogro": {"hp": 6, "damage": 2, "coins": 5, "speed": 70.0, "texture": "res://assets/sprites/enemy_ogre.png", "unlock_wave": 10},
}

static func kinds() -> PackedStringArray:
	return PackedStringArray(_TABLE.keys())

static func stats(kind: String) -> Dictionary:
	assert(_TABLE.has(kind), "tipo desconhecido: %s" % kind)
	return _TABLE[kind].duplicate()

static func kinds_unlocked_at(wave: int) -> PackedStringArray:
	var out := PackedStringArray()
	for kind in _TABLE.keys():
		if int(_TABLE[kind].unlock_wave) <= wave:
			out.append(kind)
	return out
```

Nota: ordem de `Dictionary.keys()` no Godot 4 é de inserção. O teste de `w1` exige só slime; `kinds()` size == 9 basta.

- [ ] **Step 4: Rodar teste e confirmar PASS**

```bash
godot --headless --path . -s res://tests/test_enemy_catalog.gd
```

Expected: imprime `TEST_ENEMY_CATALOG_OK` e exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/enemy_catalog.gd tests/test_enemy_catalog.gd
git commit -m "$(cat <<'EOF'
feat: adiciona catálogo de tipos de inimigo

EOF
)"
```

---

### Task 3: WaveConfig (12 ondas + loja)

**Files:**
- Modify: `scripts/wave_config.gd`
- Modify: `tests/test_wave_config.gd`

**Interfaces:**
- Consumes: `EnemyCatalog.kinds_unlocked_at`
- Produces:
  - `WaveConfig.total_waves() -> int` (= 12)
  - `WaveConfig.enemy_count(wave: int) -> int` (1-based: `4 + wave`)
  - `WaveConfig.wave_interval() -> float` (= 1.5)
  - `WaveConfig.is_shop_wave(wave: int) -> bool` (true se wave % 4 == 0 e wave < 12)
  - `WaveConfig.shop_cycle(wave: int) -> int` (1 após onda 4, 2 após 8; 0 se não for shop)
  - `WaveConfig.pick_kinds_for_wave(wave: int) -> PackedStringArray` (pool liberada; ondas 1–2 quase só slime)
  - `WaveConfig.speed_multiplier(wave: int) -> float` (1.0 + 0.05 * floor((wave-1)/4))

- [ ] **Step 1: Reescrever teste**

`tests/test_wave_config.gd`:

```gdscript
extends SceneTree

func _init() -> void:
	assert(WaveConfig.total_waves() == 12)
	assert(WaveConfig.enemy_count(1) == 5)
	assert(WaveConfig.enemy_count(12) == 16)
	assert(is_equal_approx(WaveConfig.wave_interval(), 1.5))
	assert(WaveConfig.is_shop_wave(4) == true)
	assert(WaveConfig.is_shop_wave(8) == true)
	assert(WaveConfig.is_shop_wave(12) == false)
	assert(WaveConfig.is_shop_wave(3) == false)
	assert(WaveConfig.shop_cycle(4) == 1)
	assert(WaveConfig.shop_cycle(8) == 2)
	assert(WaveConfig.shop_cycle(3) == 0)
	var w1: PackedStringArray = WaveConfig.pick_kinds_for_wave(1)
	assert(w1.size() == 1 and w1[0] == "slime")
	var w2: PackedStringArray = WaveConfig.pick_kinds_for_wave(2)
	assert(w2.has("slime") and w2.has("rato"))
	assert(is_equal_approx(WaveConfig.speed_multiplier(1), 1.0))
	assert(is_equal_approx(WaveConfig.speed_multiplier(5), 1.05))
	assert(is_equal_approx(WaveConfig.speed_multiplier(9), 1.1))
	print("TEST_WAVE_CONFIG_OK")
	quit(0)
```

- [ ] **Step 2: Rodar e confirmar falha**

```bash
godot --headless --path . -s res://tests/test_wave_config.gd
```

Expected: FAIL (API antiga só tem `wave_sizes`).

- [ ] **Step 3: Implementar `scripts/wave_config.gd`**

```gdscript
class_name WaveConfig
extends RefCounted

static func total_waves() -> int:
	return 12

static func enemy_count(wave: int) -> int:
	return 4 + wave

static func wave_interval() -> float:
	return 1.5

static func is_shop_wave(wave: int) -> bool:
	return wave > 0 and wave % 4 == 0 and wave < total_waves()

static func shop_cycle(wave: int) -> int:
	if not is_shop_wave(wave):
		return 0
	return int(wave / 4)

static func speed_multiplier(wave: int) -> float:
	return 1.0 + 0.05 * float(int((wave - 1) / 4))

static func pick_kinds_for_wave(wave: int) -> PackedStringArray:
	var unlocked: PackedStringArray = EnemyCatalog.kinds_unlocked_at(wave)
	if wave <= 1:
		return PackedStringArray(["slime"])
	if wave == 2:
		return PackedStringArray(["slime", "rato"])
	return unlocked
```

- [ ] **Step 4: Rodar teste PASS**

```bash
godot --headless --path . -s res://tests/test_wave_config.gd
```

Expected: `TEST_WAVE_CONFIG_OK`.

- [ ] **Step 5: Commit**

```bash
git add scripts/wave_config.gd tests/test_wave_config.gd
git commit -m "$(cat <<'EOF'
feat: configura 12 ondas com intervalos de loja

EOF
)"
```

---

### Task 4: ShopCatalog

**Files:**
- Create: `scripts/shop_catalog.gd`
- Create: `tests/test_shop_catalog.gd`

**Interfaces:**
- Consumes: nada
- Produces:
  - `ShopCatalog.item_ids() -> PackedStringArray`
  - `ShopCatalog.price(item_id: String, cycle: int) -> int` (cycle 1+)
  - `ShopCatalog.info(item_id: String) -> Dictionary` (`label`, `base_price`, `unique`)

Itens: `potion_small`, `potion_large`, `max_hp`, `attack`, `sword_better`.

Fórmula: `ceil(base * pow(1.2, cycle - 1))`.

- [ ] **Step 1: Teste**

```gdscript
extends SceneTree

func _init() -> void:
	assert(ShopCatalog.item_ids().size() == 5)
	assert(ShopCatalog.price("potion_small", 1) == 5)
	assert(ShopCatalog.price("potion_large", 1) == 12)
	assert(ShopCatalog.price("max_hp", 1) == 15)
	assert(ShopCatalog.price("attack", 1) == 18)
	assert(ShopCatalog.price("sword_better", 1) == 25)
	assert(ShopCatalog.price("potion_small", 2) == 6) # ceil(5*1.2)=6
	assert(ShopCatalog.price("sword_better", 2) == 30) # ceil(25*1.2)=30
	assert(ShopCatalog.info("sword_better").unique == true)
	print("TEST_SHOP_CATALOG_OK")
	quit(0)
```

- [ ] **Step 2: Rodar → FAIL**

```bash
godot --headless --path . -s res://tests/test_shop_catalog.gd
```

- [ ] **Step 3: Implementar**

```gdscript
class_name ShopCatalog
extends RefCounted

const _ITEMS := {
	"potion_small": {"label": "Poção pequena (+2 HP)", "base_price": 5, "unique": false},
	"potion_large": {"label": "Poção grande (+5 HP)", "base_price": 12, "unique": false},
	"max_hp": {"label": "+1 vida máxima", "base_price": 15, "unique": false},
	"attack": {"label": "+1 ataque", "base_price": 18, "unique": false},
	"sword_better": {"label": "Espada melhor (+1 dano)", "base_price": 25, "unique": true},
}

static func item_ids() -> PackedStringArray:
	return PackedStringArray(_ITEMS.keys())

static func info(item_id: String) -> Dictionary:
	assert(_ITEMS.has(item_id))
	return _ITEMS[item_id].duplicate()

static func price(item_id: String, cycle: int) -> int:
	var base: int = int(info(item_id).base_price)
	var safe_cycle: int = maxi(1, cycle)
	return int(ceil(float(base) * pow(1.2, float(safe_cycle - 1))))
```

- [ ] **Step 4: PASS + commit**

```bash
godot --headless --path . -s res://tests/test_shop_catalog.gd
git add scripts/shop_catalog.gd tests/test_shop_catalog.gd
git commit -m "$(cat <<'EOF'
feat: adiciona catálogo e preços da loja

EOF
)"
```

---

### Task 5: Well (objetivo)

**Files:**
- Create: `scripts/well.gd`
- Create: `scenes/well.tscn`

**Interfaces:**
- Consumes: textura `res://assets/sprites/town_well.png`
- Produces:
  - grupo `"well"`
  - `signal health_changed(current: int, max_health: int)`
  - `signal destroyed`
  - `take_damage(amount: int) -> void`
  - propriedades `health`, `MAX_HEALTH` (= 20)

- [ ] **Step 1: Criar `scripts/well.gd`**

```gdscript
extends StaticBody2D

signal health_changed(current: int, max_health: int)
signal destroyed

const MAX_HEALTH := 20

var health: int = MAX_HEALTH
var _destroyed: bool = false

func _ready() -> void:
	add_to_group("well")
	collision_layer = 1
	collision_mask = 0
	health_changed.emit(health, MAX_HEALTH)

func take_damage(amount: int) -> void:
	if _destroyed:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	if health <= 0:
		_destroyed = true
		destroyed.emit()
```

- [ ] **Step 2: Criar `scenes/well.tscn`**

Cena:
- raiz `Well` (`StaticBody2D`) + script
- filho `Sprite2D` textura `town_well.png`, centered true
- filho `CollisionShape2D` com `RectangleShape2D` size `(24, 24)`
- filho `HurtZone` (`Area2D`) collision_layer 0, mask bit enemies (layer 3 = valor 4), `CollisionShape2D` size `(28, 28)`

Não conectar dano no Well ainda: o Enemy detecta o poço no chase/contato (Task 6). `HurtZone` pode ficar para overlap opcional; preferência do plano: Enemy aplica dano ao tocar o nó well via `move_and_slide` + distância OU Area2D no Enemy. Manter Well sem lógica de Area2D de dano (só StaticBody + sprite + HP). Remova HurtZone se não for usada: cena mínima Sprite + CollisionShape.

Versão mínima da cena (texto):

```
[gd_scene load_steps=4 format=3]
[ext_resource script well.gd]
[ext_resource texture town_well.png]
[sub_resource RectangleShape2D size=Vector2(24,24)]
Well (StaticBody2D) + Sprite2D + CollisionShape2D
```

- [ ] **Step 3: Smoke headless (opcional)**

Abrir no editor ou instanciar via script curto não é obrigatório. Validar que a cena carrega:

```bash
godot --headless --path . --quit-after 1
```

- [ ] **Step 4: Commit**

```bash
git add scripts/well.gd scenes/well.tscn
git commit -m "$(cat <<'EOF'
feat: adiciona poço com HP como objetivo da vila

EOF
)"
```

---

### Task 6: Enemy tipado (chase do poço + drop)

**Files:**
- Modify: `scripts/enemy.gd`
- Modify: `scenes/enemy.tscn` (garantir Sprite2D nomeado `Sprite2D`, Hurtbox Area2D)

**Interfaces:**
- Consumes: `EnemyCatalog.stats`, nó no grupo `"well"`
- Produces:
  - `signal died(coins: int)`
  - `setup(kind: String, speed_mult: float) -> void` (chamar antes ou no `_ready` via meta; preferir `setup` logo após `instantiate`, antes de `add_child`, setando campos, e aplicar textura em `_ready` OU chamar `setup` após `add_child`)
  - chase exclusivo do poço
  - dano de contato = `stats.damage` no player e no well

Contrato de spawn (WaveManager):

```gdscript
var enemy = enemy_scene.instantiate()
enemies_root.add_child(enemy)
enemy.setup(kind, WaveConfig.speed_multiplier(wave))
enemy.global_position = point.global_position
enemy.died.connect(_on_enemy_died)
```

- [ ] **Step 1: Reescrever `scripts/enemy.gd`**

```gdscript
extends CharacterBody2D

signal died(coins: int)

var kind: String = "slime"
var health: int = 2
var contact_damage: int = 1
var coins: int = 1
var speed: float = 90.0
var _well: Node2D
var _attack_cooldown: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D

func setup(enemy_kind: String, speed_mult: float = 1.0) -> void:
	kind = enemy_kind
	var s: Dictionary = EnemyCatalog.stats(kind)
	health = int(s.hp)
	contact_damage = int(s.damage)
	coins = int(s.coins)
	speed = float(s.speed) * speed_mult
	if is_node_ready():
		_apply_texture(String(s.texture))

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	var s: Dictionary = EnemyCatalog.stats(kind)
	if health == 2 and kind == "slime":
		# defaults já ok se setup ainda não rodou; setup sobrescreve
		pass
	_apply_texture(String(EnemyCatalog.stats(kind).texture))
	_well = get_tree().get_first_node_in_group("well")
	var hurtbox := get_node_or_null("Hurtbox")
	if hurtbox:
		hurtbox.body_entered.connect(_on_hurtbox_body_entered)

func _apply_texture(path: String) -> void:
	if _sprite == null:
		_sprite = get_node_or_null("Sprite2D")
	if _sprite:
		_sprite.texture = load(path)

func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if _well == null or not is_instance_valid(_well):
		_well = get_tree().get_first_node_in_group("well")
		return
	var direction := global_position.direction_to(_well.global_position)
	velocity = direction * speed
	move_and_slide()
	if global_position.distance_to(_well.global_position) < 22.0 and _attack_cooldown <= 0.0:
		if _well.has_method("take_damage"):
			_well.take_damage(contact_damage)
			_attack_cooldown = 0.8

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	if health <= 0:
		var drop := coins
		if WaveConfig.total_waves() >= 8:
			# bônus após onda 8: WaveManager pode setar meta; aqui usamos Autoload-free check via grupo main
			pass
		died.emit(drop)
		queue_free()

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(contact_damage)
```

Ajuste fino do bônus de moeda: mover para `take_damage` com parâmetro ou meta. Preferência limpa:

Em `setup` / WaveManager, após spawn: `enemy.bonus_coin_chance = 0.1 if wave > 8 else 0.0`.

Adicionar em enemy:

```gdscript
var bonus_coin_chance: float = 0.0

# em take_damage ao morrer:
var drop := coins
if bonus_coin_chance > 0.0 and randf() < bonus_coin_chance:
	drop += 1
died.emit(drop)
```

Remover o bloco `pass` morto do snippet acima na implementação final.

- [ ] **Step 2: Commit**

```bash
git add scripts/enemy.gd scenes/enemy.tscn
git commit -m "$(cat <<'EOF'
feat: inimigos tipados perseguem o poço e dropam ouro

EOF
)"
```

---

### Task 7: Player (ouro, poções, upgrades)

**Files:**
- Modify: `scripts/player.gd`
- Modify: `scenes/player.tscn` (sem mudança estrutural obrigatória)

**Interfaces:**
- Consumes: input 1/2; textura `sword_better.png`
- Produces:
  - `signal gold_changed(amount: int)`
  - `signal potions_changed(small: int, large: int)`
  - `signal health_changed` / `died` (já existem)
  - `gold: int`, `potion_small: int`, `potion_large: int`
  - `attack_damage: int` (inicia 1)
  - `max_health: int` (inicia 5, variável)
  - `has_better_sword: bool`
  - `add_gold(amount: int) -> void`
  - `try_buy(item_id: String, price: int) -> bool`
  - `use_potion_small() / use_potion_large()`
  - dano do swing usa `attack_damage` (não constante)

- [ ] **Step 1: Atualizar campos e sinais no topo de `player.gd`**

Substituir `const MAX_HEALTH` / `ATTACK_DAMAGE` por variáveis:

```gdscript
signal gold_changed(amount: int)
signal potions_changed(small: int, large: int)

const BASE_MAX_HEALTH := 5
const BASE_ATTACK_DAMAGE := 1

var max_health: int = BASE_MAX_HEALTH
var health: int = BASE_MAX_HEALTH
var attack_damage: int = BASE_ATTACK_DAMAGE
var gold: int = 0
var potion_small: int = 0
var potion_large: int = 0
var has_better_sword: bool = false
```

Em `_on_attack_hit`: `body.take_damage(attack_damage)`.

Em `take_damage` / emits: usar `max_health` no lugar de `MAX_HEALTH`.

- [ ] **Step 2: Métodos de economia**

```gdscript
func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func use_potion_small() -> void:
	if potion_small <= 0 or _dead:
		return
	potion_small -= 1
	health = mini(max_health, health + 2)
	potions_changed.emit(potion_small, potion_large)
	health_changed.emit(health, max_health)

func use_potion_large() -> void:
	if potion_large <= 0 or _dead:
		return
	potion_large -= 1
	health = mini(max_health, health + 5)
	potions_changed.emit(potion_small, potion_large)
	health_changed.emit(health, max_health)

func try_buy(item_id: String, price: int) -> bool:
	if gold < price or _dead:
		return false
	match item_id:
		"potion_small":
			gold -= price
			potion_small += 1
			potions_changed.emit(potion_small, potion_large)
		"potion_large":
			gold -= price
			potion_large += 1
			potions_changed.emit(potion_small, potion_large)
		"max_hp":
			gold -= price
			max_health += 1
			health = mini(max_health, health + 1)
			health_changed.emit(health, max_health)
		"attack":
			gold -= price
			attack_damage += 1
		"sword_better":
			if has_better_sword:
				return false
			gold -= price
			has_better_sword = true
			attack_damage += 1
			_sword.texture = load("res://assets/sprites/sword_better.png")
		_:
			return false
	gold_changed.emit(gold)
	return true
```

- [ ] **Step 3: Input das poções em `_physics_process` ou `_unhandled_input`**

Em `_ensure_input_actions` adicionar:

```gdscript
_replace_key_action("potion_small", [KEY_1])
_replace_key_action("potion_large", [KEY_2])
_replace_key_action("interact", [KEY_E])
```

No process:

```gdscript
if Input.is_action_just_pressed("potion_small"):
	use_potion_small()
if Input.is_action_just_pressed("potion_large"):
	use_potion_large()
```

- [ ] **Step 4: Commit**

```bash
git add scripts/player.gd
git commit -m "$(cat <<'EOF'
feat: adiciona ouro, poções e upgrades ao jogador

EOF
)"
```

---

### Task 8: Shop UI

**Files:**
- Create: `scripts/shop.gd`
- Modify: `scripts/hud.gd` e `scenes/main.tscn` (painel de loja filho do HUD) **ou** cena `scenes/shop_panel` embutida no HUD

**Interfaces:**
- Consumes: `ShopCatalog`, `Player.try_buy`, ciclo da loja
- Produces:
  - `signal next_wave_pressed`
  - `open(cycle: int, player: Node) -> void`
  - `close() -> void`
  - painel com botões por item + “Próxima onda”
  - compra só com botões (E perto do NPC pode focar/abrir o mesmo painel; botões bastam se painel já aberto no intervalo)

- [ ] **Step 1: Adicionar nós no HUD (`scenes/main.tscn` sob `HUD`)**

- `ShopPanel` (`PanelContainer`, anchors centro, inicialmente `visible = false`)
  - `VBox`
    - `Title` Label “Loja”
    - `GoldLabel`
    - botões: `BuyPotionSmall`, `BuyPotionLarge`, `BuyMaxHp`, `BuyAttack`, `BuySword`
    - `NextWaveButton` texto “Próxima onda”

- [ ] **Step 2: Criar `scripts/shop.gd` e anexar em `ShopPanel`**

```gdscript
extends PanelContainer

signal next_wave_pressed

var _cycle: int = 1
var _player: Node

@onready var _gold_label: Label = $VBox/GoldLabel
@onready var _btn_small: Button = $VBox/BuyPotionSmall
@onready var _btn_large: Button = $VBox/BuyPotionLarge
@onready var _btn_hp: Button = $VBox/BuyMaxHp
@onready var _btn_atk: Button = $VBox/BuyAttack
@onready var _btn_sword: Button = $VBox/BuySword
@onready var _btn_next: Button = $VBox/NextWaveButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_btn_small.pressed.connect(func(): _buy("potion_small"))
	_btn_large.pressed.connect(func(): _buy("potion_large"))
	_btn_hp.pressed.connect(func(): _buy("max_hp"))
	_btn_atk.pressed.connect(func(): _buy("attack"))
	_btn_sword.pressed.connect(func(): _buy("sword_better"))
	_btn_next.pressed.connect(func(): next_wave_pressed.emit())

func open(cycle: int, player: Node) -> void:
	_cycle = cycle
	_player = player
	visible = true
	_refresh()

func close() -> void:
	visible = false
	_player = null

func _buy(item_id: String) -> void:
	if _player == null:
		return
	var price: int = ShopCatalog.price(item_id, _cycle)
	if _player.try_buy(item_id, price):
		_refresh()

func _refresh() -> void:
	if _player == null:
		return
	_gold_label.text = "Ouro: %d" % int(_player.gold)
	_btn_small.text = "%s (%d)" % [ShopCatalog.info("potion_small").label, ShopCatalog.price("potion_small", _cycle)]
	_btn_large.text = "%s (%d)" % [ShopCatalog.info("potion_large").label, ShopCatalog.price("potion_large", _cycle)]
	_btn_hp.text = "%s (%d)" % [ShopCatalog.info("max_hp").label, ShopCatalog.price("max_hp", _cycle)]
	_btn_atk.text = "%s (%d)" % [ShopCatalog.info("attack").label, ShopCatalog.price("attack", _cycle)]
	_btn_sword.text = "%s (%d)" % [ShopCatalog.info("sword_better").label, ShopCatalog.price("sword_better", _cycle)]
	_btn_sword.disabled = bool(_player.has_better_sword)
```

- [ ] **Step 3: Commit**

```bash
git add scripts/shop.gd scenes/main.tscn
git commit -m "$(cat <<'EOF'
feat: adiciona painel de loja entre ciclos de ondas

EOF
)"
```

---

### Task 9: WaveManager (shop + spawn tipado)

**Files:**
- Modify: `scripts/wave_manager.gd`

**Interfaces:**
- Consumes: `WaveConfig`, `EnemyCatalog`/`WaveConfig.pick_kinds_for_wave`, `enemy_scene`
- Produces:
  - `signal wave_started(wave_index: int, total_waves: int)` (substituir o antigo `wave_changed`; HUD e Main usam este nome)
  - `signal enemies_changed(remaining: int)`
  - `signal shop_started(cycle: int)`
  - `signal enemy_killed(coins: int)`
  - `signal all_waves_cleared`
  - `func start() -> void`
  - `func continue_after_shop() -> void`
  - ao morrer inimigo: emitir `enemy_killed(coins)` e decrementar vivos:

```gdscript
func _on_enemy_died(coins: int) -> void:
	_alive = maxi(0, _alive - 1)
	enemies_changed.emit(_alive)
	if _alive == 0 and not _spawning:
		_on_wave_cleared()
```

Fluxo `_on_wave_cleared`:
1. Se `wave == 12`: `all_waves_cleared.emit()`
2. Elif `WaveConfig.is_shop_wave(wave)`: `shop_started.emit(WaveConfig.shop_cycle(wave))` e **não** agenda próxima onda
3. Else: timer `wave_interval` → `_spawn_next_wave`

`continue_after_shop()` chama `_spawn_next_wave`.

Spawn: para `i in count`, escolher kind aleatório de `pick_kinds_for_wave` com vieses:
- onda 1: 100% slime
- onda 2: 80% slime / 20% rato
- demais: uniforme na pool

```gdscript
func _pick_kind(wave: int) -> String:
	var pool: PackedStringArray = WaveConfig.pick_kinds_for_wave(wave)
	if wave == 2 and pool.size() >= 2:
		return "slime" if randf() < 0.8 else "rato"
	return pool[randi() % pool.size()]
```

- [ ] **Step 1: Reescrever `wave_manager.gd` completo** conforme interfaces acima (manter `@export` de `enemy_scene`, `spawn_points_root`, `enemies_root`). Remover uso de `WaveConfig.wave_sizes()`.

- [ ] **Step 2: Commit**

```bash
git add scripts/wave_manager.gd
git commit -m "$(cat <<'EOF'
feat: wave manager com 12 ondas e pausa de loja

EOF
)"
```

---

### Task 10: HUD expandido

**Files:**
- Modify: `scripts/hud.gd`
- Modify: `scenes/main.tscn` (labels novos)

**Interfaces:**
- Produces:
  - `set_health`, `set_well_health`, `set_gold`, `set_wave`, `set_enemies`, `set_potions`
  - `show_victory` / `show_defeat` (já existem)

Labels: `WellHealthLabel`, `GoldLabel`, `PotionsLabel` além dos atuais.

```gdscript
func set_well_health(current: int, max_health: int) -> void:
	well_health_label.text = "Poço: %d/%d" % [current, max_health]

func set_gold(amount: int) -> void:
	gold_label.text = "Ouro: %d" % amount

func set_potions(small: int, large: int) -> void:
	potions_label.text = "Poções: %d / %d" % [small, large]
```

- [ ] **Step 1: Atualizar cena + script**
- [ ] **Step 2: Commit**

```bash
git add scripts/hud.gd scenes/main.tscn
git commit -m "$(cat <<'EOF'
feat: HUD com poço, ouro e poções

EOF
)"
```

---

### Task 11: Mapa da vila + wiring em Main

**Files:**
- Modify: `scripts/main.gd`
- Modify: `scenes/main.tscn` (instanciar Well, NPC, reposicionar Player/spawns)
- Modify: `project.godot` (`config/name="Vila sob Ataque"`)

**Interfaces:**
- Consome todos os sistemas anteriores
- Produz partida jogável ponta a ponta

Layout (coords em tiles 32×32, origem canto superior esquerdo):
- Grama em todo 20×15
- Caminho cruzando o centro (coluna 9–10 e linha 7) com `town_path`
- Poço em tile (~9.5, 7) → posição mundo `(304, 224)` ou `(320, 240)`
- 2 casas (parede+teto+porta) em (~3,3) e (~14,3), colisão StaticBody
- Cercas em trechos; árvores nos cantos internos
- Spawns Marker2D nas 4 bordas + cantos (já existem; reposicionar se mapa mudar)
- NPC `Sprite2D` em `(360, 260)`, visível só no intervalo de loja
- Player spawn perto do poço `(280, 260)`

- [ ] **Step 1: Reescrever `main.gd`**

Pontos chave do `_ready`:

```gdscript
_build_village()
var well = preload("res://scenes/well.tscn").instantiate()
well.position = Vector2(320, 240)
add_child(well)
# wiring
player.health_changed.connect(hud.set_health)
player.gold_changed.connect(hud.set_gold)
player.potions_changed.connect(hud.set_potions)
player.died.connect(_on_player_died)
well.health_changed.connect(hud.set_well_health)
well.destroyed.connect(_on_well_destroyed)
wave_manager.wave_started.connect(hud.set_wave)
wave_manager.enemies_changed.connect(hud.set_enemies)
wave_manager.shop_started.connect(_on_shop_started)
wave_manager.enemy_killed.connect(func(coins: int): player.add_gold(coins))
wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
hud.get_node("ShopPanel").next_wave_pressed.connect(_on_shop_next)
```

Shop:

```gdscript
func _on_shop_started(cycle: int) -> void:
	get_tree().paused = true
	$Npc.visible = true
	$HUD/ShopPanel.open(cycle, player)

func _on_shop_next() -> void:
	$HUD/ShopPanel.close()
	$Npc.visible = false
	get_tree().paused = false
	wave_manager.continue_after_shop()
```

Garantir `ShopPanel` e botões com `process_mode = ALWAYS` (já no shop.gd). Overlay de vitória/derrota idem.

`_build_village`: preencher chão, props, colisões de casas/cercas (CollisionShape por prop bloqueante). Remover `_build_ground`/`_build_walls` antigos de arena ou adaptá-los: manter paredes invisíveis nas bordas do viewport para ninguém sair.

- [ ] **Step 2: Jogar smoke test manual**

```bash
godot --path .
```

Checklist:
1. Mapa parece vila com poço central
2. Inimigos andam para o poço, não para o player
3. Matar slime dá ouro no HUD
4. Após onda 4, loja abre; comprar poção; “Próxima onda” retoma
5. Poço a 0 → derrota; herói a 0 → derrota
6. (opcional acelerar) vitória na 12

- [ ] **Step 3: Commit**

```bash
git add scripts/main.gd scenes/main.tscn project.godot
git commit -m "$(cat <<'EOF'
feat: monta mapa da vila e conecta loop completo

EOF
)"
```

---

### Task 12: README + limpeza leve

**Files:**
- Modify: `README.md`
- Optional: remover referências a tiro/bullet do README; deixar `scenes/bullet.tscn` órfão ok

- [ ] **Step 1: Atualizar README**

```markdown
# Vila sob Ataque

Jogo 2D top-down em Godot 4.7: defenda o poço da vila por 12 ondas.

## Rodar

godot --path .

## Controles

- WASD: mover
- Setas: atacar na direção
- 1 / 2: poção pequena / grande
- E: interagir (loja)
- UI: comprar e Próxima onda / Reiniciar

## Loop

Defenda o poço. Inimigos dropam ouro. A cada 4 ondas há loja com upgrades.
Vitória na onda 12. Derrota se herói ou poço chegar a 0 de vida.

## Sprites

./tools/apply_game_sprites.sh

Packs Kenney em assets/third_party/ (CC0). Ver ATTRIBUTION.md.
```

- [ ] **Step 2: Rodar todos os testes headless**

```bash
godot --headless --path . -s res://tests/test_enemy_catalog.gd
godot --headless --path . -s res://tests/test_shop_catalog.gd
godot --headless --path . -s res://tests/test_wave_config.gd
```

Expected: três `*_OK`.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "$(cat <<'EOF'
docs: atualiza README para Vila sob Ataque

EOF
)"
```

---

## Self-Review

**Spec coverage:**
- Mapa vila + poço HP 20 → Tasks 1, 5, 11
- 12 ondas, loja a cada 4 → Tasks 3, 8, 9, 11
- Pool inimigos + progressão → Tasks 2, 3, 6, 9
- Drops e compras → Tasks 4, 6, 7, 8
- Poções 1/2 e upgrades → Task 7
- Vitória/derrota herói ou poço → Tasks 5, 10, 11
- Controles WASD/setas → já no player; 1/2/E → Task 7/8
- Sem projétil de arqueiro → Task 6 (só contato)
- Arte Tiny Town/Dungeon → Task 1

**Placeholder scan:** sem TBD; código concreto nas tasks de dados e sistemas.

**Type consistency:** `died(coins: int)`, `shop_started(cycle: int)`, `try_buy(item_id, price)`, `setup(kind, speed_mult)`, `continue_after_shop()`, kind strings alinhadas (`slime`, `rato`, …, `ogro`), item ids alinhados ao ShopCatalog.
