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
echo -e "${BLUE}[1/7] Проверка наличия Git...${NC}"
if ! command -v git &> /dev/null; then
    echo -e "${RED}Git не найден. Выполняю автоматическую установку...${NC}"
    # Обновляем базы данных пакетов и ставим git
    sudo pacman -Sy --noconfirm git
    
    if ! command -v git &> /dev/null; then
        echo -e "${RED}ОШИБКА: Не удалось установить Git. Проверьте интернет-соединение.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Git успешно установлен!${NC}"
else
    echo -e "${GREEN}Git уже установлен.${NC}"
fi

# ---------------------------------------------------
# 2. ПРОВЕРКА И УСТАНОВКА YAY (AUR Helper)
# ---------------------------------------------------
echo -e "${BLUE}[2/7] Проверка AUR helper...${NC}"
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
echo -e "${BLUE}[3/7] Полное обновление системы...${NC}"
sudo pacman -Syu --noconfirm

# ---------------------------------------------------
# 4. УСТАНОВКА ЗАВИСИМОСТЕЙ (Для твоих конфигов)
# ---------------------------------------------------
echo -e "${BLUE}[4/7] Установка зависимостей для дотфайлов...${NC}"
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
# 5. УСТАНОВКА СОФТА (Pacman & AUR)
# ---------------------------------------------------
echo -e "${BLUE}[5/7] Установка приложений...${NC}"

# Список для Pacman
PACMAN_APPS=(
    "steam"
    "discord"
    "obs-studio"
    "vscodium" 
    "ayugram-desktop"
)

for app in "${PACMAN_APPS[@]}"; do
    if sudo pacman -S --needed --noconfirm "$app"; then
        echo -e "${GREEN}[OK] $app${NC}"
    else
        echo -e "${RED}[SKIP] $app не найден в pacman, попробуем через AUR.${NC}"
    fi
done

# Список для AUR
YAY_APPS=(
    "github-desktop-bin"
    "proton-vpn-gtk"
    "hyprpanel-bin"
)

# Проверяем, если ayugram не встал через pacman, добавляем его в список для yay
if ! command -v ayugram-desktop &> /dev/null; then
    YAY_APPS+=("ayugram-desktop-bin")
fi

$AUR_HELPER -S --needed --noconfirm "${YAY_APPS[@]}"

# ---------------------------------------------------
# 6. БЕКАП И ЗАГРУЗКА ДОТФАЙЛОВ
# ---------------------------------------------------
echo -e "${BLUE}[6/7] Скачивание твоего конфига с GitHub...${NC}"

# Чистим временную папку, если была
rm -rf "$TEMP_DIR"

# КЛОНИРУЕМ ТВОЙ РЕПОЗИТОРИЙ
git clone "$REPO_URL" "$TEMP_DIR"

if [ ! -d "$TEMP_DIR" ]; then
    echo -e "${RED}ОШИБКА: Не удалось скачать репозиторий. Проверь ссылку в скрипте!${NC}"
    exit 1
fi

echo -e "${BLUE}Приступаем к замене конфигов...${NC}"
mkdir -p "$BACKUP_DIR"

# Список папок, которые копируем
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
        # Бекап старого, если есть
        if [ -e "$dest" ]; then
            echo -e "  -> Бекап старого $item в $BACKUP_DIR..."
            mv "$dest" "$BACKUP_DIR/"
        fi
        
        # Копирование нового
        echo -e "${GREEN}  -> Установка $item${NC}"
        cp -r "$src" "$CONFIG_DIR/"
    else
        echo -e "${RED}  -> Внимание: $item нет в скачанном репозитории.${NC}"
    fi
done

# Удаляем временную папку
rm -rf "$TEMP_DIR"

# ---------------------------------------------------
# 7. ЗАВЕРШЕНИЕ
# ---------------------------------------------------
echo -e "${BLUE}[7/7] Готово!${NC}"
echo -e "Старые конфиги лежат в: ${GREEN}$BACKUP_DIR${NC}"
echo -e "Теперь можно перезагрузиться или перезайти в Hyprland."
