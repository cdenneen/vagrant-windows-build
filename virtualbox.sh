#!/bin/bash

# Creates a VirtualBox VM capable of running the Windows Server 2008 R2 Evaluation VHD
# http://www.microsoft.com/en-au/download/details.aspx?id=16572

if [ ! -f "$1" ]; then 
  echo "Usage: `basename $0` source_vhd_file_path" >&2;
  exit -1;
fi;

SOURCE_VHD=$1;
SOURCE=$(basename -s '.vhd' -a "${SOURCE_VHD}");
TARGET="${SOURCE}.$$";
TARGET_VHD="./${TARGET}.vhd";

echo "Copying $SOURCE_VHD to $TARGET_VHD";
cp -v "${SOURCE_VHD}" "${TARGET_VHD}";

echo "Creating VirtualBox VM to run target image"
VBoxManage createvm --name "${TARGET}" --register;
VBoxManage modifyvm "${TARGET}" --ostype Windows2008_64;
VBoxManage modifyvm "${TARGET}" --memory 2048 --vram 64 --cpus 2 --pae on --ioapic on --hwvirtex on --acpi on --boot1 disk;
VBoxManage modifyvm "${TARGET}" --nic1 nat --nictype1 82545EM;
VBoxManage modifyvm "${TARGET}" --audio none --usb on --usbehci on;
VBoxManage modifyvm "${TARGET}" --clipboard bidirectional --draganddrop disabled;
VBoxManage modifyvm "${TARGET}" --vrde off;

VBoxManage storagectl "${TARGET}" --name "IDE Controller" --add ide;
VBoxManage storageattach "${TARGET}" --storagectl "IDE Controller" --port 0 --device 0 --type hdd --medium "${TARGET_VHD}";
VBoxManage storageattach "${TARGET}" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium emptydrive;

VBoxManage startvm "${TARGET}";
exit $?;
