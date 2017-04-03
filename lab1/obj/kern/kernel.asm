
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in i386_vm_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 80 19 10 f0 	movl   $0xf0101980,(%esp)
f0100055:	e8 dd 08 00 00       	call   f0100937 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 0f 07 00 00       	call   f0100796 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 9c 19 10 f0 	movl   $0xf010199c,(%esp)
f0100092:	e8 a0 08 00 00       	call   f0100937 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 a0 29 11 f0       	mov    $0xf01129a0,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 ca 13 00 00       	call   f010148f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 aa 04 00 00       	call   f0100574 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 b7 19 10 f0 	movl   $0xf01019b7,(%esp)
f01000d9:	e8 59 08 00 00       	call   f0100937 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 aa 06 00 00       	call   f01007a0 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 d2 19 10 f0 	movl   $0xf01019d2,(%esp)
f010012c:	e8 06 08 00 00       	call   f0100937 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 c7 07 00 00       	call   f0100904 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 0e 1a 10 f0 	movl   $0xf0101a0e,(%esp)
f0100144:	e8 ee 07 00 00       	call   f0100937 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 4b 06 00 00       	call   f01007a0 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 ea 19 10 f0 	movl   $0xf01019ea,(%esp)
f0100176:	e8 bc 07 00 00       	call   f0100937 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 7a 07 00 00       	call   f0100904 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 0e 1a 10 f0 	movl   $0xf0101a0e,(%esp)
f0100191:	e8 a1 07 00 00       	call   f0100937 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    

f010019c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010019c:	55                   	push   %ebp
f010019d:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010019f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a4:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a5:	a8 01                	test   $0x1,%al
f01001a7:	74 08                	je     f01001b1 <serial_proc_data+0x15>
f01001a9:	b2 f8                	mov    $0xf8,%dl
f01001ab:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001ac:	0f b6 c0             	movzbl %al,%eax
f01001af:	eb 05                	jmp    f01001b6 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001b6:	5d                   	pop    %ebp
f01001b7:	c3                   	ret    

f01001b8 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001b8:	55                   	push   %ebp
f01001b9:	89 e5                	mov    %esp,%ebp
f01001bb:	53                   	push   %ebx
f01001bc:	83 ec 04             	sub    $0x4,%esp
f01001bf:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c1:	eb 2a                	jmp    f01001ed <cons_intr+0x35>
		if (c == 0)
f01001c3:	85 d2                	test   %edx,%edx
f01001c5:	74 26                	je     f01001ed <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001c7:	a1 84 25 11 f0       	mov    0xf0112584,%eax
f01001cc:	8d 48 01             	lea    0x1(%eax),%ecx
f01001cf:	89 0d 84 25 11 f0    	mov    %ecx,0xf0112584
f01001d5:	88 90 80 23 11 f0    	mov    %dl,-0xfeedc80(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001db:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e1:	75 0a                	jne    f01001ed <cons_intr+0x35>
			cons.wpos = 0;
f01001e3:	c7 05 84 25 11 f0 00 	movl   $0x0,0xf0112584
f01001ea:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001ed:	ff d3                	call   *%ebx
f01001ef:	89 c2                	mov    %eax,%edx
f01001f1:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f4:	75 cd                	jne    f01001c3 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001f6:	83 c4 04             	add    $0x4,%esp
f01001f9:	5b                   	pop    %ebx
f01001fa:	5d                   	pop    %ebp
f01001fb:	c3                   	ret    

f01001fc <kbd_proc_data>:
f01001fc:	ba 64 00 00 00       	mov    $0x64,%edx
f0100201:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100202:	a8 01                	test   $0x1,%al
f0100204:	0f 84 f0 00 00 00    	je     f01002fa <kbd_proc_data+0xfe>
f010020a:	b2 60                	mov    $0x60,%dl
f010020c:	ec                   	in     (%dx),%al
f010020d:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010020f:	3c e0                	cmp    $0xe0,%al
f0100211:	75 0d                	jne    f0100220 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100213:	83 0d 40 23 11 f0 40 	orl    $0x40,0xf0112340
		return 0;
f010021a:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010021f:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100220:	55                   	push   %ebp
f0100221:	89 e5                	mov    %esp,%ebp
f0100223:	53                   	push   %ebx
f0100224:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100227:	84 c0                	test   %al,%al
f0100229:	79 36                	jns    f0100261 <kbd_proc_data+0x65>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022b:	8b 0d 40 23 11 f0    	mov    0xf0112340,%ecx
f0100231:	89 cb                	mov    %ecx,%ebx
f0100233:	83 e3 40             	and    $0x40,%ebx
f0100236:	83 e0 7f             	and    $0x7f,%eax
f0100239:	85 db                	test   %ebx,%ebx
f010023b:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010023e:	0f b6 d2             	movzbl %dl,%edx
f0100241:	0f b6 82 80 1b 10 f0 	movzbl -0xfefe480(%edx),%eax
f0100248:	83 c8 40             	or     $0x40,%eax
f010024b:	0f b6 c0             	movzbl %al,%eax
f010024e:	f7 d0                	not    %eax
f0100250:	21 c8                	and    %ecx,%eax
f0100252:	a3 40 23 11 f0       	mov    %eax,0xf0112340
		return 0;
f0100257:	b8 00 00 00 00       	mov    $0x0,%eax
f010025c:	e9 a1 00 00 00       	jmp    f0100302 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f0100261:	8b 0d 40 23 11 f0    	mov    0xf0112340,%ecx
f0100267:	f6 c1 40             	test   $0x40,%cl
f010026a:	74 0e                	je     f010027a <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010026c:	83 c8 80             	or     $0xffffff80,%eax
f010026f:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100271:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100274:	89 0d 40 23 11 f0    	mov    %ecx,0xf0112340
	}

	shift |= shiftcode[data];
f010027a:	0f b6 c2             	movzbl %dl,%eax
f010027d:	0f b6 90 80 1b 10 f0 	movzbl -0xfefe480(%eax),%edx
f0100284:	0b 15 40 23 11 f0    	or     0xf0112340,%edx
	shift ^= togglecode[data];
f010028a:	0f b6 88 80 1a 10 f0 	movzbl -0xfefe580(%eax),%ecx
f0100291:	31 ca                	xor    %ecx,%edx
f0100293:	89 15 40 23 11 f0    	mov    %edx,0xf0112340

	c = charcode[shift & (CTL | SHIFT)][data];
f0100299:	89 d1                	mov    %edx,%ecx
f010029b:	83 e1 03             	and    $0x3,%ecx
f010029e:	8b 0c 8d 40 1a 10 f0 	mov    -0xfefe5c0(,%ecx,4),%ecx
f01002a5:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f01002a9:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f01002ac:	f6 c2 08             	test   $0x8,%dl
f01002af:	74 1b                	je     f01002cc <kbd_proc_data+0xd0>
		if ('a' <= c && c <= 'z')
f01002b1:	89 d8                	mov    %ebx,%eax
f01002b3:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b6:	83 f9 19             	cmp    $0x19,%ecx
f01002b9:	77 05                	ja     f01002c0 <kbd_proc_data+0xc4>
			c += 'A' - 'a';
f01002bb:	83 eb 20             	sub    $0x20,%ebx
f01002be:	eb 0c                	jmp    f01002cc <kbd_proc_data+0xd0>
		else if ('A' <= c && c <= 'Z')
f01002c0:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f01002c3:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c6:	83 f8 19             	cmp    $0x19,%eax
f01002c9:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cc:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002d2:	75 2c                	jne    f0100300 <kbd_proc_data+0x104>
f01002d4:	f7 d2                	not    %edx
f01002d6:	f6 c2 06             	test   $0x6,%dl
f01002d9:	75 25                	jne    f0100300 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01002db:	83 ec 0c             	sub    $0xc,%esp
f01002de:	68 04 1a 10 f0       	push   $0xf0101a04
f01002e3:	e8 4f 06 00 00       	call   f0100937 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002e8:	ba 92 00 00 00       	mov    $0x92,%edx
f01002ed:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f2:	ee                   	out    %al,(%dx)
f01002f3:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f6:	89 d8                	mov    %ebx,%eax
f01002f8:	eb 08                	jmp    f0100302 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002ff:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100300:	89 d8                	mov    %ebx,%eax
}
f0100302:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100305:	c9                   	leave  
f0100306:	c3                   	ret    

f0100307 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100307:	55                   	push   %ebp
f0100308:	89 e5                	mov    %esp,%ebp
f010030a:	57                   	push   %edi
f010030b:	56                   	push   %esi
f010030c:	53                   	push   %ebx
f010030d:	83 ec 1c             	sub    $0x1c,%esp
f0100310:	89 c7                	mov    %eax,%edi

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100312:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100317:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;
	
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100318:	a8 20                	test   $0x20,%al
f010031a:	75 27                	jne    f0100343 <cons_putc+0x3c>
f010031c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100321:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100326:	be fd 03 00 00       	mov    $0x3fd,%esi
f010032b:	89 ca                	mov    %ecx,%edx
f010032d:	ec                   	in     (%dx),%al
f010032e:	ec                   	in     (%dx),%al
f010032f:	ec                   	in     (%dx),%al
f0100330:	ec                   	in     (%dx),%al
	     i++)
f0100331:	83 c3 01             	add    $0x1,%ebx
f0100334:	89 f2                	mov    %esi,%edx
f0100336:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;
	
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100337:	a8 20                	test   $0x20,%al
f0100339:	75 08                	jne    f0100343 <cons_putc+0x3c>
f010033b:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100341:	7e e8                	jle    f010032b <cons_putc+0x24>
f0100343:	89 f8                	mov    %edi,%eax
f0100345:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100348:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010034d:	89 f8                	mov    %edi,%eax
f010034f:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100350:	b2 79                	mov    $0x79,%dl
f0100352:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100353:	84 c0                	test   %al,%al
f0100355:	78 27                	js     f010037e <cons_putc+0x77>
f0100357:	bb 00 00 00 00       	mov    $0x0,%ebx
f010035c:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100361:	be 79 03 00 00       	mov    $0x379,%esi
f0100366:	89 ca                	mov    %ecx,%edx
f0100368:	ec                   	in     (%dx),%al
f0100369:	ec                   	in     (%dx),%al
f010036a:	ec                   	in     (%dx),%al
f010036b:	ec                   	in     (%dx),%al
f010036c:	83 c3 01             	add    $0x1,%ebx
f010036f:	89 f2                	mov    %esi,%edx
f0100371:	ec                   	in     (%dx),%al
f0100372:	84 c0                	test   %al,%al
f0100374:	78 08                	js     f010037e <cons_putc+0x77>
f0100376:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010037c:	7e e8                	jle    f0100366 <cons_putc+0x5f>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010037e:	ba 78 03 00 00       	mov    $0x378,%edx
f0100383:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100387:	ee                   	out    %al,(%dx)
f0100388:	b2 7a                	mov    $0x7a,%dl
f010038a:	b8 0d 00 00 00       	mov    $0xd,%eax
f010038f:	ee                   	out    %al,(%dx)
f0100390:	b8 08 00 00 00       	mov    $0x8,%eax
f0100395:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF)) // if (c && 0xFFFFFF00 != 0) ==> if (c <= 0xFF)
f0100396:	89 fa                	mov    %edi,%edx
f0100398:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010039e:	89 f8                	mov    %edi,%eax
f01003a0:	80 cc 07             	or     $0x7,%ah
f01003a3:	85 d2                	test   %edx,%edx
f01003a5:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01003a8:	89 f8                	mov    %edi,%eax
f01003aa:	0f b6 c0             	movzbl %al,%eax
f01003ad:	83 f8 09             	cmp    $0x9,%eax
f01003b0:	74 74                	je     f0100426 <cons_putc+0x11f>
f01003b2:	83 f8 09             	cmp    $0x9,%eax
f01003b5:	7f 0a                	jg     f01003c1 <cons_putc+0xba>
f01003b7:	83 f8 08             	cmp    $0x8,%eax
f01003ba:	74 14                	je     f01003d0 <cons_putc+0xc9>
f01003bc:	e9 99 00 00 00       	jmp    f010045a <cons_putc+0x153>
f01003c1:	83 f8 0a             	cmp    $0xa,%eax
f01003c4:	74 3a                	je     f0100400 <cons_putc+0xf9>
f01003c6:	83 f8 0d             	cmp    $0xd,%eax
f01003c9:	74 3d                	je     f0100408 <cons_putc+0x101>
f01003cb:	e9 8a 00 00 00       	jmp    f010045a <cons_putc+0x153>
	case '\b':
		if (crt_pos > 0) {
f01003d0:	0f b7 05 88 25 11 f0 	movzwl 0xf0112588,%eax
f01003d7:	66 85 c0             	test   %ax,%ax
f01003da:	0f 84 e6 00 00 00    	je     f01004c6 <cons_putc+0x1bf>
			crt_pos--;
f01003e0:	83 e8 01             	sub    $0x1,%eax
f01003e3:	66 a3 88 25 11 f0    	mov    %ax,0xf0112588
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003e9:	0f b7 c0             	movzwl %ax,%eax
f01003ec:	66 81 e7 00 ff       	and    $0xff00,%di
f01003f1:	83 cf 20             	or     $0x20,%edi
f01003f4:	8b 15 8c 25 11 f0    	mov    0xf011258c,%edx
f01003fa:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003fe:	eb 78                	jmp    f0100478 <cons_putc+0x171>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100400:	66 83 05 88 25 11 f0 	addw   $0x50,0xf0112588
f0100407:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100408:	0f b7 05 88 25 11 f0 	movzwl 0xf0112588,%eax
f010040f:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100415:	c1 e8 16             	shr    $0x16,%eax
f0100418:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010041b:	c1 e0 04             	shl    $0x4,%eax
f010041e:	66 a3 88 25 11 f0    	mov    %ax,0xf0112588
f0100424:	eb 52                	jmp    f0100478 <cons_putc+0x171>
		break;
	case '\t':
		cons_putc(' ');
f0100426:	b8 20 00 00 00       	mov    $0x20,%eax
f010042b:	e8 d7 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f0100430:	b8 20 00 00 00       	mov    $0x20,%eax
f0100435:	e8 cd fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f010043a:	b8 20 00 00 00       	mov    $0x20,%eax
f010043f:	e8 c3 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f0100444:	b8 20 00 00 00       	mov    $0x20,%eax
f0100449:	e8 b9 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f010044e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100453:	e8 af fe ff ff       	call   f0100307 <cons_putc>
f0100458:	eb 1e                	jmp    f0100478 <cons_putc+0x171>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010045a:	0f b7 05 88 25 11 f0 	movzwl 0xf0112588,%eax
f0100461:	8d 50 01             	lea    0x1(%eax),%edx
f0100464:	66 89 15 88 25 11 f0 	mov    %dx,0xf0112588
f010046b:	0f b7 c0             	movzwl %ax,%eax
f010046e:	8b 15 8c 25 11 f0    	mov    0xf011258c,%edx
f0100474:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100478:	66 81 3d 88 25 11 f0 	cmpw   $0x7cf,0xf0112588
f010047f:	cf 07 
f0100481:	76 43                	jbe    f01004c6 <cons_putc+0x1bf>
		int i;
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100483:	a1 8c 25 11 f0       	mov    0xf011258c,%eax
f0100488:	83 ec 04             	sub    $0x4,%esp
f010048b:	68 00 0f 00 00       	push   $0xf00
f0100490:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100496:	52                   	push   %edx
f0100497:	50                   	push   %eax
f0100498:	e8 3f 10 00 00       	call   f01014dc <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010049d:	8b 15 8c 25 11 f0    	mov    0xf011258c,%edx
f01004a3:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004a9:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004af:	83 c4 10             	add    $0x10,%esp
f01004b2:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004b7:	83 c0 02             	add    $0x2,%eax

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004ba:	39 d0                	cmp    %edx,%eax
f01004bc:	75 f4                	jne    f01004b2 <cons_putc+0x1ab>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004be:	66 83 2d 88 25 11 f0 	subw   $0x50,0xf0112588
f01004c5:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004c6:	8b 0d 90 25 11 f0    	mov    0xf0112590,%ecx
f01004cc:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004d1:	89 ca                	mov    %ecx,%edx
f01004d3:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004d4:	0f b7 1d 88 25 11 f0 	movzwl 0xf0112588,%ebx
f01004db:	8d 71 01             	lea    0x1(%ecx),%esi
f01004de:	89 d8                	mov    %ebx,%eax
f01004e0:	66 c1 e8 08          	shr    $0x8,%ax
f01004e4:	89 f2                	mov    %esi,%edx
f01004e6:	ee                   	out    %al,(%dx)
f01004e7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004ec:	89 ca                	mov    %ecx,%edx
f01004ee:	ee                   	out    %al,(%dx)
f01004ef:	89 d8                	mov    %ebx,%eax
f01004f1:	89 f2                	mov    %esi,%edx
f01004f3:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004f4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004f7:	5b                   	pop    %ebx
f01004f8:	5e                   	pop    %esi
f01004f9:	5f                   	pop    %edi
f01004fa:	5d                   	pop    %ebp
f01004fb:	c3                   	ret    

f01004fc <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004fc:	83 3d 94 25 11 f0 00 	cmpl   $0x0,0xf0112594
f0100503:	74 11                	je     f0100516 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100505:	55                   	push   %ebp
f0100506:	89 e5                	mov    %esp,%ebp
f0100508:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010050b:	b8 9c 01 10 f0       	mov    $0xf010019c,%eax
f0100510:	e8 a3 fc ff ff       	call   f01001b8 <cons_intr>
}
f0100515:	c9                   	leave  
f0100516:	f3 c3                	repz ret 

