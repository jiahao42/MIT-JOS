> Exercise 7. Use QEMU and GDB to trace into the JOS kernel and stop at the movl %eax, %cr0. Examine memory at 0x00100000 and at 0xf0100000. Now, single step over that instruction using the stepi GDB command. Again, examine memory at 0x00100000 and at 0xf0100000. Make sure you understand what just happened.

> What is the first instruction after the new mapping is established that would fail to work properly if the mapping weren't in place? Comment out the movl %eax, %cr0 in kern/entry.S, trace into it, and see if you were right.

The key part of this exercise is here:
```gdb
=> 0x10001d:	mov    eax,cr0 //get the value of cr0
=> 0x100020:	or     eax,0x80010001 //set the value
(gdb) x/8b 0x100000 // check the content of address 0x100000
0x100000:	0x02	0xb0	0xad	0x1b	0x00	0x00	0x00	0x00
(gdb) x/8b 0xf0100000 // check the content of address 0xf0100000
0xf0100000 <_start+4026531828>:	0x00	0x00	0x00	0x00	0x00	0x00	0x00	0x00
=> 0x100025:	mov    cr0,eax // write the value back to cr0
(gdb) x/8b 0xf0100000 // check the content of address 0xf0100000 again
0xf0100000 <_start+4026531828>:	0x02	0xb0	0xad	0x1b	0x00	0x00	0x00	0x00
```

`=> 0x100020:	or     eax,0x80010001`, it set `bit0`, `bit16`, and `bit31`, which stands for `protected mode enable`, `write protect` and `paging` separately, you can check the function of these bits [here](http://wiki.osdev.org/CPU_Registers_x86#CR0).
```
CR0
bit	label	description
0	pe	protected mode enable
1	mp	monitor co-processor
2	em	emulation
3	ts	task switched
4	et	extension type
5	ne	numeric error
16	wp	write protect
18	am	alignment mask
29	nw	not-write through
30	cd	cache disable
31	pg	paging
```
