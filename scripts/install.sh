#!/usr/bin/env bash
set -euo pipefail

# Defaults
VENV_PATH=".venv"
FORCE_RECREATE="false"
INSTALL_SYSTEM_DEPS="true"
GPU="auto"  # options: auto|cpu|cuda|rocm (torch install optional)

usage() {
  cat << 'EOF'
Usage: bash scripts/install.sh [options]

Options:
  --venv-path <path>      Path to create/use the Python virtual environment (default: .venv)
  --no-system-deps        Skip installing system dependencies via the OS package manager
  --force-recreate        Recreate the virtual environment if it already exists
  --gpu <auto|cpu|cuda|rocm>
                          Optional CUDA/ROCm torch selection. Default: auto (no forced torch wheel)
  -h, --help              Show this help and exit

Examples:
  bash scripts/install.sh
  bash scripts/install.sh --venv-path .venv --gpu cpu
  bash scripts/install.sh --no-system-deps --force-recreate
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --venv-path)
      VENV_PATH="$2"; shift 2 ;;
    --no-system-deps)
      INSTALL_SYSTEM_DEPS="false"; shift 1 ;;
    --force-recreate)
      FORCE_RECREATE="true"; shift 1 ;;
    --gpu)
      GPU="${2:-auto}"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage; exit 1 ;;
  esac
done

command_exists() { command -v "$1" >/dev/null 2>&1; }

require_cmd() { if ! command_exists "$1"; then echo "Required command '$1' not found" >&2; exit 1; fi; }

sudo_prefix() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    if command_exists sudo; then echo sudo; else echo ""; fi
  else
    echo ""
  fi
}

install_system_deps_apt() {
  local SUDO; SUDO=$(sudo_prefix)
  $SUDO apt-get update -y
  $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3 python3-venv python3-pip \
    build-essential git pkg-config \
    libgl1 ffmpeg tesseract-ocr poppler-utils
}

install_system_deps_dnf() {
  local SUDO; SUDO=$(sudo_prefix)
  $SUDO dnf install -y \
    python3 python3-pip python3-virtualenv \
    gcc gcc-c++ make git pkgconf-pkg-config \
    libglvnd-glx ffmpeg tesseract poppler-utils
}

install_system_deps_pacman() {
  local SUDO; SUDO=$(sudo_prefix)
  $SUDO pacman -Sy --noconfirm \
    python python-virtualenv base-devel git pkgconf \
    libgl ffmpeg tesseract poppler
}

install_system_deps_apk() {
  local SUDO; SUDO=$(sudo_prefix)
  $SUDO apk add --no-cache \
    python3 py3-pip py3-virtualenv build-base git pkgconf \
    mesa-gl ffmpeg tesseract-ocr poppler-utils
}

install_system_deps_brew() {
  # Homebrew generally doesn't require sudo
  if ! command_exists brew; then
    echo "[warn] Homebrew not found; skipping brew installation of system deps"
    return
  fi
  brew update
  brew install python git pkg-config ffmpeg tesseract poppler || true
}

maybe_install_system_deps() {
  if [[ "$INSTALL_SYSTEM_DEPS" != "true" ]]; then
    echo "[info] Skipping system dependencies (user requested)"
    return
  fi
  if command_exists apt-get; then
    echo "[info] Installing system dependencies with apt-get"
    install_system_deps_apt
  elif command_exists dnf; then
    echo "[info] Installing system dependencies with dnf"
    install_system_deps_dnf
  elif command_exists pacman; then
    echo "[info] Installing system dependencies with pacman"
    install_system_deps_pacman
  elif command_exists apk; then
    echo "[info] Installing system dependencies with apk"
    install_system_deps_apk
  elif command_exists brew; then
    echo "[info] Installing system dependencies with Homebrew"
    install_system_deps_brew
  else
    echo "[warn] Unsupported package manager. Please install dependencies manually:"
    echo "       python3, python3-venv, python3-pip, build-essential/gcc, git, pkg-config, libgl, ffmpeg, tesseract-ocr, poppler-utils"
  fi
}

bootstrap_project_files() {
  mkdir -p src/config

  if [[ ! -f src/config/requirements.txt ]]; then
    cat > src/config/requirements.txt << 'REQ'
# Core runtime
gradio>=4.36.1
python-dotenv>=1.0.1

# Data & embeddings
chromadb>=0.5.5
minio>=7.2.7
sentence-transformers>=2.7.0

# Preprocessing utilities
pillow>=10.3.0
pytesseract>=0.3.10
pdfminer.six>=20231228

# General
pydantic>=2.7.1
requests>=2.32.2
numpy>=1.26.4
REQ
    echo "[info] Created default src/config/requirements.txt"
  fi

  if [[ ! -f src/config/.env.example ]]; then
    cat > src/config/.env.example << 'ENV'
# LXC Container Endpoints
MINIO_ENDPOINT=http://10.0.0.100:9000
CHROMADB_HOST=10.0.0.101
MODEL_REPO_ENDPOINT=http://10.0.0.102:8080

# GPU Service API Keys
LIGHTNING_API_KEY=
PAPERSPACE_API_KEY=

# Gradio Interface
GRADIO_HOST=0.0.0.0
GRADIO_PORT=7860
ENV
    echo "[info] Created default src/config/.env.example"
  fi

  if [[ ! -f .env && -f src/config/.env.example ]]; then
    cp src/config/.env.example .env
    echo "[info] Bootstrapped .env from src/config/.env.example"
  fi
}

create_or_recreate_venv() {
  if [[ -d "$VENV_PATH" && "$FORCE_RECREATE" == "true" ]]; then
    echo "[info] Removing existing virtual environment: $VENV_PATH"
    rm -rf "$VENV_PATH"
  fi
  if [[ ! -d "$VENV_PATH" ]]; then
    echo "[info] Creating virtual environment at: $VENV_PATH"
    python3 -m venv "$VENV_PATH"
  else
    echo "[info] Using existing virtual environment: $VENV_PATH"
  fi
}

install_python_packages() {
  # shellcheck disable=SC1090
  source "$VENV_PATH/bin/activate"
  python -m pip install --upgrade pip setuptools wheel

  # Optional torch selection
  case "$GPU" in
    cuda)
      echo "[info] Installing PyTorch (CUDA 12.1)"
      python -m pip install --extra-index-url https://download.pytorch.org/whl/cu121 torch torchvision torchaudio || true
      ;;
    rocm)
      echo "[info] Installing PyTorch (ROCm 6.0)"
      python -m pip install --index-url https://download.pytorch.org/whl/rocm6.0 torch torchvision torchaudio || true
      ;;
    cpu|auto|*)
      : # rely on transitive deps (e.g., sentence-transformers) to pull CPU torch if needed
      ;;
  esac

  if [[ -f src/config/requirements.txt ]]; then
    echo "[info] Installing Python requirements"
    python -m pip install -r src/config/requirements.txt
  fi
}

main() {
  maybe_install_system_deps
  bootstrap_project_files
  require_cmd python3
  create_or_recreate_venv
  install_python_packages

  cat << 'POST'

[done] Installation complete.

Next steps:
  1) Activate the virtual environment:
       source .venv/bin/activate
  2) Configure environment variables in .env as needed.
  3) Launch the application (if present):
       python src/main.py

You can re-run with flags, e.g.:
  bash scripts/install.sh --force-recreate --gpu cuda
POST
}

main "$@"