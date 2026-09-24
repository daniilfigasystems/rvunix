# rvunix
## rvunix is an UNIX-like operating system written in RISC-V assembly
## Features
Sv39 Virtual memory support<br>
Basic memory allocator<br>
Userspace and system calls<br>
RISC-V Timer support **(requires Sstc extension)**<br>
16550 UART<br>
M-mode, S-mode, U-mode trap handler
## Main purpose
A highly documented UNIX-like operating system for RISC-V research purposes
## Compatibility
### Currently supports:
```
QEMU VIRT board with rv64 processor
```
## Building and running
__You must have: make, riscv64-linux-gnu-gcc, riscv64-linux-gnu-binutils, qemu-system-riscv64 installed on your system__
Compile kernel for QEMU VIRT board
```
make CROSS_PREFIX=riscv64-linux-gnu-
```
Run kernel in QEMU
```
qemu-system-riscv64 -M virt -bios build/rvkrnl.bin -nographic
```