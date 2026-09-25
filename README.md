# rvunix

[![License: GPL v3](https://shields.io)](https://gnu.org)
![Architecture: RISC-V](https://shields.io)

**rvunix** is an UNIX-like operating system written entirely in **RISC-V assembly**. 

The main purpose of this project is to provide a highly documented, minimalistic UNIX-like operating system tailored for RISC-V research, academic study, and low-level development.

---

## Features

* **Sv39 Virtual Memory:** Full support for Sv39 page-based virtual memory system.
* **Memory Management:** Includes a basic memory allocator.
* **Userspace:** Userspace support paired with basic system calls.
* **RISC-V Timer:** Built-in timer support **(requires Sstc extension)**.
* **Peripherals:** 16550 UART driver.
* **Privilege Modes:** Comprehensive trap handlers for M-mode, S-mode, and U-mode.

## Roadmap

- [ ] Peripherals
    - [x] RISC-V Timer support
    - [x] 16550 UART support
    - [ ] Interrupt controller support
    - [ ] Virtio-blk support
    - [ ] DMA support
- [x] Trap handlers
    - [x] M-mode trap handler
    - [x] S-mode trap handler
    - [x] U-mode trap handler
- [ ] Memory management
    - [x] Physical memory manager
    - [ ] Heap manager
    - [x] Sv39 Virtual memory
    - [ ] Sv48 Virtual memory
- [ ] Userspace
    - [ ] Process management
        - [ ] Process creation
        - [ ] Process handling
        - [ ] Scheduler
        - [ ] Executable loading
        - [ ] File descriptors
        - [ ] Process isolation
        - [ ] Shared memory
    - [ ] Userspace programs
        - [ ] coreutils
        - [ ] libc
        - [ ] sh

---

## Compatibility

Currently, the system supports:
* **QEMU VIRT board** equipped with a **rv64** processor.

---

## Building and Running

### Prerequisites

You must have the following toolchain and emulators installed on your system:
* `make`
* `riscv64-linux-gnu-gcc`
* `riscv64-linux-gnu-binutils`
* `qemu-system-riscv64`

### 1. Compile the Kernel

Compile the kernel specifically for the QEMU VIRT board by running:

```bash
make CROSS_PREFIX=riscv64-linux-gnu-
```

### 2. Run the Kernel in QEMU

Launch the compiled kernel in the QEMU emulator with the following command:

```bash
qemu-system-riscv64 -M virt -bios build/rvkrnl.bin -nographic
```

---

## License

This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.
