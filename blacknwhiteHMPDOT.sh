#!/bin/bash
set -e

echo "=== Checking for yay ==="

if ! command -v yay &>/dev/null; then
    echo "→ yay not found, installing..."

    sudo pacman -S --needed --noconfirm git base-devel

    TMP_DIR="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$TMP_DIR/yay"
    cd "$TMP_DIR/yay"

    makepkg -si --noconfirm

    cd ~
    rm -rf "$TMP_DIR"

    echo "✔ yay installed"
else
    echo "✔ yay is already installed"
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
# HYPRPANEL (LOCKED VERSION)
# ==========================================================

echo "=== Installing Hyprpanel (ags-hyprpanel-git) ==="
yay -S --needed --noconfirm ags-hyprpanel-git

# ==========================================================
# FONT INSTALL (Azeret Mono Variable)
# ==========================================================

echo "=== Installing Azeret Mono system font ==="

FONT_SRC="./fonts/AzeretMono-VariableFont_wght.ttf"
FONT_DEST="/usr/share/fonts/TTF"

if [ -f "$FONT_SRC" ]; then
    sudo mkdir -p "$FONT_DEST"
    sudo cp "$FONT_SRC" "$FONT_DEST/"
    echo "✔ Font copied to $FONT_DEST"
else
    echo "✖ Font file not found: $FONT_SRC"
    exit 1
fi

sudo fc-cache -fv

# ==========================================================
# FONTCONFIG (system monospace)
# ==========================================================

echo "=== Configuring system monospace font ==="

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
# CONFIG BACKUP
# ==========================================================

echo "=== Creating config backup ==="
BACKUP_DIR="$HOME/.config/backup_$(date +%F_%H-%M)"
mkdir -p "$BACKUP_DIR"

backup_if_exists() {
    if [ -d "$HOME/.config/$1" ]; then
        echo "→ Backup $1"
        cp -r "$HOME/.config/$1" "$BACKUP_DIR/"
    fi
}

backup_if_exists hypr
backup_if_exists hyprpanel
backup_if_exists alacritty
backup_if_exists gtk-4.0
backup_if_exists gtk-5.0
backup_if_exists Kvantum
backup_if_exists qt5ct
backup_if_exists qt6ct
backup_if_exists rofi

# ==========================================================
# COPY CONFIGS
# ==========================================================

echo "=== Copying new configs ==="

copy_cfg() {
    SRC="$1"
    DEST="$HOME/.config/$2"

    if [ -d "$SRC" ]; then
        mkdir -p "$DEST"
        echo "→ Copying $SRC → $DEST"
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

if [ -d kvantum ]; then
    mkdir -p "$HOME/.config/Kvantum"
    echo "→ Copying Kvantum themes"
    cp -r kvantum/* "$HOME/.config/Kvantum/"
fi

# ==========================================================
# ACTIVATE KVANTUM
# ==========================================================

echo "=== Activating Kvantum themes ==="
if command -v kvantummanager &>/dev/null; then
    THEME=$(ls kvantum 2>/dev/null | head -n 1)
    if [ -n "$THEME" ]; then
        kvantummanager --set "$THEME"
    fi
fi

# ==========================================================
# DONE
# ==========================================================

echo "=== DONE ==="
echo "✔ Azeret Mono is now system monospace"
echo "✔ Backups stored in: $BACKUP_DIR"
echo "➡ Reboot or re-login for full effect"
