## Exercise 3
>Take a look at the lab tools guide, especially the section on GDB commands. Even if you're familiar with GDB, this includes some esoteric GDB commands that are useful for OS work.

>Set a breakpoint at address 0x7c00, which is where the boot sector will be loaded. Continue execution until that breakpoint. Trace through the code in boot/boot.S, using the source code and the disassembly file obj/boot/boot.asm to keep track of where you are. Also use the x/i command in GDB to disassemble sequences of instructions in the boot loader, and compare the original boot loader source code with both the disassembly in obj/boot/boot.asm and GDB.

>Trace into bootmain() in boot/main.c, and then into readsect(). Identify the exact assembly instructions that correspond to each of the statements in readsect(). Trace through the rest of readsect() and back out into bootmain(), and identify the begin and end of the for loop that reads the remaining sectors of the kernel from the disk. Find out what code will run when the loop is finished, set a breakpoint there, and continue to that breakpoint. Then step through the remainder of the boot loader. **

### All about boot.S
Ok, now we are going to trace the boot sector, using gdb as usual. After attaching gdb to qemu, input `b *0x7c00` to set breakpoint at 0x7c00, where the boot sector will be loaded.

```
[   0:7c00] => 0x7c00:	cli ;disable interrupt
[   0:7c01] => 0x7c01:	cld ;clear direction flag
[   0:7c02] => 0x7c02:	xor    ax,ax ;clear ax
[   0:7c04] => 0x7c04:	mov    ds,ax ;clear ds
[   0:7c06] => 0x7c06:	mov    es,ax ;clear es
[   0:7c08] => 0x7c08:	mov    ss,ax ;clear ss
```
First, just like we talked about before in Exercise1&&2, these are the preparation instructions. You can see the usage of them according to the comment.

```
[   0:7c0a] => 0x7c0a:	in     al,0x64
[   0:7c0c] => 0x7c0c:	test   al,0x2
[   0:7c0e] => 0x7c0e:	jne    0x7c0a
```
We can see according to the code above that these three instructions form a loop, it keeps checking the bit1 of the port 0x64, if this bit is not 1, then breaks.
check [here](http://bochs.sourceforge.net/techspec/PORTS.LST) to see how the port 0x64 works.

```
0064	r	KB controller read status (ISA, EISA)
		 bit 7 = 1 parity error on transmission from keyboard
		 bit 6 = 1 receive timeout
		 bit 5 = 1 transmit timeout
		 bit 4 = 0 keyboard inhibit
		 bit 3 = 1 data in input register is command
			 0 data in input register is data
		 bit 2	 system flag status: 0=power up or reset  1=selftest OK
		 bit 1 = 1 input buffer full (input 60/64 has data for 8042)
		 bit 0 = 1 output buffer full (output 60 has data for system)
...
```
Evidently, this loop is trying to see whether the input buffer is full, if not, then breaks the loop.

```
[   0:7c10] => 0x7c10:	mov    al,0xd1
[   0:7c12] => 0x7c12:	out    0x64,al
[   0:7c14] => 0x7c14:	in     al,0x64
[   0:7c16] => 0x7c16:	test   al,0x2
[   0:7c18] => 0x7c18:	jne    0x7c14
```


### All about main.c



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
