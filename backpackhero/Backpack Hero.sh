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
GAMEDIR="/$directory/windows/backpackhero"
SPLASH="/$directory/windows/.proton/tools/splash"
EXEC="$GAMEDIR/data/Backpack Hero.exe"
BASE=$(basename "$EXEC")

# CD and set log
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Display loading splash
chmod 777 $SPLASH
$SPLASH "$GAMEDIR/splash.png" 120000 &

# Source winesetup
source "/$directory/windows/.proton/winesetup"

# Exports
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Config Setup
mkdir -p $GAMEDIR/config
bind_directories "$WINEPREFIX/drive_c/users/steamuser/AppData/LocalLow/TheJaspel/Backpack Hero" "$GAMEDIR/config"

# Run the game
$GPTOKEYB "$BASE" -c "$GAMEDIR/bphero.gptk" &
$BOX $PROTON/$WINE "$EXEC"

# Kill processes
wineserver -k
pm_finish