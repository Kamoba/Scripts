#!/bin/bash

APPDIR="$HOME/Applications"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"

mkdir -p "$DESKTOP_DIR" "$ICON_DIR"

for app in "$APPDIR"/*.AppImage; do
    echo "Processing $app ..."
    
    # Ensure AppImage is executable
    chmod +x "$app"

    # Extract AppImage content
    tmpdir=$(mktemp -d)
    "$app" --appimage-extract > /dev/null 2>&1

    if [ -d "squashfs-root" ]; then
        mv squashfs-root/* "$tmpdir" 2>/dev/null
        rm -rf squashfs-root
    fi

    # Find .desktop file inside AppImage
    desktop_file_inside=$(find "$tmpdir" -name "*.desktop" | head -n 1)

    if [ -f "$desktop_file_inside" ]; then
        real_name=$(grep -m1 "^Name=" "$desktop_file_inside" | cut -d'=' -f2)
        comment=$(grep -m1 "^Comment=" "$desktop_file_inside" | cut -d'=' -f2)
        categories=$(grep -m1 "^Categories=" "$desktop_file_inside" | cut -d'=' -f2)
        icon_file=$(grep -m1 "^Icon=" "$desktop_file_inside" | cut -d'=' -f2)

        # Define .desktop destination
        new_desktop="$DESKTOP_DIR/${real_name}.desktop"

        # Skip if launcher exists and points to same AppImage
        if [ -f "$new_desktop" ] && grep -q "$app" "$new_desktop"; then
            echo "✔ Launcher for $real_name already exists, skipping."
            rm -rf "$tmpdir"
            continue
        fi

        # Handle icon
        found_icon=$(find "$tmpdir" -type f \( -name "${icon_file}*.png" -o -name "${icon_file}*.svg" \) | head -n 1)
        if [ -f "$found_icon" ]; then
            cp "$found_icon" "$ICON_DIR/${real_name}.png"
            icon_path="$ICON_DIR/${real_name}.png"
        else
            icon_path="$app"
        fi

        # Create launcher
        cat <<EOF > "$new_desktop"
[Desktop Entry]
Name=$real_name
Comment=$comment
Exec=$app
Icon=$icon_path
Type=Application
Terminal=false
Categories=$categories
EOF

        chmod +x "$new_desktop"
        echo "✔ Created/Updated launcher for $real_name"
    else
        echo "⚠ No .desktop file found in $app"
    fi

    rm -rf "$tmpdir"
done

update-desktop-database "$DESKTOP_DIR"
echo "✅ All done!"
