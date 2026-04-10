#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

echo "🚀 AWSMissions Installation"
echo "==========================="
echo ""

# ─── Helpers ──────────────────────────────────────────────────────────────────
install_pkg() {
  local pkg="$1"
  echo "📦 Installing $pkg..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install "$pkg"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt-get update -qq && sudo apt-get install -y "$pkg"
  else
    echo "❌ Cannot auto-install $pkg on this OS. Please install it manually."
    exit 1
  fi
}

# ─── Python 3.9+ ──────────────────────────────────────────────────────────────
if ! command -v python3 >/dev/null 2>&1; then
  install_pkg python3
fi

PYTHON_VERSION=$(python3 -c "
import sys; v = sys.version_info
print(f'{v.major}.{v.minor}')
exit(0 if (v.major, v.minor) >= (3, 9) else 1)
") || {
  echo "❌ Python 3.9+ required (found $PYTHON_VERSION)"
  echo "   Linux: sudo apt install python3.11"
  echo "   macOS: brew install python@3.11"
  exit 1
}
echo "✅ Python $PYTHON_VERSION"

# ─── Docker ───────────────────────────────────────────────────────────────────
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker is not installed."
  echo "   Install: https://docs.docker.com/get-docker/"
  echo "   Linux quick-install: sudo apt install docker.io && sudo usermod -aG docker \$USER"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker is installed but not running. Please start Docker and re-run install.sh"
  exit 1
fi
echo "✅ Docker running"

# ─── AWS CLI v2 ───────────────────────────────────────────────────────────────
if ! command -v aws >/dev/null 2>&1; then
  echo "📦 Installing AWS CLI v2..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install awscli
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # apt package was removed in Ubuntu 22.04+; use the official AWS installer
    if ! command -v curl >/dev/null 2>&1; then
      sudo apt-get update -qq && sudo apt-get install -y curl unzip
    fi
    TMP_DIR=$(mktemp -d)
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$TMP_DIR/awscliv2.zip"
    unzip -q "$TMP_DIR/awscliv2.zip" -d "$TMP_DIR"
    sudo "$TMP_DIR/aws/install"
    rm -rf "$TMP_DIR"
  else
    echo "❌ Cannot auto-install AWS CLI on this OS."
    echo "   Install manually: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
  fi
fi
echo "✅ AWS CLI $(aws --version 2>&1 | awk '{print $1}')"

# ─── jq ───────────────────────────────────────────────────────────────────────
if ! command -v jq >/dev/null 2>&1; then
  install_pkg jq
fi
echo "✅ jq $(jq --version)"

# ─── zip ──────────────────────────────────────────────────────────────────────
if ! command -v zip >/dev/null 2>&1; then
  install_pkg zip
fi
echo "✅ zip"

# ─── Python venv ──────────────────────────────────────────────────────────────
echo ""
echo "🐍 Setting up Python virtual environment..."
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi

if [ -f ".venv/bin/activate" ]; then
  source .venv/bin/activate
elif [ -f ".venv/Scripts/activate" ]; then
  source .venv/Scripts/activate
else
  echo "❌ venv activation script not found"; exit 1
fi

echo "📦 Installing Python dependencies..."
pip install -q -r requirements.txt
echo "✅ Python packages installed"

# ─── awscli-local (awslocal wrapper) ──────────────────────────────────────────
if ! command -v awslocal >/dev/null 2>&1; then
  echo "📦 Installing awscli-local..."
  pip install -q awscli-local
fi
echo "✅ awslocal (awscli-local)"

# ─── LocalStack Docker image ──────────────────────────────────────────────────
echo ""
echo "🐳 Pulling LocalStack Docker image..."
docker pull localstack/localstack:3.8
echo "✅ LocalStack image ready"

# ─── Build level registry ─────────────────────────────────────────────────────
echo ""
echo "📋 Building level registry..."
python3 scripts/build_levels.py
echo "✅ levels.json generated"

# ─── Progress file ────────────────────────────────────────────────────────────
if [[ ! -f progress.json ]]; then
  echo '{"player_name":null,"total_xp":0,"completed_levels":[],"current_level_id":1,"module_certificates":[],"hint_state":{},"time_per_level":{}}' > progress.json
fi

echo ""
echo "════════════════════════════════════"
echo "✅  AWSMissions is ready!"
echo "   Run:  ./play.sh"
echo ""
echo "   No AWS account needed."
echo "   Everything runs locally via LocalStack."
echo "════════════════════════════════════"
echo ""
