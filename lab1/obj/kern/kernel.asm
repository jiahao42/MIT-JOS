
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
f010004e:	c7 04 24 20 1a 10 f0 	movl   $0xf0101a20,(%esp)
f0100055:	e8 cd 08 00 00       	call   f0100927 <cprintf>
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
f0100082:	e8 ff 06 00 00       	call   f0100786 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 3c 1a 10 f0 	movl   $0xf0101a3c,(%esp)
f0100092:	e8 90 08 00 00       	call   f0100927 <cprintf>
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
f01000a3:	b8 60 29 11 f0       	mov    $0xf0112960,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 8a 14 00 00       	call   f010154f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a5 04 00 00       	call   f010056f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 57 1a 10 f0 	movl   $0xf0101a57,(%esp)
f01000d9:	e8 49 08 00 00       	call   f0100927 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 9a 06 00 00       	call   f0100790 <monitor>
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
f0100125:	c7 04 24 72 1a 10 f0 	movl   $0xf0101a72,(%esp)
f010012c:	e8 f6 07 00 00       	call   f0100927 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 b7 07 00 00       	call   f01008f4 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 ae 1a 10 f0 	movl   $0xf0101aae,(%esp)
f0100144:	e8 de 07 00 00       	call   f0100927 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 3b 06 00 00       	call   f0100790 <monitor>
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
f010016f:	c7 04 24 8a 1a 10 f0 	movl   $0xf0101a8a,(%esp)
f0100176:	e8 ac 07 00 00       	call   f0100927 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 6a 07 00 00       	call   f01008f4 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 ae 1a 10 f0 	movl   $0xf0101aae,(%esp)
f0100191:	e8 91 07 00 00       	call   f0100927 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 44 25 11 f0    	mov    %ecx,0xf0112544
f01001d9:	88 90 40 23 11 f0    	mov    %dl,-0xfeedcc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 44 25 11 f0 00 	movl   $0x0,0xf0112544
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
f010020e:	b2 60                	mov    $0x60,%dl
f0100210:	ec                   	in     (%dx),%al
f0100211:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100213:	3c e0                	cmp    $0xe0,%al
f0100215:	75 0d                	jne    f0100224 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100217:	83 0d 20 23 11 f0 40 	orl    $0x40,0xf0112320
		return 0;
f010021e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100223:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	53                   	push   %ebx
f0100228:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010022b:	84 c0                	test   %al,%al
f010022d:	79 37                	jns    f0100266 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022f:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f0100235:	89 cb                	mov    %ecx,%ebx
f0100237:	83 e3 40             	and    $0x40,%ebx
f010023a:	83 e0 7f             	and    $0x7f,%eax
f010023d:	85 db                	test   %ebx,%ebx
f010023f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100242:	0f b6 d2             	movzbl %dl,%edx
f0100245:	0f b6 82 00 1c 10 f0 	movzbl -0xfefe400(%edx),%eax
f010024c:	83 c8 40             	or     $0x40,%eax
f010024f:	0f b6 c0             	movzbl %al,%eax
f0100252:	f7 d0                	not    %eax
f0100254:	21 c1                	and    %eax,%ecx
f0100256:	89 0d 20 23 11 f0    	mov    %ecx,0xf0112320
		return 0;
f010025c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100261:	e9 9d 00 00 00       	jmp    f0100303 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100266:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f010026c:	f6 c1 40             	test   $0x40,%cl
f010026f:	74 0e                	je     f010027f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100271:	83 c8 80             	or     $0xffffff80,%eax
f0100274:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100276:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100279:	89 0d 20 23 11 f0    	mov    %ecx,0xf0112320
	}

	shift |= shiftcode[data];
f010027f:	0f b6 d2             	movzbl %dl,%edx
f0100282:	0f b6 82 00 1c 10 f0 	movzbl -0xfefe400(%edx),%eax
f0100289:	0b 05 20 23 11 f0    	or     0xf0112320,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a 00 1b 10 f0 	movzbl -0xfefe500(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 20 23 11 f0       	mov    %eax,0xf0112320

	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d e0 1a 10 f0 	mov    -0xfefe520(,%ecx,4),%ecx
f01002a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b0:	a8 08                	test   $0x8,%al
f01002b2:	74 1b                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b4:	89 da                	mov    %ebx,%edx
f01002b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b9:	83 f9 19             	cmp    $0x19,%ecx
f01002bc:	77 05                	ja     f01002c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002be:	83 eb 20             	sub    $0x20,%ebx
f01002c1:	eb 0c                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c9:	83 fa 19             	cmp    $0x19,%edx
f01002cc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 29                	jne    f0100303 <kbd_proc_data+0x103>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 21                	jne    f0100303 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 a4 1a 10 f0 	movl   $0xf0101aa4,(%esp)
f01002e9:	e8 39 06 00 00       	call   f0100927 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 06                	jmp    f0100303 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100303:	83 c4 14             	add    $0x14,%esp
f0100306:	5b                   	pop    %ebx
f0100307:	5d                   	pop    %ebp
f0100308:	c3                   	ret    

f0100309 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	57                   	push   %edi
f010030d:	56                   	push   %esi
f010030e:	53                   	push   %ebx
f010030f:	83 ec 1c             	sub    $0x1c,%esp
f0100312:	89 c7                	mov    %eax,%edi

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100314:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100319:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f010031a:	a8 20                	test   $0x20,%al
f010031c:	75 21                	jne    f010033f <cons_putc+0x36>
f010031e:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100323:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100328:	be fd 03 00 00       	mov    $0x3fd,%esi
f010032d:	89 ca                	mov    %ecx,%edx
f010032f:	ec                   	in     (%dx),%al
f0100330:	ec                   	in     (%dx),%al
f0100331:	ec                   	in     (%dx),%al
f0100332:	ec                   	in     (%dx),%al
f0100333:	89 f2                	mov    %esi,%edx
f0100335:	ec                   	in     (%dx),%al
f0100336:	a8 20                	test   $0x20,%al
f0100338:	75 05                	jne    f010033f <cons_putc+0x36>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010033a:	83 eb 01             	sub    $0x1,%ebx
f010033d:	75 ee                	jne    f010032d <cons_putc+0x24>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f010033f:	89 f8                	mov    %edi,%eax
f0100341:	0f b6 c0             	movzbl %al,%eax
f0100344:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100347:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010034c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010034d:	b2 79                	mov    $0x79,%dl
f010034f:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100350:	84 c0                	test   %al,%al
f0100352:	78 21                	js     f0100375 <cons_putc+0x6c>
f0100354:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100359:	b9 84 00 00 00       	mov    $0x84,%ecx
f010035e:	be 79 03 00 00       	mov    $0x379,%esi
f0100363:	89 ca                	mov    %ecx,%edx
f0100365:	ec                   	in     (%dx),%al
f0100366:	ec                   	in     (%dx),%al
f0100367:	ec                   	in     (%dx),%al
f0100368:	ec                   	in     (%dx),%al
f0100369:	89 f2                	mov    %esi,%edx
f010036b:	ec                   	in     (%dx),%al
f010036c:	84 c0                	test   %al,%al
f010036e:	78 05                	js     f0100375 <cons_putc+0x6c>
f0100370:	83 eb 01             	sub    $0x1,%ebx
f0100373:	75 ee                	jne    f0100363 <cons_putc+0x5a>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100375:	ba 78 03 00 00       	mov    $0x378,%edx
f010037a:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010037e:	ee                   	out    %al,(%dx)
f010037f:	b2 7a                	mov    $0x7a,%dl
f0100381:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100386:	ee                   	out    %al,(%dx)
f0100387:	b8 08 00 00 00       	mov    $0x8,%eax
f010038c:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010038d:	89 fa                	mov    %edi,%edx
f010038f:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100395:	89 f8                	mov    %edi,%eax
f0100397:	80 cc 07             	or     $0x7,%ah
f010039a:	85 d2                	test   %edx,%edx
f010039c:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010039f:	89 f8                	mov    %edi,%eax
f01003a1:	0f b6 c0             	movzbl %al,%eax
f01003a4:	83 f8 09             	cmp    $0x9,%eax
f01003a7:	74 79                	je     f0100422 <cons_putc+0x119>
f01003a9:	83 f8 09             	cmp    $0x9,%eax
f01003ac:	7f 0a                	jg     f01003b8 <cons_putc+0xaf>
f01003ae:	83 f8 08             	cmp    $0x8,%eax
f01003b1:	74 19                	je     f01003cc <cons_putc+0xc3>
f01003b3:	e9 9e 00 00 00       	jmp    f0100456 <cons_putc+0x14d>
f01003b8:	83 f8 0a             	cmp    $0xa,%eax
f01003bb:	90                   	nop
f01003bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01003c0:	74 3a                	je     f01003fc <cons_putc+0xf3>
f01003c2:	83 f8 0d             	cmp    $0xd,%eax
f01003c5:	74 3d                	je     f0100404 <cons_putc+0xfb>
f01003c7:	e9 8a 00 00 00       	jmp    f0100456 <cons_putc+0x14d>
	case '\b':
		if (crt_pos > 0) {
f01003cc:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f01003d3:	66 85 c0             	test   %ax,%ax
f01003d6:	0f 84 e5 00 00 00    	je     f01004c1 <cons_putc+0x1b8>
			crt_pos--;
f01003dc:	83 e8 01             	sub    $0x1,%eax
f01003df:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003e5:	0f b7 c0             	movzwl %ax,%eax
f01003e8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003ed:	83 cf 20             	or     $0x20,%edi
f01003f0:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f01003f6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003fa:	eb 78                	jmp    f0100474 <cons_putc+0x16b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003fc:	66 83 05 48 25 11 f0 	addw   $0x50,0xf0112548
f0100403:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100404:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f010040b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100411:	c1 e8 16             	shr    $0x16,%eax
f0100414:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100417:	c1 e0 04             	shl    $0x4,%eax
f010041a:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
f0100420:	eb 52                	jmp    f0100474 <cons_putc+0x16b>
		break;
	case '\t':
		cons_putc(' ');
f0100422:	b8 20 00 00 00       	mov    $0x20,%eax
f0100427:	e8 dd fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010042c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100431:	e8 d3 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100436:	b8 20 00 00 00       	mov    $0x20,%eax
f010043b:	e8 c9 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100440:	b8 20 00 00 00       	mov    $0x20,%eax
f0100445:	e8 bf fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010044a:	b8 20 00 00 00       	mov    $0x20,%eax
f010044f:	e8 b5 fe ff ff       	call   f0100309 <cons_putc>
f0100454:	eb 1e                	jmp    f0100474 <cons_putc+0x16b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100456:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f010045d:	8d 50 01             	lea    0x1(%eax),%edx
f0100460:	66 89 15 48 25 11 f0 	mov    %dx,0xf0112548
f0100467:	0f b7 c0             	movzwl %ax,%eax
f010046a:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f0100470:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100474:	66 81 3d 48 25 11 f0 	cmpw   $0x7cf,0xf0112548
f010047b:	cf 07 
f010047d:	76 42                	jbe    f01004c1 <cons_putc+0x1b8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010047f:	a1 4c 25 11 f0       	mov    0xf011254c,%eax
f0100484:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010048b:	00 
f010048c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100492:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100496:	89 04 24             	mov    %eax,(%esp)
f0100499:	e8 fe 10 00 00       	call   f010159c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010049e:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004a4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01004a9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004af:	83 c0 01             	add    $0x1,%eax
f01004b2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004b7:	75 f0                	jne    f01004a9 <cons_putc+0x1a0>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004b9:	66 83 2d 48 25 11 f0 	subw   $0x50,0xf0112548
f01004c0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004c1:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f01004c7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004cc:	89 ca                	mov    %ecx,%edx
f01004ce:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004cf:	0f b7 1d 48 25 11 f0 	movzwl 0xf0112548,%ebx
f01004d6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004d9:	89 d8                	mov    %ebx,%eax
f01004db:	66 c1 e8 08          	shr    $0x8,%ax
f01004df:	89 f2                	mov    %esi,%edx
f01004e1:	ee                   	out    %al,(%dx)
f01004e2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004e7:	89 ca                	mov    %ecx,%edx
f01004e9:	ee                   	out    %al,(%dx)
f01004ea:	89 d8                	mov    %ebx,%eax
f01004ec:	89 f2                	mov    %esi,%edx
f01004ee:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004ef:	83 c4 1c             	add    $0x1c,%esp
f01004f2:	5b                   	pop    %ebx
f01004f3:	5e                   	pop    %esi
f01004f4:	5f                   	pop    %edi
f01004f5:	5d                   	pop    %ebp
f01004f6:	c3                   	ret    

f01004f7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004f7:	83 3d 54 25 11 f0 00 	cmpl   $0x0,0xf0112554
f01004fe:	74 11                	je     f0100511 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100500:	55                   	push   %ebp
f0100501:	89 e5                	mov    %esp,%ebp
f0100503:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100506:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f010050b:	e8 ac fc ff ff       	call   f01001bc <cons_intr>
}
f0100510:	c9                   	leave  
f0100511:	f3 c3                	repz ret 

f0100513 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100513:	55                   	push   %ebp
f0100514:	89 e5                	mov    %esp,%ebp
f0100516:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100519:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010051e:	e8 99 fc ff ff       	call   f01001bc <cons_intr>
}
f0100523:	c9                   	leave  
f0100524:	c3                   	ret    

f0100525 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100525:	55                   	push   %ebp
f0100526:	89 e5                	mov    %esp,%ebp
f0100528:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010052b:	e8 c7 ff ff ff       	call   f01004f7 <serial_intr>
	kbd_intr();
