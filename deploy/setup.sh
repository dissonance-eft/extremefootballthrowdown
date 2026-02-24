#!/bin/bash
# EFT Server — One-time setup for Debian/Ubuntu
# Run as root on a fresh VPS: bash setup.sh
set -e

GMOD_USER="gmod"
SERVER_DIR="/home/gmod/server"
GAMEMODE_DIR="$SERVER_DIR/garrysmod/gamemodes/extremefootballthrowdown"
REPO_URL="https://github.com/dissonance-eft/extremefootballthrowdown.git"

echo "[EFT] Creating $GMOD_USER user..."
useradd -m -s /bin/bash "$GMOD_USER" 2>/dev/null || echo "  (user already exists)"

echo "[EFT] Installing dependencies..."
apt-get update -qq
apt-get install -y lib32gcc-s1 lib32stdc++6 git curl wget

echo "[EFT] Installing SteamCMD..."
mkdir -p /home/gmod/steamcmd
cd /home/gmod/steamcmd
wget -q https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzf steamcmd_linux.tar.gz
rm -f steamcmd_linux.tar.gz
chown -R "$GMOD_USER:$GMOD_USER" /home/gmod/steamcmd

echo "[EFT] Downloading GMod dedicated server (this takes a few minutes)..."
sudo -u "$GMOD_USER" /home/gmod/steamcmd/steamcmd.sh \
    +force_install_dir "$SERVER_DIR" \
    +login anonymous \
    +app_update 4020 validate \
    +quit

echo "[EFT] Cloning EFT gamemode..."
mkdir -p "$SERVER_DIR/garrysmod/gamemodes"
cd "$SERVER_DIR/garrysmod/gamemodes"
sudo -u "$GMOD_USER" git clone "$REPO_URL"
chown -R "$GMOD_USER:$GMOD_USER" "$SERVER_DIR/garrysmod/gamemodes"

echo "[EFT] Setting up server.cfg..."
CFG_DIR="$SERVER_DIR/garrysmod/cfg"
mkdir -p "$CFG_DIR"
if [ ! -f "$CFG_DIR/server.cfg" ]; then
    cp "$GAMEMODE_DIR/deploy/server.cfg.example" "$CFG_DIR/server.cfg"
    echo ""
    echo "  >>> IMPORTANT: Edit $CFG_DIR/server.cfg and set your rcon_password before starting!"
    echo ""
else
    echo "  (server.cfg already exists, skipping)"
fi

echo "[EFT] Installing systemd service..."
cp "$GAMEMODE_DIR/deploy/eft.service" /etc/systemd/system/eft-srcds.service
chmod 644 /etc/systemd/system/eft-srcds.service
systemctl daemon-reload
systemctl enable eft-srcds

echo "[EFT] Granting passwordless sudo for service management..."
cat > /etc/sudoers.d/gmod-eft << 'EOF'
gmod ALL=(ALL) NOPASSWD: /bin/systemctl restart eft-srcds
gmod ALL=(ALL) NOPASSWD: /bin/systemctl start eft-srcds
gmod ALL=(ALL) NOPASSWD: /bin/systemctl stop eft-srcds
gmod ALL=(ALL) NOPASSWD: /bin/systemctl status eft-srcds
EOF
chmod 440 /etc/sudoers.d/gmod-eft

echo "[EFT] Generating SSH key for GitHub Actions deploy..."
sudo -u "$GMOD_USER" ssh-keygen -t ed25519 -C "eft-deploy" -f /home/gmod/.ssh/deploy_key -N ""
cat /home/gmod/.ssh/deploy_key.pub >> /home/gmod/.ssh/authorized_keys
chmod 600 /home/gmod/.ssh/authorized_keys
chown "$GMOD_USER:$GMOD_USER" /home/gmod/.ssh/authorized_keys

echo ""
echo "========================================"
echo "  EFT Setup Complete"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Edit $CFG_DIR/server.cfg — set hostname, rcon_password"
echo "  2. Add these GitHub repo secrets:"
echo "       DEPLOY_HOST  = $(curl -s ifconfig.me)"
echo "       DEPLOY_USER  = gmod"
echo "       DEPLOY_KEY   = (contents of /home/gmod/.ssh/deploy_key — shown below)"
echo ""
echo "--- DEPLOY_KEY (copy everything including BEGIN/END lines) ---"
cat /home/gmod/.ssh/deploy_key
echo "--- END ---"
echo ""
echo "  3. Start the server: sudo systemctl start eft-srcds"
echo "  4. Check logs:       journalctl -u eft-srcds -f"
echo ""
