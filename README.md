# Bare-Metal x86 Pong

A classic Pong game written entirely in 16-bit x86 Assembly. The game runs directly on bare metal without an operating system, fitting completely inside a standard 512-byte boot sector.

## Architecture & Features
* **Bare Metal Execution:** Runs natively as a bootloader. 
* **Graphics:** Utilizes BIOS interrupt `0x10` (VGA Mode 13h) for rendering pixels directly to the screen.
* **Input Handling:** Uses BIOS interrupt `0x16` for real-time keyboard input.
* **Size Constraint:** Fully optimized to execute within the strict 512-byte limit of the Master Boot Record (MBR), including the `0xAA55` magic number.

## Execution
To run the game using QEMU:
```bash
# Assuming the compiled binary is named pong.bin
qemu-system-i386 -drive format=raw,file=pong.bin
