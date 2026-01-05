#!/bin/bash

# ================================================
# PORTMASTER PREAMBLE
# ================================================
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

# ================================================
# LOCAL VARIABLES
# ================================================

GAMEDIR="/$directory/windows/oceanhorn"
EXEC="$GAMEDIR/data/Oceanhorn.exe"
BASE=$(basename "$EXEC")

SPLASH="/$directory/windows/.winecellar/tools/splash"
LOG="$GAMEDIR/log.txt"

cd "$GAMEDIR/data"
> "$LOG" && exec > >(tee "$LOG") 2>&1

# Splash
chmod 777 "$SPLASH"
"$SPLASH" "$GAMEDIR/splash.png" 50000 &

export WINETRICKS_DL_CMD="curl -L -O"

# ================================================
# WINE RUNNER CONFIG
# ================================================

# Function to find the latest runner version
find_runner_dir() {
    # Find any folder under ../.winecellar that matches $1 (case-insensitive)
    # Sorts by version and takes the latest one (tail -n1)
    find "/$directory/windows/.winecellar" -maxdepth 1 -type d -iname "*$1*" | sort -V | tail -n1
}

# Runner selection
RUNNER=$(jq -r '.runner // "default"' "$GAMEDIR/bottle.json")
WINEARCH=$(jq -r '.env.WINEARCH // "win64"' "$GAMEDIR/bottle.json")

case "$RUNNER" in
    default)
        WINEPREFIX="$HOME/.wine"
        WINE="wine"
        ;;
    proton)
        RUNNER_DIR=$(find_runner_dir "proton")
        WINEPREFIX="$HOME/.proton"
        WINE="$RUNNER_DIR/bin/wine"
        ;;
    wine-wow64)
        RUNNER_DIR=$(find_runner_dir "wine-wow64")
        WINEPREFIX="$HOME/.wine"
        WINE="$(readlink -f "$RUNNER_DIR/bin/wine")"
        ;;
    *)
        echo "Error: Unknown runner '$RUNNER' specified in bottle.json"
        exit 1
        ;;
esac

# Append 32 to prefix if win32 architecture is required
[ "$WINEARCH" = "win32" ] && WINEPREFIX="${WINEPREFIX}32"
# Set BOX based on architecture
BOX=box64

# Error checking for non-default runners and PATH setup
if [ "$RUNNER" != "default" ]; then
    if [ -z "$RUNNER_DIR" ] || [ ! -x "$WINE" ]; then
        echo "Error: Required runner '$RUNNER' not found or is not executable."
        exit 1
    fi
    # Only export PATH once, if we're using a custom runner
    export PATH="$(dirname "$WINE"):$PATH"
fi

echo "[LAUNCHER]: Using runner '$RUNNER' with WINEPREFIX='$WINEPREFIX' BOX='$BOX' WINE='$WINE'"

# Mapping of dependencies to a file that indicates installation
declare -A DEP_DLL_MAP=(
    [d3dx10]="drive_c/windows/system32/d3dx10_43.dll"
    [d3dcompiler_43]="drive_c/windows/system32/d3dcompiler_43.dll"
    [d3dcompiler_47]="drive_c/windows/system32/d3dcompiler_47.dll"
)

# Install dependencies from bottle.json
if jq -e '.deps' "$GAMEDIR/bottle.json" >/dev/null 2>&1; then
    echo "[LAUNCHER]: Installing dependencies from bottle.json..."
    jq -r '.deps[]?' "$GAMEDIR/bottle.json" | while read -r dep; do
        marker="${DEP_DLL_MAP[$dep]}"
        if [ -n "$marker" ] && [ -f "$WINEPREFIX/$marker" ]; then
            echo "[LAUNCHER]: $dep already installed (found $marker)"
        else
            echo "[LAUNCHER]: Installing $dep..."
            WINEPREFIX="$WINEPREFIX" winetricks -q "$dep" || {
                echo "[ERROR]: Failed to install $dep"
                exit 1
            }
        fi
    done
fi

# If proton then install dxvk and vkd3d-proton
if [ "$RUNNER" = "proton" ]; then
    if ! WINEPREFIX="$WINEPREFIX" winetricks list-installed | grep -q '^dxvk$'; then
        echo "[LAUNCHER]: Installing DXVK into Proton prefix..."
        WINEPREFIX="$WINEPREFIX" winetricks -q dxvk
    fi
    if ! WINEPREFIX="$WINEPREFIX" winetricks list-installed | grep -q '^vkd3d-proton$'; then
        echo "[LAUNCHER]: Installing vkd3d-proton into Proton prefix..."
        WINEPREFIX="$WINEPREFIX" winetricks -q vkd3d-proton
    fi
fi

# Load bottle env
if command -v jq >/dev/null; then
    while IFS="=" read -r k v; do
        export "$k=$v"
    done < <(jq -r '.env | to_entries | .[] | "\(.key)=\(.value)"' "$GAMEDIR/bottle.json")
else
    echo "Error: jq not found"
    exit 1
fi

# ================================================
# RUN GAME
# ================================================

# Run the game
$GPTOKEYB "$BASE" -c "$GAMEDIR/oceanhorn.gptk" &
$BOX $WINE "$EXEC"

# Kill processes
wineserver -k
pm_finish