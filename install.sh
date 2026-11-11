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
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "$TMP_DIR/awscliv2.zip"
    unzip -q "$TMP_DIR/awscliv2.zip" -d "$TMP_DIR"
    sudo "$TMP_DIR/aws/install"
    rm -rf "$TMP_DIR"
  else
    echo "❌ Cannot auto-install AWS CLI on this OS."
    echo "   Install manually: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
  fi
fi
AWS_CLI_VERSION=$(aws --version 2>&1 | awk '{print $1}' | cut -d/ -f2)
if ! python3 -c "import sys; v=tuple(int(x) for x in '$AWS_CLI_VERSION'.split('.')[:2]); sys.exit(0 if v >= (2, 13) else 1)" 2>/dev/null; then
  echo "⚠️  AWS CLI $AWS_CLI_VERSION is older than 2.13. In-game commands still work, but upgrading is recommended."
fi
echo "✅ AWS CLI $AWS_CLI_VERSION"

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
if [ -d ".venv" ] && ! .venv/bin/python -c "import sys" >/dev/null 2>&1; then
  echo "♻️  Existing .venv is broken — recreating it"
  rm -rf .venv
fi
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

# ─── Floci (local AWS emulator) ───────────────────────────────────────────────
FLOCI_IMAGE="floci/floci:2.4.0"
echo ""
echo "🐳 Pulling Floci emulator image ($FLOCI_IMAGE)..."
docker pull "$FLOCI_IMAGE"
echo "✅ Floci image ready"

# ─── Build level registry ─────────────────────────────────────────────────────
echo ""
echo "📋 Building level registry..."
python3 scripts/build_levels.py
echo "✅ levels.json generated"

echo ""
echo "════════════════════════════════════"
echo "✅  AWSMissions is ready!"
echo "   Run:  ./play.sh"
echo ""
echo "   No AWS account needed."
echo "   Everything runs locally via Floci (https://github.com/floci-io/floci)."
echo "════════════════════════════════════"
echo ""