f0100530:	e8 de ff ff ff       	call   f0100513 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100535:	a1 40 25 11 f0       	mov    0xf0112540,%eax
f010053a:	3b 05 44 25 11 f0    	cmp    0xf0112544,%eax
f0100540:	74 26                	je     f0100568 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100542:	8d 50 01             	lea    0x1(%eax),%edx
f0100545:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
f010054b:	0f b6 88 40 23 11 f0 	movzbl -0xfeedcc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100552:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100554:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010055a:	75 11                	jne    f010056d <cons_getc+0x48>
			cons.rpos = 0;
f010055c:	c7 05 40 25 11 f0 00 	movl   $0x0,0xf0112540
f0100563:	00 00 00 
f0100566:	eb 05                	jmp    f010056d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100568:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010056d:	c9                   	leave  
f010056e:	c3                   	ret    

f010056f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010056f:	55                   	push   %ebp
f0100570:	89 e5                	mov    %esp,%ebp
f0100572:	57                   	push   %edi
f0100573:	56                   	push   %esi
f0100574:	53                   	push   %ebx
f0100575:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100578:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010057f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100586:	5a a5 
	if (*cp != 0xA55A) {
f0100588:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010058f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100593:	74 11                	je     f01005a6 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100595:	c7 05 50 25 11 f0 b4 	movl   $0x3b4,0xf0112550
f010059c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010059f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01005a4:	eb 16                	jmp    f01005bc <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005a6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005ad:	c7 05 50 25 11 f0 d4 	movl   $0x3d4,0xf0112550
f01005b4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01005bc:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f01005c2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c7:	89 ca                	mov    %ecx,%edx
f01005c9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ca:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cd:	89 da                	mov    %ebx,%edx
f01005cf:	ec                   	in     (%dx),%al
f01005d0:	0f b6 f0             	movzbl %al,%esi
f01005d3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005db:	89 ca                	mov    %ecx,%edx
f01005dd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005de:	89 da                	mov    %ebx,%edx
f01005e0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005e1:	89 3d 4c 25 11 f0    	mov    %edi,0xf011254c
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005e7:	0f b6 d8             	movzbl %al,%ebx
f01005ea:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005ec:	66 89 35 48 25 11 f0 	mov    %si,0xf0112548
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005f3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005fd:	89 f2                	mov    %esi,%edx
f01005ff:	ee                   	out    %al,(%dx)
f0100600:	b2 fb                	mov    $0xfb,%dl
f0100602:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100607:	ee                   	out    %al,(%dx)
f0100608:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010060d:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100612:	89 da                	mov    %ebx,%edx
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 f9                	mov    $0xf9,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 fb                	mov    $0xfb,%dl
f010061f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100624:	ee                   	out    %al,(%dx)
f0100625:	b2 fc                	mov    $0xfc,%dl
f0100627:	b8 00 00 00 00       	mov    $0x0,%eax
f010062c:	ee                   	out    %al,(%dx)
f010062d:	b2 f9                	mov    $0xf9,%dl
f010062f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100634:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100635:	b2 fd                	mov    $0xfd,%dl
f0100637:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100638:	3c ff                	cmp    $0xff,%al
f010063a:	0f 95 c1             	setne  %cl
f010063d:	0f b6 c9             	movzbl %cl,%ecx
f0100640:	89 0d 54 25 11 f0    	mov    %ecx,0xf0112554
f0100646:	89 f2                	mov    %esi,%edx
f0100648:	ec                   	in     (%dx),%al
f0100649:	89 da                	mov    %ebx,%edx
f010064b:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010064c:	85 c9                	test   %ecx,%ecx
f010064e:	75 0c                	jne    f010065c <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f0100650:	c7 04 24 b0 1a 10 f0 	movl   $0xf0101ab0,(%esp)
f0100657:	e8 cb 02 00 00       	call   f0100927 <cprintf>
}
f010065c:	83 c4 1c             	add    $0x1c,%esp
f010065f:	5b                   	pop    %ebx
f0100660:	5e                   	pop    %esi
f0100661:	5f                   	pop    %edi
f0100662:	5d                   	pop    %ebp
f0100663:	c3                   	ret    

f0100664 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100664:	55                   	push   %ebp
f0100665:	89 e5                	mov    %esp,%ebp
f0100667:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010066a:	8b 45 08             	mov    0x8(%ebp),%eax
f010066d:	e8 97 fc ff ff       	call   f0100309 <cons_putc>
}
f0100672:	c9                   	leave  
f0100673:	c3                   	ret    

f0100674 <getchar>:

int
getchar(void)
{
f0100674:	55                   	push   %ebp
f0100675:	89 e5                	mov    %esp,%ebp
f0100677:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010067a:	e8 a6 fe ff ff       	call   f0100525 <cons_getc>
f010067f:	85 c0                	test   %eax,%eax
f0100681:	74 f7                	je     f010067a <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100683:	c9                   	leave  
f0100684:	c3                   	ret    

f0100685 <iscons>:

int
iscons(int fdnum)
{
f0100685:	55                   	push   %ebp
f0100686:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100688:	b8 01 00 00 00       	mov    $0x1,%eax
f010068d:	5d                   	pop    %ebp
f010068e:	c3                   	ret    
f010068f:	90                   	nop

f0100690 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100696:	c7 44 24 08 00 1d 10 	movl   $0xf0101d00,0x8(%esp)
f010069d:	f0 
f010069e:	c7 44 24 04 1e 1d 10 	movl   $0xf0101d1e,0x4(%esp)
f01006a5:	f0 
f01006a6:	c7 04 24 23 1d 10 f0 	movl   $0xf0101d23,(%esp)
f01006ad:	e8 75 02 00 00       	call   f0100927 <cprintf>
f01006b2:	c7 44 24 08 8c 1d 10 	movl   $0xf0101d8c,0x8(%esp)
f01006b9:	f0 
f01006ba:	c7 44 24 04 2c 1d 10 	movl   $0xf0101d2c,0x4(%esp)
f01006c1:	f0 
f01006c2:	c7 04 24 23 1d 10 f0 	movl   $0xf0101d23,(%esp)
f01006c9:	e8 59 02 00 00       	call   f0100927 <cprintf>
	return 0;
}
f01006ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d3:	c9                   	leave  
f01006d4:	c3                   	ret    

f01006d5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006d5:	55                   	push   %ebp
f01006d6:	89 e5                	mov    %esp,%ebp
f01006d8:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006db:	c7 04 24 35 1d 10 f0 	movl   $0xf0101d35,(%esp)
f01006e2:	e8 40 02 00 00       	call   f0100927 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006e7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ee:	00 
f01006ef:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006f6:	f0 
f01006f7:	c7 04 24 b4 1d 10 f0 	movl   $0xf0101db4,(%esp)
f01006fe:	e8 24 02 00 00       	call   f0100927 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100703:	c7 44 24 08 17 1a 10 	movl   $0x101a17,0x8(%esp)
f010070a:	00 
f010070b:	c7 44 24 04 17 1a 10 	movl   $0xf0101a17,0x4(%esp)
f0100712:	f0 
f0100713:	c7 04 24 d8 1d 10 f0 	movl   $0xf0101dd8,(%esp)
f010071a:	e8 08 02 00 00       	call   f0100927 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010071f:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100726:	00 
f0100727:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010072e:	f0 
f010072f:	c7 04 24 fc 1d 10 f0 	movl   $0xf0101dfc,(%esp)
f0100736:	e8 ec 01 00 00       	call   f0100927 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010073b:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f0100742:	00 
f0100743:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f010074a:	f0 
f010074b:	c7 04 24 20 1e 10 f0 	movl   $0xf0101e20,(%esp)
f0100752:	e8 d0 01 00 00       	call   f0100927 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100757:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f010075c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100761:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100767:	85 c0                	test   %eax,%eax
f0100769:	0f 48 c2             	cmovs  %edx,%eax
f010076c:	c1 f8 0a             	sar    $0xa,%eax
f010076f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100773:	c7 04 24 44 1e 10 f0 	movl   $0xf0101e44,(%esp)
f010077a:	e8 a8 01 00 00       	call   f0100927 <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010077f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100784:	c9                   	leave  
f0100785:	c3                   	ret    

f0100786 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100786:	55                   	push   %ebp
f0100787:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100789:	b8 00 00 00 00       	mov    $0x0,%eax
f010078e:	5d                   	pop    %ebp
f010078f:	c3                   	ret    

f0100790 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100790:	55                   	push   %ebp
f0100791:	89 e5                	mov    %esp,%ebp
f0100793:	57                   	push   %edi
f0100794:	56                   	push   %esi
f0100795:	53                   	push   %ebx
f0100796:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100799:	c7 04 24 70 1e 10 f0 	movl   $0xf0101e70,(%esp)
f01007a0:	e8 82 01 00 00       	call   f0100927 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007a5:	c7 04 24 94 1e 10 f0 	movl   $0xf0101e94,(%esp)
f01007ac:	e8 76 01 00 00       	call   f0100927 <cprintf>


	while (1) {
		buf = readline("K> ");
f01007b1:	c7 04 24 4e 1d 10 f0 	movl   $0xf0101d4e,(%esp)
f01007b8:	e8 e3 0a 00 00       	call   f01012a0 <readline>
f01007bd:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007bf:	85 c0                	test   %eax,%eax
f01007c1:	74 ee                	je     f01007b1 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007c3:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007ca:	be 00 00 00 00       	mov    $0x0,%esi
f01007cf:	eb 0a                	jmp    f01007db <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007d1:	c6 03 00             	movb   $0x0,(%ebx)
f01007d4:	89 f7                	mov    %esi,%edi
f01007d6:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007d9:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007db:	0f b6 03             	movzbl (%ebx),%eax
f01007de:	84 c0                	test   %al,%al
f01007e0:	74 6a                	je     f010084c <monitor+0xbc>
f01007e2:	0f be c0             	movsbl %al,%eax
f01007e5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007e9:	c7 04 24 52 1d 10 f0 	movl   $0xf0101d52,(%esp)
f01007f0:	e8 f9 0c 00 00       	call   f01014ee <strchr>
f01007f5:	85 c0                	test   %eax,%eax
f01007f7:	75 d8                	jne    f01007d1 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01007f9:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007fc:	74 4e                	je     f010084c <monitor+0xbc>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007fe:	83 fe 0f             	cmp    $0xf,%esi
f0100801:	75 16                	jne    f0100819 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100803:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010080a:	00 
f010080b:	c7 04 24 57 1d 10 f0 	movl   $0xf0101d57,(%esp)
f0100812:	e8 10 01 00 00       	call   f0100927 <cprintf>
f0100817:	eb 98                	jmp    f01007b1 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100819:	8d 7e 01             	lea    0x1(%esi),%edi
f010081c:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100820:	0f b6 03             	movzbl (%ebx),%eax
f0100823:	84 c0                	test   %al,%al
f0100825:	75 0c                	jne    f0100833 <monitor+0xa3>
f0100827:	eb b0                	jmp    f01007d9 <monitor+0x49>
			buf++;
f0100829:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010082c:	0f b6 03             	movzbl (%ebx),%eax
f010082f:	84 c0                	test   %al,%al
f0100831:	74 a6                	je     f01007d9 <monitor+0x49>
f0100833:	0f be c0             	movsbl %al,%eax
f0100836:	89 44 24 04          	mov    %eax,0x4(%esp)
f010083a:	c7 04 24 52 1d 10 f0 	movl   $0xf0101d52,(%esp)
f0100841:	e8 a8 0c 00 00       	call   f01014ee <strchr>
f0100846:	85 c0                	test   %eax,%eax
f0100848:	74 df                	je     f0100829 <monitor+0x99>
f010084a:	eb 8d                	jmp    f01007d9 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f010084c:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100853:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100854:	85 f6                	test   %esi,%esi
f0100856:	0f 84 55 ff ff ff    	je     f01007b1 <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010085c:	c7 44 24 04 1e 1d 10 	movl   $0xf0101d1e,0x4(%esp)
f0100863:	f0 
f0100864:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100867:	89 04 24             	mov    %eax,(%esp)
f010086a:	e8 fb 0b 00 00       	call   f010146a <strcmp>
f010086f:	85 c0                	test   %eax,%eax
f0100871:	74 1b                	je     f010088e <monitor+0xfe>
f0100873:	c7 44 24 04 2c 1d 10 	movl   $0xf0101d2c,0x4(%esp)
f010087a:	f0 
f010087b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010087e:	89 04 24             	mov    %eax,(%esp)
f0100881:	e8 e4 0b 00 00       	call   f010146a <strcmp>
f0100886:	85 c0                	test   %eax,%eax
f0100888:	75 2f                	jne    f01008b9 <monitor+0x129>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010088a:	b0 01                	mov    $0x1,%al
f010088c:	eb 05                	jmp    f0100893 <monitor+0x103>
		if (strcmp(argv[0], commands[i].name) == 0)
f010088e:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100893:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100896:	01 d0                	add    %edx,%eax
f0100898:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010089b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010089f:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008a2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008a6:	89 34 24             	mov    %esi,(%esp)
f01008a9:	ff 14 85 c4 1e 10 f0 	call   *-0xfefe13c(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008b0:	85 c0                	test   %eax,%eax
f01008b2:	78 1d                	js     f01008d1 <monitor+0x141>
f01008b4:	e9 f8 fe ff ff       	jmp    f01007b1 <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008b9:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008bc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008c0:	c7 04 24 74 1d 10 f0 	movl   $0xf0101d74,(%esp)
f01008c7:	e8 5b 00 00 00       	call   f0100927 <cprintf>
f01008cc:	e9 e0 fe ff ff       	jmp    f01007b1 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008d1:	83 c4 5c             	add    $0x5c,%esp
f01008d4:	5b                   	pop    %ebx
f01008d5:	5e                   	pop    %esi
f01008d6:	5f                   	pop    %edi
f01008d7:	5d                   	pop    %ebp
f01008d8:	c3                   	ret    

f01008d9 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01008d9:	55                   	push   %ebp
f01008da:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01008dc:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01008df:	5d                   	pop    %ebp
f01008e0:	c3                   	ret    

f01008e1 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008e1:	55                   	push   %ebp
f01008e2:	89 e5                	mov    %esp,%ebp
f01008e4:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01008e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01008ea:	89 04 24             	mov    %eax,(%esp)
f01008ed:	e8 72 fd ff ff       	call   f0100664 <cputchar>
	*cnt++;
}
f01008f2:	c9                   	leave  
f01008f3:	c3                   	ret    

f01008f4 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008f4:	55                   	push   %ebp
f01008f5:	89 e5                	mov    %esp,%ebp
f01008f7:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01008fa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100901:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100904:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100908:	8b 45 08             	mov    0x8(%ebp),%eax
f010090b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010090f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100912:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100916:	c7 04 24 e1 08 10 f0 	movl   $0xf01008e1,(%esp)
f010091d:	e8 58 04 00 00       	call   f0100d7a <vprintfmt>
	return cnt;
}
f0100922:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100925:	c9                   	leave  
f0100926:	c3                   	ret    

f0100927 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100927:	55                   	push   %ebp
f0100928:	89 e5                	mov    %esp,%ebp
f010092a:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010092d:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100930:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100934:	8b 45 08             	mov    0x8(%ebp),%eax
f0100937:	89 04 24             	mov    %eax,(%esp)
f010093a:	e8 b5 ff ff ff       	call   f01008f4 <vcprintf>
	va_end(ap);

	return cnt;
}
f010093f:	c9                   	leave  
f0100940:	c3                   	ret    
f0100941:	66 90                	xchg   %ax,%ax
f0100943:	66 90                	xchg   %ax,%ax
f0100945:	66 90                	xchg   %ax,%ax
f0100947:	66 90                	xchg   %ax,%ax
f0100949:	66 90                	xchg   %ax,%ax
f010094b:	66 90                	xchg   %ax,%ax
f010094d:	66 90                	xchg   %ax,%ax
f010094f:	90                   	nop

