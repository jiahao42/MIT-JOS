### lab1-exercise5

In `boot/Makefrag`, we can find these following line:

```
$(OBJDIR)/boot/boot: $(BOOT_OBJS)
	@echo + ld boot/boot
	$(V)$(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 -o $@.out $^
	$(V)$(OBJDUMP) -S $@.out >$@.asm
	$(V)$(OBJCOPY) -S -O binary -j .text $@.out $@
	$(V)perl boot/sign.pl $(OBJDIR)/boot/boot
```
We can see that `-Ttext 0x7C00` in it, then we can change it to `-Ttext 0x7E00`

Then we run the bootloader, break at `0x7C00` as usual, after a few instructions, we can see the difference comparing to the right one.
```
[   0:7c00] => 0x7c00:	cli    
[   0:7c01] => 0x7c01:	cld    
[   0:7c02] => 0x7c02:	xor    ax,ax
[   0:7c04] => 0x7c04:	mov    ds,ax
[   0:7c06] => 0x7c06:	mov    es,ax
[   0:7c08] => 0x7c08:	mov    ss,ax
[   0:7c0a] => 0x7c0a:	in     al,0x64
[   0:7c0c] => 0x7c0c:	test   al,0x2
[   0:7c0e] => 0x7c0e:	jne    0x7c0a
[   0:7c10] => 0x7c10:	mov    al,0xd1
[   0:7c12] => 0x7c12:	out    0x64,al
[   0:7c14] => 0x7c14:	in     al,0x64
[   0:7c16] => 0x7c16:	test   al,0x2
[   0:7c18] => 0x7c18:	jne    0x7c14
[   0:7c1a] => 0x7c1a:	mov    al,0xdf
[   0:7c1c] => 0x7c1c:	out    0x60,al
[   0:7c1e] => 0x7c1e:	lgdtw  ds:0x7e64
[   0:7c23] => 0x7c23:	mov    eax,cr0
[   0:7c26] => 0x7c26:	or     eax,0x1
[   0:7c2a] => 0x7c2a:	mov    cr0,eax
[   0:7c2d] => 0x7c2d:	jmp    0x8:0x7e32 ; this should lead the program to the protected mode
[f000:e05b]    0xfe05b:	cmp    DWORD PTR cs:0x6574,0x0
[f000:e062]    0xfe062:	jne    0xfd2b6
```
This should be caused by `[   0:7c1e] => 0x7c1e:	lgdtw  ds:0x7e64`, when we check the value in `0x07e64`, you can see only zeros.
```
; When the VMA = 0x7E00
[   0:7c1e] => 0x7c1e:	lgdtw  ds:0x7e64
0x00007c1e in ?? ()
(gdb) x/8b 0x7e64
0x7e64:	0x00	0x00	0x00	0x00	0x00	0x00	0x00	0x00
```
The correct version should be:
```
; When the VMA = 0x7C00
[   0:7c1e] => 0x7c1e:	lgdtw  ds:0x7c64
0x00007c1e in ?? ()
(gdb) x/8b 0x7c64
0x7c64:	0x17	0x00	0x4c	0x7c	0x00	0x00	0x55	0xba
```

When `VMA = 0x7E00`, the program will keep running endlessly.
