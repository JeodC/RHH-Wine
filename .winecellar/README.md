# Config Setup

Copy this folder `.winecellar` to your `roms/windows` system folder. If any bottles use a custom wine build such as proton, you will need to install the custom builds here. For example you would go to https://github.com/Kron4ek/Wine-Builds/releases to find and download the latest Proton release, and unzip it to `.winecellar`.

An example directory structure after unzipping would be:

```
.winecellar/
├───tools
│   ├───splash
└───wine-proton-10.0-3-amd64-wow64
    ├───bin
    ├───include
    ├───lib
    └───share
```

The `tools/splash` binary is provided and can be used as a courtesy to users so they have something to view while a game is loading.