f0100518 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100518:	55                   	push   %ebp
f0100519:	89 e5                	mov    %esp,%ebp
f010051b:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010051e:	b8 fc 01 10 f0       	mov    $0xf01001fc,%eax
f0100523:	e8 90 fc ff ff       	call   f01001b8 <cons_intr>
}
f0100528:	c9                   	leave  
f0100529:	c3                   	ret    

f010052a <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010052a:	55                   	push   %ebp
f010052b:	89 e5                	mov    %esp,%ebp
f010052d:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100530:	e8 c7 ff ff ff       	call   f01004fc <serial_intr>
	kbd_intr();
f0100535:	e8 de ff ff ff       	call   f0100518 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010053a:	a1 80 25 11 f0       	mov    0xf0112580,%eax
f010053f:	3b 05 84 25 11 f0    	cmp    0xf0112584,%eax
f0100545:	74 26                	je     f010056d <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100547:	8d 50 01             	lea    0x1(%eax),%edx
f010054a:	89 15 80 25 11 f0    	mov    %edx,0xf0112580
f0100550:	0f b6 88 80 23 11 f0 	movzbl -0xfeedc80(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100557:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100559:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010055f:	75 11                	jne    f0100572 <cons_getc+0x48>
			cons.rpos = 0;
f0100561:	c7 05 80 25 11 f0 00 	movl   $0x0,0xf0112580
f0100568:	00 00 00 
f010056b:	eb 05                	jmp    f0100572 <cons_getc+0x48>
		return c;
	}
	return 0;
f010056d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100572:	c9                   	leave  
f0100573:	c3                   	ret    

f0100574 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100574:	55                   	push   %ebp
f0100575:	89 e5                	mov    %esp,%ebp
f0100577:	57                   	push   %edi
f0100578:	56                   	push   %esi
f0100579:	53                   	push   %ebx
f010057a:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010057d:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100584:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010058b:	5a a5 
	if (*cp != 0xA55A) {
f010058d:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100594:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100598:	74 11                	je     f01005ab <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010059a:	c7 05 90 25 11 f0 b4 	movl   $0x3b4,0xf0112590
f01005a1:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005a4:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f01005a9:	eb 16                	jmp    f01005c1 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005ab:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005b2:	c7 05 90 25 11 f0 d4 	movl   $0x3d4,0xf0112590
f01005b9:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005bc:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01005c1:	8b 3d 90 25 11 f0    	mov    0xf0112590,%edi
f01005c7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005cc:	89 fa                	mov    %edi,%edx
f01005ce:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005cf:	8d 4f 01             	lea    0x1(%edi),%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d2:	89 ca                	mov    %ecx,%edx
f01005d4:	ec                   	in     (%dx),%al
f01005d5:	0f b6 c0             	movzbl %al,%eax
f01005d8:	c1 e0 08             	shl    $0x8,%eax
f01005db:	89 c3                	mov    %eax,%ebx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005dd:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005e2:	89 fa                	mov    %edi,%edx
f01005e4:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e5:	89 ca                	mov    %ecx,%edx
f01005e7:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005e8:	89 35 8c 25 11 f0    	mov    %esi,0xf011258c
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005ee:	0f b6 c8             	movzbl %al,%ecx
f01005f1:	89 d8                	mov    %ebx,%eax
f01005f3:	09 c8                	or     %ecx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005f5:	66 a3 88 25 11 f0    	mov    %ax,0xf0112588
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005fb:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f0100600:	b8 00 00 00 00       	mov    $0x0,%eax
f0100605:	89 da                	mov    %ebx,%edx
f0100607:	ee                   	out    %al,(%dx)
f0100608:	b2 fb                	mov    $0xfb,%dl
f010060a:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010060f:	ee                   	out    %al,(%dx)
f0100610:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f0100615:	b8 0c 00 00 00       	mov    $0xc,%eax
f010061a:	89 ca                	mov    %ecx,%edx
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 f9                	mov    $0xf9,%dl
f010061f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100624:	ee                   	out    %al,(%dx)
f0100625:	b2 fb                	mov    $0xfb,%dl
f0100627:	b8 03 00 00 00       	mov    $0x3,%eax
f010062c:	ee                   	out    %al,(%dx)
f010062d:	b2 fc                	mov    $0xfc,%dl
f010062f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100634:	ee                   	out    %al,(%dx)
f0100635:	b2 f9                	mov    $0xf9,%dl
f0100637:	b8 01 00 00 00       	mov    $0x1,%eax
f010063c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010063d:	b2 fd                	mov    $0xfd,%dl
f010063f:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100640:	3c ff                	cmp    $0xff,%al
f0100642:	0f 95 c0             	setne  %al
f0100645:	0f b6 c0             	movzbl %al,%eax
f0100648:	89 c6                	mov    %eax,%esi
f010064a:	a3 94 25 11 f0       	mov    %eax,0xf0112594
f010064f:	89 da                	mov    %ebx,%edx
f0100651:	ec                   	in     (%dx),%al
f0100652:	89 ca                	mov    %ecx,%edx
f0100654:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100655:	85 f6                	test   %esi,%esi
f0100657:	75 10                	jne    f0100669 <cons_init+0xf5>
		cprintf("Serial port does not exist!\n");
f0100659:	83 ec 0c             	sub    $0xc,%esp
f010065c:	68 10 1a 10 f0       	push   $0xf0101a10
f0100661:	e8 d1 02 00 00       	call   f0100937 <cprintf>
f0100666:	83 c4 10             	add    $0x10,%esp
}
f0100669:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010066c:	5b                   	pop    %ebx
f010066d:	5e                   	pop    %esi
f010066e:	5f                   	pop    %edi
f010066f:	5d                   	pop    %ebp
f0100670:	c3                   	ret    

f0100671 <cputchar>:

// 'High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100671:	55                   	push   %ebp
f0100672:	89 e5                	mov    %esp,%ebp
f0100674:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100677:	8b 45 08             	mov    0x8(%ebp),%eax
f010067a:	e8 88 fc ff ff       	call   f0100307 <cons_putc>
}
f010067f:	c9                   	leave  
f0100680:	c3                   	ret    

f0100681 <getchar>:

