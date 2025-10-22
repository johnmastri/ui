#!/bin/bash

# USB Gadget Setup Script - RNDIS for Windows with DHCP
# Configfs-based gadget configuration for modern kernels
# Auto-starts on boot via systemd service

sleep 5

modprobe libcomposite

cd /sys/kernel/config/usb_gadget/
mkdir -p pi4
cd pi4

echo 0x045e > idVendor
echo 0x07ab > idProduct
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

echo 0xEF > bDeviceClass
echo 0x02 > bDeviceSubClass  
echo 0x01 > bDeviceProtocol

mkdir -p strings/0x409
echo "fedcba9876543210" > strings/0x409/serialnumber
echo "Microsoft" > strings/0x409/manufacturer
echo "RNDIS/Ethernet Gadget" > strings/0x409/product

mkdir -p configs/c.1/strings/0x409
echo "RNDIS Configuration" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower

mkdir -p functions/rndis.usb0
echo "00:dc:c8:f7:75:14" > functions/rndis.usb0/host_addr
echo "00:dd:dc:eb:6d:a1" > functions/rndis.usb0/dev_addr

mkdir -p os_desc
echo 1 > os_desc/use
echo 0xcd > os_desc/b_vendor_code
echo MSFT100 > os_desc/qw_sign

ln -s functions/rndis.usb0 configs/c.1/
ln -s configs/c.1 os_desc/c.1

ls /sys/class/udc > UDC

sleep 3

ip addr add 192.168.4.1/24 dev usb0
ip link set usb0 up

echo "USB Gadget configured at 192.168.4.1"

