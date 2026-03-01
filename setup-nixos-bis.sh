#!/usr/bin/env nix-shell
#! nix-shell -i bash -p git openssl

# ============================================================
#  Mode dry-run (true = simulation, false = réel)
# ============================================================
DRY_RUN=false

# ================================s============================
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
echo -e "${BOLD}${CYAN}   NixOS — Configuration post-installation${RESET}"
hr
if [[ "$DRY_RUN" == true ]]; then
    echo -e "\n  ${YELLOW}${BOLD}⚠️  MODE DRY-RUN — aucune commande ne sera exécutée${RESET}\n"
fi
echo ""
warn "Lance ce script APRÈS l'installation graphique ET APRÈS le redémarrage !"
echo ""
read -p "$(echo -e ${YELLOW}"L'installation graphique est terminée ? [y/N] "${RESET})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    error "Lance d'abord l'installeur graphique !"
    exit 1
fi

# ============================================================
#  Détection du host
# ============================================================
echo ""
VALID_HOSTS=("maousse" "travail" "jarvis" "valheim")

echo -e "${BOLD}Hosts disponibles :${RESET}"
for h in "${VALID_HOSTS[@]}"; do
    echo -e "  ${CYAN}•${RESET} $h"
done
echo ""

read -p "$(echo -e ${BOLD}"Nom du host à installer : "${RESET})" HOST

if [[ ! " ${VALID_HOSTS[@]} " =~ " $HOST " ]]; then
    error "Host '$HOST' inconnu. Valides : ${VALID_HOSTS[*]}"
    exit 1
fi

success "Host sélectionné : ${BOLD}$HOST${RESET}"

# ============================================================
#  Étapes
# ============================================================

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
success "Configuration copiée"

step "5/9 — Restauration du hardware-configuration.nix"
run sudo cp /tmp/hardware-configuration.nix.backup /etc/nixos/hosts/$HOST/hardware-configuration.nix
success "Restauré dans hosts/$HOST/"

step "6/9 — Configuration SSH (déchiffrement des clés)"
run openssl enc -aes-256-cbc -pbkdf2 -d \
    -in /etc/nixos/asset/ssh-keys.enc \
    -out /home/$USER/ssh-backup.tar.gz
run sudo chown $USER:users /home/$USER/ssh-backup.tar.gz
run mkdir -p /home/$USER/.ssh
run tar xzf /home/$USER/ssh-backup.tar.gz -C /home/$USER/
run sudo chown -R $USER:users /home/$USER/.ssh
run sudo chmod 600 /home/$USER/.ssh/id_ed25519
run sudo chmod 644 /home/$USER/.ssh/id_ed25519.pub
success "Clés SSH configurées pour $USER"

step "7/9 — Copie des clés SSH pour root"
run sudo mkdir -p /root/.ssh
run sudo cp /home/$USER/.ssh/id_ed25519* /root/.ssh/
run sudo chown -R root:users /root/.ssh
run sudo chmod 600 /root/.ssh/id_ed25519
run sudo chmod 644 /root/.ssh/id_ed25519.pub
success "Clés SSH configurées pour root"

step "8/9 — Droits et configuration Git"
run cd /etc/nixos
run sudo chown -R $USER:users /etc/nixos
run sudo -u $USER git config --global --add safe.directory /etc/nixos
run git remote set-url origin git@github.com:Sinsry/nixos-config.git
run git config --global user.name "Sinsry"
run git config --global user.email "113318091+Sinsry@users.noreply.github.com"
run git config --global pull.rebase true
success "Git configuré"

step "9/9 — Mise à jour du flake et rebuild"
info "Mise à jour des inputs du flake..."
run nix --extra-experimental-features 'nix-command flakes' flake update /etc/nixos
run git -C /etc/nixos add .
run git -C /etc/nixos commit -m "auto: update flake.lock" || true
info "Rebuild en cours pour ${BOLD}$HOST${RESET}..."
run sudo NIXOS_HOST="$HOST" nixos-rebuild boot --flake /etc/nixos#$HOST
info "Push vers GitHub..."
run git -C /etc/nixos push

# ============================================================
#  Fin
# ============================================================
echo ""
hr
echo -e "${GREEN}${BOLD}  ✅  Configuration terminée avec succès !${RESET}"
hr
echo ""
echo -e "  Tu doit redémarrer pour profiter de ton système complet 🎉"
echo ""
