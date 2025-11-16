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

GAMEDIR="/$directory/windows/tmosonic"
EXEC="$GAMEDIR/data/The Murder of Sonic The Hedgehog.exe"
BASE=$(basename "$EXEC")

SPLASH="/$directory/windows/.winecellar/tools/splash"
LOG="$GAMEDIR/log.txt"

SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

cd "$GAMEDIR/data"
> "$LOG" && exec > >(tee "$LOG") 2>&1

# Splash
chmod 777 "$SPLASH"
"$SPLASH" "$GAMEDIR/splash.png" 50000 &

# ================================================
# WINE RUNNER CONFIG
# ================================================

# Runner selection
# Default = use $PATH built-ins
# Proton = use .winecellar/proton
# Lutris = use .winecellar/lutris
# Wine-XX.XX = use specific version in .winecellar/wine-xx.xx
## Each of these will have a prefix named for their folder
## i.e. either ~/.wine, ~/.proton, ~/.lutris, etc
## If win32 is needed, 32 will be appended to the prefix
RUNNER=$(jq -r '.runner // "default"' "$GAMEDIR/bottle.json")
WINEARCH=$(jq -r '.env.WINEARCH // "win64"' "$GAMEDIR/bottle.json")

case "$RUNNER" in
    default)
        # Use PATH wine/box64 with standard .wine prefix
        WINEPREFIX="$HOME/.wine"
        [ "$WINEARCH" = "win32" ] && WINEPREFIX="${WINEPREFIX}32"
        WINE="wine"
        BOX=$([ "$WINEARCH" = "win32" ] && echo "box86" || echo "box64")
        ;;
    proton)
        # Find any folder under ~/.winecellar that contains "proton" (case-insensitive)
        PROTON_DIR=$(find "$HOME/.winecellar" -maxdepth 1 -type d -iname "*proton*" | sort -V | tail -n1)
        if [ -z "$PROTON_DIR" ]; then
            echo "Error: No proton folder found in ~/.winecellar"
            exit 1
        fi

        WINEPREFIX="$PROTON_DIR"
        [ "$WINEARCH" = "win32" ] && WINEPREFIX="${WINEPREFIX}32"

        WINE="$PROTON_DIR/bin/wine"
        BOX=$([ "$WINEARCH" = "win32" ] && echo "$PROTON_DIR/box86" || echo "$PROTON_DIR/box64")
        ;;
esac

echo "[LAUNCHER]: Using runner '$RUNNER' with WINEPREFIX='$WINEPREFIX' BOX='$BOX' WINE='$WINE'"

# Mapping of dependencies to a file that indicates installation
declare -A DEP_DLL_MAP=(
    [vcrun2022]="drive_c/windows/system32/vcruntime140_1.dll"
    [dxvk]="drive_c/windows/system32/dxgi.dll"
    [vkd3d-proton]="drive_c/windows/system32/d3d12.dll"
    [vcrun2019]="drive_c/windows/system32/vcruntime140.dll"
    [dotnet48]="drive_c/windows/Microsoft.NET/Framework64/v4.0.30319/mscorlib.dll"
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

# Config Setup
CONFIGDIR=$(jq -r '.configdir // empty' "$GAMEDIR/bottle.json")
if [ -n "$CONFIGDIR" ] && [ -n "$WINEPREFIX" ]; then
    mkdir -p "$GAMEDIR/config"
    bind_directories "$WINEPREFIX/$CONFIGDIR" "$GAMEDIR/config"
fi

# ================================================
# LOCAL SETUP
# ================================================

swapabxy() {
    # Only use sdl_controllerconfig if SDL_GAMECONTROLLERCONFIG is empty
    export SDL_GAMECONTROLLERCONFIG="${SDL_GAMECONTROLLERCONFIG:-$sdl_controllerconfig}"

    if [ -z "$SDL_GAMECONTROLLERCONFIG" ]; then
        echo "[swapabxy]: SDL_GAMECONTROLLERCONFIG is empty, cannot swap"
        return
    fi

    if [ ! -x "$GAMEDIR/tools/swapabxy.py" ]; then
        echo "[swapabxy]: $GAMEDIR/tools/swapabxy.py not executable"
        return
    fi

    # Perform the swap
    export SDL_GAMECONTROLLERCONFIG="$(echo "$SDL_GAMECONTROLLERCONFIG" | "$GAMEDIR/tools/swapabxy.py")"
    echo "[swapabxy]: SDL_GAMECONTROLLERCONFIG after swap: $SDL_GAMECONTROLLERCONFIG"
}

# Swap buttons only if swapabxy.txt exists
if [ -f "$GAMEDIR/tools/swapabxy.txt" ]; then
    swapabxy
fi

# Keyboard Entry; edit name here
export TEXTINPUTPRESET="NAME"          # defines preset text to insert
export TEXTINPUTINTERACTIVE="Y"        # enables interactive text input mode
export TEXTINPUTNOAUTOCAPITALS="Y"     # disables automatic capitalization of first letter of words in interactive text input mode
export TEXTINPUTADDEXTRASYMBOLS="Y"    # enables additional symbols for interactive text input

# ================================================
# RUN GAME
# ================================================

# Run the game
$GPTOKEYB "$BASE" -c "$GAMEDIR/tmosonic.gptk" &
$BOX $WINE "$EXEC"

# Kill processes
wineserver -k
pm_finish