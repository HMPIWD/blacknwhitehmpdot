#!/bin/bash

# ==========================================
# ВАЖНО: ВСТАВЬ СЮДА ССЫЛКУ НА ТВОЙ РЕПОЗИТОРИЙ
REPO_URL="https://github.com/HMPIWD/blacknwhitehmpdot.git"
# ==========================================

CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup/$(date +%Y%m%d_%H%M%S)"
TEMP_DIR="$HOME/tmp_dotfiles_install"

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

clear
echo -e "${BLUE}=== CachyOS Hyprland Installer ===${NC}"

# ---------------------------------------------------
# 1. АВТОМАТИЧЕСКАЯ УСТАНОВКА GIT
# ---------------------------------------------------
echo -e "${BLUE}[1/8] Проверка наличия Git...${NC}"
if ! command -v git &> /dev/null; then
    echo -e "${RED}Git не найден. Выполняю автоматическую установку...${NC}"
    sudo pacman -Sy --noconfirm git
    if ! command -v git &> /dev/null; then
        echo -e "${RED}ОШИБКА: Не удалось установить Git.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Git успешно установлен!${NC}"
else
    echo -e "${GREEN}Git уже установлен.${NC}"
fi

# ---------------------------------------------------
# 2. ПРОВЕРКА И УСТАНОВКА YAY
# ---------------------------------------------------
echo -e "${BLUE}[2/8] Проверка AUR helper...${NC}"
AUR_HELPER="yay"
if ! command -v yay &> /dev/null; then
    if command -v paru &> /dev/null; then
        AUR_HELPER="paru"
        echo -e "${GREEN}Обнаружен paru. Будем использовать его.${NC}"
    else
        echo -e "${RED}AUR helper не найден. Устанавливаю yay...${NC}"
        sudo pacman -S --needed --noconfirm base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd ~
        rm -rf /tmp/yay
        echo -e "${GREEN}Yay установлен.${NC}"
    fi
fi

# ---------------------------------------------------
# 3. ОБНОВЛЕНИЕ СИСТЕМЫ
# ---------------------------------------------------
echo -e "${BLUE}[3/8] Полное обновление системы...${NC}"
sudo pacman -Syu --noconfirm

# ---------------------------------------------------
# 4. УСТАНОВКА ЗАВИСИМОСТЕЙ
# ---------------------------------------------------
echo -e "${BLUE}[4/8] Установка зависимостей для дотфайлов...${NC}"
DEPENDENCIES=(
    "hyprland"
    "hyprlock"
    "hyprpaper"
    "hypridle"
    "rofi-wayland"
    "kvantum"
    "qt5ct"
    "qt6ct"
    "alacritty"
    "dolphin"
    "ttf-jetbrains-mono-nerd"
    "noto-fonts-emoji"
    "papirus-icon-theme"
    "nwg-look"
)
sudo pacman -S --needed --noconfirm "${DEPENDENCIES[@]}"

# ---------------------------------------------------
# 5. УСТАНОВКА СОФТА
# ---------------------------------------------------
echo -e "${BLUE}[5/8] Установка приложений...${NC}"
PACMAN_APPS=("steam" "discord" "obs-studio" "vscodium" "ayugram-desktop")

for app in "${PACMAN_APPS[@]}"; do
    if sudo pacman -S --needed --noconfirm "$app"; then
        echo -e "${GREEN}[OK] $app${NC}"
    else
        echo -e "${RED}[SKIP] $app не найден в pacman, попробуем через AUR.${NC}"
    fi
done

YAY_APPS=("github-desktop-bin" "proton-vpn-gtk" "hyprpanel-bin")
if ! command -v ayugram-desktop &> /dev/null; then YAY_APPS+=("ayugram-desktop-bin"); fi

$AUR_HELPER -S --needed --noconfirm "${YAY_APPS[@]}"

# ---------------------------------------------------
# 6. КЛОНИРОВАНИЕ РЕПОЗИТОРИЯ
# ---------------------------------------------------
echo -e "${BLUE}[6/8] Скачивание конфига...${NC}"
rm -rf "$TEMP_DIR"
git clone "$REPO_URL" "$TEMP_DIR"

if [ ! -d "$TEMP_DIR" ]; then
    echo -e "${RED}ОШИБКА: Не удалось скачать репозиторий.${NC}"
    exit 1
fi

# ---------------------------------------------------
# 7. УСТАНОВКА КАСТОМНОГО ШРИФТА
# ---------------------------------------------------
echo -e "${BLUE}[7/8] Установка шрифта AzeretMono...${NC}"

# Путь к шрифту в скачанном репо
FONT_SRC="$TEMP_DIR/fonts/AzeretMono-VariableFont_wght.ttf"
# Куда копировать
FONT_DEST_DIR="/usr/share/fonts"
FONT_DEST_FILE="$FONT_DEST_DIR/AzeretMono-VariableFont_wght.ttf"

if [ -f "$FONT_SRC" ]; then
    # Копируем с правами root
    echo -e "Копирую шрифт в системную директорию..."
    sudo cp "$FONT_SRC" "$FONT_DEST_FILE"
    
    # Обновляем кэш шрифтов
    echo -e "Обновляю кэш шрифтов..."
    fc-cache -f
    echo -e "${GREEN}Шрифт успешно установлен!${NC}"
else
    echo -e "${RED}ВНИМАНИЕ: Файл шрифта не найден по пути: fonts/AzeretMono-VariableFont_wght.ttf${NC}"
    echo -e "Проверьте структуру папок в репозитории."
fi

# ---------------------------------------------------
# 8. ЗАМЕНА КОНФИГОВ
# ---------------------------------------------------
echo -e "${BLUE}[8/8] Применение конфигов...${NC}"
mkdir -p "$BACKUP_DIR"

ITEMS_TO_COPY=(
    "Kvantum"
    "alacritty"
    "dolphinrc"
    "gtk-3.0"
    "gtk-4.0"
    "hypr"
    "hyprpanel"
    "qt5ct"
    "qt6ct"
    "rofi"
)

for item in "${ITEMS_TO_COPY[@]}"; do
    src="$TEMP_DIR/$item"
    dest="$CONFIG_DIR/$item"
    
    if [ -e "$src" ]; then
        if [ -e "$dest" ]; then
            echo -e "  -> Бекап: $item"
            mv "$dest" "$BACKUP_DIR/"
        fi
        echo -e "${GREEN}  -> Установка: $item${NC}"
        cp -r "$src" "$CONFIG_DIR/"
    else
        echo -e "${RED}  -> Пропуск: $item не найден в репо.${NC}"
    fi
done

rm -rf "$TEMP_DIR"

echo -e "${BLUE}=== Готово! ===${NC}"
echo -e "Бекапы лежат в: ${GREEN}$BACKUP_DIR${NC}"
echo -e "Шрифт установлен, программы скачаны."
echo -e "Перезагрузите компьютер. (reboot)"
