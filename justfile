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

# Build HTML5 (WASM; não depende de CPU do host)
build-web:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{ project }}/build/web"
    "{{ godot }}" --path "{{ project }}" --headless \
      --export-release "Web" "{{ project }}/build/web/index.html"
    du -sh "{{ project }}/build/web"

# Todas as plataformas / arquiteturas
build-all: build-linux build-windows build-web

# Serve a build web em http://127.0.0.1:8080/
serve-web:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ ! -f "{{ project }}/build/web/index.html" ]]; then
      echo "Sem build web. Rode: just build-web"
      exit 1
    fi
    cd "{{ project }}/build/web"
    echo "Abrindo http://127.0.0.1:8080/"
    python3 -m http.server 8080

# Abre o editor Godot no projeto
editor:
    "{{ godot }}" --path "{{ project }}" --editor

# Roda o jogo (hub)
run:
    "{{ godot }}" --path "{{ project }}"
