#!/bin/bash

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

# Variables
GAMEDIR="/$directory/windows/vampiresurvivors"
SPLASH="/$directory/windows/.proton/tools/splash"
EXEC="$GAMEDIR/data/VampireSurvivors.exe"
BASE=$(basename "$EXEC")

# CD and set log
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Display loading splash
chmod 777 $SPLASH
$SPLASH "$GAMEDIR/splash.png" 30000 &

# Source winesetup
source "/$directory/windows/.proton/winesetup"

# Exports
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Config Setup
mkdir -p $GAMEDIR/config
bind_directories "$WINEPREFIX/drive_c/users/steamuser/AppData/Roaming/Vampire_Survivors_EGS" "$GAMEDIR/config"

# Run the game
echo "[INFO] Disabling Wi-Fi for offline gameplay"
ip link set wlan0 down

$GPTOKEYB "$BASE" -c "$GAMEDIR/vampire.gptk" &
$BOX $PROTON/$WINE "$EXEC"
GAMEPID=$!

wait $GAMEPID

echo "[INFO] Re-enabling Wi-Fi after game exit"
ip link set wlan0 up



# Kill processes
wineserver -k
pm_finish