#!/bin/bash
set -e

# -----------------------------
# VARIABLES
# -----------------------------
REPO_URL="https://github.com/HMPIWD/blacknwhitehmpdot.git"
INSTALL_DIR="$HOME/.local/share/blacknwhitehmpdot"
BACKUP_DIR="$HOME/.config/backup_$(date +%F_%H-%M)"

echo "=== blacknwhitehmpdot installer ==="

# -----------------------------
# REQUIREMENTS
# -----------------------------
echo "=== Checking for git ==="
if ! command -v git &>/dev/null; then
    echo "→ Installing git..."
    sudo pacman -S --needed --noconfirm git
fi

# -----------------------------
# CLONE DOTFILES
# -----------------------------
if [ ! -d "$INSTALL_DIR" ]; then
    echo "→ Cloning dotfiles repository"
    git clone "$REPO_URL" "$INSTALL_DIR"
else
    echo "→ Dotfiles repo already exists, updating"
    git -C "$INSTALL_DIR" pull
fi

cd "$INSTALL_DIR"

# -----------------------------
# YAY
# -----------------------------
echo "=== Checking for yay ==="
if ! command -v yay &>/dev/null; then
    echo "→ Installing yay..."
    sudo pacman -S --needed --noconfirm base-devel
    TMP_DIR="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$TMP_DIR/yay"
    cd "$TMP_DIR/yay"
    makepkg -si --noconfirm
    cd "$INSTALL_DIR"
    rm -rf "$TMP_DIR"
    echo "✔ yay installed"
else
    echo "✔ yay already installed"
fi

# -----------------------------
# SYSTEM DEPENDENCIES
# -----------------------------
echo "=== Installing system dependencies ==="
sudo pacman -S --needed --noconfirm \
    hyprland \
    hyprpaper \
    hyprlock \
    hypridle \
    hyprpicker \
    alacritty \
    rofi \
    rofi-wayland \
    kvantum \
    kvantum-theme-materia \
    qt5ct \
    qt6ct \
    nwg-look \
    gtk4 \
    gtk3 \
    python \
    sassc \
    fontconfig \
    wl-clipboard \
    grim \
    slurp \
    wayland-protocols \
    xdg-desktop-portal \
    xdg-desktop-portal-hyprland \
    brightnessctl \
    playerctl \
    pamixer \
    gnome-keyring

# -----------------------------
# HYPRPANEL & POLKIT
# -----------------------------
echo "=== Installing Hyprpanel (ags-hyprpanel-git) ==="
yay -S --needed --noconfirm ags-hyprpanel-git

echo "=== Installing Polkit agent (Hyprland) ==="
yay -S --needed --noconfirm hyprpolkitagent

# -----------------------------
# FONT INSTALL (Azeret Mono)
# -----------------------------
echo "=== Installing Azeret Mono ==="
FONT_SRC="$INSTALL_DIR/fonts/AzeretMono-VariableFont_wght.ttf"
FONT_DEST="/usr/share/fonts/TTF"

if [ -f "$FONT_SRC" ]; then
    sudo mkdir -p "$FONT_DEST"
    sudo cp "$FONT_SRC" "$FONT_DEST/"
else
    echo "✖ Font not found: $FONT_SRC"
    exit 1
fi
sudo fc-cache -fv

# -----------------------------
# FONTCONFIG
# -----------------------------
echo "=== Configuring monospace font ==="
sudo tee /etc/fonts/local.conf >/dev/null << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias>
    <family>monospace</family>
    <prefer>
      <family>Azeret Mono</family>
    </prefer>
  </alias>
</fontconfig>
EOF
sudo fc-cache -fv

# -----------------------------
# CONFIG BACKUP
# -----------------------------
echo "=== Backing up existing configs ==="
mkdir -p "$BACKUP_DIR"
backup() {
    [ -e "$HOME/.config/$1" ] && cp -r "$HOME/.config/$1" "$BACKUP_DIR/"
}
backup hypr
backup hyprpanel
backup alacritty
backup gtk-4.0
backup gtk-5.0
backup Kvantum
backup qt5ct
backup qt6ct
backup rofi
backup dolphinrc

# -----------------------------
# COPY CONFIGS
# -----------------------------
echo "=== Installing configs ==="
copy_cfg() {
    SRC="$INSTALL_DIR/$1"
    DEST="$HOME/.config/$2"
    if [ -d "$SRC" ]; then
        mkdir -p "$DEST"
        cp -r "$SRC"/* "$DEST"/
    fi
}

copy_cfg hypr hypr
copy_cfg hyprpanel hyprpanel
copy_cfg alacritty alacritty
copy_cfg gtk-4.0 gtk-4.0
copy_cfg gtk-5.0 gtk-5.0
copy_cfg qt5ct qt5ct
copy_cfg qt6ct qt6ct
copy_cfg rofi rofi

# Dolphin config (single file)
if [ -f "$INSTALL_DIR/dolphinrc" ]; then
    echo "→ Installing dolphinrc"
    cp "$INSTALL_DIR/dolphinrc" "$HOME/.config/dolphinrc"
fi

# Kvantum themes
if [ -d "$INSTALL_DIR/kvantum" ]; then
    mkdir -p "$HOME/.config/Kvantum"
    cp -r "$INSTALL_DIR/kvantum"/* "$HOME/.config/Kvantum/"
fi

# -----------------------------
# ACTIVATE KVANTUM
# -----------------------------
if command -v kvantummanager &>/dev/null; then
    THEME=$(ls "$INSTALL_DIR/kvantum" 2>/dev/null | head -n 1)
    [ -n "$THEME" ] && kvantummanager --set "$THEME"
fi

# -----------------------------
# DONE
# -----------------------------
echo "=== INSTALL COMPLETE ==="
echo "✔ Backups stored in: $BACKUP_DIR"
echo "➡ Reboot or re-login recommended"