int
getchar(void)
{
f0100681:	55                   	push   %ebp
f0100682:	89 e5                	mov    %esp,%ebp
f0100684:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100687:	e8 9e fe ff ff       	call   f010052a <cons_getc>
f010068c:	85 c0                	test   %eax,%eax
f010068e:	74 f7                	je     f0100687 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100690:	c9                   	leave  
f0100691:	c3                   	ret    

f0100692 <iscons>:

int
iscons(int fdnum)
{
f0100692:	55                   	push   %ebp
f0100693:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100695:	b8 01 00 00 00       	mov    $0x1,%eax
f010069a:	5d                   	pop    %ebp
f010069b:	c3                   	ret    
f010069c:	66 90                	xchg   %ax,%ax
f010069e:	66 90                	xchg   %ax,%ax

f01006a0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006a0:	55                   	push   %ebp
f01006a1:	89 e5                	mov    %esp,%ebp
f01006a3:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006a6:	c7 44 24 08 80 1c 10 	movl   $0xf0101c80,0x8(%esp)
f01006ad:	f0 
f01006ae:	c7 44 24 04 9e 1c 10 	movl   $0xf0101c9e,0x4(%esp)
f01006b5:	f0 
f01006b6:	c7 04 24 a3 1c 10 f0 	movl   $0xf0101ca3,(%esp)
f01006bd:	e8 75 02 00 00       	call   f0100937 <cprintf>
f01006c2:	c7 44 24 08 0c 1d 10 	movl   $0xf0101d0c,0x8(%esp)
f01006c9:	f0 
f01006ca:	c7 44 24 04 ac 1c 10 	movl   $0xf0101cac,0x4(%esp)
f01006d1:	f0 
f01006d2:	c7 04 24 a3 1c 10 f0 	movl   $0xf0101ca3,(%esp)
f01006d9:	e8 59 02 00 00       	call   f0100937 <cprintf>
	return 0;
}
f01006de:	b8 00 00 00 00       	mov    $0x0,%eax
f01006e3:	c9                   	leave  
f01006e4:	c3                   	ret    

f01006e5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006e5:	55                   	push   %ebp
f01006e6:	89 e5                	mov    %esp,%ebp
f01006e8:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006eb:	c7 04 24 b5 1c 10 f0 	movl   $0xf0101cb5,(%esp)
f01006f2:	e8 40 02 00 00       	call   f0100937 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006f7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006fe:	00 
f01006ff:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100706:	f0 
f0100707:	c7 04 24 34 1d 10 f0 	movl   $0xf0101d34,(%esp)
f010070e:	e8 24 02 00 00       	call   f0100937 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100713:	c7 44 24 08 75 19 10 	movl   $0x101975,0x8(%esp)
f010071a:	00 
f010071b:	c7 44 24 04 75 19 10 	movl   $0xf0101975,0x4(%esp)
f0100722:	f0 
f0100723:	c7 04 24 58 1d 10 f0 	movl   $0xf0101d58,(%esp)
f010072a:	e8 08 02 00 00       	call   f0100937 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010072f:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100736:	00 
f0100737:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010073e:	f0 
f010073f:	c7 04 24 7c 1d 10 f0 	movl   $0xf0101d7c,(%esp)
f0100746:	e8 ec 01 00 00       	call   f0100937 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010074b:	c7 44 24 08 a0 29 11 	movl   $0x1129a0,0x8(%esp)
f0100752:	00 
f0100753:	c7 44 24 04 a0 29 11 	movl   $0xf01129a0,0x4(%esp)
f010075a:	f0 
f010075b:	c7 04 24 a0 1d 10 f0 	movl   $0xf0101da0,(%esp)
f0100762:	e8 d0 01 00 00       	call   f0100937 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100767:	b8 9f 2d 11 f0       	mov    $0xf0112d9f,%eax
f010076c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100771:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100777:	85 c0                	test   %eax,%eax
f0100779:	0f 48 c2             	cmovs  %edx,%eax
f010077c:	c1 f8 0a             	sar    $0xa,%eax
f010077f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100783:	c7 04 24 c4 1d 10 f0 	movl   $0xf0101dc4,(%esp)
f010078a:	e8 a8 01 00 00       	call   f0100937 <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010078f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100794:	c9                   	leave  
f0100795:	c3                   	ret    

f0100796 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100796:	55                   	push   %ebp
f0100797:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100799:	b8 00 00 00 00       	mov    $0x0,%eax
f010079e:	5d                   	pop    %ebp
f010079f:	c3                   	ret    

f01007a0 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007a0:	55                   	push   %ebp
f01007a1:	89 e5                	mov    %esp,%ebp
f01007a3:	57                   	push   %edi
f01007a4:	56                   	push   %esi
f01007a5:	53                   	push   %ebx
f01007a6:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007a9:	c7 04 24 f0 1d 10 f0 	movl   $0xf0101df0,(%esp)
f01007b0:	e8 82 01 00 00       	call   f0100937 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007b5:	c7 04 24 14 1e 10 f0 	movl   $0xf0101e14,(%esp)
f01007bc:	e8 76 01 00 00       	call   f0100937 <cprintf>


	while (1) {
		buf = readline("K> ");
f01007c1:	c7 04 24 ce 1c 10 f0 	movl   $0xf0101cce,(%esp)
f01007c8:	e8 13 0a 00 00       	call   f01011e0 <readline>
f01007cd:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007cf:	85 c0                	test   %eax,%eax
f01007d1:	74 ee                	je     f01007c1 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007d3:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007da:	be 00 00 00 00       	mov    $0x0,%esi
f01007df:	eb 0a                	jmp    f01007eb <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007e1:	c6 03 00             	movb   $0x0,(%ebx)
f01007e4:	89 f7                	mov    %esi,%edi
f01007e6:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007e9:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007eb:	0f b6 03             	movzbl (%ebx),%eax
f01007ee:	84 c0                	test   %al,%al
f01007f0:	74 6a                	je     f010085c <monitor+0xbc>
f01007f2:	0f be c0             	movsbl %al,%eax
f01007f5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007f9:	c7 04 24 d2 1c 10 f0 	movl   $0xf0101cd2,(%esp)
f0100800:	e8 29 0c 00 00       	call   f010142e <strchr>
f0100805:	85 c0                	test   %eax,%eax
f0100807:	75 d8                	jne    f01007e1 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100809:	80 3b 00             	cmpb   $0x0,(%ebx)
f010080c:	74 4e                	je     f010085c <monitor+0xbc>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010080e:	83 fe 0f             	cmp    $0xf,%esi
f0100811:	75 16                	jne    f0100829 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100813:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010081a:	00 
f010081b:	c7 04 24 d7 1c 10 f0 	movl   $0xf0101cd7,(%esp)
f0100822:	e8 10 01 00 00       	call   f0100937 <cprintf>
f0100827:	eb 98                	jmp    f01007c1 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100829:	8d 7e 01             	lea    0x1(%esi),%edi
f010082c:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100830:	0f b6 03             	movzbl (%ebx),%eax
f0100833:	84 c0                	test   %al,%al
f0100835:	75 0c                	jne    f0100843 <monitor+0xa3>
f0100837:	eb b0                	jmp    f01007e9 <monitor+0x49>
			buf++;
f0100839:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010083c:	0f b6 03             	movzbl (%ebx),%eax
f010083f:	84 c0                	test   %al,%al
f0100841:	74 a6                	je     f01007e9 <monitor+0x49>
f0100843:	0f be c0             	movsbl %al,%eax
f0100846:	89 44 24 04          	mov    %eax,0x4(%esp)
f010084a:	c7 04 24 d2 1c 10 f0 	movl   $0xf0101cd2,(%esp)
f0100851:	e8 d8 0b 00 00       	call   f010142e <strchr>
f0100856:	85 c0                	test   %eax,%eax
f0100858:	74 df                	je     f0100839 <monitor+0x99>
f010085a:	eb 8d                	jmp    f01007e9 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f010085c:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100863:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100864:	85 f6                	test   %esi,%esi
f0100866:	0f 84 55 ff ff ff    	je     f01007c1 <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010086c:	c7 44 24 04 9e 1c 10 	movl   $0xf0101c9e,0x4(%esp)
f0100873:	f0 
f0100874:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100877:	89 04 24             	mov    %eax,(%esp)
f010087a:	e8 2b 0b 00 00       	call   f01013aa <strcmp>
f010087f:	85 c0                	test   %eax,%eax
f0100881:	74 1b                	je     f010089e <monitor+0xfe>
f0100883:	c7 44 24 04 ac 1c 10 	movl   $0xf0101cac,0x4(%esp)
f010088a:	f0 
f010088b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010088e:	89 04 24             	mov    %eax,(%esp)
f0100891:	e8 14 0b 00 00       	call   f01013aa <strcmp>
f0100896:	85 c0                	test   %eax,%eax
f0100898:	75 2f                	jne    f01008c9 <monitor+0x129>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010089a:	b0 01                	mov    $0x1,%al
f010089c:	eb 05                	jmp    f01008a3 <monitor+0x103>
		if (strcmp(argv[0], commands[i].name) == 0)
f010089e:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008a3:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008a6:	01 d0                	add    %edx,%eax
f01008a8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01008ab:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01008af:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008b2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008b6:	89 34 24             	mov    %esi,(%esp)
f01008b9:	ff 14 85 44 1e 10 f0 	call   *-0xfefe1bc(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008c0:	85 c0                	test   %eax,%eax
f01008c2:	78 1d                	js     f01008e1 <monitor+0x141>
f01008c4:	e9 f8 fe ff ff       	jmp    f01007c1 <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008c9:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d0:	c7 04 24 f4 1c 10 f0 	movl   $0xf0101cf4,(%esp)
f01008d7:	e8 5b 00 00 00       	call   f0100937 <cprintf>
f01008dc:	e9 e0 fe ff ff       	jmp    f01007c1 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008e1:	83 c4 5c             	add    $0x5c,%esp
f01008e4:	5b                   	pop    %ebx
f01008e5:	5e                   	pop    %esi
f01008e6:	5f                   	pop    %edi
f01008e7:	5d                   	pop    %ebp
f01008e8:	c3                   	ret    

f01008e9 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01008e9:	55                   	push   %ebp
f01008ea:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01008ec:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01008ef:	5d                   	pop    %ebp
f01008f0:	c3                   	ret    

f01008f1 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008f1:	55                   	push   %ebp
f01008f2:	89 e5                	mov    %esp,%ebp
f01008f4:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01008f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01008fa:	89 04 24             	mov    %eax,(%esp)
f01008fd:	e8 6f fd ff ff       	call   f0100671 <cputchar>
	*cnt++;
}
f0100902:	c9                   	leave  
f0100903:	c3                   	ret    

f0100904 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100904:	55                   	push   %ebp
f0100905:	89 e5                	mov    %esp,%ebp
f0100907:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010090a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100911:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100914:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100918:	8b 45 08             	mov    0x8(%ebp),%eax
f010091b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010091f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100922:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100926:	c7 04 24 f1 08 10 f0 	movl   $0xf01008f1,(%esp)
f010092d:	e8 3f 04 00 00       	call   f0100d71 <vprintfmt>
	return cnt;
}
f0100932:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100935:	c9                   	leave  
f0100936:	c3                   	ret    

f0100937 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100937:	55                   	push   %ebp
f0100938:	89 e5                	mov    %esp,%ebp
f010093a:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010093d:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100940:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100944:	8b 45 08             	mov    0x8(%ebp),%eax
f0100947:	89 04 24             	mov    %eax,(%esp)
f010094a:	e8 b5 ff ff ff       	call   f0100904 <vcprintf>
	va_end(ap);

	return cnt;
}
f010094f:	c9                   	leave  
f0100950:	c3                   	ret    
f0100951:	66 90                	xchg   %ax,%ax
f0100953:	66 90                	xchg   %ax,%ax
f0100955:	66 90                	xchg   %ax,%ax
f0100957:	66 90                	xchg   %ax,%ax
f0100959:	66 90                	xchg   %ax,%ax
f010095b:	66 90                	xchg   %ax,%ax
f010095d:	66 90                	xchg   %ax,%ax
f010095f:	90                   	nop

f0100960 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100960:	55                   	push   %ebp
f0100961:	89 e5                	mov    %esp,%ebp
f0100963:	57                   	push   %edi
f0100964:	56                   	push   %esi
f0100965:	53                   	push   %ebx
f0100966:	83 ec 10             	sub    $0x10,%esp
f0100969:	89 c6                	mov    %eax,%esi
f010096b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010096e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100971:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100974:	8b 1a                	mov    (%edx),%ebx
f0100976:	8b 01                	mov    (%ecx),%eax
f0100978:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010097b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0100982:	eb 77                	jmp    f01009fb <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100984:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100987:	01 d8                	add    %ebx,%eax
f0100989:	b9 02 00 00 00       	mov    $0x2,%ecx
f010098e:	99                   	cltd   
f010098f:	f7 f9                	idiv   %ecx
f0100991:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100993:	eb 01                	jmp    f0100996 <stab_binsearch+0x36>
			m--;
f0100995:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100996:	39 d9                	cmp    %ebx,%ecx
f0100998:	7c 1d                	jl     f01009b7 <stab_binsearch+0x57>
f010099a:	6b d1 0c             	imul   $0xc,%ecx,%edx
f010099d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f01009a2:	39 fa                	cmp    %edi,%edx
f01009a4:	75 ef                	jne    f0100995 <stab_binsearch+0x35>
f01009a6:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009a9:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01009ac:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f01009b0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01009b3:	73 18                	jae    f01009cd <stab_binsearch+0x6d>
f01009b5:	eb 05                	jmp    f01009bc <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009b7:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f01009ba:	eb 3f                	jmp    f01009fb <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01009bc:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01009bf:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f01009c1:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009c4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009cb:	eb 2e                	jmp    f01009fb <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009cd:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009d0:	73 15                	jae    f01009e7 <stab_binsearch+0x87>
			*region_right = m - 1;
f01009d2:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01009d5:	48                   	dec    %eax
f01009d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009d9:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009dc:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009de:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009e5:	eb 14                	jmp    f01009fb <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009e7:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01009ea:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f01009ed:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f01009ef:	ff 45 0c             	incl   0xc(%ebp)
f01009f2:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009f4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f01009fb:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01009fe:	7e 84                	jle    f0100984 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a00:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a04:	75 0d                	jne    f0100a13 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100a06:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a09:	8b 00                	mov    (%eax),%eax
f0100a0b:	48                   	dec    %eax
f0100a0c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100a0f:	89 07                	mov    %eax,(%edi)
f0100a11:	eb 22                	jmp    f0100a35 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a13:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a16:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a18:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a1b:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a1d:	eb 01                	jmp    f0100a20 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a1f:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a20:	39 c1                	cmp    %eax,%ecx
f0100a22:	7d 0c                	jge    f0100a30 <stab_binsearch+0xd0>
f0100a24:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100a27:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a2c:	39 fa                	cmp    %edi,%edx
f0100a2e:	75 ef                	jne    f0100a1f <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a30:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100a33:	89 07                	mov    %eax,(%edi)
	}
}
f0100a35:	83 c4 10             	add    $0x10,%esp
f0100a38:	5b                   	pop    %ebx
f0100a39:	5e                   	pop    %esi
f0100a3a:	5f                   	pop    %edi
f0100a3b:	5d                   	pop    %ebp
f0100a3c:	c3                   	ret    

f0100a3d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a3d:	55                   	push   %ebp
f0100a3e:	89 e5                	mov    %esp,%ebp
f0100a40:	57                   	push   %edi
f0100a41:	56                   	push   %esi
f0100a42:	53                   	push   %ebx
f0100a43:	83 ec 2c             	sub    $0x2c,%esp
f0100a46:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a49:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a4c:	c7 03 54 1e 10 f0    	movl   $0xf0101e54,(%ebx)
	info->eip_line = 0;
f0100a52:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a59:	c7 43 08 54 1e 10 f0 	movl   $0xf0101e54,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100a60:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100a67:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100a6a:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a71:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100a77:	76 12                	jbe    f0100a8b <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a79:	b8 3b 72 10 f0       	mov    $0xf010723b,%eax
f0100a7e:	3d f1 58 10 f0       	cmp    $0xf01058f1,%eax
f0100a83:	0f 86 8b 01 00 00    	jbe    f0100c14 <debuginfo_eip+0x1d7>
f0100a89:	eb 1c                	jmp    f0100aa7 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a8b:	c7 44 24 08 5e 1e 10 	movl   $0xf0101e5e,0x8(%esp)
f0100a92:	f0 
f0100a93:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100a9a:	00 
f0100a9b:	c7 04 24 6b 1e 10 f0 	movl   $0xf0101e6b,(%esp)
f0100aa2:	e8 51 f6 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100aa7:	80 3d 3a 72 10 f0 00 	cmpb   $0x0,0xf010723a
f0100aae:	0f 85 67 01 00 00    	jne    f0100c1b <debuginfo_eip+0x1de>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100ab4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100abb:	b8 f0 58 10 f0       	mov    $0xf01058f0,%eax
f0100ac0:	2d 8c 20 10 f0       	sub    $0xf010208c,%eax
f0100ac5:	c1 f8 02             	sar    $0x2,%eax
f0100ac8:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100ace:	83 e8 01             	sub    $0x1,%eax
f0100ad1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100ad4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ad8:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100adf:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100ae2:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ae5:	b8 8c 20 10 f0       	mov    $0xf010208c,%eax
f0100aea:	e8 71 fe ff ff       	call   f0100960 <stab_binsearch>
	if (lfile == 0)
f0100aef:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100af2:	85 c0                	test   %eax,%eax
f0100af4:	0f 84 28 01 00 00    	je     f0100c22 <debuginfo_eip+0x1e5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100afa:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100afd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b00:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b03:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b07:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b0e:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b11:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b14:	b8 8c 20 10 f0       	mov    $0xf010208c,%eax
f0100b19:	e8 42 fe ff ff       	call   f0100960 <stab_binsearch>

	if (lfun <= rfun) {
f0100b1e:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100b21:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100b24:	7f 2e                	jg     f0100b54 <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b26:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b29:	8d 90 8c 20 10 f0    	lea    -0xfefdf74(%eax),%edx
f0100b2f:	8b 80 8c 20 10 f0    	mov    -0xfefdf74(%eax),%eax
f0100b35:	b9 3b 72 10 f0       	mov    $0xf010723b,%ecx
f0100b3a:	81 e9 f1 58 10 f0    	sub    $0xf01058f1,%ecx
f0100b40:	39 c8                	cmp    %ecx,%eax
f0100b42:	73 08                	jae    f0100b4c <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b44:	05 f1 58 10 f0       	add    $0xf01058f1,%eax
f0100b49:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b4c:	8b 42 08             	mov    0x8(%edx),%eax
f0100b4f:	89 43 10             	mov    %eax,0x10(%ebx)
f0100b52:	eb 06                	jmp    f0100b5a <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b54:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b57:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b5a:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100b61:	00 
f0100b62:	8b 43 08             	mov    0x8(%ebx),%eax
f0100b65:	89 04 24             	mov    %eax,(%esp)
f0100b68:	e8 f7 08 00 00       	call   f0101464 <strfind>
f0100b6d:	2b 43 08             	sub    0x8(%ebx),%eax
f0100b70:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b73:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b76:	39 cf                	cmp    %ecx,%edi
f0100b78:	7c 5c                	jl     f0100bd6 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0100b7a:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b7d:	8d b0 8c 20 10 f0    	lea    -0xfefdf74(%eax),%esi
f0100b83:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f0100b87:	80 fa 84             	cmp    $0x84,%dl
f0100b8a:	74 2b                	je     f0100bb7 <debuginfo_eip+0x17a>
f0100b8c:	05 80 20 10 f0       	add    $0xf0102080,%eax
f0100b91:	eb 15                	jmp    f0100ba8 <debuginfo_eip+0x16b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b93:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b96:	39 cf                	cmp    %ecx,%edi
f0100b98:	7c 3c                	jl     f0100bd6 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0100b9a:	89 c6                	mov    %eax,%esi
f0100b9c:	83 e8 0c             	sub    $0xc,%eax
f0100b9f:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f0100ba3:	80 fa 84             	cmp    $0x84,%dl
f0100ba6:	74 0f                	je     f0100bb7 <debuginfo_eip+0x17a>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100ba8:	80 fa 64             	cmp    $0x64,%dl
f0100bab:	75 e6                	jne    f0100b93 <debuginfo_eip+0x156>
f0100bad:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0100bb1:	74 e0                	je     f0100b93 <debuginfo_eip+0x156>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100bb3:	39 f9                	cmp    %edi,%ecx
f0100bb5:	7f 1f                	jg     f0100bd6 <debuginfo_eip+0x199>
f0100bb7:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100bba:	8b 87 8c 20 10 f0    	mov    -0xfefdf74(%edi),%eax
f0100bc0:	ba 3b 72 10 f0       	mov    $0xf010723b,%edx
f0100bc5:	81 ea f1 58 10 f0    	sub    $0xf01058f1,%edx
f0100bcb:	39 d0                	cmp    %edx,%eax
f0100bcd:	73 07                	jae    f0100bd6 <debuginfo_eip+0x199>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100bcf:	05 f1 58 10 f0       	add    $0xf01058f1,%eax
f0100bd4:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bd6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100bd9:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100bdc:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100be1:	39 ca                	cmp    %ecx,%edx
f0100be3:	7d 5e                	jge    f0100c43 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
f0100be5:	8d 42 01             	lea    0x1(%edx),%eax
f0100be8:	39 c1                	cmp    %eax,%ecx
f0100bea:	7e 3d                	jle    f0100c29 <debuginfo_eip+0x1ec>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bec:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100bef:	80 ba 90 20 10 f0 a0 	cmpb   $0xa0,-0xfefdf70(%edx)
f0100bf6:	75 38                	jne    f0100c30 <debuginfo_eip+0x1f3>
f0100bf8:	81 c2 80 20 10 f0    	add    $0xf0102080,%edx
		     lline++)
			info->eip_fn_narg++;
