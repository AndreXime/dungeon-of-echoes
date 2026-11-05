# Arena de Floresta com Ondas — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar um jogo Godot 4.7 top-down de floresta com 3 ondas de slimes, tiro mirado no mouse, HUD, vitória e derrota.

**Architecture:** Projeto Godot com cena `Main` contendo arena, `Player`, `WaveManager` e `HUD`. Inimigos e projéteis são cenas instanciadas. Sprites PNG gerados offline a partir de SVG via ImageMagick.

**Tech Stack:** Godot 4.7.2, GDScript, SVG + ImageMagick `convert`

## Global Constraints

- Engine: Godot 4.7.x (projeto `config_version=5`)
- Idioma da UI e commits: português brasileiro
- Arena ~640×480 px, paredes sólidas nas bordas
- Jogador: 5 HP, 180 px/s, cooldown 0,25 s, i-frames 0,6 s
- Projétil: 1 dano, 400 px/s
- Slime: 2 HP, 90 px/s, 1 dano no contato
- Ondas: 4 → 6 → 8 inimigos, intervalo 1,5 s entre ondas
- Controles: WASD/setas, mira mouse, tiro clique esquerdo ou Espaço
- Sem sons, salas múltiplas, itens ou menu além de vitória/derrota

## File Structure

| Path | Responsabilidade |
|---|---|
| `project.godot` | Config do projeto, main scene, input map |
| `assets/svg/*.svg` | Fontes vetoriais dos sprites |
| `assets/sprites/*.png` | Sprites raster usados pelas cenas |
| `tools/generate_sprites.sh` | Converte SVG → PNG |
| `scenes/bullet.tscn` + `scripts/bullet.gd` | Projétil |
| `scenes/player.tscn` + `scripts/player.gd` | Jogador |
| `scenes/enemy.tscn` + `scripts/enemy.gd` | Slime |
| `scripts/wave_manager.gd` | Contagem e spawn de ondas |
| `scripts/hud.gd` | HUD + overlays |
| `scenes/main.tscn` + `scripts/main.gd` | Arena, wiring, vitória/derrota |
| `scripts/wave_config.gd` | Constantes de tamanho de onda (testável) |
| `tests/test_wave_config.gd` | Asserts headless dos tamanhos de onda |

---

### Task 1: Sprites SVG → PNG

**Files:**
- Create: `assets/svg/player.svg`
- Create: `assets/svg/enemy_slime.svg`
- Create: `assets/svg/bullet.svg`
- Create: `assets/svg/tile_grass.svg`
- Create: `assets/svg/tile_wall.svg`
- Create: `tools/generate_sprites.sh`
- Create: `assets/sprites/` (saída)

**Interfaces:**
- Consumes: ImageMagick `convert` no PATH
- Produces: `assets/sprites/{player,enemy_slime,bullet,tile_grass,tile_wall}.png` nos tamanhos 32×32 (bullet 16×16)

- [ ] **Step 1: Criar SVGs**

`assets/svg/player.svg` (viewBox 0 0 32 32, herói top-down azul/marrom):

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
  <rect width="32" height="32" fill="none"/>
  <circle cx="16" cy="16" r="10" fill="#3d6ea5"/>
  <circle cx="16" cy="14" r="5" fill="#e8c39e"/>
  <rect x="13" y="8" width="6" height="3" fill="#5b3a29"/>
  <circle cx="14" cy="13" r="1" fill="#1a1a1a"/>
  <circle cx="18" cy="13" r="1" fill="#1a1a1a"/>
  <rect x="14" y="22" width="4" height="5" fill="#2f4f7a"/>
</svg>
```

`assets/svg/enemy_slime.svg`:

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
  <ellipse cx="16" cy="20" rx="12" ry="8" fill="#3cb043"/>
  <ellipse cx="16" cy="16" rx="10" ry="10" fill="#4cd964"/>
  <circle cx="12" cy="14" r="2" fill="#1a1a1a"/>
  <circle cx="20" cy="14" r="2" fill="#1a1a1a"/>
  <ellipse cx="16" cy="19" rx="3" ry="2" fill="#2a7a32"/>
</svg>
```

