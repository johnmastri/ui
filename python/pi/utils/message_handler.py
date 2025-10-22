import json
import time

def parse_message(message_str):
    try:
        message = json.loads(message_str)
        if not isinstance(message, dict) or 'type' not in message:
            return None
        return message
    except json.JSONDecodeError:
        return None

def validate_message(message, required_fields):
    for field in required_fields:
        if field not in message:
            return False
    return True

def build_startup(device_id, version, ip, status="ready"):
    return {
        'type': 'startup',
        'device_id': device_id,
        'version': version,
        'ip': ip,
        'status': status,
        'timestamp': int(time.time() * 1000)
    }

def build_heartbeat(device_id, uptime):
    return {
        'type': 'heartbeat',
        'device_id': device_id,
        'uptime': uptime,
        'timestamp': int(time.time() * 1000)
    }

def build_encoder_update(device_id, encoder_id, value, direction):
    return {
        'type': 'encoder',
        'device_id': device_id,
        'encoder_id': encoder_id,
        'value': value,
        'direction': direction,
        'timestamp': int(time.time() * 1000)
    }

def build_button_press(device_id, encoder_id):
    return {
        'type': 'button_press',
        'device_id': device_id,
        'encoder_id': encoder_id,
        'timestamp': int(time.time() * 1000)
    }

def build_status(device_id, stats):
    return {
        'type': 'status',
        'device_id': device_id,
        **stats,
        'timestamp': int(time.time() * 1000)
    }

def build_error(device_id, error_message):
    return {
        'type': 'error',
        'device_id': device_id,
        'error': error_message,
        'timestamp': int(time.time() * 1000)
    }

def build_bridge_status(device_id, connected, stats):
    return {
        'type': 'bridge_status',
        'device_id': device_id,
        'connected': connected,
        'stats': stats,
        'timestamp': int(time.time() * 1000)
    }

def get_timestamp():
    return int(time.time() * 1000)

def format_log_time():
    return time.strftime("%H:%M:%S", time.localtime())

