## Exercise 1
> Exercise 1. Familiarize yourself with the assembly language materials available on the 6.828 reference page. You don't have to read them now, but you'll almost certainly want to refer to some of this material when reading and writing x86 assembly.
<!-- more -->

> We do recommend reading the section "The Syntax" in Brennan's Guide to Inline Assembly. It gives a good (and quite brief) description of the AT&T assembly syntax we'll be using with the GNU assembler in JOS.


---

## Exercise 2
> Use GDB's si (Step Instruction) command to trace into the ROM BIOS for a few more instructions, and try to guess what it might be doing. You might want to look at Phil Storrs I/O Ports Description, as well as other materials on the 6.828 reference materials page. No need to figure out all the details - just the general idea of what the BIOS is doing first.

First of all, I would like to add this line in `~/.gdbinit` :
`set disassembly-flavor intel`, this can make gdb use the Intel style assembly

The BIOS mainly do two things:
* 1. switch the mode to i386
* 2. transfer to the boot sector

Let's trace step by step, I will make comments as well as I can:
```assembly
[f000:fff0]    0xffff0:	jmp    0xf000:0xe05b
```

At first, the target architecture is assumed to be i8086, and as we all know that i8086 can only reach memory of 1MB, as the layout below.

The first instruction is `jmp 0xf000:0xe05b`, and it is in `[f000:fff0]`, which represents the address `0xffff0`, from the layout, we can see this address belongs to the top of BIOS ROM. Since there is no room for instructions at `0xffff0`, so the first instruction is to jump to `0xe05b`.

```plain
                    +------------------+  <- 0xFFFFFFFF (4GB)
                    |      32-bit      |
                    |  memory mapped   |
                    |     devices      |
                    |                  |
                    /\/\/\/\/\/\/\/\/\/\

                    /\/\/\/\/\/\/\/\/\/\
                    |                  |
                    |      Unused      |
                    |                  |
                    +------------------+  <- depends on amount of RAM
                    |                  |
                    |                  |
                    | Extended Memory  |
                    |                  |
                    |                  |
                    +------------------+  <- 0x00100000 (1MB)
                    |     BIOS ROM     |
                    +------------------+  <- 0x000F0000 (960KB)
                    |  16-bit devices, |
                    |  expansion ROMs  |
                    +------------------+  <- 0x000C0000 (768KB)
                    |   VGA Display    |
                    +------------------+  <- 0x000A0000 (640KB)
                    |                  |
                    |    Low Memory    |
                    |                  |
                    +------------------+  <- 0x00000000

```

And then, we can see these instructions:
```assembly
[f000:e05b]    0xfe05b:	cmp    DWORD PTR cs:0x6574,0x0
[f000:e062]    0xfe062:	jne    0xfd2b6
[f000:e066]    0xfe066:	xor    ax,ax
[f000:e068]    0xfe068:	mov    ss,ax
[f000:e06a]    0xfe06a:	mov    esp,0x7000
[f000:e070]    0xfe070:	mov    edx,0xf3c24
[f000:e076]    0xfe076:	jmp    0xfd124
[f000:d124]    0xfd124:	mov    ecx,eax
[f000:d127]    0xfd127:	cli    ;clear interrupt flag
[f000:d128]    0xfd128:	cld    ;clear the direction flag
```
The BIOS then makes some preparations for next stage, such as reset the `ax` register and set the `esp` register.

The important instructions here are cli and cld, it clear the flags, especially the cli instruction, it disable the interrupts so that the following instructions will not be interrupted. As for cld, it clears the direction flag, set it to 0, it means the memory will grow from low memory to high memory.

```assembly
[f000:d129]    0xfd129:	mov    eax,0x8f
[f000:d12f]    0xfd12f:	out    0x70,al
[f000:d131]    0xfd131:	in     al,0x71
```
The `out` and `in` instructions are used to communicate with hardware devices through certain port and the `eax/ax/al` register.
* `in` means to read a `byte/word/dword` from certain port to `al/ax/eax`
* `out` means to write a `byte/word/dword` to certain port from `al/ax/eax`

As for what the ports stand for, [check it here](http://bochs.sourceforge.net/techspec/PORTS.LST).
From that link above, we can see the port 0x70 is the CMOS RAM index register port:
```plain
0070	w	CMOS RAM index register port (ISA, EISA)
		 bit 7	 = 1  NMI disabled
			 = 0  NMI enabled
		 bit 6-0      CMOS RAM index (64 bytes, sometimes 128 bytes)

		any write to 0070 should be followed by an action to 0071
		or the RTC wil be left in an unknown state.
```
Since `0x8f == 0b1000 1111`, we can learn that the NMI has been disabled, NMI stands for `non-maskable interrupt`, [a non-maskable interrupt is a hardware interrupt that standard interrupt-masking techniques in the system cannot ignore. It typically occurs to signal attention for non-recoverable hardware errors](https://en.wikipedia.org/wiki/Non-maskable_interrupt).

This is also to make sure the following interrupt would not be interrupted.

You may be confused about why `in al,0x71` and `in al,0x92` execute in a row, the value read from port 0x71 in `al` will be covered by the value read from port 0x92, you may find the answer [here](http://stackoverflow.com/questions/42593957/bios-read-twice-from-different-port-to-the-same-register-in-a-row). Note that `any write to 0070 should be followed by an action to 0071
or the RTC wil be left in an unknown state`, so this `in al, 0x71` is just to make RTC out of an unknown state.


And then:
```assembly
[f000:d133]    0xfd133:	in     al,0x92
[f000:d135]    0xfd135:	or     al,0x2
[f000:d137]    0xfd137:	out    0x92,al
```
Also, we can check it [here](http://bochs.sourceforge.net/techspec/PORTS.LST), and this is all about port 0x92:
```plain
0092	r/w	PS/2 system control port A  (port B is at 0061)
		 bit 7-6   any bit set to 1 turns activity light on
		 bit 5	   reserved
		 bit 4 = 1 watchdog timout occurred
		 bit 3 = 0 RTC/CMOS security lock (on password area) unlocked
		       = 1 CMOS locked (done by POST)
		 bit 2	   reserved
		 bit 1 = 1 indicates A20 active
		 bit 0 = 0 system reset or write
			 1 pulse alternate reset pin (alternate CPU reset)
```
We can see that it set the bit1 to 1, so this can activate [Fast A20 Gate](http://wiki.osdev.org/A20).

```assembly
[f000:d139]    0xfd139:	lidtw  cs:0x6690
[f000:d13f]    0xfd13f:	lgdtw  cs:0x6650
[f000:d145]    0xfd145:	mov    eax,cr0
[f000:d148]    0xfd148:	or     eax,0x1
[f000:d14c]    0xfd14c:	mov    cr0,eax
[f000:d14f]    0xfd14f:	jmp    0x8:0xfd157
The target architecture is assumed to be i386
```
The lidtw and lgdtw instructions load a linear base address and limit value from a six-byte data operand in memory into the GDTR([register for GDT](https://en.wikipedia.org/wiki/Global_Descriptor_Table)) or IDTR([register for IDT](https://en.wikipedia.org/wiki/Interrupt_descriptor_table)).

And then, it set the bit0 of `cr0` to 1 so that the system will change to protected mode, check the meaning of each bit of `cr0` [here](http://wiki.osdev.org/CPU_Registers_x86#CR0)

The instructions later is really hard to understand for me, so I would just stop here temporarily.
