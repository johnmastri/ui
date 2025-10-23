# Changelog

All notable changes to the MastrCtrl project will be documented in this file.

## [1.0.0] - 2025-10-17

### Added
- Initial OTA update system implementation
- Update Manager service for checking, downloading, and installing updates
- UpdatePanel component in hardware UI
- Server-only update mode as default for rapid debugging
- ESP32 firmware flashing via UART from Raspberry Pi
- Automatic backup system before updates
- Automatic rollback on update failure
- Manual rollback script
- PowerShell deployment script for development
- GitHub Release integration for update distribution
- Systemd service files for all components
- WebSocket-based update progress tracking
- Component selection (UI, Server, Firmware)
- Update versioning and manifest system

### Changed
- Extended ws_serial_bridge.py with update message handlers
- Updated hardware settings store to include System Update option
- Enhanced websocketStore with update-specific methods

### Security
- SHA256 checksum verification for all downloads
- Automatic health checks after updates

## Template for Future Releases

## [X.Y.Z] - YYYY-MM-DD

### Added
- New feature descriptions

### Changed
- Modified feature descriptions

### Fixed
- Bug fix descriptions

### Deprecated
- Features to be removed

### Removed
- Removed features

### Security
- Security-related changes

