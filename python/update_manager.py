import asyncio
import aiohttp
import hashlib
import json
import os
import sys
import shutil
import subprocess
import time
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, List

class UpdateManager:
    def __init__(self, config_path=None):
        if config_path is None:
            if sys.platform == 'win32':
                self.base_path = Path.cwd() / 'mastrctrl_updates'
                config_path = self.base_path / 'update_config.json'
            else:
                self.base_path = Path('/home/pi/mastrctrl')
                config_path = '/home/pi/mastrctrl/update_config.json'
        else:
            self.base_path = Path(config_path).parent
            
        self.config_path = config_path
        self.load_config()
        
        self.staging_path = self.base_path / 'staging'
        self.backup_path = self.base_path / 'backups'
        self.current_path = self.base_path / 'current'
        
        self.staging_path.mkdir(parents=True, exist_ok=True)
        self.backup_path.mkdir(parents=True, exist_ok=True)
        self.current_path.mkdir(parents=True, exist_ok=True)
        
        self.current_versions = self.load_current_versions()
        self.download_progress = {}
        self.update_status = {
            'checking': False,
            'downloading': False,
            'installing': False,
            'error': None
        }
        
    def load_config(self):
        default_config = {
            'github_repo': 'johnmastri/ui',
            'auto_check': True,
            'check_interval_hours': 6,
            'auto_download': False,
            'max_backups': 2
        }
        
        if os.path.exists(self.config_path):
            with open(self.config_path, 'r') as f:
                self.config = {**default_config, **json.load(f)}
        else:
            self.config = default_config
            
    def load_current_versions(self) -> Dict[str, str]:
        version_file = self.current_path / 'version.json'
        if version_file.exists():
            with open(version_file, 'r') as f:
                return json.load(f)
        else:
            return {
                'ui': '0.0.1',
                'server': '0.0.1',
                'firmware': '0.0.1'
            }
            
    def save_current_versions(self):
        version_file = self.current_path / 'version.json'
        with open(version_file, 'w') as f:
            json.dump(self.current_versions, f, indent=2)
            
    @property
    def manifest_url(self):
        return f"https://github.com/{self.config['github_repo']}/releases/latest/download/manifest.json"
        
    async def check_for_updates(self) -> Optional[Dict]:
        self.update_status['checking'] = True
        self.update_status['error'] = None
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(self.manifest_url) as response:
                    if response.status != 200:
                        self.update_status['error'] = f"Failed to fetch manifest: HTTP {response.status}"
                        return None
                    
                    text = await response.text()
                    manifest = json.loads(text)
                    
            available_updates = {}
            for component in ['ui', 'server', 'firmware']:
                if component in manifest['components']:
                    remote_version = manifest['components'][component]['version']
                    local_version = self.current_versions.get(component, '0.0.0')
                    
                    if self._compare_versions(remote_version, local_version) > 0:
                        available_updates[component] = manifest['components'][component]
                        
            if available_updates:
                return {
                    'available': True,
                    'version': manifest['latest_version'],
                    'release_date': manifest['release_date'],
                    'components': available_updates,
                    'release_notes': manifest.get('update_notes', '')
                }
            else:
                return {'available': False}
                
        except Exception as e:
            self.update_status['error'] = f"Update check failed: {str(e)}"
            print(f"[UPDATE MANAGER] Error checking for updates: {e}")
            return None
        finally:
            self.update_status['checking'] = False
            
    def _compare_versions(self, v1: str, v2: str) -> int:
        parts1 = [int(x) for x in v1.split('.')]
        parts2 = [int(x) for x in v2.split('.')]
        
        for p1, p2 in zip(parts1, parts2):
            if p1 > p2:
                return 1
            elif p1 < p2:
                return -1
        return 0
        
    async def download_update(self, component: str, url: str, sha256: str, size_bytes: int) -> bool:
        self.update_status['downloading'] = True
        self.download_progress[component] = {'progress': 0, 'bytes_downloaded': 0, 'bytes_total': size_bytes}
        
        try:
            filename = url.split('/')[-1]
            dest_path = self.staging_path / filename
            
            async with aiohttp.ClientSession() as session:
                async with session.get(url) as response:
                    if response.status != 200:
                        raise Exception(f"Download failed: HTTP {response.status}")
                        
                    with open(dest_path, 'wb') as f:
                        bytes_downloaded = 0
                        async for chunk in response.content.iter_chunked(8192):
                            f.write(chunk)
                            bytes_downloaded += len(chunk)
                            
                            self.download_progress[component]['bytes_downloaded'] = bytes_downloaded
                            self.download_progress[component]['progress'] = bytes_downloaded / size_bytes
                            
            if not self._verify_checksum(dest_path, sha256):
                raise Exception("Checksum verification failed")
                
            print(f"[UPDATE MANAGER] Downloaded {component}: {filename}")
            return True
            
        except Exception as e:
            self.update_status['error'] = f"Download failed for {component}: {str(e)}"
            print(f"[UPDATE MANAGER] Error downloading {component}: {e}")
            return False
        finally:
            self.update_status['downloading'] = False
            
    def _verify_checksum(self, file_path: Path, expected_sha256: str) -> bool:
        sha256_hash = hashlib.sha256()
        with open(file_path, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b""):
                sha256_hash.update(chunk)
        return sha256_hash.hexdigest() == expected_sha256
        
    def create_backup(self, component: str):
        timestamp = datetime.now().strftime('%Y-%m-%d-%H%M%S')
        backup_name = f"{component}-{timestamp}"
        backup_dest = self.backup_path / backup_name
        
        if component == 'ui':
            source = self.current_path / 'ui'
            if source.exists():
                shutil.copytree(source, backup_dest)
        elif component == 'server':
            source = self.current_path / 'python'
            if source.exists():
                shutil.copytree(source, backup_dest)
        elif component == 'firmware':
            source = self.current_path / 'firmware.bin'
            if source.exists():
                shutil.copy2(source, backup_dest.with_suffix('.bin'))
                
        print(f"[UPDATE MANAGER] Created backup: {backup_name}")
        
        self._cleanup_old_backups(component)
        
    def _cleanup_old_backups(self, component: str):
        backups = sorted(
            [b for b in self.backup_path.iterdir() if b.name.startswith(component)],
            key=lambda x: x.stat().st_mtime,
            reverse=True
        )
        
        for old_backup in backups[self.config['max_backups']:]:
            if old_backup.is_dir():
                shutil.rmtree(old_backup)
            else:
                old_backup.unlink()
            print(f"[UPDATE MANAGER] Removed old backup: {old_backup.name}")
            
    def apply_ui_update(self, version: str) -> bool:
        try:
            print(f"[UPDATE MANAGER] Applying UI update to v{version}")
            
            self.create_backup('ui')
            
            subprocess.run(['sudo', 'systemctl', 'stop', 'mastrctrl-ui'], check=True)
            
            zip_file = self.staging_path / f"ui-v{version}.zip"
            ui_dest = self.current_path / 'ui'
            
            if ui_dest.exists():
                shutil.rmtree(ui_dest)
                
            shutil.unpack_archive(zip_file, ui_dest)
            
            subprocess.run(['sudo', 'systemctl', 'start', 'mastrctrl-ui'], check=True)
            
            if self._verify_service_running('mastrctrl-ui'):
                self.current_versions['ui'] = version
                self.save_current_versions()
                print(f"[UPDATE MANAGER] UI update successful")
                return True
            else:
                raise Exception("UI service failed to start")
                
        except Exception as e:
            print(f"[UPDATE MANAGER] UI update failed: {e}")
            self.rollback('ui')
            return False
            
    def apply_server_update(self, version: str) -> bool:
        try:
            print(f"[UPDATE MANAGER] Applying server update to v{version}")
            
            self.create_backup('server')
            
            subprocess.run(['sudo', 'systemctl', 'stop', 'mastrctrl-server'], check=True)
            
            zip_file = self.staging_path / f"server-v{version}.zip"
            server_dest = self.current_path / 'python'
            
            if server_dest.exists():
                shutil.rmtree(server_dest)
                
            shutil.unpack_archive(zip_file, server_dest)
            
            requirements_file = server_dest / 'requirements.txt'
            if requirements_file.exists():
                subprocess.run(['pip3', 'install', '-r', str(requirements_file)], check=True)
            
            subprocess.run(['sudo', 'systemctl', 'start', 'mastrctrl-server'], check=True)
            
            time.sleep(3)
            
            if self._verify_service_running('mastrctrl-server'):
                self.current_versions['server'] = version
                self.save_current_versions()
                print(f"[UPDATE MANAGER] Server update successful")
                return True
            else:
                raise Exception("Server service failed to start")
                
        except Exception as e:
            print(f"[UPDATE MANAGER] Server update failed: {e}")
            self.rollback('server')
            return False
            
    def apply_firmware_update(self, version: str) -> bool:
        try:
            print(f"[UPDATE MANAGER] Applying firmware update to v{version}")
            
            self.create_backup('firmware')
            
            firmware_file = self.staging_path / f"firmware-v{version}.bin"
            
            subprocess.run(['sudo', 'systemctl', 'stop', 'mastrctrl-server'], check=True)
            time.sleep(1)
            
            result = subprocess.run([
                'esptool.py',
                '--port', '/dev/serial0',
                '--baud', '460800',
                '--before', 'default_reset',
                '--after', 'hard_reset',
                '--chip', 'esp32s3',
                'write_flash',
                '--flash_mode', 'dio',
                '--flash_freq', '80m',
                '--flash_size', 'detect',
                '0x0', str(firmware_file)
            ], capture_output=True, text=True)
            
            if result.returncode != 0:
                raise Exception(f"esptool failed: {result.stderr}")
                
            time.sleep(3)
            
            subprocess.run(['sudo', 'systemctl', 'start', 'mastrctrl-server'], check=True)
            time.sleep(2)
            
            shutil.copy2(firmware_file, self.current_path / 'firmware.bin')
            
            self.current_versions['firmware'] = version
            self.save_current_versions()
            print(f"[UPDATE MANAGER] Firmware update successful")
            return True
            
        except Exception as e:
            print(f"[UPDATE MANAGER] Firmware update failed: {e}")
            self.rollback('firmware')
            return False
            
    def _verify_service_running(self, service_name: str) -> bool:
        try:
            result = subprocess.run(
                ['systemctl', 'is-active', service_name],
                capture_output=True,
                text=True
            )
            return result.stdout.strip() == 'active'
        except:
            return False
            
    def rollback(self, component: str) -> bool:
        try:
            print(f"[UPDATE MANAGER] Rolling back {component}")
            
            backups = sorted(
                [b for b in self.backup_path.iterdir() if b.name.startswith(component)],
                key=lambda x: x.stat().st_mtime,
                reverse=True
            )
            
            if not backups:
                print(f"[UPDATE MANAGER] No backup found for {component}")
                return False
                
            latest_backup = backups[0]
            
            if component == 'ui':
                subprocess.run(['sudo', 'systemctl', 'stop', 'mastrctrl-ui'], check=True)
                ui_dest = self.current_path / 'ui'
                if ui_dest.exists():
                    shutil.rmtree(ui_dest)
                shutil.copytree(latest_backup, ui_dest)
                subprocess.run(['sudo', 'systemctl', 'start', 'mastrctrl-ui'], check=True)
                
            elif component == 'server':
                subprocess.run(['sudo', 'systemctl', 'stop', 'mastrctrl-server'], check=True)
                server_dest = self.current_path / 'python'
                if server_dest.exists():
                    shutil.rmtree(server_dest)
                shutil.copytree(latest_backup, server_dest)
                subprocess.run(['sudo', 'systemctl', 'start', 'mastrctrl-server'], check=True)
                
            elif component == 'firmware':
                firmware_dest = self.current_path / 'firmware.bin'
                shutil.copy2(latest_backup, firmware_dest)
                
            print(f"[UPDATE MANAGER] Rollback successful for {component}")
            return True
            
        except Exception as e:
            print(f"[UPDATE MANAGER] Rollback failed for {component}: {e}")
            return False
            
    def get_status(self) -> Dict:
        return {
            'current_versions': self.current_versions,
            'update_status': self.update_status,
            'download_progress': self.download_progress
        }

