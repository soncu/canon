# canon
QEMU - Hello World

Please run the script `run_qemu_scipt.sh` as:
`
  ./run_qemu_scipt.sh
`

Wait some time and you will see a Kernel is booting and a message will appear as "hello world".

It will require sudo password for mounting/unmounting temporary filesystem creation.
Currently the Kernel in the host machine is being used but if you uncomment the related lines,
it will download and build the latest Kernel from public address (this operations takes time).

To see the init executable source code, check `init.c` file.
If your system does not contain `QEMU`, `busybox` binaries, you can uncomment the line:
`
  #sudo apt-get install -y qemu qemu-system qemu-utils busybox
`
in the script.