f0100950 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100950:	55                   	push   %ebp
f0100951:	89 e5                	mov    %esp,%ebp
f0100953:	57                   	push   %edi
f0100954:	56                   	push   %esi
f0100955:	53                   	push   %ebx
f0100956:	83 ec 10             	sub    $0x10,%esp
f0100959:	89 c6                	mov    %eax,%esi
f010095b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010095e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100961:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100964:	8b 1a                	mov    (%edx),%ebx
f0100966:	8b 01                	mov    (%ecx),%eax
f0100968:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010096b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0100972:	eb 77                	jmp    f01009eb <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100974:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100977:	01 d8                	add    %ebx,%eax
f0100979:	b9 02 00 00 00       	mov    $0x2,%ecx
f010097e:	99                   	cltd   
f010097f:	f7 f9                	idiv   %ecx
f0100981:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100983:	eb 01                	jmp    f0100986 <stab_binsearch+0x36>
			m--;
f0100985:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100986:	39 d9                	cmp    %ebx,%ecx
f0100988:	7c 1d                	jl     f01009a7 <stab_binsearch+0x57>
f010098a:	6b d1 0c             	imul   $0xc,%ecx,%edx
f010098d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100992:	39 fa                	cmp    %edi,%edx
f0100994:	75 ef                	jne    f0100985 <stab_binsearch+0x35>
f0100996:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100999:	6b d1 0c             	imul   $0xc,%ecx,%edx
f010099c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f01009a0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01009a3:	73 18                	jae    f01009bd <stab_binsearch+0x6d>
f01009a5:	eb 05                	jmp    f01009ac <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009a7:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f01009aa:	eb 3f                	jmp    f01009eb <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01009ac:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01009af:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f01009b1:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009b4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009bb:	eb 2e                	jmp    f01009eb <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009bd:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009c0:	73 15                	jae    f01009d7 <stab_binsearch+0x87>
			*region_right = m - 1;
f01009c2:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01009c5:	48                   	dec    %eax
f01009c6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009c9:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009cc:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009ce:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009d5:	eb 14                	jmp    f01009eb <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009d7:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01009da:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f01009dd:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f01009df:	ff 45 0c             	incl   0xc(%ebp)
f01009e2:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009e4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f01009eb:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01009ee:	7e 84                	jle    f0100974 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01009f0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01009f4:	75 0d                	jne    f0100a03 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f01009f6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01009f9:	8b 00                	mov    (%eax),%eax
f01009fb:	48                   	dec    %eax
f01009fc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01009ff:	89 07                	mov    %eax,(%edi)
f0100a01:	eb 22                	jmp    f0100a25 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a03:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a06:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a08:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a0b:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a0d:	eb 01                	jmp    f0100a10 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a0f:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a10:	39 c1                	cmp    %eax,%ecx
f0100a12:	7d 0c                	jge    f0100a20 <stab_binsearch+0xd0>
f0100a14:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100a17:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a1c:	39 fa                	cmp    %edi,%edx
f0100a1e:	75 ef                	jne    f0100a0f <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a20:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100a23:	89 07                	mov    %eax,(%edi)
	}
}
f0100a25:	83 c4 10             	add    $0x10,%esp
f0100a28:	5b                   	pop    %ebx
f0100a29:	5e                   	pop    %esi
f0100a2a:	5f                   	pop    %edi
f0100a2b:	5d                   	pop    %ebp
f0100a2c:	c3                   	ret    

f0100a2d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a2d:	55                   	push   %ebp
f0100a2e:	89 e5                	mov    %esp,%ebp
f0100a30:	57                   	push   %edi
f0100a31:	56                   	push   %esi
f0100a32:	53                   	push   %ebx
f0100a33:	83 ec 2c             	sub    $0x2c,%esp
f0100a36:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a39:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a3c:	c7 03 d4 1e 10 f0    	movl   $0xf0101ed4,(%ebx)
	info->eip_line = 0;
f0100a42:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a49:	c7 43 08 d4 1e 10 f0 	movl   $0xf0101ed4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100a50:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100a57:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100a5a:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a61:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100a67:	76 12                	jbe    f0100a7b <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a69:	b8 c9 72 10 f0       	mov    $0xf01072c9,%eax
f0100a6e:	3d a1 59 10 f0       	cmp    $0xf01059a1,%eax
f0100a73:	0f 86 8b 01 00 00    	jbe    f0100c04 <debuginfo_eip+0x1d7>
f0100a79:	eb 1c                	jmp    f0100a97 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a7b:	c7 44 24 08 de 1e 10 	movl   $0xf0101ede,0x8(%esp)
f0100a82:	f0 
f0100a83:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100a8a:	00 
f0100a8b:	c7 04 24 eb 1e 10 f0 	movl   $0xf0101eeb,(%esp)
f0100a92:	e8 61 f6 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a97:	80 3d c8 72 10 f0 00 	cmpb   $0x0,0xf01072c8
f0100a9e:	0f 85 67 01 00 00    	jne    f0100c0b <debuginfo_eip+0x1de>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100aa4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100aab:	b8 a0 59 10 f0       	mov    $0xf01059a0,%eax
f0100ab0:	2d 0c 21 10 f0       	sub    $0xf010210c,%eax
f0100ab5:	c1 f8 02             	sar    $0x2,%eax
f0100ab8:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100abe:	83 e8 01             	sub    $0x1,%eax
f0100ac1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100ac4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ac8:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100acf:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100ad2:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ad5:	b8 0c 21 10 f0       	mov    $0xf010210c,%eax
f0100ada:	e8 71 fe ff ff       	call   f0100950 <stab_binsearch>
	if (lfile == 0)
f0100adf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ae2:	85 c0                	test   %eax,%eax
f0100ae4:	0f 84 28 01 00 00    	je     f0100c12 <debuginfo_eip+0x1e5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100aea:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100aed:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100af0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100af3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100af7:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100afe:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b01:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b04:	b8 0c 21 10 f0       	mov    $0xf010210c,%eax
f0100b09:	e8 42 fe ff ff       	call   f0100950 <stab_binsearch>

	if (lfun <= rfun) {
f0100b0e:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100b11:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100b14:	7f 2e                	jg     f0100b44 <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b16:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b19:	8d 90 0c 21 10 f0    	lea    -0xfefdef4(%eax),%edx
f0100b1f:	8b 80 0c 21 10 f0    	mov    -0xfefdef4(%eax),%eax
f0100b25:	b9 c9 72 10 f0       	mov    $0xf01072c9,%ecx
f0100b2a:	81 e9 a1 59 10 f0    	sub    $0xf01059a1,%ecx
f0100b30:	39 c8                	cmp    %ecx,%eax
f0100b32:	73 08                	jae    f0100b3c <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b34:	05 a1 59 10 f0       	add    $0xf01059a1,%eax
f0100b39:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b3c:	8b 42 08             	mov    0x8(%edx),%eax
f0100b3f:	89 43 10             	mov    %eax,0x10(%ebx)
f0100b42:	eb 06                	jmp    f0100b4a <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b44:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b47:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b4a:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100b51:	00 
f0100b52:	8b 43 08             	mov    0x8(%ebx),%eax
f0100b55:	89 04 24             	mov    %eax,(%esp)
f0100b58:	e8 c7 09 00 00       	call   f0101524 <strfind>
f0100b5d:	2b 43 08             	sub    0x8(%ebx),%eax
f0100b60:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b63:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b66:	39 cf                	cmp    %ecx,%edi
f0100b68:	7c 5c                	jl     f0100bc6 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0100b6a:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b6d:	8d b0 0c 21 10 f0    	lea    -0xfefdef4(%eax),%esi
f0100b73:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f0100b77:	80 fa 84             	cmp    $0x84,%dl
f0100b7a:	74 2b                	je     f0100ba7 <debuginfo_eip+0x17a>
f0100b7c:	05 00 21 10 f0       	add    $0xf0102100,%eax
f0100b81:	eb 15                	jmp    f0100b98 <debuginfo_eip+0x16b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b83:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b86:	39 cf                	cmp    %ecx,%edi
f0100b88:	7c 3c                	jl     f0100bc6 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0100b8a:	89 c6                	mov    %eax,%esi
f0100b8c:	83 e8 0c             	sub    $0xc,%eax
f0100b8f:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f0100b93:	80 fa 84             	cmp    $0x84,%dl
f0100b96:	74 0f                	je     f0100ba7 <debuginfo_eip+0x17a>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b98:	80 fa 64             	cmp    $0x64,%dl
f0100b9b:	75 e6                	jne    f0100b83 <debuginfo_eip+0x156>
f0100b9d:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0100ba1:	74 e0                	je     f0100b83 <debuginfo_eip+0x156>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100ba3:	39 f9                	cmp    %edi,%ecx
f0100ba5:	7f 1f                	jg     f0100bc6 <debuginfo_eip+0x199>
f0100ba7:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100baa:	8b 87 0c 21 10 f0    	mov    -0xfefdef4(%edi),%eax
f0100bb0:	ba c9 72 10 f0       	mov    $0xf01072c9,%edx
f0100bb5:	81 ea a1 59 10 f0    	sub    $0xf01059a1,%edx
f0100bbb:	39 d0                	cmp    %edx,%eax
f0100bbd:	73 07                	jae    f0100bc6 <debuginfo_eip+0x199>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100bbf:	05 a1 59 10 f0       	add    $0xf01059a1,%eax
f0100bc4:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bc6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100bc9:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100bcc:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bd1:	39 ca                	cmp    %ecx,%edx
f0100bd3:	7d 5e                	jge    f0100c33 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
f0100bd5:	8d 42 01             	lea    0x1(%edx),%eax
f0100bd8:	39 c1                	cmp    %eax,%ecx
f0100bda:	7e 3d                	jle    f0100c19 <debuginfo_eip+0x1ec>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bdc:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100bdf:	80 ba 10 21 10 f0 a0 	cmpb   $0xa0,-0xfefdef0(%edx)
f0100be6:	75 38                	jne    f0100c20 <debuginfo_eip+0x1f3>
f0100be8:	81 c2 00 21 10 f0    	add    $0xf0102100,%edx
		     lline++)
			info->eip_fn_narg++;
f0100bee:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100bf2:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100bf5:	39 c1                	cmp    %eax,%ecx
f0100bf7:	7e 2e                	jle    f0100c27 <debuginfo_eip+0x1fa>
f0100bf9:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bfc:	80 7a 10 a0          	cmpb   $0xa0,0x10(%edx)
f0100c00:	74 ec                	je     f0100bee <debuginfo_eip+0x1c1>
f0100c02:	eb 2a                	jmp    f0100c2e <debuginfo_eip+0x201>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c09:	eb 28                	jmp    f0100c33 <debuginfo_eip+0x206>
f0100c0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c10:	eb 21                	jmp    f0100c33 <debuginfo_eip+0x206>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c12:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c17:	eb 1a                	jmp    f0100c33 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c19:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c1e:	eb 13                	jmp    f0100c33 <debuginfo_eip+0x206>
f0100c20:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c25:	eb 0c                	jmp    f0100c33 <debuginfo_eip+0x206>
f0100c27:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c2c:	eb 05                	jmp    f0100c33 <debuginfo_eip+0x206>
f0100c2e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c33:	83 c4 2c             	add    $0x2c,%esp
f0100c36:	5b                   	pop    %ebx
f0100c37:	5e                   	pop    %esi
f0100c38:	5f                   	pop    %edi
f0100c39:	5d                   	pop    %ebp
f0100c3a:	c3                   	ret    
f0100c3b:	66 90                	xchg   %ax,%ax
f0100c3d:	66 90                	xchg   %ax,%ax
f0100c3f:	90                   	nop

