## lab1-exercise 6

> Exercise 6. We can examine memory using GDB's x command. The GDB manual has full details, but for now, it is enough to know that the command x/Nx ADDR prints N words of memory at ADDR. (Note that both 'x's in the command are lowercase.) Warning: The size of a word is not a universal standard. In GNU assembly, a word is two bytes (the 'w' in xorw, which stands for word, means 2 bytes).


> Reset the machine (exit QEMU/GDB and start them again). Examine the 8 words of memory at 0x00100000 at the point the BIOS enters the boot loader, and then again at the point the boot loader enters the kernel. Why are they different? What is there at the second breakpoint? (You do not really need to use QEMU to answer this question. Just think.)


At the point the BIOS enters the boot sector, the content at the address `0x00100000` is all zeros.

At the point the boot loader enters the kernel, the content at the address `0x00100000` is the `.text` section in the kernel. The bootloader reads it using `readseg` after having read the header of the kernel.

```C
// load each program segment (ignores ph flags)
ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
eph = ph + ELFHDR->e_phnum;
for (; ph < eph; ph++)
  // p_pa is the load address of this segment (as well
  // as the physical address)
  /*
   * p_pa = 0x100000 p_memsz = 0x72ca p_offset = 0x1000
   * which means to read 0x72ca bytes(Size in bytes of the segment in memory) to 0x100000 from No.((offset / SECTSIZE) + 1) sector.
   */
  readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
```
