## Exercise 3
>Take a look at the lab tools guide, especially the section on GDB commands. Even if you're familiar with GDB, this includes some esoteric GDB commands that are useful for OS work.
<!-- more -->

>Set a breakpoint at address 0x7c00, which is where the boot sector will be loaded. Continue execution until that breakpoint. Trace through the code in boot/boot.S, using the source code and the disassembly file obj/boot/boot.asm to keep track of where you are. Also use the x/i command in GDB to disassemble sequences of instructions in the boot loader, and compare the original boot loader source code with both the disassembly in obj/boot/boot.asm and GDB.

>Trace into bootmain() in boot/main.c, and then into readsect(). Identify the exact assembly instructions that correspond to each of the statements in readsect(). Trace through the rest of readsect() and back out into bootmain(), and identify the begin and end of the for loop that reads the remaining sectors of the kernel from the disk. Find out what code will run when the loop is finished, set a breakpoint there, and continue to that breakpoint. Then step through the remainder of the boot loader. **

### All about boot.S
Ok, now we are going to trace the boot sector, using gdb as usual. After attaching gdb to qemu, input `b *0x7c00` to set breakpoint at 0x7c00, where the boot sector will be loaded.

```assembly
[   0:7c00] => 0x7c00:	cli ;disable interrupt
[   0:7c01] => 0x7c01:	cld ;clear direction flag
[   0:7c02] => 0x7c02:	xor    ax,ax ;clear ax
[   0:7c04] => 0x7c04:	mov    ds,ax ;clear ds
[   0:7c06] => 0x7c06:	mov    es,ax ;clear es
[   0:7c08] => 0x7c08:	mov    ss,ax ;clear ss
```
First, just like we talked about before in Exercise1&&2, these are the preparation instructions. You can see the usage of them according to the comment.

