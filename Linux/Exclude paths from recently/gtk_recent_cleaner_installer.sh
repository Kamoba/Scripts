#!/bin/bash
set -e

# === CONFIG ===
SERVICE_NAME="gtk-recent-cleaner"
SCRIPT_PATH="$HOME/Applications/scripts/gtk_recent_cleaner.sh"
SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SERVICE_DIR/$SERVICE_NAME.service"
RECENT_FILE="$HOME/.local/share/recently-used.xbel"

# Paths to exclude (edit here)
EXCLUDE_PATHS=(
    "/home/Thor/Pictures/Images/bigBoobs"
    "/mnt/PrivateDisk/secrets/bitcoins"
)

install_service() {
    echo "➡ Installing $SERVICE_NAME ..."

    mkdir -p "$(dirname "$SCRIPT_PATH")"

    {
    cat << 'EOF'
#!/bin/bash
RECENT_FILE="$HOME/.local/share/recently-used.xbel"

EXCLUDE_PATHS=(
EOF

    for path in "${EXCLUDE_PATHS[@]}"; do
        echo "    \"$path\""
    done

    cat << 'EOF'
)

# Convert path to file:// URL-encoded form
to_url_path() {
    local path="$1"
    echo "file://${path// /%20}/"
}

clean_recent_file() {
    if [[ ! -f "$RECENT_FILE" ]]; then
        return
    fi

    local content
    content=$(< "$RECENT_FILE")
    local total_removed=0

    for path in "${EXCLUDE_PATHS[@]}"; do
        url=$(to_url_path "$path")
        # Use perl for multi-line regex removal of <bookmark ...>...</bookmark>
        removed=$(perl -0777 -i -pe "
            my \$count = 0;
            s|<bookmark\\s+href=\"\Q$url\E[^\"]*\".*?</bookmark>||gms and \$count++;
            END { print STDERR \$count; }
        " "$RECENT_FILE" 2>&1)

        if [[ "$removed" -gt 0 ]]; then
            total_removed=$((total_removed + removed))
        fi
    done
}

watch() {
    # waiting efficiently until the OS kernel notify change 
    while true; do
        inotifywait -e modify "$RECENT_FILE" >/dev/null 2>&1
        sleep 0.5  # wait half a second before cleaning
        clean_recent_file
    done
}

# Run once now
clean_recent_file

watch

EOF
    } > "$SCRIPT_PATH"

    chmod +x "$SCRIPT_PATH"

    mkdir -p "$SERVICE_DIR"
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=GTK Recent Files Cleaner (inotify)
After=default.target

[Service]
ExecStart=$SCRIPT_PATH
Restart=always

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable --now $SERVICE_NAME.service

    echo "✅ Installed and started $SERVICE_NAME"
}

uninstall_service() {
    echo "➡ Uninstalling $SERVICE_NAME ..."

    systemctl --user stop $SERVICE_NAME.service || true
    systemctl --user disable $SERVICE_NAME.service || true
    rm -f "$SERVICE_FILE"
    systemctl --user daemon-reload

    rm -f "$SCRIPT_PATH"

    echo "✅ Uninstalled $SERVICE_NAME"
}

# === Main ===
case "$1" in
    uninstall)
        uninstall_service
        ;;
    install|*)
        install_service
        ;;
esac
