#!/bin/bash

set -e

echo "🚀 Miden Node Systemd Setup Script Started"

# 1. Pastikan rustup sudah terinstall
if ! command -v rustup &> /dev/null; then
    echo "📦 Installing rustup..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source $HOME/.cargo/env
else
    echo "✅ rustup already installed"
fi

# 2. Install dan gunakan Rust nightly
echo "🌙 Installing Rust nightly..."
rustup install nightly
rustup override set nightly

# 3. Clone repo miden-node
if [ ! -d "miden-node" ]; then
    echo "📁 Cloning miden-node..."
    git clone https://github.com/0xPolygonMiden/miden-node.git
fi
cd miden-node

# 4. Build miden-node
echo "🔧 Building miden-node..."
make install-node

# 5. Generate genesis dan bootstrap node
echo "🧱 Generating genesis file and bootstrapping node..."
miden-node store dump-genesis > genesis.toml
mkdir -p data accounts
miden-node bundled bootstrap \
  --data-directory data \
  --accounts-directory accounts \
  --config genesis.toml

# 6. Buat file service systemd
echo "📝 Creating systemd service for Miden node..."
SERVICE_FILE="/etc/systemd/system/miden-node.service"
echo "[Unit]
Description=Miden Node Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$PWD
ExecStart=$HOME/.cargo/bin/miden-node bundled start \
  --data-directory $PWD/data \
  --rpc.url http://0.0.0.0:57123
Restart=always
RestartSec=5
Environment=\"RUST_LOG=info\"

[Install]
WantedBy=multi-user.target" | sudo tee $SERVICE_FILE > /dev/null

# 7. Reload systemd, enable, dan start service
echo "🔄 Reloading systemd and starting Miden node service..."
sudo systemctl daemon-reload
sudo systemctl enable miden-node
sudo systemctl start miden-node

# 8. Verifikasi status service
echo "✅ Miden Node is now running. You can check its status with:"
echo "sudo systemctl status miden-node"
echo "To view logs, use: sudo journalctl -fu miden-node"

# 9. Done!
echo "🎉 Miden Node is now set up and running as a systemd service!"