```assembly
[   0:7c0a] => 0x7c0a:	in     al,0x64
[   0:7c0c] => 0x7c0c:	test   al,0x2
[   0:7c0e] => 0x7c0e:	jne    0x7c0a
```
We can see according to the code above that these three instructions form a loop, it keeps checking the bit1 of the port 0x64, if this bit is not 1, then breaks. These instructions are used to guarantee this instructions executed before are fetched by CPU.
check [here](http://bochs.sourceforge.net/techspec/PORTS.LST) to see how the port 0x64 works.

```plain
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

```assembly
[   0:7c10] => 0x7c10:	mov    al,0xd1
[   0:7c12] => 0x7c12:	out    0x64,al
[   0:7c14] => 0x7c14:	in     al,0x64
[   0:7c16] => 0x7c16:	test   al,0x2
[   0:7c18] => 0x7c18:	jne    0x7c14
```
Now the boot sector want to write 0xd1 to port 0x64, check [here](http://bochs.sourceforge.net/techspec/PORTS.LST) again, we can see things below:
```plain
D1	dbl   write output port. next byte written  to 0060
			      will be written to the 804x output port; the
			      original IBM AT and many compatibles use bit 1 of
			      the output port to control the A20 gate.
```
Also, the last 3 instructions above which are also a loop is trying to see if the instructions before are fetched by CPU.

```assembly
[   0:7c1a] => 0x7c1a:	mov    al,0xdf
[   0:7c1c] => 0x7c1c:	out    0x60,al
```
This is one problem that I haven't figured out yet, the `0xdf` is send to port `0x60`, but I think it is actually sent to port `0x64`, I don't know how it works.
```plain
0064	w  DF	sngl  enable address line A20 (HP Vectra only???)
```

```assembly
[   0:7c1e] => 0x7c1e:	lgdtw  ds:0x7c64 ;load Global Descriptor Table Register
[   0:7c23] => 0x7c23:	mov    eax,cr0
[   0:7c26] => 0x7c26:	or     eax,0x1
[   0:7c2a] => 0x7c2a:	mov    cr0,eax ; set bit0 so it can change to protected mode check [here](http://wiki.osdev.org/CPU_Registers_x86#CR0)
[   0:7c2d] => 0x7c2d:	jmp    0x8:0x7c32 ;jump to 32-bit code segment
```

```assembly
=> 0x7c32:	mov    ax,0x10 ; ax =  0x10 = kernel data segment selector
=> 0x7c36:	mov    ds,eax  ; ds = 0x10
=> 0x7c38:	mov    es,eax  ; es = 0x10
=> 0x7c3a:	mov    fs,eax  ; fs = 0x10
=> 0x7c3c:	mov    gs,eax  ; gs = 0x10
=> 0x7c3e:	mov    ss,eax  ; ss = 0x10
=> 0x7c40:	mov    esp,0x7c00 ; use 0x7c00 as the stack top, so the stack won't grow until cover the boot sector
=> 0x7c45:	call   0x7d0a  ; jump to bootmain C function
```

### All about main.c
While trace the main.c, I will draw the `stack` for you.

```assembly
=> 0x7d0a:	push   ebp
=> 0x7d0b:	mov    ebp,esp ; create new frame of bootmain
=> 0x7d0d:	push   esi
=> 0x7d0e:	push   ebx ; save the values used in the caller function
=> 0x7d0f:	push   0x0 ; push parameter3 of the readseg
=> 0x7d11:	push   0x1000 ; push parameter2 of the readseg
=> 0x7d16:	push   0x10000 ; push parameter1 of the readseg
```
At first, we should know something about how the stack works when calling functions. Look at the picture below:
![](http://images.cnitblog.com/i/569008/201405/271644419475745.jpg)
We should now that the sequence of pushing data. First, if the function has parameters, push them from right to left, then push the `eip`, which is the return address of the caller function, and then it executes the normal `push ebp` and `mov ebp, esp`, and finally, then local variables.

Until now, the stack should be like this:
```plain
          +------------------+  <-
          |                  |
          +------------------+  <- esp = ebp-0x14 = 0x7be4
          |    0x00010000    |
          +------------------+  <- ebp-0x10 = 0x7be8
          |    0x00001000    |
          +------------------+  <- ebp-0xc = 0x7bec
          |    0x00000000    |
          +------------------+  <- ebp-0x8 = 0x7bf0 : parameter3 of readseg
          |    0x00000000    |
          +------------------+  <- ebp-0x4 = 0x7bf4 : value of ebx
          |    0x00000000    |
          +------------------+  <- ebp = 0x7bf8 : value of esi
          |    0x00000000    |
          +------------------+  <- 0x7bfc : ret address
          |    0x00007c4a    |
          +------------------+  <- 0x7c00
          |     boot.S       |
          +------------------+  <-
          |                  |
          +------------------+  <- 0x00000000

```
We can see the return address `0x00007c4a` and the original `esp` `0x7c00` in `boot.asm`:
```plain
# Set up the stack pointer and call into C.
movl    $start, %esp
  7c40:	bc 00 7c 00 00       	mov    $0x7c00,%esp
call bootmain
  7c45:	e8 c0 00 00 00       	call   7d0a <bootmain>

00007c4a <spin>:

# If bootmain returns (it shouldn't), loop.
spin:
jmp spin
  7c4a:	eb fe                	jmp    7c4a <spin>
```
we can see `move $0x7c00, $esp` and `jmp 7c4a` here.


```assembly
=> 0x7d1b:	call   0x7cd1 ; jump to readseg
=> 0x7cd1:	push   ebp
=> 0x7cd2:	mov    ebp,esp ; create new frame of readseg
=> 0x7cd4:	push   edi ;
=> 0x7cd5:	mov    edi,DWORD PTR [ebp+0xc] ; edi =
=> 0x7cd8:	push   esi
=> 0x7cd9:	mov    esi,DWORD PTR [ebp+0x10]
=> 0x7cdc:	push   ebx
=> 0x7cdd:	mov    ebx,DWORD PTR [ebp+0x8]
=> 0x7ce0:	shr    esi,0x9
```

Now the stack looks like this:
```
+------------------+  <-
|                  |
+------------------+  <-
|    0x00010000    |
+------------------+  <-
|    0x00001000    |
+------------------+  <- ebp-0x4 = 0x7bd4 : [ebp+0xc]=[0x7de8]=0x10000
|    0x00000000    |
+------------------+  <- ebp = 0x7bd8 : value of edi
|    0x00000000    |
+------------------+  <- 0x7bdc : ebp of bootmain
|    0x00007df8    |
+------------------+  <- 0x7be0
|    0x00007d20    |
+------------------+  <- 0x7be4 : return address
| stack of bootmain|
+------------------+  <- 0x7c00
|     boot.S       |
+------------------+  <-
|                  |
+------------------+  <- 0x00000000
```



### Another way to see it
`cat kernel.img | xxd | head -n 32`


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
