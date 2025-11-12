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
GAMEDIR="/$directory/windows/ziggurat"
SPLASH="/$directory/windows/.proton/tools/splash"
EXEC="$GAMEDIR/data/Ziggurat.exe"
BASE=$(basename "$EXEC")

# fix random ROCKNIX audio crackle
if [[ "$CFW_NAME" = "ROCKNIX" ]]; then
    ROCKNIX_QUANTUM_SAVE="$(pw-metadata -n settings | grep 'clock.force-quantum' | cut -d"'" -f 4)"
    pw-metadata -n settings 0 clock.force-quantum 960
fi

# CD and set log
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Display loading splash
chmod 777 $SPLASH
$SPLASH "$GAMEDIR/splash.jpg" 30000 &

# Source winesetup
source "/$directory/windows/.proton/winesetup"

# Exports
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Config Setup

mkdir -p $GAMEDIR/config
bind_directories "$WINEPREFIX/drive_c/users/steamuser/AppData/LocalLow/Milkstone Studios/Ziggurat" "$GAMEDIR/config"

# Run the game

$GPTOKEYB "$BASE" -c "$GAMEDIR/ziggurat.gptk" &
$BOX $PROTON/$WINE "$EXEC"

# ROCKNIX Audio fix restore original value
if [ "$CFW_NAME" = "ROCKNIX" ]; then
    pw-metadata -n settings 0 clock.force-quantum "$ROCKNIX_QUANTUM_SAVE"
fi

# Kill processes
wineserver -k
pm_finish