f0100bfe:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c02:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c05:	39 c1                	cmp    %eax,%ecx
f0100c07:	7e 2e                	jle    f0100c37 <debuginfo_eip+0x1fa>
f0100c09:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c0c:	80 7a 10 a0          	cmpb   $0xa0,0x10(%edx)
f0100c10:	74 ec                	je     f0100bfe <debuginfo_eip+0x1c1>
f0100c12:	eb 2a                	jmp    f0100c3e <debuginfo_eip+0x201>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c14:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c19:	eb 28                	jmp    f0100c43 <debuginfo_eip+0x206>
f0100c1b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c20:	eb 21                	jmp    f0100c43 <debuginfo_eip+0x206>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c22:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c27:	eb 1a                	jmp    f0100c43 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c29:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c2e:	eb 13                	jmp    f0100c43 <debuginfo_eip+0x206>
f0100c30:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c35:	eb 0c                	jmp    f0100c43 <debuginfo_eip+0x206>
f0100c37:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c3c:	eb 05                	jmp    f0100c43 <debuginfo_eip+0x206>
f0100c3e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c43:	83 c4 2c             	add    $0x2c,%esp
f0100c46:	5b                   	pop    %ebx
f0100c47:	5e                   	pop    %esi
f0100c48:	5f                   	pop    %edi
f0100c49:	5d                   	pop    %ebp
f0100c4a:	c3                   	ret    

f0100c4b <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c4b:	55                   	push   %ebp
f0100c4c:	89 e5                	mov    %esp,%ebp
f0100c4e:	57                   	push   %edi
f0100c4f:	56                   	push   %esi
f0100c50:	53                   	push   %ebx
f0100c51:	83 ec 1c             	sub    $0x1c,%esp
f0100c54:	89 c7                	mov    %eax,%edi
f0100c56:	89 d6                	mov    %edx,%esi
f0100c58:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c5b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c5e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c61:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100c64:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c67:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100c6a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100c71:	39 55 e4             	cmp    %edx,-0x1c(%ebp)
f0100c74:	72 11                	jb     f0100c87 <printnum+0x3c>
f0100c76:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100c79:	76 0c                	jbe    f0100c87 <printnum+0x3c>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c7b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c7e:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100c81:	85 db                	test   %ebx,%ebx
f0100c83:	7f 37                	jg     f0100cbc <printnum+0x71>
f0100c85:	eb 46                	jmp    f0100ccd <printnum+0x82>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c87:	83 ec 0c             	sub    $0xc,%esp
f0100c8a:	ff 75 18             	pushl  0x18(%ebp)
f0100c8d:	8b 55 14             	mov    0x14(%ebp),%edx
f0100c90:	83 ea 01             	sub    $0x1,%edx
f0100c93:	52                   	push   %edx
f0100c94:	50                   	push   %eax
f0100c95:	83 ec 08             	sub    $0x8,%esp
f0100c98:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c9b:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c9e:	ff 75 dc             	pushl  -0x24(%ebp)
f0100ca1:	ff 75 d8             	pushl  -0x28(%ebp)
f0100ca4:	e8 27 0a 00 00       	call   f01016d0 <__udivdi3>
f0100ca9:	83 c4 18             	add    $0x18,%esp
f0100cac:	52                   	push   %edx
f0100cad:	50                   	push   %eax
f0100cae:	89 f2                	mov    %esi,%edx
f0100cb0:	89 f8                	mov    %edi,%eax
f0100cb2:	e8 94 ff ff ff       	call   f0100c4b <printnum>
f0100cb7:	83 c4 20             	add    $0x20,%esp
f0100cba:	eb 11                	jmp    f0100ccd <printnum+0x82>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100cbc:	83 ec 08             	sub    $0x8,%esp
f0100cbf:	56                   	push   %esi
f0100cc0:	ff 75 18             	pushl  0x18(%ebp)
f0100cc3:	ff d7                	call   *%edi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100cc5:	83 c4 10             	add    $0x10,%esp
f0100cc8:	83 eb 01             	sub    $0x1,%ebx
f0100ccb:	75 ef                	jne    f0100cbc <printnum+0x71>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100ccd:	83 ec 08             	sub    $0x8,%esp
f0100cd0:	56                   	push   %esi
f0100cd1:	83 ec 04             	sub    $0x4,%esp
f0100cd4:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100cd7:	ff 75 e0             	pushl  -0x20(%ebp)
f0100cda:	ff 75 dc             	pushl  -0x24(%ebp)
f0100cdd:	ff 75 d8             	pushl  -0x28(%ebp)
f0100ce0:	e8 1b 0b 00 00       	call   f0101800 <__umoddi3>
f0100ce5:	83 c4 14             	add    $0x14,%esp
f0100ce8:	0f be 80 79 1e 10 f0 	movsbl -0xfefe187(%eax),%eax
f0100cef:	50                   	push   %eax
f0100cf0:	ff d7                	call   *%edi
f0100cf2:	83 c4 10             	add    $0x10,%esp
}
f0100cf5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cf8:	5b                   	pop    %ebx
f0100cf9:	5e                   	pop    %esi
f0100cfa:	5f                   	pop    %edi
f0100cfb:	5d                   	pop    %ebp
f0100cfc:	c3                   	ret    

f0100cfd <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100cfd:	55                   	push   %ebp
f0100cfe:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d00:	83 fa 01             	cmp    $0x1,%edx
f0100d03:	7e 0e                	jle    f0100d13 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d05:	8b 10                	mov    (%eax),%edx
f0100d07:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d0a:	89 08                	mov    %ecx,(%eax)
f0100d0c:	8b 02                	mov    (%edx),%eax
f0100d0e:	8b 52 04             	mov    0x4(%edx),%edx
f0100d11:	eb 22                	jmp    f0100d35 <getuint+0x38>
	else if (lflag)
f0100d13:	85 d2                	test   %edx,%edx
f0100d15:	74 10                	je     f0100d27 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d17:	8b 10                	mov    (%eax),%edx
f0100d19:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d1c:	89 08                	mov    %ecx,(%eax)
f0100d1e:	8b 02                	mov    (%edx),%eax
f0100d20:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d25:	eb 0e                	jmp    f0100d35 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d27:	8b 10                	mov    (%eax),%edx
f0100d29:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d2c:	89 08                	mov    %ecx,(%eax)
f0100d2e:	8b 02                	mov    (%edx),%eax
f0100d30:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d35:	5d                   	pop    %ebp
f0100d36:	c3                   	ret    

f0100d37 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d37:	55                   	push   %ebp
f0100d38:	89 e5                	mov    %esp,%ebp
f0100d3a:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d3d:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d41:	8b 10                	mov    (%eax),%edx
f0100d43:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d46:	73 0a                	jae    f0100d52 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d48:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d4b:	89 08                	mov    %ecx,(%eax)
f0100d4d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d50:	88 02                	mov    %al,(%edx)
}
f0100d52:	5d                   	pop    %ebp
f0100d53:	c3                   	ret    

f0100d54 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d54:	55                   	push   %ebp
f0100d55:	89 e5                	mov    %esp,%ebp
f0100d57:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d5a:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d5d:	50                   	push   %eax
f0100d5e:	ff 75 10             	pushl  0x10(%ebp)
f0100d61:	ff 75 0c             	pushl  0xc(%ebp)
f0100d64:	ff 75 08             	pushl  0x8(%ebp)
f0100d67:	e8 05 00 00 00       	call   f0100d71 <vprintfmt>
	va_end(ap);
f0100d6c:	83 c4 10             	add    $0x10,%esp
}
f0100d6f:	c9                   	leave  
f0100d70:	c3                   	ret    

