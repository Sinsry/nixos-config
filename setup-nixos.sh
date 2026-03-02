#!/usr/bin/env nix-shell
#! nix-shell -i bash -p git openssl

# ============================================================
#  Mode dry-run (true = simulation, false = réel)
# ============================================================
DRY_RUN=false

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
#  Bannière
# ============================================================
clear
hr
echo -e "${BOLD}${CYAN}   NixOS — Script d'installation universel${RESET}"
hr
if [[ "$DRY_RUN" == true ]]; then
    echo -e "\n  ${YELLOW}${BOLD}⚠️  MODE DRY-RUN — aucune commande ne sera exécutée${RESET}\n"
fi

# ============================================================
#  Dépendances
# ============================================================
if ! command -v openssl &> /dev/null; then
    info "openssl non trouvé, installation..."
    nix-env -iA nixos.openssl
fi

# ============================================================
#  Détection du mode
# ============================================================
echo ""
echo -e "${BOLD}Mode d'installation :${RESET}"
echo -e "  ${CYAN}1)${RESET} Live ISO         — installation depuis zéro"
echo -e "  ${CYAN}2)${RESET} Système existant — post-installation"
echo ""
read -p "$(echo -e ${BOLD}"Ton choix [1/2] : "${RESET})" -n 1 -r MODE_CHOICE
echo ""

if [[ "$MODE_CHOICE" == "1" ]]; then
    MODE="liveiso"
    success "Mode sélectionné : ${BOLD}Live ISO${RESET}"
    if [[ $EUID -ne 0 ]]; then
        error "Le mode Live ISO doit être lancé en root !"
        error "Relance avec : sudo ./setup-install.sh"
        exit 1
    fi
elif [[ "$MODE_CHOICE" == "2" ]]; then
    MODE="existing"
    success "Mode sélectionné : ${BOLD}Système existant${RESET}"
    if [[ $EUID -eq 0 ]]; then
        error "Le mode Système existant doit être lancé sans root !"
        error "Relance sans sudo : ./nixos-install.sh"
        exit 1
    fi
    echo ""
    warn "À lancer APRÈS l'installation graphique ET APRÈS le redémarrage !"
    echo ""
    read -p "$(echo -e ${YELLOW}"L'installation graphique est terminée ? [y/N] "${RESET})" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Lance d'abord l'installeur graphique !"
        exit 1
    fi
else
    error "Choix invalide."
    exit 1
fi

# ============================================================
#  Détection du host
# ============================================================
echo ""
VALID_HOSTS=("maousse" "travail" "jarvis" "valheim" "VM")

