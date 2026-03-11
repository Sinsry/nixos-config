#!/usr/bin/env bash
###############################################################################
# Script Toggle VPN + DNS pour OPNsense - 100% API
# Par Sinsry - Janvier 2026
#
# Usage: ./vpn_toggle.sh [on|off|status]
###############################################################################

OPNSENSE_HOST="192.168.1.254:8443"
API_KEY="Ug5B4RMUpTmf6AqQK+C+6zjiG0Tli0fxe0D9MgUdLgWg6cOMVq5nMdFazUbgtL4qQzn22ms76cOliPl6"
API_SECRET="bMPDK7U2yc/hSREw/u9hVpJS6m3IYxM/vsUhpoMs5p14La9Ioinqs/kZSNagOqmoeufKGcfGmhr7zUE3"
VPN_RULE_UUID_LAN="ebb8b9e6-e1ff-48eb-bbfb-5038b71aef86"
VPN_RULE_UUID_HOMEVPN="cce21f14-6e14-4f68-b86a-a4320146e5ac"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

api_call() {
    [ -n "$3" ] && response=$(curl -k -s -u "$API_KEY:$API_SECRET" -X "$1" -H "Content-Type: application/json" -d "$3" "https://$OPNSENSE_HOST/api/$2" 2>&1) \
               || response=$(curl -k -s -u "$API_KEY:$API_SECRET" -X "$1" "https://$OPNSENSE_HOST/api/$2" 2>&1)
    echo "$response" | grep -q '"status":401' && { log_error "Auth failed"; return 1; }
    echo "$response"
}

get_status() {
    echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
    vpn=$(api_call GET "firewall/filter/getRule/$VPN_RULE_UUID_LAN")
    echo "$vpn" | grep -q '"enabled":"1"' && echo -e "${GREEN}VPN: ACTIVÉ${NC} (via VPN_GW)" || echo -e "${RED}VPN: DÉSACTIVÉ${NC} (via FAI)"
    dns=$(api_call GET "unbound/settings/get" | grep -o '"forwarding":{"enabled":"[01]"' | grep -o '[01]' | head -1)
    [ "$dns" = "1" ] && echo -e "DNS: ${GREEN}10.2.0.1${NC} (System Nameservers)" || echo -e "DNS: ${YELLOW}Cloudflare+Quad9${NC} (DoT)"
    echo -e "${CYAN}═══════════════════════════════════════${NC}\n"
}

enable_vpn() {
    echo -e "\n${CYAN}╔═════════════════╗${NC}\n${CYAN}║${NC} ${GREEN}ACTIVATION VPN${NC}  ${CYAN}║${NC}\n${CYAN}╚═════════════════╝${NC}\n"
    log_info "Activation règle VPN..." && api_call POST "firewall/filter/toggleRule/$VPN_RULE_UUID_LAN/1" >/dev/null && api_call POST "firewall/filter/toggleRule/$VPN_RULE_UUID_HOMEVPN/1" >/dev/null && log_success "Règles VPN activées"
    log_info "Application firewall..." && api_call POST "firewall/filter/apply" >/dev/null && log_success "Firewall appliqué"
    log_info "Activation System Nameservers..." && api_call POST "unbound/settings/set" '{"unbound":{"forwarding":{"enabled":"1"}}}' >/dev/null && log_success "System Nameservers activé"
    log_info "Application DNS..." && api_call POST "unbound/service/reconfigure" >/dev/null && log_success "DNS appliqué"
    echo -e "\n${GREEN}✓ VPN ACTIVÉ !${NC}\n"
}

disable_vpn() {
    echo -e "\n${CYAN}╔═══════════════════╗${NC}\n${CYAN}║${NC} ${YELLOW}DÉSACTIVATION VPN${NC} ${CYAN}║${NC}\n${CYAN}╚═══════════════════╝${NC}\n"
    log_info "Désactivation règle VPN..." && api_call POST "firewall/filter/toggleRule/$VPN_RULE_UUID_LAN/0" >/dev/null && api_call POST "firewall/filter/toggleRule/$VPN_RULE_UUID_HOMEVPN/0" >/dev/null && log_success "Règles VPN désactivées"
    log_info "Application firewall..." && api_call POST "firewall/filter/apply" >/dev/null && log_success "Firewall appliqué"
    log_info "Désactivation System Nameservers..." && api_call POST "unbound/settings/set" '{"unbound":{"forwarding":{"enabled":"0"}}}' >/dev/null && log_success "System Nameservers désactivé"
    log_info "Application DNS..." && api_call POST "unbound/service/reconfigure" >/dev/null && log_success "DNS appliqué"
    echo -e "\n${YELLOW}✓ VPN DÉSACTIVÉ !${NC}\n"
}

case "$1" in
    on|enable) enable_vpn && get_status ;;
    off|disable) disable_vpn && get_status ;;
    status) get_status ;;
    *) echo -e "\nUsage: $0 {on|off|status}\n"; exit 1 ;;
esac
