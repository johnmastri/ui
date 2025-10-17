#!/bin/bash
# MastrCtrl Manual Rollback Script

set -e

BASE_PATH="/home/pi/mastrctrl"
BACKUP_PATH="$BASE_PATH/backups"
CURRENT_PATH="$BASE_PATH/current"

COMPONENT=$1

if [ -z "$COMPONENT" ]; then
    echo "Usage: $0 <component>"
    echo "  component: ui, server, or firmware"
    echo ""
    echo "Available backups:"
    ls -1t "$BACKUP_PATH" 2>/dev/null || echo "  No backups found"
    exit 1
fi

echo "========================================"
echo "MastrCtrl Rollback"
echo "========================================"
echo "Component: $COMPONENT"
echo ""

# Find latest backup
BACKUP=$(ls -1t "$BACKUP_PATH" | grep "^${COMPONENT}-" | head -n 1)

if [ -z "$BACKUP" ]; then
    echo "Error: No backup found for $COMPONENT"
    exit 1
fi

echo "Latest backup: $BACKUP"
echo ""
read -p "Roll back to this version? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Rollback cancelled"
    exit 0
fi

case "$COMPONENT" in
    ui)
        echo "Rolling back UI..."
        sudo systemctl stop mastrctrl-ui || true
        
        rm -rf "$CURRENT_PATH/ui"
        cp -r "$BACKUP_PATH/$BACKUP" "$CURRENT_PATH/ui"
        
        sudo systemctl start mastrctrl-ui
        
        if sudo systemctl is-active --quiet mastrctrl-ui; then
            echo "UI rollback successful"
        else
            echo "Error: UI service failed to start"
            exit 1
        fi
        ;;
        
    server)
        echo "Rolling back server..."
        sudo systemctl stop mastrctrl-server || true
        
        rm -rf "$CURRENT_PATH/python"
        cp -r "$BACKUP_PATH/$BACKUP" "$CURRENT_PATH/python"
        
        sudo systemctl start mastrctrl-server
        
        if sudo systemctl is-active --quiet mastrctrl-server; then
            echo "Server rollback successful"
        else
            echo "Error: Server service failed to start"
            exit 1
        fi
        ;;
        
    firmware)
        echo "Rolling back firmware..."
        sudo systemctl stop mastrctrl-server || true
        
        sleep 1
        
        # Flash backup firmware
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
            0x0 "$BACKUP_PATH/$BACKUP"
        
        if [ $? -ne 0 ]; then
            echo "Error: Failed to flash firmware"
            exit 1
        fi
        
        sleep 3
        
        sudo systemctl start mastrctrl-server
        
        echo "Firmware rollback successful"
        ;;
        
    *)
        echo "Error: Unknown component: $COMPONENT"
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo "Rollback Complete!"
echo "========================================"
exit 0