echo -e "${BOLD}Hosts disponibles :${RESET}"
for i in "${!VALID_HOSTS[@]}"; do
    if [[ $i -eq $((${#VALID_HOSTS[@]}-1)) ]]; then
        echo -e "  ${CYAN}99)${RESET} ${VALID_HOSTS[$i]}"
    else
        echo -e "   ${CYAN}$((i+1)))${RESET} ${VALID_HOSTS[$i]}"
    fi
done
echo ""

read -p "$(echo -e ${BOLD}"Ton choix : "${RESET})" HOST_CHOICE
echo ""

if [[ "$HOST_CHOICE" == "99" ]]; then
    HOST="${VALID_HOSTS[-1]}"
elif [[ "$HOST_CHOICE" -lt 1 || "$HOST_CHOICE" -gt "$((${#VALID_HOSTS[@]}-1))" ]]; then
    error "Choix invalide."
    exit 1
else
    HOST="${VALID_HOSTS[$((HOST_CHOICE-1))]}"
fi
if [[ "$HOST_CHOICE" == "99" ]]; then
    NBHOST="99"
else
    NBHOST=$(printf "%02d" "$HOST_CHOICE")
fi
# echo ""
read -p "$(echo -e ${YELLOW}"Confirmer ? [y/N] "${RESET})" -n 1 -r
echo ""
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    error "Annulé."
    exit 1
fi
success "             Host : ${BOLD}$HOST${RESET}"
success "Répertoire config : ${BOLD}$NBHOST-$HOST${RESET}"

# ============================================================
#  Nom d'utilisateur
# ============================================================
echo ""
read -p "$(echo -e ${BOLD}"Nom d'utilisateur [défaut : sinsry] : "${RESET})" TARGET_USER
TARGET_USER="${TARGET_USER:-sinsry}"
echo ""
echo -e "  Utilisateur : ${BOLD}${CYAN}$TARGET_USER${RESET}"
echo ""
read -p "$(echo -e ${YELLOW}"Confirmer ? [y/N] "${RESET})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    error "Annulé."
    exit 1
fi
success "Utilisateur : ${BOLD}$TARGET_USER${RESET}"

# ============================================================
#  Branchement selon le mode
# ============================================================

if [[ "$MODE" == "existing" ]]; then

    # ==========================================================
    #  MODE SYSTÈME EXISTANT
    # ==========================================================

    step "1/9 — Sauvegarde hardware-configuration.nix"
    run sudo cp /etc/nixos/hardware-configuration.nix /tmp/hardware-configuration.nix.backup
    success "Sauvegardé dans /tmp/hardware-configuration.nix.backup"

    step "2/9 — Sauvegarde complète de /etc/nixos"
    run sudo cp -r /etc/nixos /etc/nixos.backup
    success "Sauvegarde dans /etc/nixos.backup"

    step "3/9 — Nettoyage de /etc/nixos"
    run sudo rm -rf /etc/nixos/*
    run sudo rm -rf /etc/nixos/.git* 2>/dev/null || true
    success "Dossier vidé"

    step "4/9 — Copie de la configuration"
    run sudo cp -Rf . /etc/nixos
    run sudo chown -R 1000:100 /etc/nixos
    success "Configuration copiée"

    step "5/9 — Restauration du hardware-configuration.nix"
    run sudo cp /tmp/hardware-configuration.nix.backup /etc/nixos/hosts/$NBHOST-$HOST/hardware-configuration.nix
    success "Restauré dans hosts/$HOST/"

    step "6/9 — Configuration SSH (déchiffrement des clés)"
    run openssl enc -aes-256-cbc -pbkdf2 -d \
        -in /etc/nixos/asset/ssh-keys.enc \
        -out /home/$TARGET_USER/ssh-backup.tar.gz
    run sudo chown 1000:100 /home/$TARGET_USER/ssh-backup.tar.gz
    run mkdir -p /home/$TARGET_USER/.ssh
    run tar xzf /home/$TARGET_USER/ssh-backup.tar.gz -C /home/$TARGET_USER/
    run sudo chown -R 1000:100 /home/$TARGET_USER/.ssh
    run sudo chmod 600 /home/$TARGET_USER/.ssh/id_ed25519
    run sudo chmod 644 /home/$TARGET_USER/.ssh/id_ed25519.pub
    success "Clés SSH configurées pour $TARGET_USER"

    step "7/9 — Copie des clés SSH pour root"
    run sudo mkdir -p /root/.ssh
    run sudo cp /home/$TARGET_USER/.ssh/id_ed25519* /root/.ssh/
    run sudo chown -R root:users /root/.ssh
    run sudo chmod 600 /root/.ssh/id_ed25519
    run sudo chmod 644 /root/.ssh/id_ed25519.pub
    success "Clés SSH configurées pour root"

    step "8/9 — Droits et configuration Git"
    run sudo chown -R 1000:100 /etc/nixos
    run sudo -u $TARGET_USER git -C /etc/nixos remote set-url origin git@github.com:Sinsry/nixos-config.git
    cat > /home/$TARGET_USER/.gitconfig << EOF
[user]
    name = Sinsry
    email = 113318091+Sinsry@users.noreply.github.com
[pull]
    rebase = true
[safe]
    directory = /etc/nixos
EOF
    sudo cp /home/$TARGET_USER/.gitconfig /root
    success "Git configuré"

    step "9/9 — Mise à jour du flake et rebuild"
    info "Mise à jour des inputs du flake..."
    run sudo -u $TARGET_USER nix --extra-experimental-features 'nix-command flakes' flake update /etc/nixos
    run sudo -u $TARGET_USER git -C /etc/nixos add .
    run sudo -u $TARGET_USER git -C /etc/nixos commit -m "auto: update flake.lock" || true
    info "Rebuild en cours pour ${BOLD}$HOST${RESET}..."
    run sudo NIXOS_HOST="$HOST" nixos-rebuild boot --flake /etc/nixos#$HOST
    info "Push vers GitHub..."
    run sudo -u $TARGET_USER git -C /etc/nixos push

elif [[ "$MODE" == "liveiso" ]]; then

    # ==========================================================
    #  MODE LIVE ISO
    # ==========================================================

    NIXOS_REPO="https://github.com/Sinsry/nixos-config.git"
    TARGET="/mnt"
    NIXOS_TARGET="$TARGET/etc/nixos"

    echo ""
    warn "Assure-toi que tes partitions sont déjà formatées et montées :"
    echo -e "    ${CYAN}•${RESET} Partition root  → montée dans ${BOLD}/mnt${RESET}"
    echo -e "    ${CYAN}•${RESET} Partition EFI   → montée dans ${BOLD}/mnt/boot${RESET}"
    echo ""
    read -p "$(echo -e ${YELLOW}"Les partitions sont montées dans /mnt ? [y/N] "${RESET})" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Monte tes partitions dans /mnt d'abord !"
        exit 1
    fi

    step "1/8 — Génération du hardware-configuration.nix"
    run nixos-generate-config --root $TARGET
    success "hardware-configuration.nix généré dans $TARGET/etc/nixos/"

    step "2/8 — Sauvegarde du hardware-configuration.nix"
    run cp $TARGET/etc/nixos/hardware-configuration.nix /tmp/hardware-configuration.nix.backup
    success "Sauvegardé dans /tmp/hardware-configuration.nix.backup"

    step "3/8 — Clone de la configuration NixOS"
    run git clone $NIXOS_REPO /tmp/nixos-config
    success "Repo cloné dans /tmp/nixos-config"

    step "4/8 — Copie de la configuration dans /mnt/etc/nixos"
    run rm -rf $NIXOS_TARGET
    run mkdir -p $NIXOS_TARGET
    run cp -Rf /tmp/nixos-config/. $NIXOS_TARGET

    success "Configuration copiée dans $NIXOS_TARGET"

    step "5/8 — Restauration du hardware-configuration.nix"
    run cp /tmp/hardware-configuration.nix.backup $NIXOS_TARGET/hosts/$NBHOST-$HOST/hardware-configuration.nix
    success "Restauré dans /mnt/hosts/$NBHOST-$HOST/"

    step "6/8 — Déchiffrement des clés SSH"
    run openssl enc -aes-256-cbc -pbkdf2 -d \
        -in $NIXOS_TARGET/asset/ssh-keys.enc \
        -out /tmp/ssh-backup.tar.gz
    run mkdir -p /tmp/ssh-extracted
    run tar xzf /tmp/ssh-backup.tar.gz -C /tmp/ssh-extracted/

    # Clés pour root
    run mkdir -p $TARGET/root/.ssh
    run cp /tmp/ssh-extracted/.ssh/id_ed25519* $TARGET/root/.ssh/
    run chmod 600 $TARGET/root/.ssh/id_ed25519
    run chmod 644 $TARGET/root/.ssh/id_ed25519.pub
    run cp /tmp/ssh-extracted/.ssh/id_ed25519* /root/.ssh/
    run chmod 600 /root/.ssh/id_ed25519
    run chmod 644 /root/.ssh/id_ed25519.pub
    success "Clés SSH placées pour root"

    # Clés pour l'utilisateur
    run mkdir -p $TARGET/home/$TARGET_USER/.ssh
    run cp /tmp/ssh-extracted/.ssh/id_ed25519* $TARGET/home/$TARGET_USER/.ssh/
    run chmod 700 $TARGET/home/$TARGET_USER/.ssh
    run chmod 600 $TARGET/home/$TARGET_USER/.ssh/id_ed25519
    run chmod 644 $TARGET/home/$TARGET_USER/.ssh/id_ed25519.pub
    success "Clés SSH placées pour $TARGET_USER"

    step "7/8 — Droits et configuration Git"
    run chown -R 1000:100 $NIXOS_TARGET
    run git -C $NIXOS_TARGET remote set-url origin git@github.com:Sinsry/nixos-config.git
    run mkdir -p $TARGET/home/$TARGET_USER
    cat > $TARGET/home/$TARGET_USER/.gitconfig << EOF
[user]
    name = Sinsry
    email = 113318091+Sinsry@users.noreply.github.com
[pull]
    rebase = true
[safe]
    directory = /etc/nixos
EOF
    run chown -R 1000:100 $TARGET/home/$TARGET_USER || true
    success "Git configuré pour $TARGET_USER"

    step "8/8 — Installation de NixOS"
    info "nixos-install en cours pour ${BOLD}$HOST${RESET}..."
    run nixos-install --flake $NIXOS_TARGET#$HOST --no-root-passwd
    info "Push vers GitHub..."
    run chown -R 1000:100 $NIXOS_TARGET
    run GIT_SSH_COMMAND="ssh -i /root/.ssh/id_ed25519" git -C $NIXOS_TARGET push
    success "Installation terminée !"

fi

# ============================================================
#  Fin
# ============================================================
echo ""
hr
echo -e "${GREEN}${BOLD}  ✅  Terminé avec succès !${RESET}"
hr
echo ""
if [[ "$MODE" == "existing" ]]; then
    echo -e "  Tu dois redémarrer pour profiter de ton système complet 🎉"
elif [[ "$MODE" == "liveiso" ]]; then
    echo -e "  Tu peux redémarrer et retirer le live ISO 🎉"
fi
echo ""