f0100c40 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c40:	55                   	push   %ebp
f0100c41:	89 e5                	mov    %esp,%ebp
f0100c43:	57                   	push   %edi
f0100c44:	56                   	push   %esi
f0100c45:	53                   	push   %ebx
f0100c46:	83 ec 3c             	sub    $0x3c,%esp
f0100c49:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100c4c:	89 d7                	mov    %edx,%edi
f0100c4e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c51:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100c54:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100c57:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100c5a:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c5d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100c62:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c65:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100c68:	39 f1                	cmp    %esi,%ecx
f0100c6a:	72 14                	jb     f0100c80 <printnum+0x40>
f0100c6c:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100c6f:	76 0f                	jbe    f0100c80 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c71:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c74:	8d 70 ff             	lea    -0x1(%eax),%esi
f0100c77:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100c7a:	85 f6                	test   %esi,%esi
f0100c7c:	7f 60                	jg     f0100cde <printnum+0x9e>
f0100c7e:	eb 72                	jmp    f0100cf2 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c80:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100c83:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100c87:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0100c8a:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100c8d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100c91:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100c95:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100c99:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100c9d:	89 c3                	mov    %eax,%ebx
f0100c9f:	89 d6                	mov    %edx,%esi
f0100ca1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100ca4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100ca7:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100cab:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100caf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cb2:	89 04 24             	mov    %eax,(%esp)
f0100cb5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100cb8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cbc:	e8 cf 0a 00 00       	call   f0101790 <__udivdi3>
f0100cc1:	89 d9                	mov    %ebx,%ecx
f0100cc3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100cc7:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100ccb:	89 04 24             	mov    %eax,(%esp)
f0100cce:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100cd2:	89 fa                	mov    %edi,%edx
f0100cd4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cd7:	e8 64 ff ff ff       	call   f0100c40 <printnum>
f0100cdc:	eb 14                	jmp    f0100cf2 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100cde:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ce2:	8b 45 18             	mov    0x18(%ebp),%eax
f0100ce5:	89 04 24             	mov    %eax,(%esp)
f0100ce8:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100cea:	83 ee 01             	sub    $0x1,%esi
f0100ced:	75 ef                	jne    f0100cde <printnum+0x9e>
f0100cef:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100cf2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cf6:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100cfa:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100cfd:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d00:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d04:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100d08:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d0b:	89 04 24             	mov    %eax,(%esp)
f0100d0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d11:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d15:	e8 a6 0b 00 00       	call   f01018c0 <__umoddi3>
f0100d1a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d1e:	0f be 80 f9 1e 10 f0 	movsbl -0xfefe107(%eax),%eax
f0100d25:	89 04 24             	mov    %eax,(%esp)
f0100d28:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d2b:	ff d0                	call   *%eax
}
f0100d2d:	83 c4 3c             	add    $0x3c,%esp
f0100d30:	5b                   	pop    %ebx
f0100d31:	5e                   	pop    %esi
f0100d32:	5f                   	pop    %edi
f0100d33:	5d                   	pop    %ebp
f0100d34:	c3                   	ret    

f0100d35 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d35:	55                   	push   %ebp
f0100d36:	89 e5                	mov    %esp,%ebp
f0100d38:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d3b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d3f:	8b 10                	mov    (%eax),%edx
f0100d41:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d44:	73 0a                	jae    f0100d50 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d46:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d49:	89 08                	mov    %ecx,(%eax)
f0100d4b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d4e:	88 02                	mov    %al,(%edx)
}
f0100d50:	5d                   	pop    %ebp
f0100d51:	c3                   	ret    

f0100d52 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d52:	55                   	push   %ebp
f0100d53:	89 e5                	mov    %esp,%ebp
f0100d55:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d58:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d5b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d5f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d62:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d66:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d69:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d6d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d70:	89 04 24             	mov    %eax,(%esp)
f0100d73:	e8 02 00 00 00       	call   f0100d7a <vprintfmt>
	va_end(ap);
}
f0100d78:	c9                   	leave  
f0100d79:	c3                   	ret    