f0100d71 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d71:	55                   	push   %ebp
f0100d72:	89 e5                	mov    %esp,%ebp
f0100d74:	57                   	push   %edi
f0100d75:	56                   	push   %esi
f0100d76:	53                   	push   %ebx
f0100d77:	83 ec 2c             	sub    $0x2c,%esp
f0100d7a:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100d7d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d80:	eb 03                	jmp    f0100d85 <vprintfmt+0x14>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f0100d82:	89 75 10             	mov    %esi,0x10(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d85:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d88:	8d 70 01             	lea    0x1(%eax),%esi
f0100d8b:	0f b6 00             	movzbl (%eax),%eax
f0100d8e:	83 f8 25             	cmp    $0x25,%eax
f0100d91:	74 27                	je     f0100dba <vprintfmt+0x49>
			if (ch == '\0')
f0100d93:	85 c0                	test   %eax,%eax
f0100d95:	75 0d                	jne    f0100da4 <vprintfmt+0x33>
f0100d97:	e9 ca 03 00 00       	jmp    f0101166 <vprintfmt+0x3f5>
f0100d9c:	85 c0                	test   %eax,%eax
f0100d9e:	0f 84 c2 03 00 00    	je     f0101166 <vprintfmt+0x3f5>
				return;
			putch(ch, putdat);
f0100da4:	83 ec 08             	sub    $0x8,%esp
f0100da7:	53                   	push   %ebx
f0100da8:	50                   	push   %eax
f0100da9:	ff d7                	call   *%edi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100dab:	83 c6 01             	add    $0x1,%esi
f0100dae:	0f b6 46 ff          	movzbl -0x1(%esi),%eax
f0100db2:	83 c4 10             	add    $0x10,%esp
f0100db5:	83 f8 25             	cmp    $0x25,%eax
f0100db8:	75 e2                	jne    f0100d9c <vprintfmt+0x2b>
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100dba:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
f0100dbe:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100dc5:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100dcc:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100dd3:	ba 00 00 00 00       	mov    $0x0,%edx
f0100dd8:	eb 07                	jmp    f0100de1 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dda:	8b 75 10             	mov    0x10(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100ddd:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100de1:	8d 46 01             	lea    0x1(%esi),%eax
f0100de4:	89 45 10             	mov    %eax,0x10(%ebp)
f0100de7:	0f b6 06             	movzbl (%esi),%eax
f0100dea:	0f b6 c8             	movzbl %al,%ecx
f0100ded:	83 e8 23             	sub    $0x23,%eax
f0100df0:	3c 55                	cmp    $0x55,%al
f0100df2:	0f 87 2f 03 00 00    	ja     f0101127 <vprintfmt+0x3b6>
f0100df8:	0f b6 c0             	movzbl %al,%eax
f0100dfb:	ff 24 85 08 1f 10 f0 	jmp    *-0xfefe0f8(,%eax,4)
f0100e02:	8b 75 10             	mov    0x10(%ebp),%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e05:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
f0100e09:	eb d6                	jmp    f0100de1 <vprintfmt+0x70>
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e0b:	8d 41 d0             	lea    -0x30(%ecx),%eax
f0100e0e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
f0100e11:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100e15:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100e18:	83 f9 09             	cmp    $0x9,%ecx
f0100e1b:	77 60                	ja     f0100e7d <vprintfmt+0x10c>
f0100e1d:	8b 75 10             	mov    0x10(%ebp),%esi
f0100e20:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100e23:	8b 55 d4             	mov    -0x2c(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e26:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100e29:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100e2c:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100e30:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100e33:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100e36:	83 f9 09             	cmp    $0x9,%ecx
f0100e39:	76 eb                	jbe    f0100e26 <vprintfmt+0xb5>
f0100e3b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0100e3e:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100e41:	eb 3d                	jmp    f0100e80 <vprintfmt+0x10f>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e43:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e46:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e49:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e4c:	8b 00                	mov    (%eax),%eax
f0100e4e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e51:	8b 75 10             	mov    0x10(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e54:	eb 2a                	jmp    f0100e80 <vprintfmt+0x10f>
f0100e56:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e59:	85 c0                	test   %eax,%eax
f0100e5b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e60:	0f 49 c8             	cmovns %eax,%ecx
f0100e63:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e66:	8b 75 10             	mov    0x10(%ebp),%esi
f0100e69:	e9 73 ff ff ff       	jmp    f0100de1 <vprintfmt+0x70>
f0100e6e:	8b 75 10             	mov    0x10(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e71:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100e78:	e9 64 ff ff ff       	jmp    f0100de1 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e7d:	8b 75 10             	mov    0x10(%ebp),%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100e80:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100e84:	0f 89 57 ff ff ff    	jns    f0100de1 <vprintfmt+0x70>
				width = precision, precision = -1;
f0100e8a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e8d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e90:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100e97:	e9 45 ff ff ff       	jmp    f0100de1 <vprintfmt+0x70>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e9c:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e9f:	8b 75 10             	mov    0x10(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100ea2:	e9 3a ff ff ff       	jmp    f0100de1 <vprintfmt+0x70>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ea7:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eaa:	8d 50 04             	lea    0x4(%eax),%edx
f0100ead:	89 55 14             	mov    %edx,0x14(%ebp)
f0100eb0:	83 ec 08             	sub    $0x8,%esp
f0100eb3:	53                   	push   %ebx
f0100eb4:	ff 30                	pushl  (%eax)
f0100eb6:	ff d7                	call   *%edi
			break;
f0100eb8:	83 c4 10             	add    $0x10,%esp
f0100ebb:	e9 c5 fe ff ff       	jmp    f0100d85 <vprintfmt+0x14>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ec0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ec3:	8d 50 04             	lea    0x4(%eax),%edx
f0100ec6:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ec9:	8b 00                	mov    (%eax),%eax
f0100ecb:	99                   	cltd   
f0100ecc:	31 d0                	xor    %edx,%eax
f0100ece:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100ed0:	83 f8 06             	cmp    $0x6,%eax
f0100ed3:	7f 0b                	jg     f0100ee0 <vprintfmt+0x16f>
f0100ed5:	8b 14 85 60 20 10 f0 	mov    -0xfefdfa0(,%eax,4),%edx
f0100edc:	85 d2                	test   %edx,%edx
f0100ede:	75 15                	jne    f0100ef5 <vprintfmt+0x184>
				printfmt(putch, putdat, "error %d", err);
f0100ee0:	50                   	push   %eax
f0100ee1:	68 91 1e 10 f0       	push   $0xf0101e91
f0100ee6:	53                   	push   %ebx
f0100ee7:	57                   	push   %edi
f0100ee8:	e8 67 fe ff ff       	call   f0100d54 <printfmt>
f0100eed:	83 c4 10             	add    $0x10,%esp
f0100ef0:	e9 90 fe ff ff       	jmp    f0100d85 <vprintfmt+0x14>
			else
				printfmt(putch, putdat, "%s", p);
f0100ef5:	52                   	push   %edx
f0100ef6:	68 9a 1e 10 f0       	push   $0xf0101e9a
f0100efb:	53                   	push   %ebx
f0100efc:	57                   	push   %edi
f0100efd:	e8 52 fe ff ff       	call   f0100d54 <printfmt>
f0100f02:	83 c4 10             	add    $0x10,%esp
f0100f05:	e9 7b fe ff ff       	jmp    f0100d85 <vprintfmt+0x14>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f0a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100f0d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f10:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f13:	8d 50 04             	lea    0x4(%eax),%edx
f0100f16:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f19:	8b 00                	mov    (%eax),%eax
				p = "(null)";
f0100f1b:	85 c0                	test   %eax,%eax
f0100f1d:	ba 8a 1e 10 f0       	mov    $0xf0101e8a,%edx
f0100f22:	0f 45 d0             	cmovne %eax,%edx
f0100f25:	89 55 d0             	mov    %edx,-0x30(%ebp)
			if (width > 0 && padc != '-')
f0100f28:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f0100f2c:	74 04                	je     f0100f32 <vprintfmt+0x1c1>
f0100f2e:	85 f6                	test   %esi,%esi
f0100f30:	7f 19                	jg     f0100f4b <vprintfmt+0x1da>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f32:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100f35:	8d 70 01             	lea    0x1(%eax),%esi
f0100f38:	0f b6 00             	movzbl (%eax),%eax
f0100f3b:	0f be d0             	movsbl %al,%edx
f0100f3e:	85 d2                	test   %edx,%edx
f0100f40:	0f 85 9e 00 00 00    	jne    f0100fe4 <vprintfmt+0x273>
f0100f46:	e9 8b 00 00 00       	jmp    f0100fd6 <vprintfmt+0x265>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f4b:	83 ec 08             	sub    $0x8,%esp
f0100f4e:	51                   	push   %ecx
f0100f4f:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f52:	e8 7b 03 00 00       	call   f01012d2 <strnlen>
f0100f57:	29 c6                	sub    %eax,%esi
f0100f59:	89 f1                	mov    %esi,%ecx
f0100f5b:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0100f5e:	83 c4 10             	add    $0x10,%esp
f0100f61:	85 f6                	test   %esi,%esi
f0100f63:	0f 8e e4 01 00 00    	jle    f010114d <vprintfmt+0x3dc>
					putch(padc, putdat);
f0100f69:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0100f6d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f70:	89 cb                	mov    %ecx,%ebx
f0100f72:	83 ec 08             	sub    $0x8,%esp
f0100f75:	ff 75 0c             	pushl  0xc(%ebp)
f0100f78:	56                   	push   %esi
f0100f79:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f7b:	83 c4 10             	add    $0x10,%esp
f0100f7e:	83 eb 01             	sub    $0x1,%ebx
f0100f81:	75 ef                	jne    f0100f72 <vprintfmt+0x201>
f0100f83:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100f86:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f89:	e9 bf 01 00 00       	jmp    f010114d <vprintfmt+0x3dc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f8e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f92:	74 1b                	je     f0100faf <vprintfmt+0x23e>
f0100f94:	0f be c0             	movsbl %al,%eax
f0100f97:	83 e8 20             	sub    $0x20,%eax
f0100f9a:	83 f8 5e             	cmp    $0x5e,%eax
f0100f9d:	76 10                	jbe    f0100faf <vprintfmt+0x23e>
					putch('?', putdat);
f0100f9f:	83 ec 08             	sub    $0x8,%esp
f0100fa2:	ff 75 0c             	pushl  0xc(%ebp)
f0100fa5:	6a 3f                	push   $0x3f
f0100fa7:	ff 55 08             	call   *0x8(%ebp)
f0100faa:	83 c4 10             	add    $0x10,%esp
f0100fad:	eb 0d                	jmp    f0100fbc <vprintfmt+0x24b>
				else
					putch(ch, putdat);
f0100faf:	83 ec 08             	sub    $0x8,%esp
f0100fb2:	ff 75 0c             	pushl  0xc(%ebp)
f0100fb5:	52                   	push   %edx
f0100fb6:	ff 55 08             	call   *0x8(%ebp)
f0100fb9:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fbc:	83 eb 01             	sub    $0x1,%ebx
f0100fbf:	83 c6 01             	add    $0x1,%esi
f0100fc2:	0f b6 46 ff          	movzbl -0x1(%esi),%eax
f0100fc6:	0f be d0             	movsbl %al,%edx
f0100fc9:	85 d2                	test   %edx,%edx
f0100fcb:	75 31                	jne    f0100ffe <vprintfmt+0x28d>
f0100fcd:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100fd0:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100fd3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fd6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100fd9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100fdd:	7f 33                	jg     f0101012 <vprintfmt+0x2a1>
f0100fdf:	e9 a1 fd ff ff       	jmp    f0100d85 <vprintfmt+0x14>
f0100fe4:	89 7d 08             	mov    %edi,0x8(%ebp)
f0100fe7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100fea:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fed:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100ff0:	eb 0c                	jmp    f0100ffe <vprintfmt+0x28d>
f0100ff2:	89 7d 08             	mov    %edi,0x8(%ebp)
f0100ff5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100ff8:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100ffb:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100ffe:	85 ff                	test   %edi,%edi
f0101000:	78 8c                	js     f0100f8e <vprintfmt+0x21d>
f0101002:	83 ef 01             	sub    $0x1,%edi
f0101005:	79 87                	jns    f0100f8e <vprintfmt+0x21d>
f0101007:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010100a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010100d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101010:	eb c4                	jmp    f0100fd6 <vprintfmt+0x265>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101012:	83 ec 08             	sub    $0x8,%esp
f0101015:	53                   	push   %ebx
f0101016:	6a 20                	push   $0x20
f0101018:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010101a:	83 c4 10             	add    $0x10,%esp
f010101d:	83 ee 01             	sub    $0x1,%esi
f0101020:	75 f0                	jne    f0101012 <vprintfmt+0x2a1>
f0101022:	e9 5e fd ff ff       	jmp    f0100d85 <vprintfmt+0x14>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101027:	83 fa 01             	cmp    $0x1,%edx
f010102a:	7e 16                	jle    f0101042 <vprintfmt+0x2d1>
		return va_arg(*ap, long long);
f010102c:	8b 45 14             	mov    0x14(%ebp),%eax
f010102f:	8d 50 08             	lea    0x8(%eax),%edx
f0101032:	89 55 14             	mov    %edx,0x14(%ebp)
f0101035:	8b 50 04             	mov    0x4(%eax),%edx
f0101038:	8b 00                	mov    (%eax),%eax
f010103a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010103d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101040:	eb 32                	jmp    f0101074 <vprintfmt+0x303>
	else if (lflag)
f0101042:	85 d2                	test   %edx,%edx
f0101044:	74 18                	je     f010105e <vprintfmt+0x2ed>
		return va_arg(*ap, long);
f0101046:	8b 45 14             	mov    0x14(%ebp),%eax
f0101049:	8d 50 04             	lea    0x4(%eax),%edx
f010104c:	89 55 14             	mov    %edx,0x14(%ebp)
f010104f:	8b 30                	mov    (%eax),%esi
f0101051:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0101054:	89 f0                	mov    %esi,%eax
f0101056:	c1 f8 1f             	sar    $0x1f,%eax
f0101059:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010105c:	eb 16                	jmp    f0101074 <vprintfmt+0x303>
	else
		return va_arg(*ap, int);
f010105e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101061:	8d 50 04             	lea    0x4(%eax),%edx
f0101064:	89 55 14             	mov    %edx,0x14(%ebp)
f0101067:	8b 30                	mov    (%eax),%esi
f0101069:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010106c:	89 f0                	mov    %esi,%eax
f010106e:	c1 f8 1f             	sar    $0x1f,%eax
f0101071:	89 45 dc             	mov    %eax,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101074:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101077:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010107a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010107f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101083:	79 74                	jns    f01010f9 <vprintfmt+0x388>
				putch('-', putdat);
f0101085:	83 ec 08             	sub    $0x8,%esp
f0101088:	53                   	push   %ebx
f0101089:	6a 2d                	push   $0x2d
f010108b:	ff d7                	call   *%edi
				num = -(long long) num;
f010108d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101090:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101093:	f7 d8                	neg    %eax
f0101095:	83 d2 00             	adc    $0x0,%edx
f0101098:	f7 da                	neg    %edx
f010109a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010109d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01010a2:	eb 55                	jmp    f01010f9 <vprintfmt+0x388>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01010a4:	8d 45 14             	lea    0x14(%ebp),%eax
f01010a7:	e8 51 fc ff ff       	call   f0100cfd <getuint>
			base = 10;
f01010ac:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01010b1:	eb 46                	jmp    f01010f9 <vprintfmt+0x388>
			/* original code 
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			*/
			num = getuint(&ap, lflag);
f01010b3:	8d 45 14             	lea    0x14(%ebp),%eax
f01010b6:	e8 42 fc ff ff       	call   f0100cfd <getuint>
			base = 8;
f01010bb:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01010c0:	eb 37                	jmp    f01010f9 <vprintfmt+0x388>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f01010c2:	83 ec 08             	sub    $0x8,%esp
f01010c5:	53                   	push   %ebx
f01010c6:	6a 30                	push   $0x30
f01010c8:	ff d7                	call   *%edi
			putch('x', putdat);
f01010ca:	83 c4 08             	add    $0x8,%esp
f01010cd:	53                   	push   %ebx
f01010ce:	6a 78                	push   $0x78
f01010d0:	ff d7                	call   *%edi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01010d2:	8b 45 14             	mov    0x14(%ebp),%eax
f01010d5:	8d 50 04             	lea    0x4(%eax),%edx
f01010d8:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01010db:	8b 00                	mov    (%eax),%eax
f01010dd:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01010e2:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01010e5:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01010ea:	eb 0d                	jmp    f01010f9 <vprintfmt+0x388>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01010ec:	8d 45 14             	lea    0x14(%ebp),%eax
f01010ef:	e8 09 fc ff ff       	call   f0100cfd <getuint>
			base = 16;
f01010f4:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01010f9:	83 ec 0c             	sub    $0xc,%esp
f01010fc:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0101100:	56                   	push   %esi
f0101101:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101104:	51                   	push   %ecx
f0101105:	52                   	push   %edx
f0101106:	50                   	push   %eax
f0101107:	89 da                	mov    %ebx,%edx
f0101109:	89 f8                	mov    %edi,%eax
f010110b:	e8 3b fb ff ff       	call   f0100c4b <printnum>
			break;
f0101110:	83 c4 20             	add    $0x20,%esp
f0101113:	e9 6d fc ff ff       	jmp    f0100d85 <vprintfmt+0x14>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101118:	83 ec 08             	sub    $0x8,%esp
f010111b:	53                   	push   %ebx
f010111c:	51                   	push   %ecx
f010111d:	ff d7                	call   *%edi
			break;
f010111f:	83 c4 10             	add    $0x10,%esp
f0101122:	e9 5e fc ff ff       	jmp    f0100d85 <vprintfmt+0x14>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101127:	83 ec 08             	sub    $0x8,%esp
f010112a:	53                   	push   %ebx
f010112b:	6a 25                	push   $0x25
f010112d:	ff d7                	call   *%edi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010112f:	83 c4 10             	add    $0x10,%esp
f0101132:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101136:	0f 84 46 fc ff ff    	je     f0100d82 <vprintfmt+0x11>
f010113c:	83 ee 01             	sub    $0x1,%esi
f010113f:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101143:	75 f7                	jne    f010113c <vprintfmt+0x3cb>
f0101145:	89 75 10             	mov    %esi,0x10(%ebp)
f0101148:	e9 38 fc ff ff       	jmp    f0100d85 <vprintfmt+0x14>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010114d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101150:	8d 70 01             	lea    0x1(%eax),%esi
f0101153:	0f b6 00             	movzbl (%eax),%eax
f0101156:	0f be d0             	movsbl %al,%edx
f0101159:	85 d2                	test   %edx,%edx
f010115b:	0f 85 91 fe ff ff    	jne    f0100ff2 <vprintfmt+0x281>
f0101161:	e9 1f fc ff ff       	jmp    f0100d85 <vprintfmt+0x14>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
f0101166:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101169:	5b                   	pop    %ebx
f010116a:	5e                   	pop    %esi
f010116b:	5f                   	pop    %edi
f010116c:	5d                   	pop    %ebp
f010116d:	c3                   	ret    

f010116e <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010116e:	55                   	push   %ebp
f010116f:	89 e5                	mov    %esp,%ebp
f0101171:	83 ec 18             	sub    $0x18,%esp
f0101174:	8b 45 08             	mov    0x8(%ebp),%eax
f0101177:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010117a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010117d:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101181:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101184:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010118b:	85 c0                	test   %eax,%eax
f010118d:	74 26                	je     f01011b5 <vsnprintf+0x47>
f010118f:	85 d2                	test   %edx,%edx
f0101191:	7e 22                	jle    f01011b5 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101193:	ff 75 14             	pushl  0x14(%ebp)
f0101196:	ff 75 10             	pushl  0x10(%ebp)
f0101199:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010119c:	50                   	push   %eax
f010119d:	68 37 0d 10 f0       	push   $0xf0100d37
f01011a2:	e8 ca fb ff ff       	call   f0100d71 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011a7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011aa:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011b0:	83 c4 10             	add    $0x10,%esp
f01011b3:	eb 05                	jmp    f01011ba <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011b5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011ba:	c9                   	leave  
f01011bb:	c3                   	ret    

f01011bc <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011bc:	55                   	push   %ebp
f01011bd:	89 e5                	mov    %esp,%ebp
f01011bf:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011c2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011c5:	50                   	push   %eax
f01011c6:	ff 75 10             	pushl  0x10(%ebp)
f01011c9:	ff 75 0c             	pushl  0xc(%ebp)
f01011cc:	ff 75 08             	pushl  0x8(%ebp)
f01011cf:	e8 9a ff ff ff       	call   f010116e <vsnprintf>
	va_end(ap);

	return rc;
}
f01011d4:	c9                   	leave  
f01011d5:	c3                   	ret    
f01011d6:	66 90                	xchg   %ax,%ax
f01011d8:	66 90                	xchg   %ax,%ax
f01011da:	66 90                	xchg   %ax,%ax
f01011dc:	66 90                	xchg   %ax,%ax
f01011de:	66 90                	xchg   %ax,%ax

f01011e0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01011e0:	55                   	push   %ebp
f01011e1:	89 e5                	mov    %esp,%ebp
f01011e3:	57                   	push   %edi
f01011e4:	56                   	push   %esi
f01011e5:	53                   	push   %ebx
f01011e6:	83 ec 1c             	sub    $0x1c,%esp
f01011e9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01011ec:	85 c0                	test   %eax,%eax
f01011ee:	74 10                	je     f0101200 <readline+0x20>
		cprintf("%s", prompt);
f01011f0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011f4:	c7 04 24 9a 1e 10 f0 	movl   $0xf0101e9a,(%esp)
f01011fb:	e8 37 f7 ff ff       	call   f0100937 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101200:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101207:	e8 86 f4 ff ff       	call   f0100692 <iscons>
f010120c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010120e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101213:	e8 69 f4 ff ff       	call   f0100681 <getchar>
f0101218:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010121a:	85 c0                	test   %eax,%eax
f010121c:	79 17                	jns    f0101235 <readline+0x55>
			cprintf("read error: %e\n", c);
f010121e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101222:	c7 04 24 7c 20 10 f0 	movl   $0xf010207c,(%esp)
f0101229:	e8 09 f7 ff ff       	call   f0100937 <cprintf>
			return NULL;
f010122e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101233:	eb 6d                	jmp    f01012a2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101235:	83 f8 7f             	cmp    $0x7f,%eax
f0101238:	74 05                	je     f010123f <readline+0x5f>
f010123a:	83 f8 08             	cmp    $0x8,%eax
f010123d:	75 19                	jne    f0101258 <readline+0x78>
f010123f:	85 f6                	test   %esi,%esi
f0101241:	7e 15                	jle    f0101258 <readline+0x78>
			if (echoing)
f0101243:	85 ff                	test   %edi,%edi
f0101245:	74 0c                	je     f0101253 <readline+0x73>
				cputchar('\b');
f0101247:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010124e:	e8 1e f4 ff ff       	call   f0100671 <cputchar>
			i--;
f0101253:	83 ee 01             	sub    $0x1,%esi
f0101256:	eb bb                	jmp    f0101213 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101258:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010125e:	7f 1c                	jg     f010127c <readline+0x9c>
f0101260:	83 fb 1f             	cmp    $0x1f,%ebx
f0101263:	7e 17                	jle    f010127c <readline+0x9c>
			if (echoing)
f0101265:	85 ff                	test   %edi,%edi
f0101267:	74 08                	je     f0101271 <readline+0x91>
				cputchar(c);
f0101269:	89 1c 24             	mov    %ebx,(%esp)
f010126c:	e8 00 f4 ff ff       	call   f0100671 <cputchar>
			buf[i++] = c;
f0101271:	88 9e a0 25 11 f0    	mov    %bl,-0xfeeda60(%esi)
f0101277:	8d 76 01             	lea    0x1(%esi),%esi
f010127a:	eb 97                	jmp    f0101213 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010127c:	83 fb 0d             	cmp    $0xd,%ebx
f010127f:	74 05                	je     f0101286 <readline+0xa6>
f0101281:	83 fb 0a             	cmp    $0xa,%ebx
f0101284:	75 8d                	jne    f0101213 <readline+0x33>
			if (echoing)
f0101286:	85 ff                	test   %edi,%edi
f0101288:	74 0c                	je     f0101296 <readline+0xb6>
				cputchar('\n');
f010128a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101291:	e8 db f3 ff ff       	call   f0100671 <cputchar>
			buf[i] = 0;
f0101296:	c6 86 a0 25 11 f0 00 	movb   $0x0,-0xfeeda60(%esi)
			return buf;
f010129d:	b8 a0 25 11 f0       	mov    $0xf01125a0,%eax
		}
	}
}
f01012a2:	83 c4 1c             	add    $0x1c,%esp
f01012a5:	5b                   	pop    %ebx
f01012a6:	5e                   	pop    %esi
f01012a7:	5f                   	pop    %edi
f01012a8:	5d                   	pop    %ebp
f01012a9:	c3                   	ret    
f01012aa:	66 90                	xchg   %ax,%ax
f01012ac:	66 90                	xchg   %ax,%ax
f01012ae:	66 90                	xchg   %ax,%ax

f01012b0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012b0:	55                   	push   %ebp
f01012b1:	89 e5                	mov    %esp,%ebp
f01012b3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012b6:	80 3a 00             	cmpb   $0x0,(%edx)
f01012b9:	74 10                	je     f01012cb <strlen+0x1b>
f01012bb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01012c0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012c3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012c7:	75 f7                	jne    f01012c0 <strlen+0x10>
f01012c9:	eb 05                	jmp    f01012d0 <strlen+0x20>
f01012cb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01012d0:	5d                   	pop    %ebp
f01012d1:	c3                   	ret    

f01012d2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012d2:	55                   	push   %ebp
f01012d3:	89 e5                	mov    %esp,%ebp
f01012d5:	53                   	push   %ebx
f01012d6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01012d9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012dc:	85 c9                	test   %ecx,%ecx
f01012de:	74 1c                	je     f01012fc <strnlen+0x2a>
f01012e0:	80 3b 00             	cmpb   $0x0,(%ebx)
f01012e3:	74 1e                	je     f0101303 <strnlen+0x31>
f01012e5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01012ea:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012ec:	39 ca                	cmp    %ecx,%edx
f01012ee:	74 18                	je     f0101308 <strnlen+0x36>
f01012f0:	83 c2 01             	add    $0x1,%edx
f01012f3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01012f8:	75 f0                	jne    f01012ea <strnlen+0x18>
f01012fa:	eb 0c                	jmp    f0101308 <strnlen+0x36>
f01012fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0101301:	eb 05                	jmp    f0101308 <strnlen+0x36>
f0101303:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101308:	5b                   	pop    %ebx
f0101309:	5d                   	pop    %ebp
f010130a:	c3                   	ret    

f010130b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010130b:	55                   	push   %ebp
f010130c:	89 e5                	mov    %esp,%ebp
f010130e:	53                   	push   %ebx
f010130f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101312:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101315:	89 c2                	mov    %eax,%edx
f0101317:	83 c2 01             	add    $0x1,%edx
f010131a:	83 c1 01             	add    $0x1,%ecx
f010131d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101321:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101324:	84 db                	test   %bl,%bl
f0101326:	75 ef                	jne    f0101317 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101328:	5b                   	pop    %ebx
f0101329:	5d                   	pop    %ebp
f010132a:	c3                   	ret    

f010132b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010132b:	55                   	push   %ebp
f010132c:	89 e5                	mov    %esp,%ebp
f010132e:	56                   	push   %esi
f010132f:	53                   	push   %ebx
f0101330:	8b 75 08             	mov    0x8(%ebp),%esi
f0101333:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101336:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101339:	85 db                	test   %ebx,%ebx
f010133b:	74 17                	je     f0101354 <strncpy+0x29>
f010133d:	01 f3                	add    %esi,%ebx
f010133f:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f0101341:	83 c1 01             	add    $0x1,%ecx
f0101344:	0f b6 02             	movzbl (%edx),%eax
f0101347:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010134a:	80 3a 01             	cmpb   $0x1,(%edx)
f010134d:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101350:	39 d9                	cmp    %ebx,%ecx
f0101352:	75 ed                	jne    f0101341 <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101354:	89 f0                	mov    %esi,%eax
f0101356:	5b                   	pop    %ebx
f0101357:	5e                   	pop    %esi
f0101358:	5d                   	pop    %ebp
f0101359:	c3                   	ret    

f010135a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010135a:	55                   	push   %ebp
f010135b:	89 e5                	mov    %esp,%ebp
f010135d:	57                   	push   %edi
f010135e:	56                   	push   %esi
f010135f:	53                   	push   %ebx
f0101360:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101363:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101366:	8b 75 10             	mov    0x10(%ebp),%esi
f0101369:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010136b:	85 f6                	test   %esi,%esi
f010136d:	74 34                	je     f01013a3 <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f010136f:	83 fe 01             	cmp    $0x1,%esi
f0101372:	74 26                	je     f010139a <strlcpy+0x40>
f0101374:	0f b6 0b             	movzbl (%ebx),%ecx
f0101377:	84 c9                	test   %cl,%cl
f0101379:	74 23                	je     f010139e <strlcpy+0x44>
f010137b:	83 ee 02             	sub    $0x2,%esi
f010137e:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
f0101383:	83 c0 01             	add    $0x1,%eax
f0101386:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101389:	39 f2                	cmp    %esi,%edx
f010138b:	74 13                	je     f01013a0 <strlcpy+0x46>
f010138d:	83 c2 01             	add    $0x1,%edx
f0101390:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0101394:	84 c9                	test   %cl,%cl
f0101396:	75 eb                	jne    f0101383 <strlcpy+0x29>
f0101398:	eb 06                	jmp    f01013a0 <strlcpy+0x46>
f010139a:	89 f8                	mov    %edi,%eax
f010139c:	eb 02                	jmp    f01013a0 <strlcpy+0x46>
f010139e:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f01013a0:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01013a3:	29 f8                	sub    %edi,%eax
}
f01013a5:	5b                   	pop    %ebx
f01013a6:	5e                   	pop    %esi
f01013a7:	5f                   	pop    %edi
f01013a8:	5d                   	pop    %ebp
f01013a9:	c3                   	ret    

f01013aa <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013aa:	55                   	push   %ebp
f01013ab:	89 e5                	mov    %esp,%ebp
f01013ad:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013b0:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013b3:	0f b6 01             	movzbl (%ecx),%eax
f01013b6:	84 c0                	test   %al,%al
f01013b8:	74 15                	je     f01013cf <strcmp+0x25>
f01013ba:	3a 02                	cmp    (%edx),%al
f01013bc:	75 11                	jne    f01013cf <strcmp+0x25>
		p++, q++;
f01013be:	83 c1 01             	add    $0x1,%ecx
f01013c1:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013c4:	0f b6 01             	movzbl (%ecx),%eax
f01013c7:	84 c0                	test   %al,%al
f01013c9:	74 04                	je     f01013cf <strcmp+0x25>
f01013cb:	3a 02                	cmp    (%edx),%al
f01013cd:	74 ef                	je     f01013be <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013cf:	0f b6 c0             	movzbl %al,%eax
f01013d2:	0f b6 12             	movzbl (%edx),%edx
f01013d5:	29 d0                	sub    %edx,%eax
}
f01013d7:	5d                   	pop    %ebp
f01013d8:	c3                   	ret    

