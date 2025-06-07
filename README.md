#### **NOTE: THIS PROJECT IS NOT AFFILIATED WITH STEAMODDED OR LOVELY INJECTOR**

#### **bmody** is a script I threw together because setting up Balatro mods on Linux was getting annoying. You know how it is - Wine paths, Proton compatibility layers, Steam launch options, and all that jazz.

-----
- `What is this?`:
	This is basically a one-click solution for setting up Balatro modding on Linux. It handles downloading Steamodded and Lovely Injector, finds your game installation (even if you're using Flatpak or Snap Steam), and puts everything where it needs to go. (a spiritual successor to patchy, if you will.)
- `How is it useful?`:
	If you've ever tried to mod Balatro on Linux manually, you know it's a pain. This script does all the heavy lifting - finds your Steam installation, downloads the latest mod tools, sets up the directory structure, and even tells you exactly what launch options to use.
- `What does it actually do?`:
    It downloads the Windows version of Lovely Injector (because that's what works with Proton), grabs the latest Steamodded release, figures out your Wine prefix paths, installs everything correctly, and gives you clear instructions for the Steam launch options you need.
- `Why?`:
    Because manually setting up Balatro mods on Linux sucks, and I got tired of doing it over and over.
----
### Setting up
You'll need a few things installed first: `curl`, `jq`, and `unzip`. Most distros have these, but just in case:
```bash
# Ubuntu/Debian
$ sudo apt install curl jq unzip

# Fedora
$ sudo dnf install curl jq unzip

# Arch
$ sudo pacman -S curl jq unzip
```

Then grab the script:
```bash
$ git clone https://github.com/auth-xyz/bmody
$ cd bmody/
$ chmod +x bmody.sh 
$ ./bmody.sh
```
----
### Usage 
The script is pretty straightforward - just run it and follow the prompts:
```bash
$ ./bmody.sh
```

It'll ask you if you want to:
1. Auto-download the latest Steamodded and Lovely Injector (recommended)
2. Use mod files you already have
3. Exit (if you changed your mind)

The script will:
- Find your Balatro installation automatically (supports regular Steam, Flatpak, and Snap)
- Download and install the mods to the correct locations
- Tell you exactly what Steam launch options to set
- Give you the paths for adding more mods later

**Important**: You MUST set these launch options in Steam or the mods won't work:
```
WINEDLLOVERRIDES="version=n,b" %command%
```

To set launch options: Right-click Balatro → Properties → paste the above into Launch Options.
----
### What gets installed where
- **Lovely Injector**: `version.dll` goes in your game directory (where `Balatro.exe` lives)
- **Steamodded**: Gets installed to your Wine prefix save directory under `Mods/Steamodded/`
- **Additional mods**: Go in the same `Mods/` folder as Steamodded

The script handles all the annoying Wine/Proton path detection automatically.
----
### Troubleshooting
- **Mods not loading?** Check that you set the Steam launch options correctly
- **Can't find Balatro?** The script will ask you for the path manually
- **Game crashes?** Make sure you're running through Steam with Proton, not natively
- **Flatpak/Snap issues?** The script should detect these automatically, but let me know if it doesn't

----
### Contributing
If you find bugs or have suggestions, feel free to open an issue. The code isn't perfect, but it works. If you want to improve something, PRs are welcome - just try to keep the same "actually helpful" vibe instead of overengineering it.
