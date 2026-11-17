#!/bin/bash
set -e

echo "Installing Kimi Code CLI..."

# Ensure curl and ca-certificates are present
if command -v apt-get > /dev/null 2>&1; then
    apt-get update && apt-get install -y curl ca-certificates
elif command -v yum > /dev/null 2>&1; then
    yum install -y curl ca-certificates
fi

# Install Kimi Code CLI via the official installer script
# (replaces the deprecated kimi-cli Python package archived in September 2024)
curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash

# The installer typically places the binary in /usr/local/bin or ~/.local/bin;
# make sure both are on PATH.
export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"

echo "Setting up environment variables..."
mkdir -p /root/.kimi

# Kimi Code CLI reads KIMI_MODEL_NAME and KIMI_MODEL_API_KEY (not MOONSHOT_API_KEY /
# KIMI_API_KEY / KIMI_MODEL which the old Python package used).
# KIMI_CODE_TRUST_WORKSPACE=1 suppresses the first-run trust prompt inside containers.
cat > /root/.kimi/.env << 'EOF'
export PATH="/usr/local/bin:/root/.local/bin:$PATH"
export KIMI_MODEL_NAME="${KIMI_MODEL_NAME:-kimi-k2.7-code}"
export KIMI_MODEL_API_KEY="${KIMI_MODEL_API_KEY:-${MOONSHOT_API_KEY:-}}"
export KIMI_MODEL_BASE_URL="${KIMI_MODEL_BASE_URL:-}"
export KIMI_CODE_TRUST_WORKSPACE=1
EOF

if ! grep -q "source /root/.kimi/.env" /root/.bashrc 2>/dev/null; then
    echo "source /root/.kimi/.env" >> /root/.bashrc
fi

echo "Testing installation..."
source /root/.kimi/.env

if command -v kimi > /dev/null 2>&1; then
    kimi --version || true
    echo "INSTALL_SUCCESS"
else
    echo "Installation failed: kimi executable not found" >&2
    exit 1
fi