f01013d9 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013d9:	55                   	push   %ebp
f01013da:	89 e5                	mov    %esp,%ebp
f01013dc:	56                   	push   %esi
f01013dd:	53                   	push   %ebx
f01013de:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01013e1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013e4:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f01013e7:	85 f6                	test   %esi,%esi
f01013e9:	74 29                	je     f0101414 <strncmp+0x3b>
f01013eb:	0f b6 03             	movzbl (%ebx),%eax
f01013ee:	84 c0                	test   %al,%al
f01013f0:	74 30                	je     f0101422 <strncmp+0x49>
f01013f2:	3a 02                	cmp    (%edx),%al
f01013f4:	75 2c                	jne    f0101422 <strncmp+0x49>
f01013f6:	8d 43 01             	lea    0x1(%ebx),%eax
f01013f9:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f01013fb:	89 c3                	mov    %eax,%ebx
f01013fd:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101400:	39 f0                	cmp    %esi,%eax
f0101402:	74 17                	je     f010141b <strncmp+0x42>
f0101404:	0f b6 08             	movzbl (%eax),%ecx
f0101407:	84 c9                	test   %cl,%cl
f0101409:	74 17                	je     f0101422 <strncmp+0x49>
f010140b:	83 c0 01             	add    $0x1,%eax
f010140e:	3a 0a                	cmp    (%edx),%cl
f0101410:	74 e9                	je     f01013fb <strncmp+0x22>
f0101412:	eb 0e                	jmp    f0101422 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101414:	b8 00 00 00 00       	mov    $0x0,%eax
f0101419:	eb 0f                	jmp    f010142a <strncmp+0x51>
f010141b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101420:	eb 08                	jmp    f010142a <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101422:	0f b6 03             	movzbl (%ebx),%eax
f0101425:	0f b6 12             	movzbl (%edx),%edx
f0101428:	29 d0                	sub    %edx,%eax
}
f010142a:	5b                   	pop    %ebx
f010142b:	5e                   	pop    %esi
f010142c:	5d                   	pop    %ebp
f010142d:	c3                   	ret    