f0100d7a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d7a:	55                   	push   %ebp
f0100d7b:	89 e5                	mov    %esp,%ebp
f0100d7d:	57                   	push   %edi
f0100d7e:	56                   	push   %esi
f0100d7f:	53                   	push   %ebx
f0100d80:	83 ec 3c             	sub    $0x3c,%esp
f0100d83:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100d86:	89 df                	mov    %ebx,%edi
f0100d88:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d8b:	eb 03                	jmp    f0100d90 <vprintfmt+0x16>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f0100d8d:	89 75 10             	mov    %esi,0x10(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d90:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d93:	8d 70 01             	lea    0x1(%eax),%esi
f0100d96:	0f b6 00             	movzbl (%eax),%eax
f0100d99:	83 f8 25             	cmp    $0x25,%eax
f0100d9c:	74 2d                	je     f0100dcb <vprintfmt+0x51>
			if (ch == '\0')
f0100d9e:	85 c0                	test   %eax,%eax
f0100da0:	75 14                	jne    f0100db6 <vprintfmt+0x3c>
f0100da2:	e9 6b 04 00 00       	jmp    f0101212 <vprintfmt+0x498>
f0100da7:	85 c0                	test   %eax,%eax
f0100da9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0100db0:	0f 84 5c 04 00 00    	je     f0101212 <vprintfmt+0x498>
				return;
			putch(ch, putdat);
f0100db6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100dba:	89 04 24             	mov    %eax,(%esp)
f0100dbd:	ff d7                	call   *%edi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100dbf:	83 c6 01             	add    $0x1,%esi
f0100dc2:	0f b6 46 ff          	movzbl -0x1(%esi),%eax
f0100dc6:	83 f8 25             	cmp    $0x25,%eax
f0100dc9:	75 dc                	jne    f0100da7 <vprintfmt+0x2d>
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100dcb:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
f0100dcf:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100dd6:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100ddd:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100de4:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100de9:	eb 1f                	jmp    f0100e0a <vprintfmt+0x90>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100deb:	8b 75 10             	mov    0x10(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100dee:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
f0100df2:	eb 16                	jmp    f0100e0a <vprintfmt+0x90>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100df4:	8b 75 10             	mov    0x10(%ebp),%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100df7:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
f0100dfb:	eb 0d                	jmp    f0100e0a <vprintfmt+0x90>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100dfd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e00:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e03:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e0a:	8d 46 01             	lea    0x1(%esi),%eax
f0100e0d:	89 45 10             	mov    %eax,0x10(%ebp)
f0100e10:	0f b6 06             	movzbl (%esi),%eax
f0100e13:	0f b6 d0             	movzbl %al,%edx
f0100e16:	83 e8 23             	sub    $0x23,%eax
f0100e19:	3c 55                	cmp    $0x55,%al
f0100e1b:	0f 87 c4 03 00 00    	ja     f01011e5 <vprintfmt+0x46b>
f0100e21:	0f b6 c0             	movzbl %al,%eax
f0100e24:	ff 24 85 88 1f 10 f0 	jmp    *-0xfefe078(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e2b:	8d 42 d0             	lea    -0x30(%edx),%eax
f0100e2e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
f0100e31:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100e35:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100e38:	83 fa 09             	cmp    $0x9,%edx
f0100e3b:	77 63                	ja     f0100ea0 <vprintfmt+0x126>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e3d:	8b 75 10             	mov    0x10(%ebp),%esi
f0100e40:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0100e43:	8b 55 d4             	mov    -0x2c(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e46:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100e49:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100e4c:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100e50:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100e53:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100e56:	83 f9 09             	cmp    $0x9,%ecx
f0100e59:	76 eb                	jbe    f0100e46 <vprintfmt+0xcc>
f0100e5b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100e5e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0100e61:	eb 40                	jmp    f0100ea3 <vprintfmt+0x129>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e63:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e66:	8b 00                	mov    (%eax),%eax
f0100e68:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100e6b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e6e:	8d 40 04             	lea    0x4(%eax),%eax
f0100e71:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e74:	8b 75 10             	mov    0x10(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e77:	eb 2a                	jmp    f0100ea3 <vprintfmt+0x129>
f0100e79:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100e7c:	85 d2                	test   %edx,%edx
f0100e7e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e83:	0f 49 c2             	cmovns %edx,%eax
f0100e86:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e89:	8b 75 10             	mov    0x10(%ebp),%esi
f0100e8c:	e9 79 ff ff ff       	jmp    f0100e0a <vprintfmt+0x90>
f0100e91:	8b 75 10             	mov    0x10(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e94:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100e9b:	e9 6a ff ff ff       	jmp    f0100e0a <vprintfmt+0x90>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea0:	8b 75 10             	mov    0x10(%ebp),%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100ea3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100ea7:	0f 89 5d ff ff ff    	jns    f0100e0a <vprintfmt+0x90>
f0100ead:	e9 4b ff ff ff       	jmp    f0100dfd <vprintfmt+0x83>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100eb2:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eb5:	8b 75 10             	mov    0x10(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100eb8:	e9 4d ff ff ff       	jmp    f0100e0a <vprintfmt+0x90>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ebd:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ec0:	8d 70 04             	lea    0x4(%eax),%esi
f0100ec3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ec7:	8b 00                	mov    (%eax),%eax
f0100ec9:	89 04 24             	mov    %eax,(%esp)
f0100ecc:	ff d7                	call   *%edi
f0100ece:	89 75 14             	mov    %esi,0x14(%ebp)
			break;
f0100ed1:	e9 ba fe ff ff       	jmp    f0100d90 <vprintfmt+0x16>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ed6:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ed9:	8d 70 04             	lea    0x4(%eax),%esi
f0100edc:	8b 00                	mov    (%eax),%eax
f0100ede:	99                   	cltd   
f0100edf:	31 d0                	xor    %edx,%eax
f0100ee1:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100ee3:	83 f8 06             	cmp    $0x6,%eax
f0100ee6:	7f 0b                	jg     f0100ef3 <vprintfmt+0x179>
f0100ee8:	8b 14 85 e0 20 10 f0 	mov    -0xfefdf20(,%eax,4),%edx
f0100eef:	85 d2                	test   %edx,%edx
f0100ef1:	75 20                	jne    f0100f13 <vprintfmt+0x199>
				printfmt(putch, putdat, "error %d", err);
f0100ef3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ef7:	c7 44 24 08 11 1f 10 	movl   $0xf0101f11,0x8(%esp)
f0100efe:	f0 
f0100eff:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f03:	89 3c 24             	mov    %edi,(%esp)
f0100f06:	e8 47 fe ff ff       	call   f0100d52 <printfmt>
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f0b:	89 75 14             	mov    %esi,0x14(%ebp)
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f0e:	e9 7d fe ff ff       	jmp    f0100d90 <vprintfmt+0x16>
			else
				printfmt(putch, putdat, "%s", p);
f0100f13:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100f17:	c7 44 24 08 1a 1f 10 	movl   $0xf0101f1a,0x8(%esp)
f0100f1e:	f0 
f0100f1f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f23:	89 3c 24             	mov    %edi,(%esp)
f0100f26:	e8 27 fe ff ff       	call   f0100d52 <printfmt>
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f2b:	89 75 14             	mov    %esi,0x14(%ebp)
f0100f2e:	e9 5d fe ff ff       	jmp    f0100d90 <vprintfmt+0x16>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f33:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f36:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100f39:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f3c:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100f40:	8b 00                	mov    (%eax),%eax
				p = "(null)";
f0100f42:	85 c0                	test   %eax,%eax
f0100f44:	b9 0a 1f 10 f0       	mov    $0xf0101f0a,%ecx
f0100f49:	0f 45 c8             	cmovne %eax,%ecx
f0100f4c:	89 4d d0             	mov    %ecx,-0x30(%ebp)
			if (width > 0 && padc != '-')
f0100f4f:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f0100f53:	74 04                	je     f0100f59 <vprintfmt+0x1df>
f0100f55:	85 f6                	test   %esi,%esi
f0100f57:	7f 19                	jg     f0100f72 <vprintfmt+0x1f8>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f59:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100f5c:	8d 70 01             	lea    0x1(%eax),%esi
f0100f5f:	0f b6 10             	movzbl (%eax),%edx
f0100f62:	0f be c2             	movsbl %dl,%eax
f0100f65:	85 c0                	test   %eax,%eax
f0100f67:	0f 85 9a 00 00 00    	jne    f0101007 <vprintfmt+0x28d>
f0100f6d:	e9 87 00 00 00       	jmp    f0100ff9 <vprintfmt+0x27f>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f72:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100f76:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100f79:	89 04 24             	mov    %eax,(%esp)
f0100f7c:	e8 11 04 00 00       	call   f0101392 <strnlen>
f0100f81:	29 c6                	sub    %eax,%esi
f0100f83:	89 f0                	mov    %esi,%eax
f0100f85:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0100f88:	85 f6                	test   %esi,%esi
f0100f8a:	7e cd                	jle    f0100f59 <vprintfmt+0x1df>
					putch(padc, putdat);
f0100f8c:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0100f90:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f93:	89 c3                	mov    %eax,%ebx
f0100f95:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f98:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f9c:	89 34 24             	mov    %esi,(%esp)
f0100f9f:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fa1:	83 eb 01             	sub    $0x1,%ebx
f0100fa4:	75 ef                	jne    f0100f95 <vprintfmt+0x21b>
f0100fa6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100fa9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fac:	eb ab                	jmp    f0100f59 <vprintfmt+0x1df>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fae:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100fb2:	74 1e                	je     f0100fd2 <vprintfmt+0x258>
f0100fb4:	0f be d2             	movsbl %dl,%edx
f0100fb7:	83 ea 20             	sub    $0x20,%edx
f0100fba:	83 fa 5e             	cmp    $0x5e,%edx
f0100fbd:	76 13                	jbe    f0100fd2 <vprintfmt+0x258>
					putch('?', putdat);
f0100fbf:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fc2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100fc6:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100fcd:	ff 55 08             	call   *0x8(%ebp)
f0100fd0:	eb 0d                	jmp    f0100fdf <vprintfmt+0x265>
				else
					putch(ch, putdat);
f0100fd2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0100fd5:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100fd9:	89 04 24             	mov    %eax,(%esp)
f0100fdc:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fdf:	83 eb 01             	sub    $0x1,%ebx
f0100fe2:	83 c6 01             	add    $0x1,%esi
f0100fe5:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0100fe9:	0f be c2             	movsbl %dl,%eax
f0100fec:	85 c0                	test   %eax,%eax
f0100fee:	75 23                	jne    f0101013 <vprintfmt+0x299>
f0100ff0:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100ff3:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100ff6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ff9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100ffc:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101000:	7f 25                	jg     f0101027 <vprintfmt+0x2ad>
f0101002:	e9 89 fd ff ff       	jmp    f0100d90 <vprintfmt+0x16>
f0101007:	89 7d 08             	mov    %edi,0x8(%ebp)
f010100a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010100d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101010:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101013:	85 ff                	test   %edi,%edi
f0101015:	78 97                	js     f0100fae <vprintfmt+0x234>
f0101017:	83 ef 01             	sub    $0x1,%edi
f010101a:	79 92                	jns    f0100fae <vprintfmt+0x234>
f010101c:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010101f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101022:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101025:	eb d2                	jmp    f0100ff9 <vprintfmt+0x27f>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101027:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010102b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101032:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101034:	83 ee 01             	sub    $0x1,%esi
f0101037:	75 ee                	jne    f0101027 <vprintfmt+0x2ad>
f0101039:	e9 52 fd ff ff       	jmp    f0100d90 <vprintfmt+0x16>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010103e:	83 f9 01             	cmp    $0x1,%ecx
f0101041:	7e 19                	jle    f010105c <vprintfmt+0x2e2>
		return va_arg(*ap, long long);
f0101043:	8b 45 14             	mov    0x14(%ebp),%eax
f0101046:	8b 50 04             	mov    0x4(%eax),%edx
f0101049:	8b 00                	mov    (%eax),%eax
f010104b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010104e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101051:	8b 45 14             	mov    0x14(%ebp),%eax
f0101054:	8d 40 08             	lea    0x8(%eax),%eax
f0101057:	89 45 14             	mov    %eax,0x14(%ebp)
f010105a:	eb 38                	jmp    f0101094 <vprintfmt+0x31a>
	else if (lflag)
f010105c:	85 c9                	test   %ecx,%ecx
f010105e:	74 1b                	je     f010107b <vprintfmt+0x301>
		return va_arg(*ap, long);
f0101060:	8b 45 14             	mov    0x14(%ebp),%eax
f0101063:	8b 30                	mov    (%eax),%esi
f0101065:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0101068:	89 f0                	mov    %esi,%eax
f010106a:	c1 f8 1f             	sar    $0x1f,%eax
f010106d:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101070:	8b 45 14             	mov    0x14(%ebp),%eax
f0101073:	8d 40 04             	lea    0x4(%eax),%eax
f0101076:	89 45 14             	mov    %eax,0x14(%ebp)
f0101079:	eb 19                	jmp    f0101094 <vprintfmt+0x31a>
	else
		return va_arg(*ap, int);
f010107b:	8b 45 14             	mov    0x14(%ebp),%eax
f010107e:	8b 30                	mov    (%eax),%esi
f0101080:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0101083:	89 f0                	mov    %esi,%eax
f0101085:	c1 f8 1f             	sar    $0x1f,%eax
f0101088:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010108b:	8b 45 14             	mov    0x14(%ebp),%eax
f010108e:	8d 40 04             	lea    0x4(%eax),%eax
f0101091:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101094:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101097:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010109a:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010109f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01010a3:	0f 89 06 01 00 00    	jns    f01011af <vprintfmt+0x435>
				putch('-', putdat);
f01010a9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010ad:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01010b4:	ff d7                	call   *%edi
				num = -(long long) num;
f01010b6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01010b9:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01010bc:	f7 da                	neg    %edx
f01010be:	83 d1 00             	adc    $0x0,%ecx
f01010c1:	f7 d9                	neg    %ecx
			}
			base = 10;
f01010c3:	b8 0a 00 00 00       	mov    $0xa,%eax
f01010c8:	e9 e2 00 00 00       	jmp    f01011af <vprintfmt+0x435>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010cd:	83 f9 01             	cmp    $0x1,%ecx
f01010d0:	7e 10                	jle    f01010e2 <vprintfmt+0x368>
		return va_arg(*ap, unsigned long long);
f01010d2:	8b 45 14             	mov    0x14(%ebp),%eax
f01010d5:	8b 10                	mov    (%eax),%edx
f01010d7:	8b 48 04             	mov    0x4(%eax),%ecx
f01010da:	8d 40 08             	lea    0x8(%eax),%eax
f01010dd:	89 45 14             	mov    %eax,0x14(%ebp)
f01010e0:	eb 26                	jmp    f0101108 <vprintfmt+0x38e>
	else if (lflag)
f01010e2:	85 c9                	test   %ecx,%ecx
f01010e4:	74 12                	je     f01010f8 <vprintfmt+0x37e>
		return va_arg(*ap, unsigned long);
f01010e6:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e9:	8b 10                	mov    (%eax),%edx
f01010eb:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010f0:	8d 40 04             	lea    0x4(%eax),%eax
f01010f3:	89 45 14             	mov    %eax,0x14(%ebp)
f01010f6:	eb 10                	jmp    f0101108 <vprintfmt+0x38e>
	else
		return va_arg(*ap, unsigned int);
f01010f8:	8b 45 14             	mov    0x14(%ebp),%eax
f01010fb:	8b 10                	mov    (%eax),%edx
f01010fd:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101102:	8d 40 04             	lea    0x4(%eax),%eax
f0101105:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101108:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010110d:	e9 9d 00 00 00       	jmp    f01011af <vprintfmt+0x435>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0101112:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101116:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f010111d:	ff d7                	call   *%edi
			putch('X', putdat);
f010111f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101123:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f010112a:	ff d7                	call   *%edi
			putch('X', putdat);
f010112c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101130:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101137:	ff d7                	call   *%edi
			break;
f0101139:	e9 52 fc ff ff       	jmp    f0100d90 <vprintfmt+0x16>

		// pointer
		case 'p':
			putch('0', putdat);
f010113e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101142:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101149:	ff d7                	call   *%edi
			putch('x', putdat);
f010114b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010114f:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101156:	ff d7                	call   *%edi
			num = (unsigned long long)
f0101158:	8b 45 14             	mov    0x14(%ebp),%eax
f010115b:	8b 10                	mov    (%eax),%edx
f010115d:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
f0101162:	8d 40 04             	lea    0x4(%eax),%eax
f0101165:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101168:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010116d:	eb 40                	jmp    f01011af <vprintfmt+0x435>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010116f:	83 f9 01             	cmp    $0x1,%ecx
f0101172:	7e 10                	jle    f0101184 <vprintfmt+0x40a>
		return va_arg(*ap, unsigned long long);
f0101174:	8b 45 14             	mov    0x14(%ebp),%eax
f0101177:	8b 10                	mov    (%eax),%edx
f0101179:	8b 48 04             	mov    0x4(%eax),%ecx
f010117c:	8d 40 08             	lea    0x8(%eax),%eax
f010117f:	89 45 14             	mov    %eax,0x14(%ebp)
f0101182:	eb 26                	jmp    f01011aa <vprintfmt+0x430>
	else if (lflag)
f0101184:	85 c9                	test   %ecx,%ecx
f0101186:	74 12                	je     f010119a <vprintfmt+0x420>
		return va_arg(*ap, unsigned long);
f0101188:	8b 45 14             	mov    0x14(%ebp),%eax
f010118b:	8b 10                	mov    (%eax),%edx
f010118d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101192:	8d 40 04             	lea    0x4(%eax),%eax
f0101195:	89 45 14             	mov    %eax,0x14(%ebp)
f0101198:	eb 10                	jmp    f01011aa <vprintfmt+0x430>
	else
		return va_arg(*ap, unsigned int);
f010119a:	8b 45 14             	mov    0x14(%ebp),%eax
f010119d:	8b 10                	mov    (%eax),%edx
f010119f:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011a4:	8d 40 04             	lea    0x4(%eax),%eax
f01011a7:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01011aa:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01011af:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f01011b3:	89 74 24 10          	mov    %esi,0x10(%esp)
f01011b7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01011ba:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01011be:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011c2:	89 14 24             	mov    %edx,(%esp)
f01011c5:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01011c9:	89 da                	mov    %ebx,%edx
f01011cb:	89 f8                	mov    %edi,%eax
f01011cd:	e8 6e fa ff ff       	call   f0100c40 <printnum>
			break;
f01011d2:	e9 b9 fb ff ff       	jmp    f0100d90 <vprintfmt+0x16>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01011d7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011db:	89 14 24             	mov    %edx,(%esp)
f01011de:	ff d7                	call   *%edi
			break;
f01011e0:	e9 ab fb ff ff       	jmp    f0100d90 <vprintfmt+0x16>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01011e5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011e9:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01011f0:	ff d7                	call   *%edi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01011f2:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01011f6:	0f 84 91 fb ff ff    	je     f0100d8d <vprintfmt+0x13>
f01011fc:	89 75 10             	mov    %esi,0x10(%ebp)
f01011ff:	89 f0                	mov    %esi,%eax
f0101201:	83 e8 01             	sub    $0x1,%eax
f0101204:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0101208:	75 f7                	jne    f0101201 <vprintfmt+0x487>
f010120a:	89 45 10             	mov    %eax,0x10(%ebp)
f010120d:	e9 7e fb ff ff       	jmp    f0100d90 <vprintfmt+0x16>
				/* do nothing */;
			break;
		}
	}
}
f0101212:	83 c4 3c             	add    $0x3c,%esp
f0101215:	5b                   	pop    %ebx
f0101216:	5e                   	pop    %esi
f0101217:	5f                   	pop    %edi
f0101218:	5d                   	pop    %ebp
f0101219:	c3                   	ret    

f010121a <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010121a:	55                   	push   %ebp
f010121b:	89 e5                	mov    %esp,%ebp
f010121d:	83 ec 28             	sub    $0x28,%esp
f0101220:	8b 45 08             	mov    0x8(%ebp),%eax
f0101223:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101226:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101229:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010122d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101230:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101237:	85 c0                	test   %eax,%eax
f0101239:	74 30                	je     f010126b <vsnprintf+0x51>
f010123b:	85 d2                	test   %edx,%edx
f010123d:	7e 2c                	jle    f010126b <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010123f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101242:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101246:	8b 45 10             	mov    0x10(%ebp),%eax
f0101249:	89 44 24 08          	mov    %eax,0x8(%esp)
f010124d:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101250:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101254:	c7 04 24 35 0d 10 f0 	movl   $0xf0100d35,(%esp)
f010125b:	e8 1a fb ff ff       	call   f0100d7a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101260:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101263:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101266:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101269:	eb 05                	jmp    f0101270 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010126b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101270:	c9                   	leave  
f0101271:	c3                   	ret    

f0101272 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101272:	55                   	push   %ebp
f0101273:	89 e5                	mov    %esp,%ebp
f0101275:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101278:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010127b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010127f:	8b 45 10             	mov    0x10(%ebp),%eax
f0101282:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101286:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101289:	89 44 24 04          	mov    %eax,0x4(%esp)
f010128d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101290:	89 04 24             	mov    %eax,(%esp)
f0101293:	e8 82 ff ff ff       	call   f010121a <vsnprintf>
	va_end(ap);

	return rc;
}
f0101298:	c9                   	leave  
f0101299:	c3                   	ret    
f010129a:	66 90                	xchg   %ax,%ax
f010129c:	66 90                	xchg   %ax,%ax
f010129e:	66 90                	xchg   %ax,%ax

f01012a0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012a0:	55                   	push   %ebp
f01012a1:	89 e5                	mov    %esp,%ebp
f01012a3:	57                   	push   %edi
f01012a4:	56                   	push   %esi
f01012a5:	53                   	push   %ebx
f01012a6:	83 ec 1c             	sub    $0x1c,%esp
f01012a9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012ac:	85 c0                	test   %eax,%eax
f01012ae:	74 10                	je     f01012c0 <readline+0x20>
		cprintf("%s", prompt);
f01012b0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012b4:	c7 04 24 1a 1f 10 f0 	movl   $0xf0101f1a,(%esp)
f01012bb:	e8 67 f6 ff ff       	call   f0100927 <cprintf>

	i = 0;
	echoing = iscons(0);
f01012c0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012c7:	e8 b9 f3 ff ff       	call   f0100685 <iscons>
f01012cc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01012ce:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01012d3:	e8 9c f3 ff ff       	call   f0100674 <getchar>
f01012d8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01012da:	85 c0                	test   %eax,%eax
f01012dc:	79 17                	jns    f01012f5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01012de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012e2:	c7 04 24 fc 20 10 f0 	movl   $0xf01020fc,(%esp)
f01012e9:	e8 39 f6 ff ff       	call   f0100927 <cprintf>
			return NULL;
f01012ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01012f3:	eb 6d                	jmp    f0101362 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01012f5:	83 f8 7f             	cmp    $0x7f,%eax
f01012f8:	74 05                	je     f01012ff <readline+0x5f>
f01012fa:	83 f8 08             	cmp    $0x8,%eax
f01012fd:	75 19                	jne    f0101318 <readline+0x78>
f01012ff:	85 f6                	test   %esi,%esi
f0101301:	7e 15                	jle    f0101318 <readline+0x78>
			if (echoing)
f0101303:	85 ff                	test   %edi,%edi
f0101305:	74 0c                	je     f0101313 <readline+0x73>
				cputchar('\b');
f0101307:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010130e:	e8 51 f3 ff ff       	call   f0100664 <cputchar>
			i--;
f0101313:	83 ee 01             	sub    $0x1,%esi
f0101316:	eb bb                	jmp    f01012d3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101318:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010131e:	7f 1c                	jg     f010133c <readline+0x9c>
f0101320:	83 fb 1f             	cmp    $0x1f,%ebx
f0101323:	7e 17                	jle    f010133c <readline+0x9c>
			if (echoing)
f0101325:	85 ff                	test   %edi,%edi
f0101327:	74 08                	je     f0101331 <readline+0x91>
				cputchar(c);
f0101329:	89 1c 24             	mov    %ebx,(%esp)
f010132c:	e8 33 f3 ff ff       	call   f0100664 <cputchar>
			buf[i++] = c;
f0101331:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101337:	8d 76 01             	lea    0x1(%esi),%esi
f010133a:	eb 97                	jmp    f01012d3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010133c:	83 fb 0d             	cmp    $0xd,%ebx
f010133f:	74 05                	je     f0101346 <readline+0xa6>
f0101341:	83 fb 0a             	cmp    $0xa,%ebx
f0101344:	75 8d                	jne    f01012d3 <readline+0x33>
			if (echoing)
f0101346:	85 ff                	test   %edi,%edi
f0101348:	74 0c                	je     f0101356 <readline+0xb6>
				cputchar('\n');
f010134a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101351:	e8 0e f3 ff ff       	call   f0100664 <cputchar>
			buf[i] = 0;
f0101356:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f010135d:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f0101362:	83 c4 1c             	add    $0x1c,%esp
f0101365:	5b                   	pop    %ebx
f0101366:	5e                   	pop    %esi
f0101367:	5f                   	pop    %edi
f0101368:	5d                   	pop    %ebp
f0101369:	c3                   	ret    
f010136a:	66 90                	xchg   %ax,%ax
f010136c:	66 90                	xchg   %ax,%ax
f010136e:	66 90                	xchg   %ax,%ax

f0101370 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101370:	55                   	push   %ebp
f0101371:	89 e5                	mov    %esp,%ebp
f0101373:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101376:	80 3a 00             	cmpb   $0x0,(%edx)
f0101379:	74 10                	je     f010138b <strlen+0x1b>
f010137b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0101380:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101383:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101387:	75 f7                	jne    f0101380 <strlen+0x10>
f0101389:	eb 05                	jmp    f0101390 <strlen+0x20>
f010138b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101390:	5d                   	pop    %ebp
f0101391:	c3                   	ret    

f0101392 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101392:	55                   	push   %ebp
f0101393:	89 e5                	mov    %esp,%ebp
f0101395:	53                   	push   %ebx
f0101396:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101399:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010139c:	85 c9                	test   %ecx,%ecx
f010139e:	74 1c                	je     f01013bc <strnlen+0x2a>
f01013a0:	80 3b 00             	cmpb   $0x0,(%ebx)
f01013a3:	74 1e                	je     f01013c3 <strnlen+0x31>
f01013a5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01013aa:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013ac:	39 ca                	cmp    %ecx,%edx
f01013ae:	74 18                	je     f01013c8 <strnlen+0x36>
f01013b0:	83 c2 01             	add    $0x1,%edx
f01013b3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01013b8:	75 f0                	jne    f01013aa <strnlen+0x18>
f01013ba:	eb 0c                	jmp    f01013c8 <strnlen+0x36>
f01013bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01013c1:	eb 05                	jmp    f01013c8 <strnlen+0x36>
f01013c3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01013c8:	5b                   	pop    %ebx
f01013c9:	5d                   	pop    %ebp
f01013ca:	c3                   	ret    

f01013cb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01013cb:	55                   	push   %ebp
f01013cc:	89 e5                	mov    %esp,%ebp
f01013ce:	53                   	push   %ebx
f01013cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01013d2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01013d5:	89 c2                	mov    %eax,%edx
f01013d7:	83 c2 01             	add    $0x1,%edx
f01013da:	83 c1 01             	add    $0x1,%ecx
f01013dd:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01013e1:	88 5a ff             	mov    %bl,-0x1(%edx)
f01013e4:	84 db                	test   %bl,%bl
f01013e6:	75 ef                	jne    f01013d7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01013e8:	5b                   	pop    %ebx
f01013e9:	5d                   	pop    %ebp
f01013ea:	c3                   	ret    

f01013eb <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01013eb:	55                   	push   %ebp
f01013ec:	89 e5                	mov    %esp,%ebp
f01013ee:	56                   	push   %esi
f01013ef:	53                   	push   %ebx
f01013f0:	8b 75 08             	mov    0x8(%ebp),%esi
f01013f3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013f6:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013f9:	85 db                	test   %ebx,%ebx
f01013fb:	74 17                	je     f0101414 <strncpy+0x29>
f01013fd:	01 f3                	add    %esi,%ebx
f01013ff:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f0101401:	83 c1 01             	add    $0x1,%ecx
f0101404:	0f b6 02             	movzbl (%edx),%eax
f0101407:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010140a:	80 3a 01             	cmpb   $0x1,(%edx)
f010140d:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101410:	39 d9                	cmp    %ebx,%ecx
f0101412:	75 ed                	jne    f0101401 <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101414:	89 f0                	mov    %esi,%eax
f0101416:	5b                   	pop    %ebx
f0101417:	5e                   	pop    %esi
f0101418:	5d                   	pop    %ebp
f0101419:	c3                   	ret    

f010141a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010141a:	55                   	push   %ebp
f010141b:	89 e5                	mov    %esp,%ebp
f010141d:	57                   	push   %edi
f010141e:	56                   	push   %esi
f010141f:	53                   	push   %ebx
f0101420:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101423:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101426:	8b 75 10             	mov    0x10(%ebp),%esi
f0101429:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010142b:	85 f6                	test   %esi,%esi
f010142d:	74 34                	je     f0101463 <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f010142f:	83 fe 01             	cmp    $0x1,%esi
f0101432:	74 26                	je     f010145a <strlcpy+0x40>
f0101434:	0f b6 0b             	movzbl (%ebx),%ecx
f0101437:	84 c9                	test   %cl,%cl
f0101439:	74 23                	je     f010145e <strlcpy+0x44>
f010143b:	83 ee 02             	sub    $0x2,%esi
f010143e:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
f0101443:	83 c0 01             	add    $0x1,%eax
f0101446:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101449:	39 f2                	cmp    %esi,%edx
f010144b:	74 13                	je     f0101460 <strlcpy+0x46>
f010144d:	83 c2 01             	add    $0x1,%edx
f0101450:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0101454:	84 c9                	test   %cl,%cl
f0101456:	75 eb                	jne    f0101443 <strlcpy+0x29>
f0101458:	eb 06                	jmp    f0101460 <strlcpy+0x46>
f010145a:	89 f8                	mov    %edi,%eax
f010145c:	eb 02                	jmp    f0101460 <strlcpy+0x46>
f010145e:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101460:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101463:	29 f8                	sub    %edi,%eax
}
f0101465:	5b                   	pop    %ebx
f0101466:	5e                   	pop    %esi
f0101467:	5f                   	pop    %edi
f0101468:	5d                   	pop    %ebp
f0101469:	c3                   	ret    

f010146a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010146a:	55                   	push   %ebp
f010146b:	89 e5                	mov    %esp,%ebp
f010146d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101470:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101473:	0f b6 01             	movzbl (%ecx),%eax
f0101476:	84 c0                	test   %al,%al
f0101478:	74 15                	je     f010148f <strcmp+0x25>
f010147a:	3a 02                	cmp    (%edx),%al
f010147c:	75 11                	jne    f010148f <strcmp+0x25>
		p++, q++;
f010147e:	83 c1 01             	add    $0x1,%ecx
f0101481:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101484:	0f b6 01             	movzbl (%ecx),%eax
f0101487:	84 c0                	test   %al,%al
f0101489:	74 04                	je     f010148f <strcmp+0x25>
f010148b:	3a 02                	cmp    (%edx),%al
f010148d:	74 ef                	je     f010147e <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010148f:	0f b6 c0             	movzbl %al,%eax
f0101492:	0f b6 12             	movzbl (%edx),%edx
f0101495:	29 d0                	sub    %edx,%eax
}
f0101497:	5d                   	pop    %ebp
f0101498:	c3                   	ret    

