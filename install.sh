#!/bin/bash
set -e

REPO_URL="https://github.com/HMPIWD/blacknwhitehmpdot.git"
INSTALL_DIR="$HOME/.local/share/blacknwhitehmpdot"

echo "=== blacknwhitehmpdot installer ==="

# ==========================================================
# REQUIREMENTS
# ==========================================================

if ! command -v git &>/dev/null; then
    echo "→ Installing git..."
    sudo pacman -S --needed --noconfirm git
fi

# ==========================================================
# CLONE DOTFILES
# ==========================================================

if [ ! -d "$INSTALL_DIR" ]; then
    echo "→ Cloning dotfiles repository"
    git clone "$REPO_URL" "$INSTALL_DIR"
else
    echo "→ Dotfiles repo already exists, updating"
    git -C "$INSTALL_DIR" pull
fi

cd "$INSTALL_DIR"

# ==========================================================
# YAY
# ==========================================================

echo "=== Checking for yay ==="

if ! command -v yay &>/dev/null; then
    echo "→ yay not found, installing..."

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

# ==========================================================
# SYSTEM DEPENDENCIES
# ==========================================================

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
    polkit-kde-agent \
    gnome-keyring

# ==========================================================
# HYPRPANEL (KNOWN GOOD VERSION)
# ==========================================================

echo "=== Installing Hyprpanel (ags-hyprpanel-git) ==="
yay -S --needed --noconfirm ags-hyprpanel-git

# ==========================================================
# FONT INSTALL
# ==========================================================

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

# ==========================================================
# FONTCONFIG
# ==========================================================

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

# ==========================================================
# BACKUP
# ==========================================================

echo "=== Backing up existing configs ==="
BACKUP_DIR="$HOME/.config/backup_$(date +%F_%H-%M)"
mkdir -p "$BACKUP_DIR"

backup() {
    [ -d "$HOME/.config/$1" ] && cp -r "$HOME/.config/$1" "$BACKUP_DIR/"
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

# ==========================================================
# COPY CONFIGS
# ==========================================================

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

if [ -d "$INSTALL_DIR/kvantum" ]; then
    mkdir -p "$HOME/.config/Kvantum"
    cp -r "$INSTALL_DIR/kvantum"/* "$HOME/.config/Kvantum/"
fi

# ==========================================================
# KVANTUM ACTIVATE
# ==========================================================

if command -v kvantummanager &>/dev/null; then
    THEME=$(ls "$INSTALL_DIR/kvantum" 2>/dev/null | head -n 1)
    [ -n "$THEME" ] && kvantummanager --set "$THEME"
fi

# ==========================================================
# DONE
# ==========================================================

echo "=== INSTALL COMPLETE ==="
echo "✔ Backups: $BACKUP_DIR"
echo "➡ Reboot or re-login recommended"
