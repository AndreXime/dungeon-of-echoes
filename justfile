# Dungeon Of Echoes — builds Godot 4.7
set dotenv-load := false

godot := "godot"
project := justfile_directory()

default:
    @just --list

# Linux x86_64 (AMD/Intel) + arm64
build-linux: build-linux-x86_64 build-linux-arm64

build-linux-x86_64:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{ project }}/build/linux/x86_64"
    "{{ godot }}" --path "{{ project }}" --headless \
      --export-release "Linux x86_64" \
      "{{ project }}/build/linux/x86_64/DungeonOfEchoes.x86_64"
    chmod +x "{{ project }}/build/linux/x86_64/DungeonOfEchoes.x86_64"
    ls -lh "{{ project }}/build/linux/x86_64/DungeonOfEchoes.x86_64"

build-linux-arm64:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{ project }}/build/linux/arm64"
    "{{ godot }}" --path "{{ project }}" --headless \
      --export-release "Linux arm64" \
      "{{ project }}/build/linux/arm64/DungeonOfEchoes.arm64"
    chmod +x "{{ project }}/build/linux/arm64/DungeonOfEchoes.arm64"
    ls -lh "{{ project }}/build/linux/arm64/DungeonOfEchoes.arm64"

# Windows x86_64 + arm64 (exportável a partir do Linux)
build-windows: build-windows-x86_64 build-windows-arm64

build-windows-x86_64:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{ project }}/build/windows/x86_64"
    "{{ godot }}" --path "{{ project }}" --headless \
      --export-release "Windows x86_64" \
      "{{ project }}/build/windows/x86_64/DungeonOfEchoes.exe"
    ls -lh "{{ project }}/build/windows/x86_64/DungeonOfEchoes.exe"

build-windows-arm64:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{ project }}/build/windows/arm64"
    "{{ godot }}" --path "{{ project }}" --headless \
      --export-release "Windows arm64" \
      "{{ project }}/build/windows/arm64/DungeonOfEchoes.exe"
    ls -lh "{{ project }}/build/windows/arm64/DungeonOfEchoes.exe"

# Web: single-thread + multi-thread (WASM)
build-web: build-web-single build-web-multi

build-web-single:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{ project }}/build/web/single"
    "{{ godot }}" --path "{{ project }}" --headless \
      --export-release "Web single" \
      "{{ project }}/build/web/single/index.html"
    du -sh "{{ project }}/build/web/single"

build-web-multi:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{ project }}/build/web/multi"
    "{{ godot }}" --path "{{ project }}" --headless \
      --export-release "Web multi" \
      "{{ project }}/build/web/multi/index.html"
    du -sh "{{ project }}/build/web/multi"

# Todas as plataformas / arquiteturas
build-all: build-linux build-windows build-web

# Serve web single (qualquer host HTTP simples)
serve-web: serve-web-single

serve-web-single:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ ! -f "{{ project }}/build/web/single/index.html" ]]; then
      echo "Sem build. Rode: just build-web-single"
      exit 1
    fi
    python3 "{{ project }}/scripts/dev/serve_web.py" "{{ project }}/build/web/single"

# Serve web multi (envia COOP/COEP para SharedArrayBuffer)
serve-web-multi:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ ! -f "{{ project }}/build/web/multi/index.html" ]]; then
      echo "Sem build. Rode: just build-web-multi"
      exit 1
    fi
    python3 "{{ project }}/scripts/dev/serve_web.py" "{{ project }}/build/web/multi" --coop

# Abre o editor Godot no projeto
editor:
    "{{ godot }}" --path "{{ project }}" --editor

# Roda o jogo (hub)
run:
    "{{ godot }}" --path "{{ project }}"
