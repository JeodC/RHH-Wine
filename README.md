# PortMaster - Wine Project

This repository hosts all of the DRM-free games that are proven to work with Proton-GE. Proton-GE was chosen due to its better compatibility and performance. Everything in this repository is meant to work with linux aarch64 systems such as the later Retroid Pocket and Odin family. To use these wine game wrappers as-is, you must copy the `.proton` folder from this repository to `roms/windows`. Then, download the Proton build of your choice from https://github.com/GloriousEggroll/proton-ge-custom/releases and extract all subfolders to the `.proton` folder. If done correctly your folder structure will look as such.

```
.proton/
 ├───bin/
 ├───bin-wow64/
 ├───include/
 ├───lib/
 ├───lib32/
 ├───share/
 ├───tools/
 └───winesetup
```

The `winesetup` file is sourced in every launch script and sets up the wineprefix and other common environment variables. After it's set up properly, you can copy whatever wine game wrapper you wish to `roms/windows` and then copy the respective game data into `folder/data`. If a wine game wrapper has any additional setup required, there will be a `README.md` file inside the wrapper folder.

Most wine games here make use of PortMaster's environment variables and GPTOKEYB.

## Customization

The `.proton` folder is only named because Proton is recommended. You can of course use a normal wine build inside, since the folder structure will be the same. You can also modify `winesetup` to use a specific box64 version or modify the launch scripts for a per-game override. Rocknix tends to build the latest box and wine binaries into their firmware.

## Missing X

This repository does not host wine game wrappers for any games requiring DRM bypass such as select Steam titles. Pull requests to add such games will be denied. Pull requests adding DRM-free wine game wrappers are welcome.