f0101499 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101499:	55                   	push   %ebp
f010149a:	89 e5                	mov    %esp,%ebp
f010149c:	56                   	push   %esi
f010149d:	53                   	push   %ebx
f010149e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01014a1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014a4:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f01014a7:	85 f6                	test   %esi,%esi
f01014a9:	74 29                	je     f01014d4 <strncmp+0x3b>
f01014ab:	0f b6 03             	movzbl (%ebx),%eax
f01014ae:	84 c0                	test   %al,%al
f01014b0:	74 30                	je     f01014e2 <strncmp+0x49>
f01014b2:	3a 02                	cmp    (%edx),%al
f01014b4:	75 2c                	jne    f01014e2 <strncmp+0x49>
f01014b6:	8d 43 01             	lea    0x1(%ebx),%eax
f01014b9:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f01014bb:	89 c3                	mov    %eax,%ebx
f01014bd:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01014c0:	39 f0                	cmp    %esi,%eax
f01014c2:	74 17                	je     f01014db <strncmp+0x42>
f01014c4:	0f b6 08             	movzbl (%eax),%ecx
f01014c7:	84 c9                	test   %cl,%cl
f01014c9:	74 17                	je     f01014e2 <strncmp+0x49>
f01014cb:	83 c0 01             	add    $0x1,%eax
f01014ce:	3a 0a                	cmp    (%edx),%cl
f01014d0:	74 e9                	je     f01014bb <strncmp+0x22>
f01014d2:	eb 0e                	jmp    f01014e2 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01014d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01014d9:	eb 0f                	jmp    f01014ea <strncmp+0x51>
f01014db:	b8 00 00 00 00       	mov    $0x0,%eax
f01014e0:	eb 08                	jmp    f01014ea <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01014e2:	0f b6 03             	movzbl (%ebx),%eax
f01014e5:	0f b6 12             	movzbl (%edx),%edx
f01014e8:	29 d0                	sub    %edx,%eax
}
f01014ea:	5b                   	pop    %ebx
f01014eb:	5e                   	pop    %esi
f01014ec:	5d                   	pop    %ebp
f01014ed:	c3                   	ret    

f01014ee <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01014ee:	55                   	push   %ebp
f01014ef:	89 e5                	mov    %esp,%ebp
f01014f1:	53                   	push   %ebx
f01014f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01014f5:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f01014f8:	0f b6 18             	movzbl (%eax),%ebx
f01014fb:	84 db                	test   %bl,%bl
f01014fd:	74 1d                	je     f010151c <strchr+0x2e>
f01014ff:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101501:	38 d3                	cmp    %dl,%bl
f0101503:	75 06                	jne    f010150b <strchr+0x1d>
f0101505:	eb 1a                	jmp    f0101521 <strchr+0x33>
f0101507:	38 ca                	cmp    %cl,%dl
f0101509:	74 16                	je     f0101521 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010150b:	83 c0 01             	add    $0x1,%eax
f010150e:	0f b6 10             	movzbl (%eax),%edx
f0101511:	84 d2                	test   %dl,%dl
f0101513:	75 f2                	jne    f0101507 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0101515:	b8 00 00 00 00       	mov    $0x0,%eax
f010151a:	eb 05                	jmp    f0101521 <strchr+0x33>
f010151c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101521:	5b                   	pop    %ebx
f0101522:	5d                   	pop    %ebp
f0101523:	c3                   	ret    

f0101524 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101524:	55                   	push   %ebp
f0101525:	89 e5                	mov    %esp,%ebp
f0101527:	53                   	push   %ebx
f0101528:	8b 45 08             	mov    0x8(%ebp),%eax
f010152b:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f010152e:	0f b6 18             	movzbl (%eax),%ebx
f0101531:	84 db                	test   %bl,%bl
f0101533:	74 17                	je     f010154c <strfind+0x28>
f0101535:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101537:	38 d3                	cmp    %dl,%bl
f0101539:	75 07                	jne    f0101542 <strfind+0x1e>
f010153b:	eb 0f                	jmp    f010154c <strfind+0x28>
f010153d:	38 ca                	cmp    %cl,%dl
f010153f:	90                   	nop
f0101540:	74 0a                	je     f010154c <strfind+0x28>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101542:	83 c0 01             	add    $0x1,%eax
f0101545:	0f b6 10             	movzbl (%eax),%edx
f0101548:	84 d2                	test   %dl,%dl
f010154a:	75 f1                	jne    f010153d <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f010154c:	5b                   	pop    %ebx
f010154d:	5d                   	pop    %ebp
f010154e:	c3                   	ret    

