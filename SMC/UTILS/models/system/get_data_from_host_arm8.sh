echo "get-script for ARMv8"
cd /
rm -rf /work/
mkdir -p /work
cd /tmp
mkdir mt
echo "Mounting /dev/sdb1"
mount /dev/sdb1 ./mt
echo "Move all files to /work/"
mv ./mt/* /work/
sync
umount ./mt
rm -rf ./mt
echo "Done!"