`assets/svg/bullet.svg`:

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
  <polygon points="8,1 14,8 8,15 2,8" fill="#7ec8e3"/>
  <polygon points="8,4 11,8 8,12 5,8" fill="#e8f7ff"/>
</svg>
```

`assets/svg/tile_grass.svg`:

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
  <rect width="32" height="32" fill="#4a7c3f"/>
  <rect x="4" y="6" width="3" height="3" fill="#5c9450"/>
  <rect x="18" y="14" width="4" height="2" fill="#3d6b35"/>
  <rect x="10" y="22" width="2" height="4" fill="#6aad5c"/>
</svg>
```

`assets/svg/tile_wall.svg`:

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
  <rect width="32" height="32" fill="#6b6b6b"/>
  <rect x="0" y="0" width="32" height="2" fill="#8a8a8a"/>
  <rect x="0" y="15" width="32" height="2" fill="#555555"/>
  <rect x="8" y="2" width="2" height="13" fill="#555555"/>
  <rect x="20" y="17" width="2" height="13" fill="#8a8a8a"/>
</svg>
```

- [ ] **Step 2: Criar `tools/generate_sprites.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/assets/sprites"
convert -background none "$ROOT/assets/svg/player.svg" -resize 32x32 "$ROOT/assets/sprites/player.png"
convert -background none "$ROOT/assets/svg/enemy_slime.svg" -resize 32x32 "$ROOT/assets/sprites/enemy_slime.png"
convert -background none "$ROOT/assets/svg/bullet.svg" -resize 16x16 "$ROOT/assets/sprites/bullet.png"
convert -background none "$ROOT/assets/svg/tile_grass.svg" -resize 32x32 "$ROOT/assets/sprites/tile_grass.png"
convert -background none "$ROOT/assets/svg/tile_wall.svg" -resize 32x32 "$ROOT/assets/sprites/tile_wall.png"
echo "sprites ok"
ls -la "$ROOT/assets/sprites"
```

- [ ] **Step 3: Gerar e verificar**

Run:

```bash
chmod +x tools/generate_sprites.sh && ./tools/generate_sprites.sh
file assets/sprites/*.png
```

Expected: cinco PNGs, mensagem `sprites ok`, `file` reporta PNG image data.

- [ ] **Step 4: Commit**

```bash
git add assets/svg assets/sprites tools/generate_sprites.sh
git commit -m "chore: gera sprites de floresta a partir de SVG"
```

---

### Task 2: Projeto Godot + wave_config testável

**Files:**
- Create: `project.godot`
- Create: `scripts/wave_config.gd`
- Create: `tests/test_wave_config.gd`
- Create: `.gitignore`

**Interfaces:**
- Consumes: nada
- Produces:
  - `WaveConfig.wave_sizes() -> Array[int]` retorna `[4, 6, 8]`
  - `WaveConfig.wave_interval() -> float` retorna `1.5`
  - `project.godot` com main scene ainda apontando para placeholder até Task 6 (usar `res://scenes/main.tscn` já declarado; cena criada na Task 6)
  - Input map: `move_left/right/up/down`, `shoot`

- [ ] **Step 1: Criar `.gitignore`**

```
.godot/
*.translation
export.cfg
export_presets.cfg
*.tmp
```

- [ ] **Step 2: Escrever teste que falha**

`scripts/wave_config.gd` (ainda sem a lógica correta de propósito — ou criar só o teste primeiro apontando para classe inexistente):

Na prática: criar `tests/test_wave_config.gd` primeiro referenciando `WaveConfig`, rodar e ver falha, depois implementar.

`tests/test_wave_config.gd`:

```gdscript
extends SceneTree

func _init() -> void:
	var sizes: Array = WaveConfig.wave_sizes()
	assert(sizes.size() == 3, "esperado 3 ondas")
	assert(sizes[0] == 4, "onda 1 deve ter 4")
	assert(sizes[1] == 6, "onda 2 deve ter 6")
	assert(sizes[2] == 8, "onda 3 deve ter 8")
	assert(is_equal_approx(WaveConfig.wave_interval(), 1.5), "intervalo 1.5s")
	print("TEST_WAVE_CONFIG_OK")
	quit(0)
```

- [ ] **Step 3: Rodar teste e confirmar falha**

Run:

```bash
godot --headless --path . --script tests/test_wave_config.gd
```

Expected: erro de parse/classe `WaveConfig` inexistente (ainda sem `wave_config.gd` registrado).

- [ ] **Step 4: Implementar `scripts/wave_config.gd`**

```gdscript
class_name WaveConfig
extends RefCounted

static func wave_sizes() -> Array:
	return [4, 6, 8]

static func wave_interval() -> float:
	return 1.5
```

- [ ] **Step 5: Criar `project.godot`**

```ini
; Engine configuration file.
config_version=5

[application]

config/name="Floresta Ondas"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.7")

[display]

window/size/viewport_width=640
window/size/viewport_height=480
window/stretch/mode="canvas_items"

[input]

move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":97,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194319,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":100,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194321,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":87,"key_label":0,"unicode":119,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194320,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_down={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":115,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194322,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
shoot={
"deadzone": 0.5,
"events": [Object(InputEventMouseButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"button_mask":0,"position":Vector2(0, 0),"global_position":Vector2(0, 0),"factor":false,"canceled":false,"pressed":false,"double_click":false,"button_index":1,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":32,"key_label":0,"unicode":32,"location":0,"echo":false,"script":null)
]
}

[layer_names]

2d_physics/layer_1="world"
2d_physics/layer_2="player"
2d_physics/layer_3="enemies"
2d_physics/layer_4="player_bullets"

[rendering]

textures/canvas_textures/default_texture_filter=0
```

Nota: se o Godot reescrever o input map ao abrir o editor, isso é esperado. Alternativa válida nesta task: criar o projeto com `godot --headless --path . --editor --quit-after 1` após um `project.godot` mínimo e depois editar input via script ou arquivo gerado. Preferir o mínimo abaixo se o bloco Object() for frágil:

Mínimo aceitável de `project.godot` nesta task:

```ini
config_version=5

[application]

config/name="Floresta Ondas"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.7")

[display]

window/size/viewport_width=640
window/size/viewport_height=480
window/stretch/mode="canvas_items"

[layer_names]

2d_physics/layer_1="world"
2d_physics/layer_2="player"
2d_physics/layer_3="enemies"
2d_physics/layer_4="player_bullets"

[rendering]

textures/canvas_textures/default_texture_filter=0
```

E mapear inputs em `_ready` do Player com fallback `InputMap` programático se as actions não existirem (implementar no Player Task 3).

- [ ] **Step 6: Rodar teste e confirmar sucesso**

Run:

```bash
godot --headless --path . --script tests/test_wave_config.gd
```

Expected: stdout contém `TEST_WAVE_CONFIG_OK`, exit code 0.

- [ ] **Step 7: Commit**

```bash
git add project.godot .gitignore scripts/wave_config.gd tests/test_wave_config.gd
git commit -m "chore: inicia projeto Godot e WaveConfig"
```

---

### Task 3: Bullet

**Files:**
- Create: `scripts/bullet.gd`
- Create: `scenes/bullet.tscn`

**Interfaces:**
- Consumes: `assets/sprites/bullet.png`, physics layers world + enemies
- Produces:
  - `Bullet.setup(direction: Vector2, speed: float = 400.0) -> void`
  - Ao entrar em corpo do grupo `enemies`, chama `take_damage(1)` se existir e `queue_free()`
  - Ao colidir com layer world (paredes), `queue_free()`
  - Collision: Area2D, mask = world | enemies, layer = player_bullets

- [ ] **Step 1: Implementar `scripts/bullet.gd`**

```gdscript
extends Area2D

var _velocity: Vector2 = Vector2.ZERO

func setup(direction: Vector2, speed: float = 400.0) -> void:
	_velocity = direction.normalized() * speed
	rotation = _velocity.angle()

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += _velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(1)
	queue_free()
```

- [ ] **Step 2: Criar `scenes/bullet.tscn`**

Estrutura:
- `Bullet` (Area2D) script `bullet.gd`
  - collision_layer = 8 (bit player_bullets = layer 4)
  - collision_mask = 5 (world=1 + enemies=4 → bits 1 e 3 = 1|4 = 5)
  - `Sprite2D` texture `res://assets/sprites/bullet.png`
  - `CollisionShape2D` CircleShape2D radius 4

Arquivo:

```
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/bullet.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/sprites/bullet.png" id="2"]

[sub_resource type="CircleShape2D" id="CircleShape2D_1"]
radius = 4.0

[node name="Bullet" type="Area2D"]
collision_layer = 8
collision_mask = 5
script = ExtResource("1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_1")
```

- [ ] **Step 3: Verificar parse da cena**

Run:

```bash
godot --headless --path . --check-only --quit 2>&1 | tail -20
```

Se `--check-only` não existir nesta build, usar:

```bash
godot --headless --path . -e --quit-after 1
```

Expected: sem erros de parse em `bullet.tscn` / `bullet.gd`.

- [ ] **Step 4: Commit**

```bash
git add scripts/bullet.gd scenes/bullet.tscn
git commit -m "feat: adiciona projétil do jogador"
```

---

### Task 4: Player

**Files:**
- Create: `scripts/player.gd`
- Create: `scenes/player.tscn`

**Interfaces:**
- Consumes: `scenes/bullet.tscn`, input actions (ou InputMap programático), sprite player
- Produces:
  - signal `health_changed(current: int, max_health: int)`
  - signal `died`
  - `take_damage(amount: int) -> void` com i-frames 0,6 s
  - max_health = 5, speed = 180, shoot_cooldown = 0,25
  - grupo `player`, collision_layer player (2), mask world (1)
  - Método interno `_ensure_input_actions()` registra WASD/setas/shoot se ausentes

- [ ] **Step 1: Implementar `scripts/player.gd`**

```gdscript
extends CharacterBody2D

signal health_changed(current: int, max_health: int)
signal died

const SPEED := 180.0
const MAX_HEALTH := 5
const SHOOT_COOLDOWN := 0.25
const IFRAME_TIME := 0.6

@export var bullet_scene: PackedScene

var health: int = MAX_HEALTH
var _shoot_timer: float = 0.0
var _iframe_timer: float = 0.0
var _dead: bool = false

func _ready() -> void:
	add_to_group("player")
	_ensure_input_actions()
	health_changed.emit(health, MAX_HEALTH)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_shoot_timer = maxf(0.0, _shoot_timer - delta)
	_iframe_timer = maxf(0.0, _iframe_timer - delta)
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * SPEED
	move_and_slide()
	look_at(get_global_mouse_position())
	if Input.is_action_pressed("shoot") and _shoot_timer <= 0.0:
		_shoot()
		_shoot_timer = SHOOT_COOLDOWN

func take_damage(amount: int) -> void:
	if _dead or _iframe_timer > 0.0:
		return
	health = maxi(0, health - amount)
	_iframe_timer = IFRAME_TIME
	health_changed.emit(health, MAX_HEALTH)
	modulate.a = 0.5
	get_tree().create_timer(IFRAME_TIME).timeout.connect(func() -> void: modulate.a = 1.0)
	if health <= 0:
		_dead = true
		died.emit()

func _shoot() -> void:
	if bullet_scene == null:
		return
	var bullet := bullet_scene.instantiate()
	var direction := (get_global_mouse_position() - global_position).normalized()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + direction * 18.0
	bullet.setup(direction)

func _ensure_input_actions() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	if not InputMap.has_action("shoot"):
		InputMap.add_action("shoot")
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("shoot", mouse)
		var space := InputEventKey.new()
		space.physical_keycode = KEY_SPACE
		InputMap.action_add_event("shoot", space)

func _add_key_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
```

- [ ] **Step 2: Criar `scenes/player.tscn`**

```
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/player.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/sprites/player.png" id="2"]
[ext_resource type="PackedScene" path="res://scenes/bullet.tscn" id="3"]

[sub_resource type="CircleShape2D" id="CircleShape2D_1"]
radius = 12.0

[node name="Player" type="CharacterBody2D"]
collision_layer = 2
collision_mask = 1
script = ExtResource("1")
bullet_scene = ExtResource("3")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_1")
```

- [ ] **Step 3: Verificar editor headless**

Run:

```bash
godot --headless --path . -e --quit-after 1
```

Expected: sem erros de script no Player.

- [ ] **Step 4: Commit**

```bash
git add scripts/player.gd scenes/player.tscn
git commit -m "feat: adiciona jogador com mira e tiro"
```

---

### Task 5: Enemy

**Files:**
- Create: `scripts/enemy.gd`
- Create: `scenes/enemy.tscn`

**Interfaces:**
- Consumes: grupo `player`, sprite slime
- Produces:
  - signal `died`
  - `take_damage(amount: int) -> void`
  - HP 2, speed 90
  - grupo `enemies`, layer enemies (4), mask world|player (1|2=3)
  - No contato com player (`move_and_slide` collisions ou Area2D filha), chama `player.take_damage(1)`
  - Preferir `Area2D` filha `Hurtbox` monitorando player para dano de contato

- [ ] **Step 1: Implementar `scripts/enemy.gd`**

```gdscript
extends CharacterBody2D

signal died

const SPEED := 90.0
const MAX_HEALTH := 2

var health: int = MAX_HEALTH
var _player: Node2D

func _ready() -> void:
	add_to_group("enemies")
	_player = get_tree().get_first_node_in_group("player")
	var hurtbox := get_node_or_null("Hurtbox")
	if hurtbox:
		hurtbox.body_entered.connect(_on_hurtbox_body_entered)

func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return
	var direction := global_position.direction_to(_player.global_position)
	velocity = direction * SPEED
	move_and_slide()

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	if health <= 0:
		died.emit()
		queue_free()

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1)
```

- [ ] **Step 2: Criar `scenes/enemy.tscn`**

```
[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/enemy.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/sprites/enemy_slime.png" id="2"]

[sub_resource type="CircleShape2D" id="CircleShape2D_body"]
radius = 12.0

[sub_resource type="CircleShape2D" id="CircleShape2D_hurt"]
radius = 14.0

[node name="Enemy" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_body")

[node name="Hurtbox" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="Hurtbox"]
shape = SubResource("CircleShape2D_hurt")
```

- [ ] **Step 3: Verificar**

Run:

```bash
godot --headless --path . -e --quit-after 1
```

Expected: sem erros de parse.

- [ ] **Step 4: Commit**

```bash
git add scripts/enemy.gd scenes/enemy.tscn
git commit -m "feat: adiciona slime perseguidor"
```

---

### Task 6: WaveManager + HUD + Main

**Files:**
- Create: `scripts/wave_manager.gd`
- Create: `scripts/hud.gd`
- Create: `scripts/main.gd`
- Create: `scenes/main.tscn`

**Interfaces:**
- Consumes: `WaveConfig`, `scenes/enemy.tscn`, `scenes/player.tscn`, tiles
- Produces:
  - `WaveManager` signals: `wave_changed(wave_index: int, total_waves: int)`, `enemies_changed(remaining: int)`, `all_waves_cleared`
  - `WaveManager.start()` inicia onda 0
  - Spawn em Marker2D filhos do nó `SpawnPoints`
  - `HUD` atualiza labels e mostra overlays Vitória/Derrota com botão Reiniciar
  - `Main` conecta sinais, constrói chão/paredes, chama `wave_manager.start()`

- [ ] **Step 1: Implementar `scripts/wave_manager.gd`**

```gdscript
extends Node

signal wave_changed(wave_index: int, total_waves: int)
signal enemies_changed(remaining: int)
signal all_waves_cleared

@export var enemy_scene: PackedScene
@export var spawn_points_root: Node2D
@export var enemies_root: Node2D

var _wave_index: int = -1
var _alive: int = 0
var _spawning: bool = false

func start() -> void:
	_wave_index = -1
	_spawn_next_wave()

func _spawn_next_wave() -> void:
	var sizes: Array = WaveConfig.wave_sizes()
	_wave_index += 1
	if _wave_index >= sizes.size():
		all_waves_cleared.emit()
		return
	_spawning = true
	var count: int = sizes[_wave_index]
	wave_changed.emit(_wave_index + 1, sizes.size())
	var points := _spawn_points()
	for i in count:
		var enemy := enemy_scene.instantiate()
		var point: Node2D = points[i % points.size()]
		enemies_root.add_child(enemy)
		enemy.global_position = point.global_position
		enemy.died.connect(_on_enemy_died)
		_alive += 1
	enemies_changed.emit(_alive)
	_spawning = false

func _spawn_points() -> Array:
	var result: Array = []
	for child in spawn_points_root.get_children():
		if child is Marker2D:
			result.append(child)
	assert(result.size() > 0, "SpawnPoints precisa de Marker2D")
	return result

func _on_enemy_died() -> void:
	_alive = maxi(0, _alive - 1)
	enemies_changed.emit(_alive)
	if _alive == 0 and not _spawning:
		var sizes: Array = WaveConfig.wave_sizes()
		if _wave_index >= sizes.size() - 1:
			all_waves_cleared.emit()
		else:
			get_tree().create_timer(WaveConfig.wave_interval()).timeout.connect(_spawn_next_wave)
```

- [ ] **Step 2: Implementar `scripts/hud.gd`**

```gdscript
extends CanvasLayer

@onready var health_label: Label = $Margin/VBox/HealthLabel
@onready var wave_label: Label = $Margin/VBox/WaveLabel
@onready var enemies_label: Label = $Margin/VBox/EnemiesLabel
@onready var overlay: ColorRect = $Overlay
@onready var overlay_label: Label = $Overlay/Center/VBox/Message
@onready var restart_button: Button = $Overlay/Center/VBox/RestartButton

func _ready() -> void:
	overlay.visible = false
	restart_button.pressed.connect(_on_restart_pressed)

func set_health(current: int, max_health: int) -> void:
	health_label.text = "Vida: %d/%d" % [current, max_health]

func set_wave(wave_index: int, total_waves: int) -> void:
	wave_label.text = "Onda: %d/%d" % [wave_index, total_waves]

func set_enemies(remaining: int) -> void:
	enemies_label.text = "Inimigos: %d" % remaining

func show_victory() -> void:
	overlay_label.text = "Vitória!"
	overlay.visible = true

func show_defeat() -> void:
	overlay_label.text = "Derrota"
	overlay.visible = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
```

- [ ] **Step 3: Implementar `scripts/main.gd`**

```gdscript
extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var wave_manager: Node = $WaveManager
@onready var hud: CanvasLayer = $HUD
@onready var spawn_points: Node2D = $SpawnPoints

func _ready() -> void:
	player.health_changed.connect(hud.set_health)
	player.died.connect(_on_player_died)
	wave_manager.wave_changed.connect(hud.set_wave)
	wave_manager.enemies_changed.connect(hud.set_enemies)
	wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	hud.set_health(player.health, player.MAX_HEALTH)
	wave_manager.spawn_points_root = spawn_points
	wave_manager.enemies_root = $Enemies
	wave_manager.start()

func _on_player_died() -> void:
	hud.show_defeat()
	get_tree().paused = true

func _on_all_waves_cleared() -> void:
	hud.show_victory()
	get_tree().paused = true
```

Nota: com `paused = true`, o botão Reiniciar precisa de `process_mode = PROCESS_MODE_ALWAYS` no HUD e no botão. Definir no `hud.gd` `_ready`:

```gdscript
process_mode = Node.PROCESS_MODE_ALWAYS
restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
```

- [ ] **Step 4: Criar `scenes/main.tscn`**

Construir programaticamente via script auxiliar é aceitável se o `.tscn` manual ficar frágil. Conteúdo mínimo esperado da cena:

- `Main` (Node2D) + `main.gd`
- `Ground` (Node2D): grade de Sprite2D 32×32 com `tile_grass.png` cobrindo 0..640 × 0..480
- `Walls` (StaticBody2D): quatro paredes (CollisionShape2D retângulos) nas bordas, layer world=1
  - Opcional: sprites `tile_wall` ao longo das bordas
- `SpawnPoints` (Node2D) com Marker2D em ~ (80,80), (560,80), (80,400), (560,400), (320,80), (320,400), (80,240), (560,240)
- `Player` instância de `player.tscn` em (320, 240)
- `WaveManager` (Node) + script, `enemy_scene = enemy.tscn`
- `HUD` (CanvasLayer) + script com árvore de controles:
  - MarginContainer → VBox → HealthLabel, WaveLabel, EnemiesLabel
  - Overlay ColorRect semi-transparente → Center → VBox → Message Label, RestartButton texto "Reiniciar"

Se for mais confiável, criar a cena abrindo o editor uma vez:

```bash
godot --path . --editor
```

e salvar `main.tscn` — mas o agente deve preferir gravar o `.tscn` completo no disco.

Skeleton `.tscn` (paredes + HUD + spawns; ground pode ser gerado em `main.gd` `_ready` para evitar dezenas de nós):

Adicionar em `main.gd` no início de `_ready`:

```gdscript
_build_ground()
```

```gdscript
func _build_ground() -> void:
	var tex: Texture2D = load("res://assets/sprites/tile_grass.png")
	var ground := Node2D.new()
	ground.name = "Ground"
	add_child(ground)
	move_child(ground, 0)
	for x in range(0, 640, 32):
		for y in range(0, 480, 32):
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = false
			s.position = Vector2(x, y)
			ground.add_child(s)
```

E paredes em `_build_walls()` com StaticBody2D + quatro RectangleShape2D.

- [ ] **Step 5: Smoke test headless**

Run:

```bash
godot --headless --path . --quit-after 60
```

Expected: processo termina sem SCRIPT ERROR / parse error. (Sem display, gameplay não é jogável aqui, só carrega.)

Run teste de config de novo:

```bash
godot --headless --path . --script tests/test_wave_config.gd
```

Expected: `TEST_WAVE_CONFIG_OK`

- [ ] **Step 6: Commit**

```bash
git add scripts/wave_manager.gd scripts/hud.gd scripts/main.gd scenes/main.tscn
git commit -m "feat: arena com ondas, HUD e fim de jogo"
```

---

### Task 7: Playtest manual e README

**Files:**
- Create: `README.md`

**Interfaces:**
- Consumes: projeto completo
- Produces: instruções para rodar

- [ ] **Step 1: Escrever `README.md`**

```markdown
# Floresta Ondas

Jogo 2D top-down em Godot 4.7: limpe 3 ondas de slimes na arena.

## Rodar

```bash
godot --path .
```

Ou abra a pasta no Godot Editor e rode a cena Main.

## Controles

- WASD / setas: mover
- Mouse: mirar
- Clique esquerdo / Espaço: atirar

## Sprites

```bash
./tools/generate_sprites.sh
```

Requer ImageMagick (`convert`).
```

- [ ] **Step 2: Playtest visual**

Run:

```bash
godot --path .
```

Checklist manual:
- [ ] Jogador se move e atira na direção do mouse
- [ ] Slimes perseguem e causam dano
- [ ] HUD mostra vida/onda/inimigos
- [ ] Limpar ondas leva à vitória
- [ ] Morrer mostra derrota e Reiniciar funciona

- [ ] **Step 3: Commit final**

```bash
git add README.md
git commit -m "docs: adiciona README do jogo"
```

---

## Spec coverage (self-review)

| Requisito da spec | Task |
|---|---|
| Top-down floresta, 3 ondas | 6 |
| WASD, mira mouse, tiro | 4 |
| Slimes perseguem + dano contato | 5 |
| Vitória / derrota + Reiniciar | 6 |
| Sprites SVG→PNG | 1 |
| Números de balanceamento | 2, 4, 5, 6 (WaveConfig + constantes) |
| Critério abrir e rodar Main | 6, 7 |

Placeholders: nenhum TBD restante. Nomes alinhados: `take_damage`, `died`, `all_waves_cleared`, `WaveConfig.wave_sizes()`.
