#!/run/current-system/sw/bin/bash
exec 2>/tmp/fastfetch-debug.log
birth=$(/run/current-system/sw/bin/stat -c %W /nix/store 2>/dev/null)

if [ "$birth" = "0" ] || [ -z "$birth" ]; then
  echo "Date inconnue"
  exit 0
fi

now=$(/run/current-system/sw/bin/date +%s)
days=$(( (now - birth) / 86400 ))
install_date=$(/run/current-system/sw/bin/date -d @$birth "+%d/%m/%Y")

echo "$install_date - $days jours"