f010154f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010154f:	55                   	push   %ebp
f0101550:	89 e5                	mov    %esp,%ebp
f0101552:	57                   	push   %edi
f0101553:	56                   	push   %esi
f0101554:	53                   	push   %ebx
f0101555:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101558:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010155b:	85 c9                	test   %ecx,%ecx
f010155d:	74 36                	je     f0101595 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010155f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101565:	75 28                	jne    f010158f <memset+0x40>
f0101567:	f6 c1 03             	test   $0x3,%cl
f010156a:	75 23                	jne    f010158f <memset+0x40>
		c &= 0xFF;
f010156c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101570:	89 d3                	mov    %edx,%ebx
f0101572:	c1 e3 08             	shl    $0x8,%ebx
f0101575:	89 d6                	mov    %edx,%esi
f0101577:	c1 e6 18             	shl    $0x18,%esi
f010157a:	89 d0                	mov    %edx,%eax
f010157c:	c1 e0 10             	shl    $0x10,%eax
f010157f:	09 f0                	or     %esi,%eax
f0101581:	09 c2                	or     %eax,%edx
f0101583:	89 d0                	mov    %edx,%eax
f0101585:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101587:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010158a:	fc                   	cld    
f010158b:	f3 ab                	rep stos %eax,%es:(%edi)
f010158d:	eb 06                	jmp    f0101595 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010158f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101592:	fc                   	cld    
f0101593:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101595:	89 f8                	mov    %edi,%eax
f0101597:	5b                   	pop    %ebx
f0101598:	5e                   	pop    %esi
f0101599:	5f                   	pop    %edi
f010159a:	5d                   	pop    %ebp
f010159b:	c3                   	ret    

f010159c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010159c:	55                   	push   %ebp
f010159d:	89 e5                	mov    %esp,%ebp
f010159f:	57                   	push   %edi
f01015a0:	56                   	push   %esi
f01015a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01015a4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015a7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01015aa:	39 c6                	cmp    %eax,%esi
f01015ac:	73 35                	jae    f01015e3 <memmove+0x47>
f01015ae:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01015b1:	39 d0                	cmp    %edx,%eax
f01015b3:	73 2e                	jae    f01015e3 <memmove+0x47>
		s += n;
		d += n;
f01015b5:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01015b8:	89 d6                	mov    %edx,%esi
f01015ba:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015bc:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015c2:	75 13                	jne    f01015d7 <memmove+0x3b>
f01015c4:	f6 c1 03             	test   $0x3,%cl
f01015c7:	75 0e                	jne    f01015d7 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01015c9:	83 ef 04             	sub    $0x4,%edi
f01015cc:	8d 72 fc             	lea    -0x4(%edx),%esi
f01015cf:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01015d2:	fd                   	std    
f01015d3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015d5:	eb 09                	jmp    f01015e0 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01015d7:	83 ef 01             	sub    $0x1,%edi
f01015da:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01015dd:	fd                   	std    
f01015de:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01015e0:	fc                   	cld    
f01015e1:	eb 1d                	jmp    f0101600 <memmove+0x64>
f01015e3:	89 f2                	mov    %esi,%edx
f01015e5:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015e7:	f6 c2 03             	test   $0x3,%dl
f01015ea:	75 0f                	jne    f01015fb <memmove+0x5f>
f01015ec:	f6 c1 03             	test   $0x3,%cl
f01015ef:	75 0a                	jne    f01015fb <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01015f1:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01015f4:	89 c7                	mov    %eax,%edi
f01015f6:	fc                   	cld    
f01015f7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015f9:	eb 05                	jmp    f0101600 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01015fb:	89 c7                	mov    %eax,%edi
f01015fd:	fc                   	cld    
f01015fe:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101600:	5e                   	pop    %esi
f0101601:	5f                   	pop    %edi
f0101602:	5d                   	pop    %ebp
f0101603:	c3                   	ret    

f0101604 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0101604:	55                   	push   %ebp
f0101605:	89 e5                	mov    %esp,%ebp
f0101607:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010160a:	8b 45 10             	mov    0x10(%ebp),%eax
f010160d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101611:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101614:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101618:	8b 45 08             	mov    0x8(%ebp),%eax
f010161b:	89 04 24             	mov    %eax,(%esp)
f010161e:	e8 79 ff ff ff       	call   f010159c <memmove>
}
f0101623:	c9                   	leave  
f0101624:	c3                   	ret    

f0101625 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101625:	55                   	push   %ebp
f0101626:	89 e5                	mov    %esp,%ebp
f0101628:	57                   	push   %edi
f0101629:	56                   	push   %esi
f010162a:	53                   	push   %ebx
f010162b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010162e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101631:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101634:	8d 78 ff             	lea    -0x1(%eax),%edi
f0101637:	85 c0                	test   %eax,%eax
f0101639:	74 36                	je     f0101671 <memcmp+0x4c>
		if (*s1 != *s2)
f010163b:	0f b6 03             	movzbl (%ebx),%eax
f010163e:	0f b6 0e             	movzbl (%esi),%ecx
f0101641:	ba 00 00 00 00       	mov    $0x0,%edx
f0101646:	38 c8                	cmp    %cl,%al
f0101648:	74 1c                	je     f0101666 <memcmp+0x41>
f010164a:	eb 10                	jmp    f010165c <memcmp+0x37>
f010164c:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0101651:	83 c2 01             	add    $0x1,%edx
f0101654:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101658:	38 c8                	cmp    %cl,%al
f010165a:	74 0a                	je     f0101666 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f010165c:	0f b6 c0             	movzbl %al,%eax
f010165f:	0f b6 c9             	movzbl %cl,%ecx
f0101662:	29 c8                	sub    %ecx,%eax
f0101664:	eb 10                	jmp    f0101676 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101666:	39 fa                	cmp    %edi,%edx
f0101668:	75 e2                	jne    f010164c <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010166a:	b8 00 00 00 00       	mov    $0x0,%eax
f010166f:	eb 05                	jmp    f0101676 <memcmp+0x51>
f0101671:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101676:	5b                   	pop    %ebx
f0101677:	5e                   	pop    %esi
f0101678:	5f                   	pop    %edi
f0101679:	5d                   	pop    %ebp
f010167a:	c3                   	ret    

f010167b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010167b:	55                   	push   %ebp
f010167c:	89 e5                	mov    %esp,%ebp
f010167e:	53                   	push   %ebx
f010167f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101682:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f0101685:	89 c2                	mov    %eax,%edx
f0101687:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010168a:	39 d0                	cmp    %edx,%eax
f010168c:	73 14                	jae    f01016a2 <memfind+0x27>
		if (*(const unsigned char *) s == (unsigned char) c)
f010168e:	89 d9                	mov    %ebx,%ecx
f0101690:	38 18                	cmp    %bl,(%eax)
f0101692:	75 06                	jne    f010169a <memfind+0x1f>
f0101694:	eb 0c                	jmp    f01016a2 <memfind+0x27>
f0101696:	38 08                	cmp    %cl,(%eax)
f0101698:	74 08                	je     f01016a2 <memfind+0x27>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010169a:	83 c0 01             	add    $0x1,%eax
f010169d:	39 d0                	cmp    %edx,%eax
f010169f:	90                   	nop
f01016a0:	75 f4                	jne    f0101696 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01016a2:	5b                   	pop    %ebx
f01016a3:	5d                   	pop    %ebp
f01016a4:	c3                   	ret    

f01016a5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01016a5:	55                   	push   %ebp
f01016a6:	89 e5                	mov    %esp,%ebp
f01016a8:	57                   	push   %edi
f01016a9:	56                   	push   %esi
f01016aa:	53                   	push   %ebx
f01016ab:	8b 55 08             	mov    0x8(%ebp),%edx
f01016ae:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016b1:	0f b6 0a             	movzbl (%edx),%ecx
f01016b4:	80 f9 09             	cmp    $0x9,%cl
f01016b7:	74 05                	je     f01016be <strtol+0x19>
f01016b9:	80 f9 20             	cmp    $0x20,%cl
f01016bc:	75 10                	jne    f01016ce <strtol+0x29>
		s++;
f01016be:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016c1:	0f b6 0a             	movzbl (%edx),%ecx
f01016c4:	80 f9 09             	cmp    $0x9,%cl
f01016c7:	74 f5                	je     f01016be <strtol+0x19>
f01016c9:	80 f9 20             	cmp    $0x20,%cl
f01016cc:	74 f0                	je     f01016be <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
f01016ce:	80 f9 2b             	cmp    $0x2b,%cl
f01016d1:	75 0a                	jne    f01016dd <strtol+0x38>
		s++;
f01016d3:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01016d6:	bf 00 00 00 00       	mov    $0x0,%edi
f01016db:	eb 11                	jmp    f01016ee <strtol+0x49>
f01016dd:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01016e2:	80 f9 2d             	cmp    $0x2d,%cl
f01016e5:	75 07                	jne    f01016ee <strtol+0x49>
		s++, neg = 1;
f01016e7:	83 c2 01             	add    $0x1,%edx
f01016ea:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016ee:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f01016f3:	75 15                	jne    f010170a <strtol+0x65>
f01016f5:	80 3a 30             	cmpb   $0x30,(%edx)
f01016f8:	75 10                	jne    f010170a <strtol+0x65>
f01016fa:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01016fe:	75 0a                	jne    f010170a <strtol+0x65>
		s += 2, base = 16;
f0101700:	83 c2 02             	add    $0x2,%edx
f0101703:	b8 10 00 00 00       	mov    $0x10,%eax
f0101708:	eb 10                	jmp    f010171a <strtol+0x75>
	else if (base == 0 && s[0] == '0')
f010170a:	85 c0                	test   %eax,%eax
f010170c:	75 0c                	jne    f010171a <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010170e:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101710:	80 3a 30             	cmpb   $0x30,(%edx)
f0101713:	75 05                	jne    f010171a <strtol+0x75>
		s++, base = 8;
f0101715:	83 c2 01             	add    $0x1,%edx
f0101718:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010171a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010171f:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101722:	0f b6 0a             	movzbl (%edx),%ecx
f0101725:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0101728:	89 f0                	mov    %esi,%eax
f010172a:	3c 09                	cmp    $0x9,%al
f010172c:	77 08                	ja     f0101736 <strtol+0x91>
			dig = *s - '0';
f010172e:	0f be c9             	movsbl %cl,%ecx
f0101731:	83 e9 30             	sub    $0x30,%ecx
f0101734:	eb 20                	jmp    f0101756 <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
f0101736:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0101739:	89 f0                	mov    %esi,%eax
f010173b:	3c 19                	cmp    $0x19,%al
f010173d:	77 08                	ja     f0101747 <strtol+0xa2>
			dig = *s - 'a' + 10;
f010173f:	0f be c9             	movsbl %cl,%ecx
f0101742:	83 e9 57             	sub    $0x57,%ecx
f0101745:	eb 0f                	jmp    f0101756 <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
f0101747:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010174a:	89 f0                	mov    %esi,%eax
f010174c:	3c 19                	cmp    $0x19,%al
f010174e:	77 16                	ja     f0101766 <strtol+0xc1>
			dig = *s - 'A' + 10;
f0101750:	0f be c9             	movsbl %cl,%ecx
f0101753:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101756:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0101759:	7d 0f                	jge    f010176a <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f010175b:	83 c2 01             	add    $0x1,%edx
f010175e:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101762:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101764:	eb bc                	jmp    f0101722 <strtol+0x7d>
f0101766:	89 d8                	mov    %ebx,%eax
f0101768:	eb 02                	jmp    f010176c <strtol+0xc7>
f010176a:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010176c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101770:	74 05                	je     f0101777 <strtol+0xd2>
		*endptr = (char *) s;
f0101772:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101775:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0101777:	f7 d8                	neg    %eax
f0101779:	85 ff                	test   %edi,%edi
f010177b:	0f 44 c3             	cmove  %ebx,%eax
}
f010177e:	5b                   	pop    %ebx
f010177f:	5e                   	pop    %esi
f0101780:	5f                   	pop    %edi
f0101781:	5d                   	pop    %ebp
f0101782:	c3                   	ret    
f0101783:	66 90                	xchg   %ax,%ax
f0101785:	66 90                	xchg   %ax,%ax
f0101787:	66 90                	xchg   %ax,%ax
f0101789:	66 90                	xchg   %ax,%ax
f010178b:	66 90                	xchg   %ax,%ax
f010178d:	66 90                	xchg   %ax,%ax
f010178f:	90                   	nop

