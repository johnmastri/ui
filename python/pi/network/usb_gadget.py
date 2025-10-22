import subprocess
import re

def check_usb_gadget():
    status = {
        'usb0_exists': False,
        'ip_configured': False,
        'dwc2_loaded': False,
        'g_ether_loaded': False,
        'ip_address': None
    }
    
    try:
        result = subprocess.run(['ip', 'addr', 'show', 'usb0'], 
                               capture_output=True, text=True, timeout=2)
        if result.returncode == 0 and 'usb0' in result.stdout:
            status['usb0_exists'] = True
            
            ip_match = re.search(r'inet (\d+\.\d+\.\d+\.\d+)', result.stdout)
            if ip_match:
                status['ip_address'] = ip_match.group(1)
                if '192.168.4.1' in result.stdout:
                    status['ip_configured'] = True
    except:
        pass
    
    try:
        result = subprocess.run(['lsmod'], capture_output=True, text=True, timeout=2)
        if 'dwc2' in result.stdout:
            status['dwc2_loaded'] = True
        if 'g_ether' in result.stdout:
            status['g_ether_loaded'] = True
    except:
        pass
    
    return status

def print_usb_status(status):
    print("\n[USB GADGET STATUS]")
    print(f"  usb0 interface: {'✓' if status['usb0_exists'] else '✗'}")
    print(f"  IP configured:  {'✓' if status['ip_configured'] else '✗'} ({status['ip_address']})")
    print(f"  dwc2 module:    {'✓' if status['dwc2_loaded'] else '✗'}")
    print(f"  g_ether module: {'✓' if status['g_ether_loaded'] else '✗'}")
    
    if not all([status['usb0_exists'], status['ip_configured']]):
        print("\n  ⚠ USB gadget mode not fully configured")
        print("  Run: sudo bash setup/usb_gadget_setup.sh")
    print()

