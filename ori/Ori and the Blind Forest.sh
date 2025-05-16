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
GAMEDIR="/$directory/windows/ori"
SPLASH="/$directory/windows/.proton/tools/splash"

# CD and set log
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Exports
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Determine exe and setup config folders
mkdir -p $GAMEDIR/config
if [ -f "$GAMEDIR/data/oriDE.exe" ]; then
    EXEC="$GAMEDIR/data/oriDE.exe"
    BASE=$(basename "$EXEC")
    GAMESPLASH="$GAMEDIR/splashDE.png"
    bind_directories "$WINEPREFIX/drive_c/users/root/AppData/Local/Ori and the Blind Forest DE" "$GAMEDIR/config"
else
    EXEC="$GAMEDIR/data/ori.exe"
    BASE=$(basename "$EXEC")
    GAMESPLASH="$GAMEDIR/splash.png"
    bind_directories "$WINEPREFIX/drive_c/users/root/AppData/Local/Ori and the Blind Forest" "$GAMEDIR/config"
fi

# Display loading splash
chmod 777 $SPLASH
$SPLASH "$GAMESPLASH" 30000 &

# Source winesetup
source "/$directory/windows/.proton/winesetup"

# Run the game
$GPTOKEYB "$BASE" -c "$GAMEDIR/ori.gptk" &
$BOX $PROTON/$WINE "$EXEC"

# Kill processes
wineserver -k
pm_finish