f0101790 <__udivdi3>:
f0101790:	55                   	push   %ebp
f0101791:	57                   	push   %edi
f0101792:	56                   	push   %esi
f0101793:	83 ec 0c             	sub    $0xc,%esp
f0101796:	8b 44 24 28          	mov    0x28(%esp),%eax
f010179a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010179e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01017a2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01017a6:	85 c0                	test   %eax,%eax
f01017a8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01017ac:	89 ea                	mov    %ebp,%edx
f01017ae:	89 0c 24             	mov    %ecx,(%esp)
f01017b1:	75 2d                	jne    f01017e0 <__udivdi3+0x50>
f01017b3:	39 e9                	cmp    %ebp,%ecx
f01017b5:	77 61                	ja     f0101818 <__udivdi3+0x88>
f01017b7:	85 c9                	test   %ecx,%ecx
f01017b9:	89 ce                	mov    %ecx,%esi
f01017bb:	75 0b                	jne    f01017c8 <__udivdi3+0x38>
f01017bd:	b8 01 00 00 00       	mov    $0x1,%eax
f01017c2:	31 d2                	xor    %edx,%edx
f01017c4:	f7 f1                	div    %ecx
f01017c6:	89 c6                	mov    %eax,%esi
f01017c8:	31 d2                	xor    %edx,%edx
f01017ca:	89 e8                	mov    %ebp,%eax
f01017cc:	f7 f6                	div    %esi
f01017ce:	89 c5                	mov    %eax,%ebp
f01017d0:	89 f8                	mov    %edi,%eax
f01017d2:	f7 f6                	div    %esi
f01017d4:	89 ea                	mov    %ebp,%edx
f01017d6:	83 c4 0c             	add    $0xc,%esp
f01017d9:	5e                   	pop    %esi
f01017da:	5f                   	pop    %edi
f01017db:	5d                   	pop    %ebp
f01017dc:	c3                   	ret    
f01017dd:	8d 76 00             	lea    0x0(%esi),%esi
f01017e0:	39 e8                	cmp    %ebp,%eax
f01017e2:	77 24                	ja     f0101808 <__udivdi3+0x78>
f01017e4:	0f bd e8             	bsr    %eax,%ebp
f01017e7:	83 f5 1f             	xor    $0x1f,%ebp
f01017ea:	75 3c                	jne    f0101828 <__udivdi3+0x98>
f01017ec:	8b 74 24 04          	mov    0x4(%esp),%esi
f01017f0:	39 34 24             	cmp    %esi,(%esp)
f01017f3:	0f 86 9f 00 00 00    	jbe    f0101898 <__udivdi3+0x108>
f01017f9:	39 d0                	cmp    %edx,%eax
f01017fb:	0f 82 97 00 00 00    	jb     f0101898 <__udivdi3+0x108>
f0101801:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101808:	31 d2                	xor    %edx,%edx
f010180a:	31 c0                	xor    %eax,%eax
f010180c:	83 c4 0c             	add    $0xc,%esp
f010180f:	5e                   	pop    %esi
f0101810:	5f                   	pop    %edi
f0101811:	5d                   	pop    %ebp
f0101812:	c3                   	ret    
f0101813:	90                   	nop
f0101814:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101818:	89 f8                	mov    %edi,%eax
f010181a:	f7 f1                	div    %ecx
f010181c:	31 d2                	xor    %edx,%edx
f010181e:	83 c4 0c             	add    $0xc,%esp
f0101821:	5e                   	pop    %esi
f0101822:	5f                   	pop    %edi
f0101823:	5d                   	pop    %ebp
f0101824:	c3                   	ret    
f0101825:	8d 76 00             	lea    0x0(%esi),%esi
f0101828:	89 e9                	mov    %ebp,%ecx
f010182a:	8b 3c 24             	mov    (%esp),%edi
f010182d:	d3 e0                	shl    %cl,%eax
f010182f:	89 c6                	mov    %eax,%esi
f0101831:	b8 20 00 00 00       	mov    $0x20,%eax
f0101836:	29 e8                	sub    %ebp,%eax
f0101838:	89 c1                	mov    %eax,%ecx
f010183a:	d3 ef                	shr    %cl,%edi
f010183c:	89 e9                	mov    %ebp,%ecx
f010183e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101842:	8b 3c 24             	mov    (%esp),%edi
f0101845:	09 74 24 08          	or     %esi,0x8(%esp)
f0101849:	89 d6                	mov    %edx,%esi
f010184b:	d3 e7                	shl    %cl,%edi
f010184d:	89 c1                	mov    %eax,%ecx
f010184f:	89 3c 24             	mov    %edi,(%esp)
f0101852:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101856:	d3 ee                	shr    %cl,%esi
f0101858:	89 e9                	mov    %ebp,%ecx
f010185a:	d3 e2                	shl    %cl,%edx
f010185c:	89 c1                	mov    %eax,%ecx
f010185e:	d3 ef                	shr    %cl,%edi
f0101860:	09 d7                	or     %edx,%edi
f0101862:	89 f2                	mov    %esi,%edx
f0101864:	89 f8                	mov    %edi,%eax
f0101866:	f7 74 24 08          	divl   0x8(%esp)
f010186a:	89 d6                	mov    %edx,%esi
f010186c:	89 c7                	mov    %eax,%edi
f010186e:	f7 24 24             	mull   (%esp)
f0101871:	39 d6                	cmp    %edx,%esi
f0101873:	89 14 24             	mov    %edx,(%esp)
f0101876:	72 30                	jb     f01018a8 <__udivdi3+0x118>
f0101878:	8b 54 24 04          	mov    0x4(%esp),%edx
f010187c:	89 e9                	mov    %ebp,%ecx
f010187e:	d3 e2                	shl    %cl,%edx
f0101880:	39 c2                	cmp    %eax,%edx
f0101882:	73 05                	jae    f0101889 <__udivdi3+0xf9>
f0101884:	3b 34 24             	cmp    (%esp),%esi
f0101887:	74 1f                	je     f01018a8 <__udivdi3+0x118>
f0101889:	89 f8                	mov    %edi,%eax
f010188b:	31 d2                	xor    %edx,%edx
f010188d:	e9 7a ff ff ff       	jmp    f010180c <__udivdi3+0x7c>
f0101892:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101898:	31 d2                	xor    %edx,%edx
f010189a:	b8 01 00 00 00       	mov    $0x1,%eax
f010189f:	e9 68 ff ff ff       	jmp    f010180c <__udivdi3+0x7c>
f01018a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018a8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01018ab:	31 d2                	xor    %edx,%edx
f01018ad:	83 c4 0c             	add    $0xc,%esp
f01018b0:	5e                   	pop    %esi
f01018b1:	5f                   	pop    %edi
f01018b2:	5d                   	pop    %ebp
f01018b3:	c3                   	ret    
f01018b4:	66 90                	xchg   %ax,%ax
f01018b6:	66 90                	xchg   %ax,%ax
f01018b8:	66 90                	xchg   %ax,%ax
f01018ba:	66 90                	xchg   %ax,%ax
f01018bc:	66 90                	xchg   %ax,%ax
f01018be:	66 90                	xchg   %ax,%ax

f01018c0 <__umoddi3>:
f01018c0:	55                   	push   %ebp
f01018c1:	57                   	push   %edi
f01018c2:	56                   	push   %esi
f01018c3:	83 ec 14             	sub    $0x14,%esp
f01018c6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01018ca:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01018ce:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f01018d2:	89 c7                	mov    %eax,%edi
f01018d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018d8:	8b 44 24 30          	mov    0x30(%esp),%eax
f01018dc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01018e0:	89 34 24             	mov    %esi,(%esp)
f01018e3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018e7:	85 c0                	test   %eax,%eax
f01018e9:	89 c2                	mov    %eax,%edx
f01018eb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018ef:	75 17                	jne    f0101908 <__umoddi3+0x48>
f01018f1:	39 fe                	cmp    %edi,%esi
f01018f3:	76 4b                	jbe    f0101940 <__umoddi3+0x80>
f01018f5:	89 c8                	mov    %ecx,%eax
f01018f7:	89 fa                	mov    %edi,%edx
f01018f9:	f7 f6                	div    %esi
f01018fb:	89 d0                	mov    %edx,%eax
f01018fd:	31 d2                	xor    %edx,%edx
f01018ff:	83 c4 14             	add    $0x14,%esp
f0101902:	5e                   	pop    %esi
f0101903:	5f                   	pop    %edi
f0101904:	5d                   	pop    %ebp
f0101905:	c3                   	ret    
f0101906:	66 90                	xchg   %ax,%ax
f0101908:	39 f8                	cmp    %edi,%eax
f010190a:	77 54                	ja     f0101960 <__umoddi3+0xa0>
f010190c:	0f bd e8             	bsr    %eax,%ebp
f010190f:	83 f5 1f             	xor    $0x1f,%ebp
f0101912:	75 5c                	jne    f0101970 <__umoddi3+0xb0>
f0101914:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101918:	39 3c 24             	cmp    %edi,(%esp)
f010191b:	0f 87 e7 00 00 00    	ja     f0101a08 <__umoddi3+0x148>
f0101921:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101925:	29 f1                	sub    %esi,%ecx
f0101927:	19 c7                	sbb    %eax,%edi
f0101929:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010192d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101931:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101935:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101939:	83 c4 14             	add    $0x14,%esp
f010193c:	5e                   	pop    %esi
f010193d:	5f                   	pop    %edi
f010193e:	5d                   	pop    %ebp
f010193f:	c3                   	ret    
f0101940:	85 f6                	test   %esi,%esi
f0101942:	89 f5                	mov    %esi,%ebp
f0101944:	75 0b                	jne    f0101951 <__umoddi3+0x91>
f0101946:	b8 01 00 00 00       	mov    $0x1,%eax
f010194b:	31 d2                	xor    %edx,%edx
f010194d:	f7 f6                	div    %esi
f010194f:	89 c5                	mov    %eax,%ebp
f0101951:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101955:	31 d2                	xor    %edx,%edx
f0101957:	f7 f5                	div    %ebp
f0101959:	89 c8                	mov    %ecx,%eax
f010195b:	f7 f5                	div    %ebp
f010195d:	eb 9c                	jmp    f01018fb <__umoddi3+0x3b>
f010195f:	90                   	nop
f0101960:	89 c8                	mov    %ecx,%eax
f0101962:	89 fa                	mov    %edi,%edx
f0101964:	83 c4 14             	add    $0x14,%esp
f0101967:	5e                   	pop    %esi
f0101968:	5f                   	pop    %edi
f0101969:	5d                   	pop    %ebp
f010196a:	c3                   	ret    
f010196b:	90                   	nop
f010196c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101970:	8b 04 24             	mov    (%esp),%eax
f0101973:	be 20 00 00 00       	mov    $0x20,%esi
f0101978:	89 e9                	mov    %ebp,%ecx
f010197a:	29 ee                	sub    %ebp,%esi
f010197c:	d3 e2                	shl    %cl,%edx
f010197e:	89 f1                	mov    %esi,%ecx
f0101980:	d3 e8                	shr    %cl,%eax
f0101982:	89 e9                	mov    %ebp,%ecx
f0101984:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101988:	8b 04 24             	mov    (%esp),%eax
f010198b:	09 54 24 04          	or     %edx,0x4(%esp)
f010198f:	89 fa                	mov    %edi,%edx
f0101991:	d3 e0                	shl    %cl,%eax
f0101993:	89 f1                	mov    %esi,%ecx
f0101995:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101999:	8b 44 24 10          	mov    0x10(%esp),%eax
f010199d:	d3 ea                	shr    %cl,%edx
f010199f:	89 e9                	mov    %ebp,%ecx
f01019a1:	d3 e7                	shl    %cl,%edi
f01019a3:	89 f1                	mov    %esi,%ecx
f01019a5:	d3 e8                	shr    %cl,%eax
f01019a7:	89 e9                	mov    %ebp,%ecx
f01019a9:	09 f8                	or     %edi,%eax
f01019ab:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01019af:	f7 74 24 04          	divl   0x4(%esp)
f01019b3:	d3 e7                	shl    %cl,%edi
f01019b5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01019b9:	89 d7                	mov    %edx,%edi
f01019bb:	f7 64 24 08          	mull   0x8(%esp)
f01019bf:	39 d7                	cmp    %edx,%edi
f01019c1:	89 c1                	mov    %eax,%ecx
f01019c3:	89 14 24             	mov    %edx,(%esp)
f01019c6:	72 2c                	jb     f01019f4 <__umoddi3+0x134>
f01019c8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f01019cc:	72 22                	jb     f01019f0 <__umoddi3+0x130>
f01019ce:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01019d2:	29 c8                	sub    %ecx,%eax
f01019d4:	19 d7                	sbb    %edx,%edi
f01019d6:	89 e9                	mov    %ebp,%ecx
f01019d8:	89 fa                	mov    %edi,%edx
f01019da:	d3 e8                	shr    %cl,%eax
f01019dc:	89 f1                	mov    %esi,%ecx
f01019de:	d3 e2                	shl    %cl,%edx
f01019e0:	89 e9                	mov    %ebp,%ecx
f01019e2:	d3 ef                	shr    %cl,%edi
f01019e4:	09 d0                	or     %edx,%eax
f01019e6:	89 fa                	mov    %edi,%edx
f01019e8:	83 c4 14             	add    $0x14,%esp
f01019eb:	5e                   	pop    %esi
f01019ec:	5f                   	pop    %edi
f01019ed:	5d                   	pop    %ebp
f01019ee:	c3                   	ret    
f01019ef:	90                   	nop
f01019f0:	39 d7                	cmp    %edx,%edi
f01019f2:	75 da                	jne    f01019ce <__umoddi3+0x10e>
f01019f4:	8b 14 24             	mov    (%esp),%edx
f01019f7:	89 c1                	mov    %eax,%ecx
f01019f9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f01019fd:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101a01:	eb cb                	jmp    f01019ce <__umoddi3+0x10e>
f0101a03:	90                   	nop
f0101a04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a08:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0101a0c:	0f 82 0f ff ff ff    	jb     f0101921 <__umoddi3+0x61>
f0101a12:	e9 1a ff ff ff       	jmp    f0101931 <__umoddi3+0x71>
