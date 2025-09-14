sudo chown $USER:$USER build/main_disk.raw
qemu-system-i386 -hda build/main_disk.raw
