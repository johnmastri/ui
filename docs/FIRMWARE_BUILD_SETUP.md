# Firmware Build Setup

## Overview

The release script can automatically build ESP32 firmware if Arduino CLI is properly configured. This document explains how to set it up.

## Prerequisites

### 1. Install Arduino CLI

```powershell
winget install ArduinoSA.CLI
```

After installation, restart your terminal or refresh the PATH:

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

### 2. Configure Arduino CLI for ESP32

Initialize the configuration:

```powershell
arduino-cli config init
```

Add the ESP32 board manager URL:

```powershell
arduino-cli config add board_manager.additional_urls https://espressif.github.io/arduino-esp32/package_esp32_index.json
```

Update the board index:

```powershell
arduino-cli core update-index
```

### 3. Install ESP32 Core

This is a large download (~1GB) and may take several minutes:

```powershell
arduino-cli core install esp32:esp32
```

If the download times out or fails:
- Wait a few minutes and try again (it will resume from where it left off)
- Try using a faster internet connection
- As a last resort, install manually via Arduino IDE (File > Preferences > Additional Board Manager URLs, then Tools > Board > Boards Manager > esp32)

### 4. Verify Installation

Check that ESP32 core is installed:

```powershell
arduino-cli core list
```

You should see `esp32:esp32` in the list.

Test compilation (from the esp32/MasterController directory):

```powershell
arduino-cli compile --fqbn esp32:esp32:esp32s3 MasterController.ino
```

## Building Firmware

### With Release Script

Once configured, the release script will automatically build firmware:

```powershell
.\scripts\create_release.ps1 -Version 1.0.0
```

### Manual Build

If you need to build manually:

```powershell
cd package/esp32/MasterController
arduino-cli compile --fqbn esp32:esp32:esp32s3 MasterController.ino --output-dir ../../scripts/release
```

The compiled firmware will be in the output directory as `MasterController.ino.bin`.

### Skip Firmware Build

To create a release without rebuilding firmware:

```powershell
.\scripts\create_release.ps1 -Version 1.0.0 -SkipBuild
```

Place a pre-built `firmware-v1.0.0.bin` file in the release directory manually.

## Troubleshooting

### arduino-cli not found

Make sure Arduino CLI is in your PATH. After installation, you may need to:
- Restart your terminal
- Refresh the PATH environment variable
- Log out and back in (for system-wide PATH changes)

### ESP32 core not found

Run `arduino-cli core list` to check if esp32:esp32 is installed. If not, run:

```powershell
arduino-cli core install esp32:esp32
```

### Compilation errors

Check that:
- The firmware source exists at `package/esp32/MasterController/`
- All required libraries are installed
- The board FQBN is correct: `esp32:esp32:esp32s3`

For the Seeed Studio XIAO ESP32-S3, the FQBN is:
```
esp32:esp32:esp32s3
```

If you need a more specific variant, list available boards:

```powershell
arduino-cli board listall esp32s3
```

### Download timeouts

The ESP32 core package is very large. If downloads timeout:
- Ensure you have a stable internet connection
- Try again later when the connection is better
- The Arduino CLI will resume partial downloads
- Consider using Arduino IDE as an alternative installation method

## Alternative: Arduino IDE

If Arduino CLI is problematic, you can use Arduino IDE to compile:

1. Install Arduino IDE 2.x
2. Add ESP32 board URL in Preferences
3. Install ESP32 boards via Board Manager
4. Open `MasterController.ino`
5. Select board: Tools > Board > esp32 > ESP32S3 Dev Module
6. Select Sketch > Export Compiled Binary
7. Copy the .bin file to the release directory

## Board Configuration

For Seeed Studio XIAO ESP32-S3:

- Board: ESP32S3 Dev Module
- USB CDC On Boot: Enabled
- CPU Frequency: 240MHz
- Flash Mode: QIO
- Flash Size: 8MB
- Partition Scheme: Default
- PSRAM: OPI PSRAM

