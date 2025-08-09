Param(
  [string]$VenvPath = ".venv",
  [switch]$NoSystemDeps,
  [switch]$ForceRecreate,
  [ValidateSet("auto","cpu","cuda","rocm")]
  [string]$Gpu = "auto"
)

$ErrorActionPreference = "Stop"

function Command-Exists {
  param([string]$cmd)
  $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Write-Info($msg) { Write-Host "[info] $msg" -ForegroundColor Cyan }
function Write-Warn($msg) { Write-Host "[warn] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "[error] $msg" -ForegroundColor Red }

function Install-SystemDeps {
  if ($NoSystemDeps) { Write-Info "Skipping system dependencies (user requested)"; return }

  if (Command-Exists winget) {
    Write-Info "Installing system dependencies via winget"
    winget install -e --id Python.Python.3.12 --silent | Out-Null
    winget install -e --id Git.Git --silent | Out-Null
    # Optional tools for OCR/PDF if needed on Windows can be manual; many packages are Python-based here
  } elseif (Command-Exists choco) {
    Write-Info "Installing system dependencies via Chocolatey"
    choco install -y python git
  } else {
    Write-Warn "No package manager detected (winget/choco). Ensure Python 3.10+ and Git are installed."
  }
}

function Bootstrap-ProjectFiles {
  New-Item -ItemType Directory -Force -Path "src/config" | Out-Null

  $reqPath = "src/config/requirements.txt"
  if (-not (Test-Path $reqPath)) {
@"
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
"@ | Set-Content -NoNewline $reqPath
    Write-Info "Created default $reqPath"
  }

  $envExamplePath = "src/config/.env.example"
  if (-not (Test-Path $envExamplePath)) {
@"
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
"@ | Set-Content -NoNewline $envExamplePath
    Write-Info "Created default $envExamplePath"
  }

  if (-not (Test-Path ".env") -and (Test-Path $envExamplePath)) {
    Copy-Item $envExamplePath .env
    Write-Info "Bootstrapped .env from src/config/.env.example"
  }
}

function Create-Or-RecreateVenv {
  if ((Test-Path $VenvPath) -and $ForceRecreate) {
    Write-Info "Removing existing virtual environment: $VenvPath"
    Remove-Item -Recurse -Force $VenvPath
  }
  if (-not (Test-Path $VenvPath)) {
    Write-Info "Creating virtual environment at: $VenvPath"
    python -m venv $VenvPath
  } else {
    Write-Info "Using existing virtual environment: $VenvPath"
  }
}

function Install-PythonPackages {
  $activate = Join-Path $VenvPath "Scripts/Activate.ps1"
  if (-not (Test-Path $activate)) { Write-Err "Virtual environment activation script not found"; exit 1 }
  . $activate

  python -m pip install --upgrade pip setuptools wheel

  switch ($Gpu) {
    "cuda" { Write-Info "Installing PyTorch (CUDA 12.1)"; python -m pip install --extra-index-url https://download.pytorch.org/whl/cu121 torch torchvision torchaudio; }
    "rocm" { Write-Info "Installing PyTorch (ROCm 6.0)"; python -m pip install --index-url https://download.pytorch.org/whl/rocm6.0 torch torchvision torchaudio; }
    default { }
  }

  if (Test-Path "src/config/requirements.txt") {
    Write-Info "Installing Python requirements"
    python -m pip install -r src/config/requirements.txt
  }
}

Install-SystemDeps
Bootstrap-ProjectFiles
Create-Or-RecreateVenv
Install-PythonPackages

Write-Host "`n[done] Installation complete.`n" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "  1) Activate the virtual environment:" -ForegroundColor Green
Write-Host "       .\\$VenvPath\\Scripts\\Activate.ps1" -ForegroundColor Green
Write-Host "  2) Configure environment variables in .env as needed." -ForegroundColor Green
Write-Host "  3) Launch the application (if present):" -ForegroundColor Green
Write-Host "       python src/main.py" -ForegroundColor Green