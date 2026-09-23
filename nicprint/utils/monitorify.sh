#!/usr/bin/env bash
# Put one or more interfaces into monitor mode on a given channel.
## Original author: Ravi Mangar (ravi.gr@darmouth.edu)
# Usage: sudo ./monitorify.sh -c <channel> <iface1> [iface2 iface3 ...]

set -u -o pipefail

usage() {
  echo "Usage: sudo $0 -c <channel> <iface1> [iface2 ...]"
  exit 2
}

CHANNEL=""
IFACES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--channel)
      [[ $# -ge 2 ]] || usage
      CHANNEL="$2"; shift 2 ;;
    -h|--help)
      usage ;;
    -*)
      echo "Unknown option: $1" >&2; usage ;;
    *)
      IFACES+=("$1"); shift ;;
  esac
done

[[ -n "$CHANNEL" && ${#IFACES[@]} -ge 1 ]] || usage

for cmd in iw ip; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "[err] Missing $cmd"; exit 1; }
done
command -v rfkill >/dev/null 2>&1 || true

log(){ echo "[monitorify] $*"; }
warn(){ echo "[monitorify][warn] $*" >&2; }
err(){ echo "[monitorify][err] $*" >&2; }

if command -v rfkill >/dev/null 2>&1; then
  rfkill unblock wifi || true
fi

for IFACE in "${IFACES[@]}"; do
  if [[ ! -d "/sys/class/net/$IFACE" ]]; then
    warn "Interface $IFACE not found; skipping"
    continue
  fi

  log "Preparing $IFACE"

  if pgrep -fa "wpa_supplicant.*-i${IFACE}" >/dev/null; then
    log "Stopping wpa_supplicant on $IFACE"
    pkill -f "wpa_supplicant.*-i${IFACE}" || true
  fi

  ip link set "$IFACE" down || true

  CUR_TYPE="$(iw dev "$IFACE" info 2>/dev/null | awk '/type/ {print $2; exit}')"
  if [[ "$CUR_TYPE" != "monitor" ]]; then
    log "Setting $IFACE type monitor"
    if ! iw dev "$IFACE" set type monitor 2>/dev/null; then
      # Fallback: recreate same name on same phy
      PHY_LINK="/sys/class/net/$IFACE/phy80211"
      if [[ -e "$PHY_LINK" ]]; then
        PHY="$(basename "$(readlink -f "$PHY_LINK")")"
        log "Direct set failed; recreating $IFACE on $PHY as monitor"
        iw dev "$IFACE" del || true
        if ! iw phy "$PHY" interface add "$IFACE" type monitor; then
          err "Failed to recreate $IFACE as monitor on $PHY"
          continue
        fi
      else
        err "Cannot find phy for $IFACE; skipping"
        continue
      fi
    fi
  fi

  ip link set "$IFACE" up || true

  if ! iw dev "$IFACE" set channel "$CHANNEL"; then
    warn "Failed to set channel $CHANNEL on $IFACE (driver/regdomain?); continuing"
  fi

  iw dev "$IFACE" info || true
done

log "Done."