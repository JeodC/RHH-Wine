#!/bin/bash

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

# Variables
GAMEDIR="/$directory/windows/berserkboy"
SPLASH="/$directory/windows/.proton/tools/splash"
EXEC="$GAMEDIR/data/BERSERK BOY.exe"
BASE=$(basename "$EXEC")

# CD and set log
cd $GAMEDIR/data
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
#bind_directories "$WINEPREFIX/drive_c/users/root/AppData/LocalLow/Andrew Shouldice/Secret Legend" "$GAMEDIR/config"

# Run the game
$GPTOKEYB "$BASE" -c "./berserk.gptk" &
$BOX $PROTON/$WINE "$EXEC"

# Kill processes
wineserver -k
pm_finish