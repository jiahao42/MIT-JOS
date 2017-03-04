## Exercise 3
>Take a look at the lab tools guide, especially the section on GDB commands. Even if you're familiar with GDB, this includes some esoteric GDB commands that are useful for OS work.

>Set a breakpoint at address 0x7c00, which is where the boot sector will be loaded. Continue execution until that breakpoint. Trace through the code in boot/boot.S, using the source code and the disassembly file obj/boot/boot.asm to keep track of where you are. Also use the x/i command in GDB to disassemble sequences of instructions in the boot loader, and compare the original boot loader source code with both the disassembly in obj/boot/boot.asm and GDB.

>Trace into bootmain() in boot/main.c, and then into readsect(). Identify the exact assembly instructions that correspond to each of the statements in readsect(). Trace through the rest of readsect() and back out into bootmain(), and identify the begin and end of the for loop that reads the remaining sectors of the kernel from the disk. Find out what code will run when the loop is finished, set a breakpoint there, and continue to that breakpoint. Then step through the remainder of the boot loader. **



---

* In gdb, after push the 3 parameters, it will call readseg() at 0x7d1b
    * pushing 0x0(at 0x7d0f), 0x1000(at 0x7d11) and 0x10000(at 0x7d16) in a sequence means push the parameters of readseg() onto stack
    * ```push ebp && mov ebp esp``` means to start a new frame


* At what point does the processor start executing 32-bit code? What exactly causes the switch from 16- to 32-bit mode?

    * after a jmp or ljmp
    * jmp 0x8:0xfd157

* What is the *last* instruction of the boot loader executed, and what is the first instruction of the kernel it just loaded?
    * The repnz instruction read 4 bytes at a time from port 0x1f0, the first 4 bytes it reads are the magic number of ELF header, which is ```0x7f 0x45 0x4c 0x46```, and ```0x45 0x4c 0x46``` means *ELF*
    * Actually, you can read the kernel like this: ```cat kernel.img | xxd | head 10```, then you can see the first 16*10 bytes of the kernel


* *Where* is the first instruction of the kernel?



* How does the boot loader decide how many sectors it must read in order to fetch the entire kernel from disk? Where does it find this information?
