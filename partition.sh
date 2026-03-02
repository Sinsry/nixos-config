#!/usr/bin/env bash

# ============================================================
#  Mode dry-run (true = simulation, false = réel)
# ============================================================
DRY_RUN=true

# ============================================================
#  Couleurs & helpers
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${BLUE}[•]${RESET} $*"; }
success() { echo -e "${GREEN}[✔]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[!]${RESET} $*"; }
error()   { echo -e "${RED}[✘]${RESET} $*"; }
step()    { echo -e "\n${BOLD}${CYAN}── $* ${RESET}"; }
hr()      { echo -e "${CYAN}$(printf '─%.0s' {1..45})${RESET}"; }
run()     {
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}[DRY-RUN]${RESET} $*"
    else
        "$@"
    fi
}

# ============================================================
#  Vérification des droits root
# ============================================================
if [[ $EUID -ne 0 ]]; then
    warn "Droits root requis, relancement en sudo..."
    exec sudo bash "$0" -- "$@"
fi

# ============================================================
#  Bannière
# ============================================================
clear
hr
echo -e "${BOLD}${CYAN}   NixOS — Partitionnement${RESET}"
hr
if [[ "$DRY_RUN" == true ]]; then
    echo -e "\n  ${YELLOW}${BOLD}⚠️  MODE DRY-RUN — aucune commande ne sera exécutée${RESET}\n"
fi
echo ""

# ============================================================
#  Choix du type de swap
# ============================================================
echo -e "${BOLD}Type de swap :${RESET}"
echo -e "  ${CYAN}1)${RESET} Partition swap"
echo -e "  ${CYAN}2)${RESET} Swapfile"
echo -e "  ${CYAN}3)${RESET} Pas de swap"
echo ""
read -p "$(echo -e ${BOLD}"Ton choix [1/2/3] : "${RESET})" -n 1 -r SWAP_TYPE
echo ""

if [[ "$SWAP_TYPE" == "1" ]] || [[ "$SWAP_TYPE" == "2" ]]; then
    echo ""
    echo -e "${BOLD}Taille de la swap :${RESET}"
    echo -e "  ${CYAN}1)${RESET} 8GB"
    echo -e "  ${CYAN}2)${RESET} 16GB"
    echo -e "  ${CYAN}3)${RESET} 32GB"
    echo -e "  ${CYAN}4)${RESET} 64GB"
    echo ""
    read -p "$(echo -e ${BOLD}"Ton choix [1/2/3/4] : "${RESET})" -n 1 -r SWAP_SIZE_CHOICE
    echo ""
    case $SWAP_SIZE_CHOICE in
        1) SWAP_SIZE="8GB"  ;;
        2) SWAP_SIZE="16GB" ;;
        3) SWAP_SIZE="32GB" ;;
        4) SWAP_SIZE="64GB" ;;
        *) error "Choix invalide." ; exit 1 ;;
    esac
    success "Swap : ${BOLD}$SWAP_SIZE${RESET}"
fi

case $SWAP_TYPE in
    1) success "Type swap : ${BOLD}Partition${RESET}" ;;
    2) success "Type swap : ${BOLD}Swapfile${RESET}" ;;
    3) success "Type swap : ${BOLD}Aucune${RESET}" ;;
    *) error "Choix invalide." ; exit 1 ;;
esac

# ============================================================
#  Choix du disque
# ============================================================
echo -e "${BOLD}Disques disponibles :${RESET}"
echo ""
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
echo ""
read -p "$(echo -e ${BOLD}"Disque cible (ex: sda, vda) : /dev/${RESET}")" DISK
DISK="/dev/$DISK"

if [[ ! -b "$DISK" ]]; then
    error "Disque '$DISK' introuvable !"
    exit 1
fi

echo ""
echo -e "  Disque sélectionné : ${BOLD}${CYAN}$DISK${RESET}"
echo ""

# ============================================================
#  Confirmation — opération destructive !
# ============================================================
warn "ATTENTION : toutes les données sur ${BOLD}$DISK${RESET} seront effacées !"
echo ""
read -p "$(echo -e ${RED}${BOLD}"Confirmer ? [y/N] "${RESET})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    error "Annulé."
    exit 1
fi

# ============================================================
#  Partitionnement
# ============================================================

step "1/4 — Création de la table de partition GPT"
run parted "$DISK" -- mklabel gpt
success "Table GPT créée"

step "2/4 — Partition EFI (1MB → 1024MB)"
run parted "$DISK" -- mkpart ESP fat32 1MB 1024MB
run parted "$DISK" -- set 1 esp on
success "Partition EFI créée et flag esp activé"

if [[ "$SWAP_TYPE" == "1" ]]; then
    step "3/4 — Partition root (1024MB → -$SWAP_SIZE)"
    run parted "$DISK" -- mkpart root ext4 1024MB -$SWAP_SIZE
    success "Partition root créée"

    step "3b/4 — Partition swap (-$SWAP_SIZE → 100%)"
    run parted "$DISK" -- mkpart swap linux-swap -$SWAP_SIZE 100%
    success "Partition swap créée"
else
    step "3/4 — Partition root (1024MB → 100%)"
    run parted "$DISK" -- mkpart root ext4 1024MB 100%
    success "Partition root créée"
fi

step "4/4 — Formatage"
# Détecter le nom des partitions (sda1 ou vda1 etc.)
if [[ "$DISK" =~ nvme ]]; then
    EFI="${DISK}p1"
    ROOT="${DISK}p2"
    SWAP="${DISK}p3"
else
    EFI="${DISK}1"
    ROOT="${DISK}2"
    SWAP="${DISK}3"
fi

run mkfs.fat -F32 "$EFI"
success "EFI formatée en fat32 → $EFI"

run mkfs.ext4 -L root "$ROOT"
success "Root formatée en ext4 → $ROOT"

if [[ "$SWAP_TYPE" == "1" ]]; then
    run mkswap "$SWAP"
    success "Swap formatée → $SWAP"
fi

# ============================================================
#  Montage
# ============================================================

step "Montage des partitions"
run mount "$ROOT" /mnt
run mkdir -p /mnt/boot
run mount "$EFI" /mnt/boot

if [[ "$SWAP_TYPE" == "1" ]]; then
    run swapon "$SWAP"
    success "Swap activée → $SWAP"
fi

success "Partitions montées"
echo ""
echo -e "  ${CYAN}$ROOT${RESET} → /mnt"
echo -e "  ${CYAN}$EFI${RESET}  → /mnt/boot"
if [[ "$SWAP_TYPE" == "1" ]]; then
    echo -e "  ${CYAN}$SWAP${RESET} → swap"
fi

# Swapfile
if [[ "$SWAP_TYPE" == "2" ]]; then
    step "Création du swapfile ($SWAP_SIZE)"
    SWAP_BYTES=$(echo $SWAP_SIZE | sed 's/GB//')
    run dd if=/dev/zero of=/mnt/swapfile bs=1G count=$SWAP_BYTES status=progress
    run chmod 600 /mnt/swapfile
    run mkswap /mnt/swapfile
    run swapon /mnt/swapfile
    success "Swapfile créé et activé → /mnt/swapfile"
    echo -e "  ${CYAN}/mnt/swapfile${RESET} → swap ($SWAP_SIZE)"
fi

# ============================================================
#  Fin
# ============================================================
echo ""
hr
echo -e "${GREEN}${BOLD}  ✅  Partitionnement terminé !${RESET}"
hr
echo ""
echo -e "  Tu peux maintenant lancer ${BOLD}./setup-nixos.sh${RESET}"
echo ""
