#!/bin/bash
# MastrCtrl Pi-Side Update Installation Script

set -e

BASE_PATH="/home/pi/mastrctrl"
STAGING_PATH="$BASE_PATH/staging"
BACKUP_PATH="$BASE_PATH/backups"
CURRENT_PATH="$BASE_PATH/current"

COMPONENT=$1
VERSION=$2

if [ -z "$COMPONENT" ] || [ -z "$VERSION" ]; then
    echo "Usage: $0 <component> <version>"
    echo "  component: ui, server, or firmware"
    echo "  version: version number (e.g., 1.2.3)"
    exit 1
fi

echo "========================================"
echo "MastrCtrl Update Installation"
echo "========================================"
echo "Component: $COMPONENT"
echo "Version: $VERSION"
echo ""

# Function to check disk space
check_disk_space() {
    local required_mb=$1
    local available_mb=$(df -m "$BASE_PATH" | awk 'NR==2 {print $4}')
    
    if [ "$available_mb" -lt "$required_mb" ]; then
        echo "Error: Insufficient disk space. Required: ${required_mb}MB, Available: ${available_mb}MB"
        return 1
    fi
    
    echo "Disk space OK: ${available_mb}MB available"
    return 0
}

# Function to create backup
create_backup() {
    local component=$1
    local timestamp=$(date +%Y-%m-%d-%H%M%S)
    local backup_name="${component}-${timestamp}"
    
    echo "Creating backup: $backup_name"
    
    mkdir -p "$BACKUP_PATH"
    
    case "$component" in
        ui)
            if [ -d "$CURRENT_PATH/ui" ]; then
                cp -r "$CURRENT_PATH/ui" "$BACKUP_PATH/$backup_name"
                echo "UI backup created"
            fi
            ;;
        server)
            if [ -d "$CURRENT_PATH/python" ]; then
                cp -r "$CURRENT_PATH/python" "$BACKUP_PATH/$backup_name"
                echo "Server backup created"
            fi
            ;;
        firmware)
            if [ -f "$CURRENT_PATH/firmware.bin" ]; then
                cp "$CURRENT_PATH/firmware.bin" "$BACKUP_PATH/${backup_name}.bin"
                echo "Firmware backup created"
            fi
            ;;
    esac
    
    # Cleanup old backups (keep last 2)
    local backups=$(ls -1t "$BACKUP_PATH" | grep "^${component}-" | tail -n +3)
    if [ ! -z "$backups" ]; then
        echo "Cleaning up old backups..."
        echo "$backups" | while read backup; do
            rm -rf "$BACKUP_PATH/$backup"
            echo "  Removed: $backup"
        done
    fi
}

# Function to install UI
install_ui() {
    local version=$1
    local zip_file="$STAGING_PATH/ui-v${version}.zip"
    
    if [ ! -f "$zip_file" ]; then
        echo "Error: UI package not found: $zip_file"
        return 1
    fi
    
    echo "Installing UI v${version}..."
    
    # Stop UI service
    echo "  Stopping UI service..."
    sudo systemctl stop mastrctrl-ui || true
    
    # Extract new UI
    echo "  Extracting UI package..."
    rm -rf "$CURRENT_PATH/ui"
    mkdir -p "$CURRENT_PATH/ui"
    unzip -q "$zip_file" -d "$CURRENT_PATH/ui"
    
    # Install dependencies if needed
    if [ -f "$CURRENT_PATH/ui/package.json" ]; then
        echo "  Installing UI dependencies..."
        cd "$CURRENT_PATH/ui"
        npm install --production
    fi
    
    # Start UI service
    echo "  Starting UI service..."
    sudo systemctl start mastrctrl-ui
    
    sleep 3
    
    # Verify service
    if sudo systemctl is-active --quiet mastrctrl-ui; then
        echo "UI service started successfully"
        return 0
    else
        echo "Error: UI service failed to start"
        return 1
    fi
}

# Function to install server
install_server() {
    local version=$1
    local zip_file="$STAGING_PATH/server-v${version}.zip"
    
    if [ ! -f "$zip_file" ]; then
        echo "Error: Server package not found: $zip_file"
        return 1
    fi
    
    echo "Installing Server v${version}..."
    
    # Stop server service
    echo "  Stopping server service..."
    sudo systemctl stop mastrctrl-server || true
    
    # Extract new server
    echo "  Extracting server package..."
    rm -rf "$CURRENT_PATH/python"
    mkdir -p "$CURRENT_PATH/python"
    unzip -q "$zip_file" -d "$CURRENT_PATH/python"
    
    # Install Python dependencies
    if [ -f "$CURRENT_PATH/python/requirements.txt" ]; then
        echo "  Installing Python dependencies..."
        pip3 install -r "$CURRENT_PATH/python/requirements.txt"
    fi
    
    # Start server service
    echo "  Starting server service..."
    sudo systemctl start mastrctrl-server
    
    sleep 3
    
    # Verify service
    if sudo systemctl is-active --quiet mastrctrl-server; then
        echo "Server service started successfully"
        return 0
    else
        echo "Error: Server service failed to start"
        return 1
    fi
}

# Function to install firmware
install_firmware() {
    local version=$1
    local firmware_file="$STAGING_PATH/firmware-v${version}.bin"
    
    if [ ! -f "$firmware_file" ]; then
        echo "Error: Firmware package not found: $firmware_file"
        return 1
    fi
    
    echo "Installing Firmware v${version}..."
    
    # Stop server to free up serial port
    echo "  Stopping server service..."
    sudo systemctl stop mastrctrl-server || true
    
    sleep 1
    
    # Flash ESP32
    echo "  Flashing ESP32..."
    esptool.py \
        --port /dev/serial0 \
        --baud 460800 \
        --before default_reset \
        --after hard_reset \
        --chip esp32s3 \
        write_flash \
        --flash_mode dio \
        --flash_freq 80m \
        --flash_size detect \
        0x0 "$firmware_file"
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to flash ESP32"
        return 1
    fi
    
    sleep 3
    
    # Copy firmware to current
    cp "$firmware_file" "$CURRENT_PATH/firmware.bin"
    
    # Restart server
    echo "  Starting server service..."
    sudo systemctl start mastrctrl-server
    
    sleep 2
    
    echo "Firmware flashed successfully"
    return 0
}

# Main installation flow
check_disk_space 500

create_backup "$COMPONENT"

case "$COMPONENT" in
    ui)
        if install_ui "$VERSION"; then
            echo ""
            echo "========================================"
            echo "UI Update Complete!"
            echo "========================================"
        else
            echo ""
            echo "========================================"
            echo "UI Update Failed - Rolling back..."
            echo "========================================"
            # Rollback logic handled by update_manager.py
            exit 1
        fi
        ;;
    server)
        if install_server "$VERSION"; then
            echo ""
            echo "========================================"
            echo "Server Update Complete!"
            echo "========================================"
        else
            echo ""
            echo "========================================"
            echo "Server Update Failed - Rolling back..."
            echo "========================================"
            exit 1
        fi
        ;;
    firmware)
        if install_firmware "$VERSION"; then
            echo ""
            echo "========================================"
            echo "Firmware Update Complete!"
            echo "========================================"
        else
            echo ""
            echo "========================================"
            echo "Firmware Update Failed - Rolling back..."
            echo "========================================"
            exit 1
        fi
        ;;
    *)
        echo "Error: Unknown component: $COMPONENT"
        exit 1
        ;;
esac

exit 0

