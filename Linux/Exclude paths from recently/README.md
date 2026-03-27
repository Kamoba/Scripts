# GTK Recent Cleaner

A lightweight utility to automatically **clean the GTK recent files list** by removing entries from specific directories.  
It works by monitoring the `recently-used.xbel` file using **inotify-tools** and runs as a **systemd user service**.  
No Python or external dependencies beyond `inotify-tools` are required.

---

## ✅ Features
- Automatically cleans entries from `recently-used.xbel`
- Monitors file changes in real-time using `inotifywait`
- Allows multiple exclude paths
- Runs as a **systemd user service**
- Includes **installer** and **uninstaller**

---

## 📦 Requirements
- Linux system with **systemd**
- `inotify-tools` installed:
  ```bash
  sudo apt install inotify-tools
  ```

## 📦 Installation
  ```bash
  wget https://raw.githubusercontent.com/Kamoba/Scripts/main/Linux/Exclude%20paths%20from%20recently/gtk_recent_cleaner_installer.sh
  chmod +x gtk_recent_cleaner_installer.sh
  ./gtk_recent_cleaner_installer.sh install
  ```


## 🔧 Configuration
```
nano ~/Applications/scripts/gtk_recent_cleaner.sh
```
Modify the EXCLUDE_PATHS array:
<pre> EXCLUDE_PATHS=(
  "/path1"
  "/path2"
) </pre>

Edit **SCRIPT_PATH** if you want the script to be stored in different directory than `$HOME/Applications/scripts/` like `~/.local/bin/`

Save and restart the service:
```
systemctl --user restart gtk-recent-cleaner.service
```


## ❌ Uninstall

To completely remove everything:
```
./gtk_recent_cleaner_installer.sh uninstall
sudo apt purge inotify-tools   # ⚠️ if no other app needs it!
```

Notes:

  This script only affects GTK apps (default) using: `~/.local/share/recently-used.xbel`  
  Other apps may use different files: find out with :
```
  find ~/.var/app -name recently-used.xbel
  find ~/snap -name recently-used.xbel
```


---

## 📜 License
This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