f010142e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010142e:	55                   	push   %ebp
f010142f:	89 e5                	mov    %esp,%ebp
f0101431:	53                   	push   %ebx
f0101432:	8b 45 08             	mov    0x8(%ebp),%eax
f0101435:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0101438:	0f b6 18             	movzbl (%eax),%ebx
f010143b:	84 db                	test   %bl,%bl
f010143d:	74 1d                	je     f010145c <strchr+0x2e>
f010143f:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101441:	38 d3                	cmp    %dl,%bl
f0101443:	75 06                	jne    f010144b <strchr+0x1d>
f0101445:	eb 1a                	jmp    f0101461 <strchr+0x33>
f0101447:	38 ca                	cmp    %cl,%dl
f0101449:	74 16                	je     f0101461 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010144b:	83 c0 01             	add    $0x1,%eax
f010144e:	0f b6 10             	movzbl (%eax),%edx
f0101451:	84 d2                	test   %dl,%dl
f0101453:	75 f2                	jne    f0101447 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0101455:	b8 00 00 00 00       	mov    $0x0,%eax
f010145a:	eb 05                	jmp    f0101461 <strchr+0x33>
f010145c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101461:	5b                   	pop    %ebx
f0101462:	5d                   	pop    %ebp
f0101463:	c3                   	ret    

f0101464 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101464:	55                   	push   %ebp
f0101465:	89 e5                	mov    %esp,%ebp
f0101467:	53                   	push   %ebx
f0101468:	8b 45 08             	mov    0x8(%ebp),%eax
f010146b:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f010146e:	0f b6 18             	movzbl (%eax),%ebx
f0101471:	84 db                	test   %bl,%bl
f0101473:	74 17                	je     f010148c <strfind+0x28>
f0101475:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101477:	38 d3                	cmp    %dl,%bl
f0101479:	75 07                	jne    f0101482 <strfind+0x1e>
f010147b:	eb 0f                	jmp    f010148c <strfind+0x28>
f010147d:	38 ca                	cmp    %cl,%dl
f010147f:	90                   	nop
f0101480:	74 0a                	je     f010148c <strfind+0x28>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101482:	83 c0 01             	add    $0x1,%eax
f0101485:	0f b6 10             	movzbl (%eax),%edx
f0101488:	84 d2                	test   %dl,%dl
f010148a:	75 f1                	jne    f010147d <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f010148c:	5b                   	pop    %ebx
f010148d:	5d                   	pop    %ebp
f010148e:	c3                   	ret    

f010148f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010148f:	55                   	push   %ebp
f0101490:	89 e5                	mov    %esp,%ebp
f0101492:	57                   	push   %edi
f0101493:	56                   	push   %esi
f0101494:	53                   	push   %ebx
f0101495:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101498:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010149b:	85 c9                	test   %ecx,%ecx
f010149d:	74 36                	je     f01014d5 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010149f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01014a5:	75 28                	jne    f01014cf <memset+0x40>
f01014a7:	f6 c1 03             	test   $0x3,%cl
f01014aa:	75 23                	jne    f01014cf <memset+0x40>
		c &= 0xFF;
f01014ac:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01014b0:	89 d3                	mov    %edx,%ebx
f01014b2:	c1 e3 08             	shl    $0x8,%ebx
f01014b5:	89 d6                	mov    %edx,%esi
f01014b7:	c1 e6 18             	shl    $0x18,%esi
f01014ba:	89 d0                	mov    %edx,%eax
f01014bc:	c1 e0 10             	shl    $0x10,%eax
f01014bf:	09 f0                	or     %esi,%eax
f01014c1:	09 c2                	or     %eax,%edx
f01014c3:	89 d0                	mov    %edx,%eax
f01014c5:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01014c7:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01014ca:	fc                   	cld    
f01014cb:	f3 ab                	rep stos %eax,%es:(%edi)
f01014cd:	eb 06                	jmp    f01014d5 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014cf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014d2:	fc                   	cld    
f01014d3:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014d5:	89 f8                	mov    %edi,%eax
f01014d7:	5b                   	pop    %ebx
f01014d8:	5e                   	pop    %esi
f01014d9:	5f                   	pop    %edi
f01014da:	5d                   	pop    %ebp
f01014db:	c3                   	ret    

f01014dc <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014dc:	55                   	push   %ebp
f01014dd:	89 e5                	mov    %esp,%ebp
f01014df:	57                   	push   %edi
f01014e0:	56                   	push   %esi
f01014e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014e7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014ea:	39 c6                	cmp    %eax,%esi
f01014ec:	73 35                	jae    f0101523 <memmove+0x47>
f01014ee:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014f1:	39 d0                	cmp    %edx,%eax
f01014f3:	73 2e                	jae    f0101523 <memmove+0x47>
		s += n;
		d += n;
f01014f5:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01014f8:	89 d6                	mov    %edx,%esi
f01014fa:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014fc:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101502:	75 13                	jne    f0101517 <memmove+0x3b>
f0101504:	f6 c1 03             	test   $0x3,%cl
f0101507:	75 0e                	jne    f0101517 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101509:	83 ef 04             	sub    $0x4,%edi
f010150c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010150f:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101512:	fd                   	std    
f0101513:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101515:	eb 09                	jmp    f0101520 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101517:	83 ef 01             	sub    $0x1,%edi
f010151a:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010151d:	fd                   	std    
f010151e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101520:	fc                   	cld    
f0101521:	eb 1d                	jmp    f0101540 <memmove+0x64>
f0101523:	89 f2                	mov    %esi,%edx
f0101525:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101527:	f6 c2 03             	test   $0x3,%dl
f010152a:	75 0f                	jne    f010153b <memmove+0x5f>
f010152c:	f6 c1 03             	test   $0x3,%cl
f010152f:	75 0a                	jne    f010153b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101531:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101534:	89 c7                	mov    %eax,%edi
f0101536:	fc                   	cld    
f0101537:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101539:	eb 05                	jmp    f0101540 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010153b:	89 c7                	mov    %eax,%edi
f010153d:	fc                   	cld    
f010153e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101540:	5e                   	pop    %esi
f0101541:	5f                   	pop    %edi
f0101542:	5d                   	pop    %ebp
f0101543:	c3                   	ret    

f0101544 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0101544:	55                   	push   %ebp
f0101545:	89 e5                	mov    %esp,%ebp
f0101547:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010154a:	8b 45 10             	mov    0x10(%ebp),%eax
f010154d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101551:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101554:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101558:	8b 45 08             	mov    0x8(%ebp),%eax
f010155b:	89 04 24             	mov    %eax,(%esp)
f010155e:	e8 79 ff ff ff       	call   f01014dc <memmove>
}
f0101563:	c9                   	leave  
f0101564:	c3                   	ret    

f0101565 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101565:	55                   	push   %ebp
f0101566:	89 e5                	mov    %esp,%ebp
f0101568:	57                   	push   %edi
f0101569:	56                   	push   %esi
f010156a:	53                   	push   %ebx
f010156b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010156e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101571:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101574:	8d 78 ff             	lea    -0x1(%eax),%edi
f0101577:	85 c0                	test   %eax,%eax
f0101579:	74 36                	je     f01015b1 <memcmp+0x4c>
		if (*s1 != *s2)
f010157b:	0f b6 03             	movzbl (%ebx),%eax
f010157e:	0f b6 0e             	movzbl (%esi),%ecx
f0101581:	ba 00 00 00 00       	mov    $0x0,%edx
f0101586:	38 c8                	cmp    %cl,%al
f0101588:	74 1c                	je     f01015a6 <memcmp+0x41>
f010158a:	eb 10                	jmp    f010159c <memcmp+0x37>
f010158c:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0101591:	83 c2 01             	add    $0x1,%edx
f0101594:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101598:	38 c8                	cmp    %cl,%al
f010159a:	74 0a                	je     f01015a6 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f010159c:	0f b6 c0             	movzbl %al,%eax
f010159f:	0f b6 c9             	movzbl %cl,%ecx
f01015a2:	29 c8                	sub    %ecx,%eax
f01015a4:	eb 10                	jmp    f01015b6 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01015a6:	39 fa                	cmp    %edi,%edx
f01015a8:	75 e2                	jne    f010158c <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01015aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01015af:	eb 05                	jmp    f01015b6 <memcmp+0x51>
f01015b1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015b6:	5b                   	pop    %ebx
f01015b7:	5e                   	pop    %esi
f01015b8:	5f                   	pop    %edi
f01015b9:	5d                   	pop    %ebp
f01015ba:	c3                   	ret    

f01015bb <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01015bb:	55                   	push   %ebp
f01015bc:	89 e5                	mov    %esp,%ebp
f01015be:	53                   	push   %ebx
f01015bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01015c2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f01015c5:	89 c2                	mov    %eax,%edx
f01015c7:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01015ca:	39 d0                	cmp    %edx,%eax
f01015cc:	73 14                	jae    f01015e2 <memfind+0x27>
		if (*(const unsigned char *) s == (unsigned char) c)
f01015ce:	89 d9                	mov    %ebx,%ecx
f01015d0:	38 18                	cmp    %bl,(%eax)
f01015d2:	75 06                	jne    f01015da <memfind+0x1f>
f01015d4:	eb 0c                	jmp    f01015e2 <memfind+0x27>
f01015d6:	38 08                	cmp    %cl,(%eax)
f01015d8:	74 08                	je     f01015e2 <memfind+0x27>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015da:	83 c0 01             	add    $0x1,%eax
f01015dd:	39 d0                	cmp    %edx,%eax
f01015df:	90                   	nop
f01015e0:	75 f4                	jne    f01015d6 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01015e2:	5b                   	pop    %ebx
f01015e3:	5d                   	pop    %ebp
f01015e4:	c3                   	ret    

f01015e5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01015e5:	55                   	push   %ebp
f01015e6:	89 e5                	mov    %esp,%ebp
f01015e8:	57                   	push   %edi
f01015e9:	56                   	push   %esi
f01015ea:	53                   	push   %ebx
f01015eb:	8b 55 08             	mov    0x8(%ebp),%edx
f01015ee:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015f1:	0f b6 0a             	movzbl (%edx),%ecx
f01015f4:	80 f9 09             	cmp    $0x9,%cl
f01015f7:	74 05                	je     f01015fe <strtol+0x19>
f01015f9:	80 f9 20             	cmp    $0x20,%cl
f01015fc:	75 10                	jne    f010160e <strtol+0x29>
		s++;
f01015fe:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101601:	0f b6 0a             	movzbl (%edx),%ecx
f0101604:	80 f9 09             	cmp    $0x9,%cl
f0101607:	74 f5                	je     f01015fe <strtol+0x19>
f0101609:	80 f9 20             	cmp    $0x20,%cl
f010160c:	74 f0                	je     f01015fe <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
f010160e:	80 f9 2b             	cmp    $0x2b,%cl
f0101611:	75 0a                	jne    f010161d <strtol+0x38>
		s++;
f0101613:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101616:	bf 00 00 00 00       	mov    $0x0,%edi
f010161b:	eb 11                	jmp    f010162e <strtol+0x49>
f010161d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101622:	80 f9 2d             	cmp    $0x2d,%cl
f0101625:	75 07                	jne    f010162e <strtol+0x49>
		s++, neg = 1;
f0101627:	83 c2 01             	add    $0x1,%edx
f010162a:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010162e:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101633:	75 15                	jne    f010164a <strtol+0x65>
f0101635:	80 3a 30             	cmpb   $0x30,(%edx)
f0101638:	75 10                	jne    f010164a <strtol+0x65>
f010163a:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010163e:	75 0a                	jne    f010164a <strtol+0x65>
		s += 2, base = 16;
f0101640:	83 c2 02             	add    $0x2,%edx
f0101643:	b8 10 00 00 00       	mov    $0x10,%eax
f0101648:	eb 10                	jmp    f010165a <strtol+0x75>
	else if (base == 0 && s[0] == '0')
f010164a:	85 c0                	test   %eax,%eax
f010164c:	75 0c                	jne    f010165a <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010164e:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101650:	80 3a 30             	cmpb   $0x30,(%edx)
f0101653:	75 05                	jne    f010165a <strtol+0x75>
		s++, base = 8;
f0101655:	83 c2 01             	add    $0x1,%edx
f0101658:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010165a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010165f:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101662:	0f b6 0a             	movzbl (%edx),%ecx
f0101665:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0101668:	89 f0                	mov    %esi,%eax
f010166a:	3c 09                	cmp    $0x9,%al
f010166c:	77 08                	ja     f0101676 <strtol+0x91>
			dig = *s - '0';
f010166e:	0f be c9             	movsbl %cl,%ecx
f0101671:	83 e9 30             	sub    $0x30,%ecx
f0101674:	eb 20                	jmp    f0101696 <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
f0101676:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0101679:	89 f0                	mov    %esi,%eax
f010167b:	3c 19                	cmp    $0x19,%al
f010167d:	77 08                	ja     f0101687 <strtol+0xa2>
			dig = *s - 'a' + 10;
f010167f:	0f be c9             	movsbl %cl,%ecx
f0101682:	83 e9 57             	sub    $0x57,%ecx
f0101685:	eb 0f                	jmp    f0101696 <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
f0101687:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010168a:	89 f0                	mov    %esi,%eax
f010168c:	3c 19                	cmp    $0x19,%al
f010168e:	77 16                	ja     f01016a6 <strtol+0xc1>
			dig = *s - 'A' + 10;
f0101690:	0f be c9             	movsbl %cl,%ecx
f0101693:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101696:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0101699:	7d 0f                	jge    f01016aa <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f010169b:	83 c2 01             	add    $0x1,%edx
f010169e:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01016a2:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01016a4:	eb bc                	jmp    f0101662 <strtol+0x7d>
f01016a6:	89 d8                	mov    %ebx,%eax
f01016a8:	eb 02                	jmp    f01016ac <strtol+0xc7>
f01016aa:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01016ac:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01016b0:	74 05                	je     f01016b7 <strtol+0xd2>
		*endptr = (char *) s;
f01016b2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016b5:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01016b7:	f7 d8                	neg    %eax
f01016b9:	85 ff                	test   %edi,%edi
f01016bb:	0f 44 c3             	cmove  %ebx,%eax
}
f01016be:	5b                   	pop    %ebx
f01016bf:	5e                   	pop    %esi
f01016c0:	5f                   	pop    %edi
f01016c1:	5d                   	pop    %ebp
f01016c2:	c3                   	ret    
f01016c3:	66 90                	xchg   %ax,%ax
f01016c5:	66 90                	xchg   %ax,%ax
f01016c7:	66 90                	xchg   %ax,%ax
f01016c9:	66 90                	xchg   %ax,%ax
f01016cb:	66 90                	xchg   %ax,%ax
f01016cd:	66 90                	xchg   %ax,%ax
f01016cf:	90                   	nop

f01016d0 <__udivdi3>:
f01016d0:	55                   	push   %ebp
f01016d1:	57                   	push   %edi
f01016d2:	56                   	push   %esi
f01016d3:	83 ec 10             	sub    $0x10,%esp
f01016d6:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f01016da:	8b 7c 24 20          	mov    0x20(%esp),%edi
f01016de:	8b 74 24 24          	mov    0x24(%esp),%esi
f01016e2:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01016e6:	85 d2                	test   %edx,%edx
f01016e8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01016ec:	89 34 24             	mov    %esi,(%esp)
f01016ef:	89 c8                	mov    %ecx,%eax
f01016f1:	75 35                	jne    f0101728 <__udivdi3+0x58>
f01016f3:	39 f1                	cmp    %esi,%ecx
f01016f5:	0f 87 bd 00 00 00    	ja     f01017b8 <__udivdi3+0xe8>
f01016fb:	85 c9                	test   %ecx,%ecx
f01016fd:	89 cd                	mov    %ecx,%ebp
f01016ff:	75 0b                	jne    f010170c <__udivdi3+0x3c>
f0101701:	b8 01 00 00 00       	mov    $0x1,%eax
f0101706:	31 d2                	xor    %edx,%edx
f0101708:	f7 f1                	div    %ecx
f010170a:	89 c5                	mov    %eax,%ebp
f010170c:	89 f0                	mov    %esi,%eax
f010170e:	31 d2                	xor    %edx,%edx
f0101710:	f7 f5                	div    %ebp
f0101712:	89 c6                	mov    %eax,%esi
f0101714:	89 f8                	mov    %edi,%eax
f0101716:	f7 f5                	div    %ebp
f0101718:	89 f2                	mov    %esi,%edx
f010171a:	83 c4 10             	add    $0x10,%esp
f010171d:	5e                   	pop    %esi
f010171e:	5f                   	pop    %edi
f010171f:	5d                   	pop    %ebp
f0101720:	c3                   	ret    
f0101721:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101728:	3b 14 24             	cmp    (%esp),%edx
f010172b:	77 7b                	ja     f01017a8 <__udivdi3+0xd8>
f010172d:	0f bd f2             	bsr    %edx,%esi
f0101730:	83 f6 1f             	xor    $0x1f,%esi
f0101733:	0f 84 97 00 00 00    	je     f01017d0 <__udivdi3+0x100>
f0101739:	bd 20 00 00 00       	mov    $0x20,%ebp
f010173e:	89 d7                	mov    %edx,%edi
f0101740:	89 f1                	mov    %esi,%ecx
f0101742:	29 f5                	sub    %esi,%ebp
f0101744:	d3 e7                	shl    %cl,%edi
f0101746:	89 c2                	mov    %eax,%edx
f0101748:	89 e9                	mov    %ebp,%ecx
f010174a:	d3 ea                	shr    %cl,%edx
f010174c:	89 f1                	mov    %esi,%ecx
f010174e:	09 fa                	or     %edi,%edx
f0101750:	8b 3c 24             	mov    (%esp),%edi
f0101753:	d3 e0                	shl    %cl,%eax
f0101755:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101759:	89 e9                	mov    %ebp,%ecx
f010175b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010175f:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101763:	89 fa                	mov    %edi,%edx
f0101765:	d3 ea                	shr    %cl,%edx
f0101767:	89 f1                	mov    %esi,%ecx
f0101769:	d3 e7                	shl    %cl,%edi
f010176b:	89 e9                	mov    %ebp,%ecx
f010176d:	d3 e8                	shr    %cl,%eax
f010176f:	09 c7                	or     %eax,%edi
f0101771:	89 f8                	mov    %edi,%eax
f0101773:	f7 74 24 08          	divl   0x8(%esp)
f0101777:	89 d5                	mov    %edx,%ebp
f0101779:	89 c7                	mov    %eax,%edi
f010177b:	f7 64 24 0c          	mull   0xc(%esp)
f010177f:	39 d5                	cmp    %edx,%ebp
f0101781:	89 14 24             	mov    %edx,(%esp)
f0101784:	72 11                	jb     f0101797 <__udivdi3+0xc7>
f0101786:	8b 54 24 04          	mov    0x4(%esp),%edx
f010178a:	89 f1                	mov    %esi,%ecx
f010178c:	d3 e2                	shl    %cl,%edx
f010178e:	39 c2                	cmp    %eax,%edx
f0101790:	73 5e                	jae    f01017f0 <__udivdi3+0x120>
f0101792:	3b 2c 24             	cmp    (%esp),%ebp
f0101795:	75 59                	jne    f01017f0 <__udivdi3+0x120>
f0101797:	8d 47 ff             	lea    -0x1(%edi),%eax
f010179a:	31 f6                	xor    %esi,%esi
f010179c:	89 f2                	mov    %esi,%edx
f010179e:	83 c4 10             	add    $0x10,%esp
f01017a1:	5e                   	pop    %esi
f01017a2:	5f                   	pop    %edi
f01017a3:	5d                   	pop    %ebp
f01017a4:	c3                   	ret    
f01017a5:	8d 76 00             	lea    0x0(%esi),%esi
f01017a8:	31 f6                	xor    %esi,%esi
f01017aa:	31 c0                	xor    %eax,%eax
f01017ac:	89 f2                	mov    %esi,%edx
f01017ae:	83 c4 10             	add    $0x10,%esp
f01017b1:	5e                   	pop    %esi
f01017b2:	5f                   	pop    %edi
f01017b3:	5d                   	pop    %ebp
f01017b4:	c3                   	ret    
f01017b5:	8d 76 00             	lea    0x0(%esi),%esi
f01017b8:	89 f2                	mov    %esi,%edx
f01017ba:	31 f6                	xor    %esi,%esi
f01017bc:	89 f8                	mov    %edi,%eax
f01017be:	f7 f1                	div    %ecx
f01017c0:	89 f2                	mov    %esi,%edx
f01017c2:	83 c4 10             	add    $0x10,%esp
f01017c5:	5e                   	pop    %esi
f01017c6:	5f                   	pop    %edi
f01017c7:	5d                   	pop    %ebp
f01017c8:	c3                   	ret    
f01017c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017d0:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f01017d4:	76 0b                	jbe    f01017e1 <__udivdi3+0x111>
f01017d6:	31 c0                	xor    %eax,%eax
f01017d8:	3b 14 24             	cmp    (%esp),%edx
f01017db:	0f 83 37 ff ff ff    	jae    f0101718 <__udivdi3+0x48>
f01017e1:	b8 01 00 00 00       	mov    $0x1,%eax
f01017e6:	e9 2d ff ff ff       	jmp    f0101718 <__udivdi3+0x48>
f01017eb:	90                   	nop
f01017ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017f0:	89 f8                	mov    %edi,%eax
f01017f2:	31 f6                	xor    %esi,%esi
f01017f4:	e9 1f ff ff ff       	jmp    f0101718 <__udivdi3+0x48>
f01017f9:	66 90                	xchg   %ax,%ax
f01017fb:	66 90                	xchg   %ax,%ax
f01017fd:	66 90                	xchg   %ax,%ax
f01017ff:	90                   	nop

f0101800 <__umoddi3>:
f0101800:	55                   	push   %ebp
f0101801:	57                   	push   %edi
f0101802:	56                   	push   %esi
f0101803:	83 ec 20             	sub    $0x20,%esp
f0101806:	8b 44 24 34          	mov    0x34(%esp),%eax
f010180a:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010180e:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101812:	89 c6                	mov    %eax,%esi
f0101814:	89 44 24 10          	mov    %eax,0x10(%esp)
f0101818:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010181c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0101820:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101824:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0101828:	89 74 24 18          	mov    %esi,0x18(%esp)
f010182c:	85 c0                	test   %eax,%eax
f010182e:	89 c2                	mov    %eax,%edx
f0101830:	75 1e                	jne    f0101850 <__umoddi3+0x50>
f0101832:	39 f7                	cmp    %esi,%edi
f0101834:	76 52                	jbe    f0101888 <__umoddi3+0x88>
f0101836:	89 c8                	mov    %ecx,%eax
f0101838:	89 f2                	mov    %esi,%edx
f010183a:	f7 f7                	div    %edi
f010183c:	89 d0                	mov    %edx,%eax
f010183e:	31 d2                	xor    %edx,%edx
f0101840:	83 c4 20             	add    $0x20,%esp
f0101843:	5e                   	pop    %esi
f0101844:	5f                   	pop    %edi
f0101845:	5d                   	pop    %ebp
f0101846:	c3                   	ret    
f0101847:	89 f6                	mov    %esi,%esi
f0101849:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101850:	39 f0                	cmp    %esi,%eax
f0101852:	77 5c                	ja     f01018b0 <__umoddi3+0xb0>
f0101854:	0f bd e8             	bsr    %eax,%ebp
f0101857:	83 f5 1f             	xor    $0x1f,%ebp
f010185a:	75 64                	jne    f01018c0 <__umoddi3+0xc0>
f010185c:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0101860:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0101864:	0f 86 f6 00 00 00    	jbe    f0101960 <__umoddi3+0x160>
f010186a:	3b 44 24 18          	cmp    0x18(%esp),%eax
f010186e:	0f 82 ec 00 00 00    	jb     f0101960 <__umoddi3+0x160>
f0101874:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101878:	8b 54 24 18          	mov    0x18(%esp),%edx
f010187c:	83 c4 20             	add    $0x20,%esp
f010187f:	5e                   	pop    %esi
f0101880:	5f                   	pop    %edi
f0101881:	5d                   	pop    %ebp
f0101882:	c3                   	ret    
f0101883:	90                   	nop
f0101884:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101888:	85 ff                	test   %edi,%edi
f010188a:	89 fd                	mov    %edi,%ebp
f010188c:	75 0b                	jne    f0101899 <__umoddi3+0x99>
f010188e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101893:	31 d2                	xor    %edx,%edx
f0101895:	f7 f7                	div    %edi
f0101897:	89 c5                	mov    %eax,%ebp
f0101899:	8b 44 24 10          	mov    0x10(%esp),%eax
f010189d:	31 d2                	xor    %edx,%edx
f010189f:	f7 f5                	div    %ebp
f01018a1:	89 c8                	mov    %ecx,%eax
f01018a3:	f7 f5                	div    %ebp
f01018a5:	eb 95                	jmp    f010183c <__umoddi3+0x3c>
f01018a7:	89 f6                	mov    %esi,%esi
f01018a9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01018b0:	89 c8                	mov    %ecx,%eax
f01018b2:	89 f2                	mov    %esi,%edx
f01018b4:	83 c4 20             	add    $0x20,%esp
f01018b7:	5e                   	pop    %esi
f01018b8:	5f                   	pop    %edi
f01018b9:	5d                   	pop    %ebp
f01018ba:	c3                   	ret    
f01018bb:	90                   	nop
f01018bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018c0:	b8 20 00 00 00       	mov    $0x20,%eax
f01018c5:	89 e9                	mov    %ebp,%ecx
f01018c7:	29 e8                	sub    %ebp,%eax
f01018c9:	d3 e2                	shl    %cl,%edx
f01018cb:	89 c7                	mov    %eax,%edi
f01018cd:	89 44 24 18          	mov    %eax,0x18(%esp)
f01018d1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01018d5:	89 f9                	mov    %edi,%ecx
f01018d7:	d3 e8                	shr    %cl,%eax
f01018d9:	89 c1                	mov    %eax,%ecx
f01018db:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01018df:	09 d1                	or     %edx,%ecx
f01018e1:	89 fa                	mov    %edi,%edx
f01018e3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01018e7:	89 e9                	mov    %ebp,%ecx
f01018e9:	d3 e0                	shl    %cl,%eax
f01018eb:	89 f9                	mov    %edi,%ecx
f01018ed:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01018f1:	89 f0                	mov    %esi,%eax
f01018f3:	d3 e8                	shr    %cl,%eax
f01018f5:	89 e9                	mov    %ebp,%ecx
f01018f7:	89 c7                	mov    %eax,%edi
f01018f9:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f01018fd:	d3 e6                	shl    %cl,%esi
f01018ff:	89 d1                	mov    %edx,%ecx
f0101901:	89 fa                	mov    %edi,%edx
f0101903:	d3 e8                	shr    %cl,%eax
f0101905:	89 e9                	mov    %ebp,%ecx
f0101907:	09 f0                	or     %esi,%eax
f0101909:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f010190d:	f7 74 24 10          	divl   0x10(%esp)
f0101911:	d3 e6                	shl    %cl,%esi
f0101913:	89 d1                	mov    %edx,%ecx
f0101915:	f7 64 24 0c          	mull   0xc(%esp)
f0101919:	39 d1                	cmp    %edx,%ecx
f010191b:	89 74 24 14          	mov    %esi,0x14(%esp)
f010191f:	89 d7                	mov    %edx,%edi
f0101921:	89 c6                	mov    %eax,%esi
f0101923:	72 0a                	jb     f010192f <__umoddi3+0x12f>
f0101925:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0101929:	73 10                	jae    f010193b <__umoddi3+0x13b>
f010192b:	39 d1                	cmp    %edx,%ecx
f010192d:	75 0c                	jne    f010193b <__umoddi3+0x13b>
f010192f:	89 d7                	mov    %edx,%edi
f0101931:	89 c6                	mov    %eax,%esi
f0101933:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0101937:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f010193b:	89 ca                	mov    %ecx,%edx
f010193d:	89 e9                	mov    %ebp,%ecx
f010193f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101943:	29 f0                	sub    %esi,%eax
f0101945:	19 fa                	sbb    %edi,%edx
f0101947:	d3 e8                	shr    %cl,%eax
f0101949:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f010194e:	89 d7                	mov    %edx,%edi
f0101950:	d3 e7                	shl    %cl,%edi
f0101952:	89 e9                	mov    %ebp,%ecx
f0101954:	09 f8                	or     %edi,%eax
f0101956:	d3 ea                	shr    %cl,%edx
f0101958:	83 c4 20             	add    $0x20,%esp
f010195b:	5e                   	pop    %esi
f010195c:	5f                   	pop    %edi
f010195d:	5d                   	pop    %ebp
f010195e:	c3                   	ret    
f010195f:	90                   	nop
f0101960:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101964:	29 f9                	sub    %edi,%ecx
f0101966:	19 c6                	sbb    %eax,%esi
f0101968:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010196c:	89 74 24 18          	mov    %esi,0x18(%esp)
f0101970:	e9 ff fe ff ff       	jmp    f0101874 <__umoddi3+0x74>
