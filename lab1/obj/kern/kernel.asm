
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
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

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
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 c0 19 10 f0       	push   $0xf01019c0
f0100050:	e8 8a 08 00 00       	call   f01008df <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 cd 06 00 00       	call   f0100748 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 dc 19 10 f0       	push   $0xf01019dc
f0100087:	e8 53 08 00 00       	call   f01008df <cprintf>
f010008c:	83 c4 10             	add    $0x10,%esp
}
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 c0 29 11 f0       	mov    $0xf01129c0,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 13 14 00 00       	call   f01014c4 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 99 04 00 00       	call   f010054f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 f7 19 10 f0       	push   $0xf01019f7
f01000c3:	e8 17 08 00 00       	call   f01008df <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 71 06 00 00       	call   f0100752 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 12 1a 10 f0       	push   $0xf0101a12
f0100110:	e8 ca 07 00 00       	call   f01008df <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 9a 07 00 00       	call   f01008b9 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 4e 1a 10 f0 	movl   $0xf0101a4e,(%esp)
f0100126:	e8 b4 07 00 00       	call   f01008df <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 1a 06 00 00       	call   f0100752 <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 2a 1a 10 f0       	push   $0xf0101a2a
f0100152:	e8 88 07 00 00       	call   f01008df <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 56 07 00 00       	call   f01008b9 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 4e 1a 10 f0 	movl   $0xf0101a4e,(%esp)
f010016a:	e8 70 07 00 00       	call   f01008df <cprintf>
	va_end(ap);
f010016f:	83 c4 10             	add    $0x10,%esp
}
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 08                	je     f010018c <serial_proc_data+0x15>
f0100184:	b2 f8                	mov    $0xf8,%dl
f0100186:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100187:	0f b6 c0             	movzbl %al,%eax
f010018a:	eb 05                	jmp    f0100191 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100193:	55                   	push   %ebp
f0100194:	89 e5                	mov    %esp,%ebp
f0100196:	53                   	push   %ebx
f0100197:	83 ec 04             	sub    $0x4,%esp
f010019a:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019c:	eb 2a                	jmp    f01001c8 <cons_intr+0x35>
		if (c == 0)
f010019e:	85 d2                	test   %edx,%edx
f01001a0:	74 26                	je     f01001c8 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a2:	a1 84 25 11 f0       	mov    0xf0112584,%eax
f01001a7:	8d 48 01             	lea    0x1(%eax),%ecx
f01001aa:	89 0d 84 25 11 f0    	mov    %ecx,0xf0112584
f01001b0:	88 90 80 23 11 f0    	mov    %dl,-0xfeedc80(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001b6:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001bc:	75 0a                	jne    f01001c8 <cons_intr+0x35>
			cons.wpos = 0;
f01001be:	c7 05 84 25 11 f0 00 	movl   $0x0,0xf0112584
f01001c5:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001c8:	ff d3                	call   *%ebx
f01001ca:	89 c2                	mov    %eax,%edx
f01001cc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001cf:	75 cd                	jne    f010019e <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d1:	83 c4 04             	add    $0x4,%esp
f01001d4:	5b                   	pop    %ebx
f01001d5:	5d                   	pop    %ebp
f01001d6:	c3                   	ret    

f01001d7 <kbd_proc_data>:
f01001d7:	ba 64 00 00 00       	mov    $0x64,%edx
f01001dc:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001dd:	a8 01                	test   $0x1,%al
f01001df:	0f 84 f0 00 00 00    	je     f01002d5 <kbd_proc_data+0xfe>
f01001e5:	b2 60                	mov    $0x60,%dl
f01001e7:	ec                   	in     (%dx),%al
f01001e8:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001ea:	3c e0                	cmp    $0xe0,%al
f01001ec:	75 0d                	jne    f01001fb <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001ee:	83 0d 40 23 11 f0 40 	orl    $0x40,0xf0112340
		return 0;
f01001f5:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001fa:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001fb:	55                   	push   %ebp
f01001fc:	89 e5                	mov    %esp,%ebp
f01001fe:	53                   	push   %ebx
f01001ff:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100202:	84 c0                	test   %al,%al
f0100204:	79 36                	jns    f010023c <kbd_proc_data+0x65>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100206:	8b 0d 40 23 11 f0    	mov    0xf0112340,%ecx
f010020c:	89 cb                	mov    %ecx,%ebx
f010020e:	83 e3 40             	and    $0x40,%ebx
f0100211:	83 e0 7f             	and    $0x7f,%eax
f0100214:	85 db                	test   %ebx,%ebx
f0100216:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100219:	0f b6 d2             	movzbl %dl,%edx
f010021c:	0f b6 82 c0 1b 10 f0 	movzbl -0xfefe440(%edx),%eax
f0100223:	83 c8 40             	or     $0x40,%eax
f0100226:	0f b6 c0             	movzbl %al,%eax
f0100229:	f7 d0                	not    %eax
f010022b:	21 c8                	and    %ecx,%eax
f010022d:	a3 40 23 11 f0       	mov    %eax,0xf0112340
		return 0;
f0100232:	b8 00 00 00 00       	mov    $0x0,%eax
f0100237:	e9 a1 00 00 00       	jmp    f01002dd <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f010023c:	8b 0d 40 23 11 f0    	mov    0xf0112340,%ecx
f0100242:	f6 c1 40             	test   $0x40,%cl
f0100245:	74 0e                	je     f0100255 <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100247:	83 c8 80             	or     $0xffffff80,%eax
f010024a:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010024c:	83 e1 bf             	and    $0xffffffbf,%ecx
f010024f:	89 0d 40 23 11 f0    	mov    %ecx,0xf0112340
	}

	shift |= shiftcode[data];
f0100255:	0f b6 c2             	movzbl %dl,%eax
f0100258:	0f b6 90 c0 1b 10 f0 	movzbl -0xfefe440(%eax),%edx
f010025f:	0b 15 40 23 11 f0    	or     0xf0112340,%edx
	shift ^= togglecode[data];
f0100265:	0f b6 88 c0 1a 10 f0 	movzbl -0xfefe540(%eax),%ecx
f010026c:	31 ca                	xor    %ecx,%edx
f010026e:	89 15 40 23 11 f0    	mov    %edx,0xf0112340

	c = charcode[shift & (CTL | SHIFT)][data];
f0100274:	89 d1                	mov    %edx,%ecx
f0100276:	83 e1 03             	and    $0x3,%ecx
f0100279:	8b 0c 8d 80 1a 10 f0 	mov    -0xfefe580(,%ecx,4),%ecx
f0100280:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f0100284:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100287:	f6 c2 08             	test   $0x8,%dl
f010028a:	74 1b                	je     f01002a7 <kbd_proc_data+0xd0>
		if ('a' <= c && c <= 'z')
f010028c:	89 d8                	mov    %ebx,%eax
f010028e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100291:	83 f9 19             	cmp    $0x19,%ecx
f0100294:	77 05                	ja     f010029b <kbd_proc_data+0xc4>
			c += 'A' - 'a';
f0100296:	83 eb 20             	sub    $0x20,%ebx
f0100299:	eb 0c                	jmp    f01002a7 <kbd_proc_data+0xd0>
		else if ('A' <= c && c <= 'Z')
f010029b:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f010029e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002a1:	83 f8 19             	cmp    $0x19,%eax
f01002a4:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002a7:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002ad:	75 2c                	jne    f01002db <kbd_proc_data+0x104>
f01002af:	f7 d2                	not    %edx
f01002b1:	f6 c2 06             	test   $0x6,%dl
f01002b4:	75 25                	jne    f01002db <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01002b6:	83 ec 0c             	sub    $0xc,%esp
f01002b9:	68 44 1a 10 f0       	push   $0xf0101a44
f01002be:	e8 1c 06 00 00       	call   f01008df <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c3:	ba 92 00 00 00       	mov    $0x92,%edx
f01002c8:	b8 03 00 00 00       	mov    $0x3,%eax
f01002cd:	ee                   	out    %al,(%dx)
f01002ce:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d1:	89 d8                	mov    %ebx,%eax
f01002d3:	eb 08                	jmp    f01002dd <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002da:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002db:	89 d8                	mov    %ebx,%eax
}
f01002dd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002e0:	c9                   	leave  
f01002e1:	c3                   	ret    

f01002e2 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002e2:	55                   	push   %ebp
f01002e3:	89 e5                	mov    %esp,%ebp
f01002e5:	57                   	push   %edi
f01002e6:	56                   	push   %esi
f01002e7:	53                   	push   %ebx
f01002e8:	83 ec 1c             	sub    $0x1c,%esp
f01002eb:	89 c7                	mov    %eax,%edi

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ed:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002f2:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;
	
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002f3:	a8 20                	test   $0x20,%al
f01002f5:	75 27                	jne    f010031e <cons_putc+0x3c>
f01002f7:	bb 00 00 00 00       	mov    $0x0,%ebx
f01002fc:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100301:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100306:	89 ca                	mov    %ecx,%edx
f0100308:	ec                   	in     (%dx),%al
f0100309:	ec                   	in     (%dx),%al
f010030a:	ec                   	in     (%dx),%al
f010030b:	ec                   	in     (%dx),%al
	     i++)
f010030c:	83 c3 01             	add    $0x1,%ebx
f010030f:	89 f2                	mov    %esi,%edx
f0100311:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;
	
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100312:	a8 20                	test   $0x20,%al
f0100314:	75 08                	jne    f010031e <cons_putc+0x3c>
f0100316:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010031c:	7e e8                	jle    f0100306 <cons_putc+0x24>
f010031e:	89 f8                	mov    %edi,%eax
f0100320:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100323:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100328:	89 f8                	mov    %edi,%eax
f010032a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010032b:	b2 79                	mov    $0x79,%dl
f010032d:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010032e:	84 c0                	test   %al,%al
f0100330:	78 27                	js     f0100359 <cons_putc+0x77>
f0100332:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100337:	b9 84 00 00 00       	mov    $0x84,%ecx
f010033c:	be 79 03 00 00       	mov    $0x379,%esi
f0100341:	89 ca                	mov    %ecx,%edx
f0100343:	ec                   	in     (%dx),%al
f0100344:	ec                   	in     (%dx),%al
f0100345:	ec                   	in     (%dx),%al
f0100346:	ec                   	in     (%dx),%al
f0100347:	83 c3 01             	add    $0x1,%ebx
f010034a:	89 f2                	mov    %esi,%edx
f010034c:	ec                   	in     (%dx),%al
f010034d:	84 c0                	test   %al,%al
f010034f:	78 08                	js     f0100359 <cons_putc+0x77>
f0100351:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100357:	7e e8                	jle    f0100341 <cons_putc+0x5f>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100359:	ba 78 03 00 00       	mov    $0x378,%edx
f010035e:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100362:	ee                   	out    %al,(%dx)
f0100363:	b2 7a                	mov    $0x7a,%dl
f0100365:	b8 0d 00 00 00       	mov    $0xd,%eax
f010036a:	ee                   	out    %al,(%dx)
f010036b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100370:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100371:	89 fa                	mov    %edi,%edx
f0100373:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100379:	89 f8                	mov    %edi,%eax
f010037b:	80 cc 07             	or     $0x7,%ah
f010037e:	85 d2                	test   %edx,%edx
f0100380:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100383:	89 f8                	mov    %edi,%eax
f0100385:	0f b6 c0             	movzbl %al,%eax
f0100388:	83 f8 09             	cmp    $0x9,%eax
f010038b:	74 74                	je     f0100401 <cons_putc+0x11f>
f010038d:	83 f8 09             	cmp    $0x9,%eax
f0100390:	7f 0a                	jg     f010039c <cons_putc+0xba>
f0100392:	83 f8 08             	cmp    $0x8,%eax
f0100395:	74 14                	je     f01003ab <cons_putc+0xc9>
f0100397:	e9 99 00 00 00       	jmp    f0100435 <cons_putc+0x153>
f010039c:	83 f8 0a             	cmp    $0xa,%eax
f010039f:	74 3a                	je     f01003db <cons_putc+0xf9>
f01003a1:	83 f8 0d             	cmp    $0xd,%eax
f01003a4:	74 3d                	je     f01003e3 <cons_putc+0x101>
f01003a6:	e9 8a 00 00 00       	jmp    f0100435 <cons_putc+0x153>
	case '\b':
		if (crt_pos > 0) {
f01003ab:	0f b7 05 88 25 11 f0 	movzwl 0xf0112588,%eax
f01003b2:	66 85 c0             	test   %ax,%ax
f01003b5:	0f 84 e6 00 00 00    	je     f01004a1 <cons_putc+0x1bf>
			crt_pos--;
f01003bb:	83 e8 01             	sub    $0x1,%eax
f01003be:	66 a3 88 25 11 f0    	mov    %ax,0xf0112588
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003c4:	0f b7 c0             	movzwl %ax,%eax
f01003c7:	66 81 e7 00 ff       	and    $0xff00,%di
f01003cc:	83 cf 20             	or     $0x20,%edi
f01003cf:	8b 15 8c 25 11 f0    	mov    0xf011258c,%edx
f01003d5:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003d9:	eb 78                	jmp    f0100453 <cons_putc+0x171>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003db:	66 83 05 88 25 11 f0 	addw   $0x50,0xf0112588
f01003e2:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003e3:	0f b7 05 88 25 11 f0 	movzwl 0xf0112588,%eax
f01003ea:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003f0:	c1 e8 16             	shr    $0x16,%eax
f01003f3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003f6:	c1 e0 04             	shl    $0x4,%eax
f01003f9:	66 a3 88 25 11 f0    	mov    %ax,0xf0112588
f01003ff:	eb 52                	jmp    f0100453 <cons_putc+0x171>
		break;
	case '\t':
		cons_putc(' ');
f0100401:	b8 20 00 00 00       	mov    $0x20,%eax
f0100406:	e8 d7 fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f010040b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100410:	e8 cd fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f0100415:	b8 20 00 00 00       	mov    $0x20,%eax
f010041a:	e8 c3 fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f010041f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100424:	e8 b9 fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f0100429:	b8 20 00 00 00       	mov    $0x20,%eax
f010042e:	e8 af fe ff ff       	call   f01002e2 <cons_putc>
f0100433:	eb 1e                	jmp    f0100453 <cons_putc+0x171>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100435:	0f b7 05 88 25 11 f0 	movzwl 0xf0112588,%eax
f010043c:	8d 50 01             	lea    0x1(%eax),%edx
f010043f:	66 89 15 88 25 11 f0 	mov    %dx,0xf0112588
f0100446:	0f b7 c0             	movzwl %ax,%eax
f0100449:	8b 15 8c 25 11 f0    	mov    0xf011258c,%edx
f010044f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100453:	66 81 3d 88 25 11 f0 	cmpw   $0x7cf,0xf0112588
f010045a:	cf 07 
f010045c:	76 43                	jbe    f01004a1 <cons_putc+0x1bf>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010045e:	a1 8c 25 11 f0       	mov    0xf011258c,%eax
f0100463:	83 ec 04             	sub    $0x4,%esp
f0100466:	68 00 0f 00 00       	push   $0xf00
f010046b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100471:	52                   	push   %edx
f0100472:	50                   	push   %eax
f0100473:	e8 99 10 00 00       	call   f0101511 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100478:	8b 15 8c 25 11 f0    	mov    0xf011258c,%edx
f010047e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100484:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010048a:	83 c4 10             	add    $0x10,%esp
f010048d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100492:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100495:	39 d0                	cmp    %edx,%eax
f0100497:	75 f4                	jne    f010048d <cons_putc+0x1ab>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100499:	66 83 2d 88 25 11 f0 	subw   $0x50,0xf0112588
f01004a0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004a1:	8b 0d 90 25 11 f0    	mov    0xf0112590,%ecx
f01004a7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004ac:	89 ca                	mov    %ecx,%edx
f01004ae:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004af:	0f b7 1d 88 25 11 f0 	movzwl 0xf0112588,%ebx
f01004b6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004b9:	89 d8                	mov    %ebx,%eax
f01004bb:	66 c1 e8 08          	shr    $0x8,%ax
f01004bf:	89 f2                	mov    %esi,%edx
f01004c1:	ee                   	out    %al,(%dx)
f01004c2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004c7:	89 ca                	mov    %ecx,%edx
f01004c9:	ee                   	out    %al,(%dx)
f01004ca:	89 d8                	mov    %ebx,%eax
f01004cc:	89 f2                	mov    %esi,%edx
f01004ce:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004cf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004d2:	5b                   	pop    %ebx
f01004d3:	5e                   	pop    %esi
f01004d4:	5f                   	pop    %edi
f01004d5:	5d                   	pop    %ebp
f01004d6:	c3                   	ret    

f01004d7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004d7:	83 3d 94 25 11 f0 00 	cmpl   $0x0,0xf0112594
f01004de:	74 11                	je     f01004f1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004e0:	55                   	push   %ebp
f01004e1:	89 e5                	mov    %esp,%ebp
f01004e3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004e6:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004eb:	e8 a3 fc ff ff       	call   f0100193 <cons_intr>
}
f01004f0:	c9                   	leave  
f01004f1:	f3 c3                	repz ret 

f01004f3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004f3:	55                   	push   %ebp
f01004f4:	89 e5                	mov    %esp,%ebp
f01004f6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004f9:	b8 d7 01 10 f0       	mov    $0xf01001d7,%eax
f01004fe:	e8 90 fc ff ff       	call   f0100193 <cons_intr>
}
f0100503:	c9                   	leave  
f0100504:	c3                   	ret    

f0100505 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100505:	55                   	push   %ebp
f0100506:	89 e5                	mov    %esp,%ebp
f0100508:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010050b:	e8 c7 ff ff ff       	call   f01004d7 <serial_intr>
	kbd_intr();
f0100510:	e8 de ff ff ff       	call   f01004f3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100515:	a1 80 25 11 f0       	mov    0xf0112580,%eax
f010051a:	3b 05 84 25 11 f0    	cmp    0xf0112584,%eax
f0100520:	74 26                	je     f0100548 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100522:	8d 50 01             	lea    0x1(%eax),%edx
f0100525:	89 15 80 25 11 f0    	mov    %edx,0xf0112580
f010052b:	0f b6 88 80 23 11 f0 	movzbl -0xfeedc80(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100532:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100534:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010053a:	75 11                	jne    f010054d <cons_getc+0x48>
			cons.rpos = 0;
f010053c:	c7 05 80 25 11 f0 00 	movl   $0x0,0xf0112580
f0100543:	00 00 00 
f0100546:	eb 05                	jmp    f010054d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100548:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010054d:	c9                   	leave  
f010054e:	c3                   	ret    

f010054f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010054f:	55                   	push   %ebp
f0100550:	89 e5                	mov    %esp,%ebp
f0100552:	57                   	push   %edi
f0100553:	56                   	push   %esi
f0100554:	53                   	push   %ebx
f0100555:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100558:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010055f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100566:	5a a5 
	if (*cp != 0xA55A) {
f0100568:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010056f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100573:	74 11                	je     f0100586 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100575:	c7 05 90 25 11 f0 b4 	movl   $0x3b4,0xf0112590
f010057c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010057f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100584:	eb 16                	jmp    f010059c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100586:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010058d:	c7 05 90 25 11 f0 d4 	movl   $0x3d4,0xf0112590
f0100594:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100597:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f010059c:	8b 3d 90 25 11 f0    	mov    0xf0112590,%edi
f01005a2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005a7:	89 fa                	mov    %edi,%edx
f01005a9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005aa:	8d 4f 01             	lea    0x1(%edi),%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ad:	89 ca                	mov    %ecx,%edx
f01005af:	ec                   	in     (%dx),%al
f01005b0:	0f b6 c0             	movzbl %al,%eax
f01005b3:	c1 e0 08             	shl    $0x8,%eax
f01005b6:	89 c3                	mov    %eax,%ebx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005b8:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005bd:	89 fa                	mov    %edi,%edx
f01005bf:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c0:	89 ca                	mov    %ecx,%edx
f01005c2:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005c3:	89 35 8c 25 11 f0    	mov    %esi,0xf011258c
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005c9:	0f b6 c8             	movzbl %al,%ecx
f01005cc:	89 d8                	mov    %ebx,%eax
f01005ce:	09 c8                	or     %ecx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005d0:	66 a3 88 25 11 f0    	mov    %ax,0xf0112588
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005db:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e0:	89 da                	mov    %ebx,%edx
f01005e2:	ee                   	out    %al,(%dx)
f01005e3:	b2 fb                	mov    $0xfb,%dl
f01005e5:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005ea:	ee                   	out    %al,(%dx)
f01005eb:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01005f0:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005f5:	89 ca                	mov    %ecx,%edx
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	b2 f9                	mov    $0xf9,%dl
f01005fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ff:	ee                   	out    %al,(%dx)
f0100600:	b2 fb                	mov    $0xfb,%dl
f0100602:	b8 03 00 00 00       	mov    $0x3,%eax
f0100607:	ee                   	out    %al,(%dx)
f0100608:	b2 fc                	mov    $0xfc,%dl
f010060a:	b8 00 00 00 00       	mov    $0x0,%eax
f010060f:	ee                   	out    %al,(%dx)
f0100610:	b2 f9                	mov    $0xf9,%dl
f0100612:	b8 01 00 00 00       	mov    $0x1,%eax
f0100617:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100618:	b2 fd                	mov    $0xfd,%dl
f010061a:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010061b:	3c ff                	cmp    $0xff,%al
f010061d:	0f 95 c0             	setne  %al
f0100620:	0f b6 c0             	movzbl %al,%eax
f0100623:	89 c6                	mov    %eax,%esi
f0100625:	a3 94 25 11 f0       	mov    %eax,0xf0112594
f010062a:	89 da                	mov    %ebx,%edx
f010062c:	ec                   	in     (%dx),%al
f010062d:	89 ca                	mov    %ecx,%edx
f010062f:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100630:	85 f6                	test   %esi,%esi
f0100632:	75 10                	jne    f0100644 <cons_init+0xf5>
		cprintf("Serial port does not exist!\n");
f0100634:	83 ec 0c             	sub    $0xc,%esp
f0100637:	68 50 1a 10 f0       	push   $0xf0101a50
f010063c:	e8 9e 02 00 00       	call   f01008df <cprintf>
f0100641:	83 c4 10             	add    $0x10,%esp
}
f0100644:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100647:	5b                   	pop    %ebx
f0100648:	5e                   	pop    %esi
f0100649:	5f                   	pop    %edi
f010064a:	5d                   	pop    %ebp
f010064b:	c3                   	ret    

f010064c <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010064c:	55                   	push   %ebp
f010064d:	89 e5                	mov    %esp,%ebp
f010064f:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100652:	8b 45 08             	mov    0x8(%ebp),%eax
f0100655:	e8 88 fc ff ff       	call   f01002e2 <cons_putc>
}
f010065a:	c9                   	leave  
f010065b:	c3                   	ret    

f010065c <getchar>:

int
getchar(void)
{
f010065c:	55                   	push   %ebp
f010065d:	89 e5                	mov    %esp,%ebp
f010065f:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100662:	e8 9e fe ff ff       	call   f0100505 <cons_getc>
f0100667:	85 c0                	test   %eax,%eax
f0100669:	74 f7                	je     f0100662 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010066b:	c9                   	leave  
f010066c:	c3                   	ret    

f010066d <iscons>:

int
iscons(int fdnum)
{
f010066d:	55                   	push   %ebp
f010066e:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100670:	b8 01 00 00 00       	mov    $0x1,%eax
f0100675:	5d                   	pop    %ebp
f0100676:	c3                   	ret    

f0100677 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100677:	55                   	push   %ebp
f0100678:	89 e5                	mov    %esp,%ebp
f010067a:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010067d:	68 c0 1c 10 f0       	push   $0xf0101cc0
f0100682:	68 de 1c 10 f0       	push   $0xf0101cde
f0100687:	68 e3 1c 10 f0       	push   $0xf0101ce3
f010068c:	e8 4e 02 00 00       	call   f01008df <cprintf>
f0100691:	83 c4 0c             	add    $0xc,%esp
f0100694:	68 4c 1d 10 f0       	push   $0xf0101d4c
f0100699:	68 ec 1c 10 f0       	push   $0xf0101cec
f010069e:	68 e3 1c 10 f0       	push   $0xf0101ce3
f01006a3:	e8 37 02 00 00       	call   f01008df <cprintf>
	return 0;
}
f01006a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ad:	c9                   	leave  
f01006ae:	c3                   	ret    

f01006af <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006af:	55                   	push   %ebp
f01006b0:	89 e5                	mov    %esp,%ebp
f01006b2:	83 ec 14             	sub    $0x14,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006b5:	68 f5 1c 10 f0       	push   $0xf0101cf5
f01006ba:	e8 20 02 00 00       	call   f01008df <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006bf:	83 c4 0c             	add    $0xc,%esp
f01006c2:	68 0c 00 10 00       	push   $0x10000c
f01006c7:	68 0c 00 10 f0       	push   $0xf010000c
f01006cc:	68 74 1d 10 f0       	push   $0xf0101d74
f01006d1:	e8 09 02 00 00       	call   f01008df <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d6:	83 c4 0c             	add    $0xc,%esp
f01006d9:	68 b5 19 10 00       	push   $0x1019b5
f01006de:	68 b5 19 10 f0       	push   $0xf01019b5
f01006e3:	68 98 1d 10 f0       	push   $0xf0101d98
f01006e8:	e8 f2 01 00 00       	call   f01008df <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ed:	83 c4 0c             	add    $0xc,%esp
f01006f0:	68 00 23 11 00       	push   $0x112300
f01006f5:	68 00 23 11 f0       	push   $0xf0112300
f01006fa:	68 bc 1d 10 f0       	push   $0xf0101dbc
f01006ff:	e8 db 01 00 00       	call   f01008df <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100704:	83 c4 0c             	add    $0xc,%esp
f0100707:	68 c0 29 11 00       	push   $0x1129c0
f010070c:	68 c0 29 11 f0       	push   $0xf01129c0
f0100711:	68 e0 1d 10 f0       	push   $0xf0101de0
f0100716:	e8 c4 01 00 00       	call   f01008df <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010071b:	83 c4 08             	add    $0x8,%esp
		(end-entry+1023)/1024);
f010071e:	b8 bf 2d 11 f0       	mov    $0xf0112dbf,%eax
f0100723:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100728:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010072e:	85 c0                	test   %eax,%eax
f0100730:	0f 48 c2             	cmovs  %edx,%eax
f0100733:	c1 f8 0a             	sar    $0xa,%eax
f0100736:	50                   	push   %eax
f0100737:	68 04 1e 10 f0       	push   $0xf0101e04
f010073c:	e8 9e 01 00 00       	call   f01008df <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f0100741:	b8 00 00 00 00       	mov    $0x0,%eax
f0100746:	c9                   	leave  
f0100747:	c3                   	ret    

f0100748 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100748:	55                   	push   %ebp
f0100749:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f010074b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100750:	5d                   	pop    %ebp
f0100751:	c3                   	ret    

f0100752 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100752:	55                   	push   %ebp
f0100753:	89 e5                	mov    %esp,%ebp
f0100755:	57                   	push   %edi
f0100756:	56                   	push   %esi
f0100757:	53                   	push   %ebx
f0100758:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010075b:	68 30 1e 10 f0       	push   $0xf0101e30
f0100760:	e8 7a 01 00 00       	call   f01008df <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100765:	c7 04 24 54 1e 10 f0 	movl   $0xf0101e54,(%esp)
f010076c:	e8 6e 01 00 00       	call   f01008df <cprintf>
f0100771:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100774:	83 ec 0c             	sub    $0xc,%esp
f0100777:	68 0e 1d 10 f0       	push   $0xf0101d0e
f010077c:	e8 8f 0a 00 00       	call   f0101210 <readline>
f0100781:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100783:	83 c4 10             	add    $0x10,%esp
f0100786:	85 c0                	test   %eax,%eax
f0100788:	74 ea                	je     f0100774 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010078a:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100791:	be 00 00 00 00       	mov    $0x0,%esi
f0100796:	eb 0a                	jmp    f01007a2 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100798:	c6 03 00             	movb   $0x0,(%ebx)
f010079b:	89 f7                	mov    %esi,%edi
f010079d:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007a0:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007a2:	0f b6 03             	movzbl (%ebx),%eax
f01007a5:	84 c0                	test   %al,%al
f01007a7:	74 6a                	je     f0100813 <monitor+0xc1>
f01007a9:	83 ec 08             	sub    $0x8,%esp
f01007ac:	0f be c0             	movsbl %al,%eax
f01007af:	50                   	push   %eax
f01007b0:	68 12 1d 10 f0       	push   $0xf0101d12
f01007b5:	e8 ac 0c 00 00       	call   f0101466 <strchr>
f01007ba:	83 c4 10             	add    $0x10,%esp
f01007bd:	85 c0                	test   %eax,%eax
f01007bf:	75 d7                	jne    f0100798 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f01007c1:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007c4:	74 4d                	je     f0100813 <monitor+0xc1>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007c6:	83 fe 0f             	cmp    $0xf,%esi
f01007c9:	75 14                	jne    f01007df <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007cb:	83 ec 08             	sub    $0x8,%esp
f01007ce:	6a 10                	push   $0x10
f01007d0:	68 17 1d 10 f0       	push   $0xf0101d17
f01007d5:	e8 05 01 00 00       	call   f01008df <cprintf>
f01007da:	83 c4 10             	add    $0x10,%esp
f01007dd:	eb 95                	jmp    f0100774 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01007df:	8d 7e 01             	lea    0x1(%esi),%edi
f01007e2:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f01007e6:	0f b6 03             	movzbl (%ebx),%eax
f01007e9:	84 c0                	test   %al,%al
f01007eb:	75 0c                	jne    f01007f9 <monitor+0xa7>
f01007ed:	eb b1                	jmp    f01007a0 <monitor+0x4e>
			buf++;
f01007ef:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007f2:	0f b6 03             	movzbl (%ebx),%eax
f01007f5:	84 c0                	test   %al,%al
f01007f7:	74 a7                	je     f01007a0 <monitor+0x4e>
f01007f9:	83 ec 08             	sub    $0x8,%esp
f01007fc:	0f be c0             	movsbl %al,%eax
f01007ff:	50                   	push   %eax
f0100800:	68 12 1d 10 f0       	push   $0xf0101d12
f0100805:	e8 5c 0c 00 00       	call   f0101466 <strchr>
f010080a:	83 c4 10             	add    $0x10,%esp
f010080d:	85 c0                	test   %eax,%eax
f010080f:	74 de                	je     f01007ef <monitor+0x9d>
f0100811:	eb 8d                	jmp    f01007a0 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100813:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010081a:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010081b:	85 f6                	test   %esi,%esi
f010081d:	0f 84 51 ff ff ff    	je     f0100774 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100823:	83 ec 08             	sub    $0x8,%esp
f0100826:	68 de 1c 10 f0       	push   $0xf0101cde
f010082b:	ff 75 a8             	pushl  -0x58(%ebp)
f010082e:	e8 af 0b 00 00       	call   f01013e2 <strcmp>
f0100833:	83 c4 10             	add    $0x10,%esp
f0100836:	85 c0                	test   %eax,%eax
f0100838:	74 1b                	je     f0100855 <monitor+0x103>
f010083a:	83 ec 08             	sub    $0x8,%esp
f010083d:	68 ec 1c 10 f0       	push   $0xf0101cec
f0100842:	ff 75 a8             	pushl  -0x58(%ebp)
f0100845:	e8 98 0b 00 00       	call   f01013e2 <strcmp>
f010084a:	83 c4 10             	add    $0x10,%esp
f010084d:	85 c0                	test   %eax,%eax
f010084f:	75 2d                	jne    f010087e <monitor+0x12c>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100851:	b0 01                	mov    $0x1,%al
f0100853:	eb 05                	jmp    f010085a <monitor+0x108>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100855:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f010085a:	83 ec 04             	sub    $0x4,%esp
f010085d:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100860:	01 d0                	add    %edx,%eax
f0100862:	ff 75 08             	pushl  0x8(%ebp)
f0100865:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100868:	51                   	push   %ecx
f0100869:	56                   	push   %esi
f010086a:	ff 14 85 84 1e 10 f0 	call   *-0xfefe17c(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100871:	83 c4 10             	add    $0x10,%esp
f0100874:	85 c0                	test   %eax,%eax
f0100876:	0f 89 f8 fe ff ff    	jns    f0100774 <monitor+0x22>
f010087c:	eb 18                	jmp    f0100896 <monitor+0x144>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010087e:	83 ec 08             	sub    $0x8,%esp
f0100881:	ff 75 a8             	pushl  -0x58(%ebp)
f0100884:	68 34 1d 10 f0       	push   $0xf0101d34
f0100889:	e8 51 00 00 00       	call   f01008df <cprintf>
f010088e:	83 c4 10             	add    $0x10,%esp
f0100891:	e9 de fe ff ff       	jmp    f0100774 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100896:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100899:	5b                   	pop    %ebx
f010089a:	5e                   	pop    %esi
f010089b:	5f                   	pop    %edi
f010089c:	5d                   	pop    %ebp
f010089d:	c3                   	ret    

f010089e <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f010089e:	55                   	push   %ebp
f010089f:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01008a1:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01008a4:	5d                   	pop    %ebp
f01008a5:	c3                   	ret    

f01008a6 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008a6:	55                   	push   %ebp
f01008a7:	89 e5                	mov    %esp,%ebp
f01008a9:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01008ac:	ff 75 08             	pushl  0x8(%ebp)
f01008af:	e8 98 fd ff ff       	call   f010064c <cputchar>
f01008b4:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f01008b7:	c9                   	leave  
f01008b8:	c3                   	ret    

f01008b9 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008b9:	55                   	push   %ebp
f01008ba:	89 e5                	mov    %esp,%ebp
f01008bc:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01008bf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01008c6:	ff 75 0c             	pushl  0xc(%ebp)
f01008c9:	ff 75 08             	pushl  0x8(%ebp)
f01008cc:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01008cf:	50                   	push   %eax
f01008d0:	68 a6 08 10 f0       	push   $0xf01008a6
f01008d5:	e8 32 04 00 00       	call   f0100d0c <vprintfmt>
	return cnt;
}
f01008da:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01008dd:	c9                   	leave  
f01008de:	c3                   	ret    

f01008df <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01008df:	55                   	push   %ebp
f01008e0:	89 e5                	mov    %esp,%ebp
f01008e2:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01008e5:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01008e8:	50                   	push   %eax
f01008e9:	ff 75 08             	pushl  0x8(%ebp)
f01008ec:	e8 c8 ff ff ff       	call   f01008b9 <vcprintf>
	va_end(ap);

	return cnt;
}
f01008f1:	c9                   	leave  
f01008f2:	c3                   	ret    

f01008f3 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01008f3:	55                   	push   %ebp
f01008f4:	89 e5                	mov    %esp,%ebp
f01008f6:	57                   	push   %edi
f01008f7:	56                   	push   %esi
f01008f8:	53                   	push   %ebx
f01008f9:	83 ec 14             	sub    $0x14,%esp
f01008fc:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01008ff:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100902:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100905:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100908:	8b 1a                	mov    (%edx),%ebx
f010090a:	8b 01                	mov    (%ecx),%eax
f010090c:	89 45 f0             	mov    %eax,-0x10(%ebp)
	
	while (l <= r) {
f010090f:	39 c3                	cmp    %eax,%ebx
f0100911:	0f 8f 9a 00 00 00    	jg     f01009b1 <stab_binsearch+0xbe>
f0100917:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
		int true_m = (l + r) / 2, m = true_m;
f010091e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100921:	01 d8                	add    %ebx,%eax
f0100923:	89 c6                	mov    %eax,%esi
f0100925:	c1 ee 1f             	shr    $0x1f,%esi
f0100928:	01 c6                	add    %eax,%esi
f010092a:	d1 fe                	sar    %esi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010092c:	39 de                	cmp    %ebx,%esi
f010092e:	0f 8c c4 00 00 00    	jl     f01009f8 <stab_binsearch+0x105>
f0100934:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100937:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010093a:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010093d:	0f b6 42 04          	movzbl 0x4(%edx),%eax
f0100941:	39 f8                	cmp    %edi,%eax
f0100943:	0f 84 b4 00 00 00    	je     f01009fd <stab_binsearch+0x10a>
f0100949:	89 f0                	mov    %esi,%eax
			m--;
f010094b:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010094e:	39 d8                	cmp    %ebx,%eax
f0100950:	0f 8c a2 00 00 00    	jl     f01009f8 <stab_binsearch+0x105>
f0100956:	0f b6 4a f8          	movzbl -0x8(%edx),%ecx
f010095a:	83 ea 0c             	sub    $0xc,%edx
f010095d:	39 f9                	cmp    %edi,%ecx
f010095f:	75 ea                	jne    f010094b <stab_binsearch+0x58>
f0100961:	e9 99 00 00 00       	jmp    f01009ff <stab_binsearch+0x10c>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100966:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100969:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010096b:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010096e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100975:	eb 2b                	jmp    f01009a2 <stab_binsearch+0xaf>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100977:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010097a:	76 14                	jbe    f0100990 <stab_binsearch+0x9d>
			*region_right = m - 1;
f010097c:	83 e8 01             	sub    $0x1,%eax
f010097f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100982:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100985:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100987:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010098e:	eb 12                	jmp    f01009a2 <stab_binsearch+0xaf>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100990:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100993:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100995:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100999:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010099b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f01009a2:	39 5d f0             	cmp    %ebx,-0x10(%ebp)
f01009a5:	0f 8d 73 ff ff ff    	jge    f010091e <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01009ab:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01009af:	75 0f                	jne    f01009c0 <stab_binsearch+0xcd>
		*region_right = *region_left - 1;
f01009b1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009b4:	8b 00                	mov    (%eax),%eax
f01009b6:	83 e8 01             	sub    $0x1,%eax
f01009b9:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01009bc:	89 07                	mov    %eax,(%edi)
f01009be:	eb 57                	jmp    f0100a17 <stab_binsearch+0x124>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009c0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009c3:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01009c5:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01009c8:	8b 0e                	mov    (%esi),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009ca:	39 c8                	cmp    %ecx,%eax
f01009cc:	7e 23                	jle    f01009f1 <stab_binsearch+0xfe>
		     l > *region_left && stabs[l].n_type != type;
f01009ce:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01009d1:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01009d4:	8d 14 96             	lea    (%esi,%edx,4),%edx
f01009d7:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01009db:	39 fb                	cmp    %edi,%ebx
f01009dd:	74 12                	je     f01009f1 <stab_binsearch+0xfe>
		     l--)
f01009df:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009e2:	39 c8                	cmp    %ecx,%eax
f01009e4:	7e 0b                	jle    f01009f1 <stab_binsearch+0xfe>
		     l > *region_left && stabs[l].n_type != type;
f01009e6:	0f b6 5a f8          	movzbl -0x8(%edx),%ebx
f01009ea:	83 ea 0c             	sub    $0xc,%edx
f01009ed:	39 fb                	cmp    %edi,%ebx
f01009ef:	75 ee                	jne    f01009df <stab_binsearch+0xec>
		     l--)
			/* do nothing */;
		*region_left = l;
f01009f1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01009f4:	89 07                	mov    %eax,(%edi)
f01009f6:	eb 1f                	jmp    f0100a17 <stab_binsearch+0x124>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009f8:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01009fb:	eb a5                	jmp    f01009a2 <stab_binsearch+0xaf>
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f01009fd:	89 f0                	mov    %esi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009ff:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a02:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a05:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a09:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a0c:	0f 82 54 ff ff ff    	jb     f0100966 <stab_binsearch+0x73>
f0100a12:	e9 60 ff ff ff       	jmp    f0100977 <stab_binsearch+0x84>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100a17:	83 c4 14             	add    $0x14,%esp
f0100a1a:	5b                   	pop    %ebx
f0100a1b:	5e                   	pop    %esi
f0100a1c:	5f                   	pop    %edi
f0100a1d:	5d                   	pop    %ebp
f0100a1e:	c3                   	ret    

f0100a1f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a1f:	55                   	push   %ebp
f0100a20:	89 e5                	mov    %esp,%ebp
f0100a22:	57                   	push   %edi
f0100a23:	56                   	push   %esi
f0100a24:	53                   	push   %ebx
f0100a25:	83 ec 1c             	sub    $0x1c,%esp
f0100a28:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100a2b:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a2e:	c7 06 94 1e 10 f0    	movl   $0xf0101e94,(%esi)
	info->eip_line = 0;
f0100a34:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100a3b:	c7 46 08 94 1e 10 f0 	movl   $0xf0101e94,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100a42:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100a49:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100a4c:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a53:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100a59:	76 11                	jbe    f0100a6c <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a5b:	b8 f9 71 10 f0       	mov    $0xf01071f9,%eax
f0100a60:	3d 25 59 10 f0       	cmp    $0xf0105925,%eax
f0100a65:	77 19                	ja     f0100a80 <debuginfo_eip+0x61>
f0100a67:	e9 84 01 00 00       	jmp    f0100bf0 <debuginfo_eip+0x1d1>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a6c:	83 ec 04             	sub    $0x4,%esp
f0100a6f:	68 9e 1e 10 f0       	push   $0xf0101e9e
f0100a74:	6a 7f                	push   $0x7f
f0100a76:	68 ab 1e 10 f0       	push   $0xf0101eab
f0100a7b:	e8 66 f6 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a80:	80 3d f8 71 10 f0 00 	cmpb   $0x0,0xf01071f8
f0100a87:	0f 85 6a 01 00 00    	jne    f0100bf7 <debuginfo_eip+0x1d8>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a8d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100a94:	b8 24 59 10 f0       	mov    $0xf0105924,%eax
f0100a99:	2d cc 20 10 f0       	sub    $0xf01020cc,%eax
f0100a9e:	c1 f8 02             	sar    $0x2,%eax
f0100aa1:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100aa7:	83 e8 01             	sub    $0x1,%eax
f0100aaa:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100aad:	83 ec 08             	sub    $0x8,%esp
f0100ab0:	57                   	push   %edi
f0100ab1:	6a 64                	push   $0x64
f0100ab3:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100ab6:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ab9:	b8 cc 20 10 f0       	mov    $0xf01020cc,%eax
f0100abe:	e8 30 fe ff ff       	call   f01008f3 <stab_binsearch>
	if (lfile == 0)
f0100ac3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ac6:	83 c4 10             	add    $0x10,%esp
f0100ac9:	85 c0                	test   %eax,%eax
f0100acb:	0f 84 2d 01 00 00    	je     f0100bfe <debuginfo_eip+0x1df>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100ad1:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100ad4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ad7:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100ada:	83 ec 08             	sub    $0x8,%esp
f0100add:	57                   	push   %edi
f0100ade:	6a 24                	push   $0x24
f0100ae0:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100ae3:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ae6:	b8 cc 20 10 f0       	mov    $0xf01020cc,%eax
f0100aeb:	e8 03 fe ff ff       	call   f01008f3 <stab_binsearch>

	if (lfun <= rfun) {
f0100af0:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100af3:	83 c4 10             	add    $0x10,%esp
f0100af6:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100af9:	7f 31                	jg     f0100b2c <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100afb:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100afe:	c1 e0 02             	shl    $0x2,%eax
f0100b01:	8d 90 cc 20 10 f0    	lea    -0xfefdf34(%eax),%edx
f0100b07:	8b 88 cc 20 10 f0    	mov    -0xfefdf34(%eax),%ecx
f0100b0d:	b8 f9 71 10 f0       	mov    $0xf01071f9,%eax
f0100b12:	2d 25 59 10 f0       	sub    $0xf0105925,%eax
f0100b17:	39 c1                	cmp    %eax,%ecx
f0100b19:	73 09                	jae    f0100b24 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b1b:	81 c1 25 59 10 f0    	add    $0xf0105925,%ecx
f0100b21:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b24:	8b 42 08             	mov    0x8(%edx),%eax
f0100b27:	89 46 10             	mov    %eax,0x10(%esi)
f0100b2a:	eb 06                	jmp    f0100b32 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b2c:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100b2f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b32:	83 ec 08             	sub    $0x8,%esp
f0100b35:	6a 3a                	push   $0x3a
f0100b37:	ff 76 08             	pushl  0x8(%esi)
f0100b3a:	e8 5d 09 00 00       	call   f010149c <strfind>
f0100b3f:	2b 46 08             	sub    0x8(%esi),%eax
f0100b42:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b45:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b48:	83 c4 10             	add    $0x10,%esp
f0100b4b:	39 fb                	cmp    %edi,%ebx
f0100b4d:	7c 5b                	jl     f0100baa <debuginfo_eip+0x18b>
	       && stabs[lline].n_type != N_SOL
f0100b4f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b52:	8d 0c 85 cc 20 10 f0 	lea    -0xfefdf34(,%eax,4),%ecx
f0100b59:	0f b6 41 04          	movzbl 0x4(%ecx),%eax
f0100b5d:	3c 84                	cmp    $0x84,%al
f0100b5f:	74 29                	je     f0100b8a <debuginfo_eip+0x16b>
f0100b61:	89 ca                	mov    %ecx,%edx
f0100b63:	83 c1 08             	add    $0x8,%ecx
f0100b66:	eb 15                	jmp    f0100b7d <debuginfo_eip+0x15e>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b68:	83 eb 01             	sub    $0x1,%ebx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b6b:	39 fb                	cmp    %edi,%ebx
f0100b6d:	7c 3b                	jl     f0100baa <debuginfo_eip+0x18b>
	       && stabs[lline].n_type != N_SOL
f0100b6f:	0f b6 42 f8          	movzbl -0x8(%edx),%eax
f0100b73:	83 ea 0c             	sub    $0xc,%edx
f0100b76:	83 e9 0c             	sub    $0xc,%ecx
f0100b79:	3c 84                	cmp    $0x84,%al
f0100b7b:	74 0d                	je     f0100b8a <debuginfo_eip+0x16b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b7d:	3c 64                	cmp    $0x64,%al
f0100b7f:	75 e7                	jne    f0100b68 <debuginfo_eip+0x149>
f0100b81:	83 39 00             	cmpl   $0x0,(%ecx)
f0100b84:	74 e2                	je     f0100b68 <debuginfo_eip+0x149>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b86:	39 df                	cmp    %ebx,%edi
f0100b88:	7f 20                	jg     f0100baa <debuginfo_eip+0x18b>
f0100b8a:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b8d:	8b 14 85 cc 20 10 f0 	mov    -0xfefdf34(,%eax,4),%edx
f0100b94:	b8 f9 71 10 f0       	mov    $0xf01071f9,%eax
f0100b99:	2d 25 59 10 f0       	sub    $0xf0105925,%eax
f0100b9e:	39 c2                	cmp    %eax,%edx
f0100ba0:	73 08                	jae    f0100baa <debuginfo_eip+0x18b>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100ba2:	81 c2 25 59 10 f0    	add    $0xf0105925,%edx
f0100ba8:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100baa:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100bad:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100bb0:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bb5:	39 ca                	cmp    %ecx,%edx
f0100bb7:	7d 5f                	jge    f0100c18 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
f0100bb9:	8d 42 01             	lea    0x1(%edx),%eax
f0100bbc:	39 c1                	cmp    %eax,%ecx
f0100bbe:	7e 45                	jle    f0100c05 <debuginfo_eip+0x1e6>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bc0:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100bc3:	c1 e2 02             	shl    $0x2,%edx
f0100bc6:	80 ba d0 20 10 f0 a0 	cmpb   $0xa0,-0xfefdf30(%edx)
f0100bcd:	75 3d                	jne    f0100c0c <debuginfo_eip+0x1ed>
f0100bcf:	81 c2 c0 20 10 f0    	add    $0xf01020c0,%edx
		     lline++)
			info->eip_fn_narg++;
f0100bd5:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100bd9:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100bdc:	39 c1                	cmp    %eax,%ecx
f0100bde:	7e 33                	jle    f0100c13 <debuginfo_eip+0x1f4>
f0100be0:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100be3:	80 7a 10 a0          	cmpb   $0xa0,0x10(%edx)
f0100be7:	74 ec                	je     f0100bd5 <debuginfo_eip+0x1b6>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100be9:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bee:	eb 28                	jmp    f0100c18 <debuginfo_eip+0x1f9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100bf0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bf5:	eb 21                	jmp    f0100c18 <debuginfo_eip+0x1f9>
f0100bf7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bfc:	eb 1a                	jmp    f0100c18 <debuginfo_eip+0x1f9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100bfe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c03:	eb 13                	jmp    f0100c18 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c05:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c0a:	eb 0c                	jmp    f0100c18 <debuginfo_eip+0x1f9>
f0100c0c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c11:	eb 05                	jmp    f0100c18 <debuginfo_eip+0x1f9>
f0100c13:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c18:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c1b:	5b                   	pop    %ebx
f0100c1c:	5e                   	pop    %esi
f0100c1d:	5f                   	pop    %edi
f0100c1e:	5d                   	pop    %ebp
f0100c1f:	c3                   	ret    

f0100c20 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c20:	55                   	push   %ebp
f0100c21:	89 e5                	mov    %esp,%ebp
f0100c23:	57                   	push   %edi
f0100c24:	56                   	push   %esi
f0100c25:	53                   	push   %ebx
f0100c26:	83 ec 1c             	sub    $0x1c,%esp
f0100c29:	89 c7                	mov    %eax,%edi
f0100c2b:	89 d6                	mov    %edx,%esi
f0100c2d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c30:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c33:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c36:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100c39:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c3c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100c3f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100c46:	39 55 e4             	cmp    %edx,-0x1c(%ebp)
f0100c49:	72 11                	jb     f0100c5c <printnum+0x3c>
f0100c4b:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100c4e:	76 0c                	jbe    f0100c5c <printnum+0x3c>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c50:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c53:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100c56:	85 db                	test   %ebx,%ebx
f0100c58:	7f 37                	jg     f0100c91 <printnum+0x71>
f0100c5a:	eb 46                	jmp    f0100ca2 <printnum+0x82>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c5c:	83 ec 0c             	sub    $0xc,%esp
f0100c5f:	ff 75 18             	pushl  0x18(%ebp)
f0100c62:	8b 55 14             	mov    0x14(%ebp),%edx
f0100c65:	83 ea 01             	sub    $0x1,%edx
f0100c68:	52                   	push   %edx
f0100c69:	50                   	push   %eax
f0100c6a:	83 ec 08             	sub    $0x8,%esp
f0100c6d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c70:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c73:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c76:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c79:	e8 92 0a 00 00       	call   f0101710 <__udivdi3>
f0100c7e:	83 c4 18             	add    $0x18,%esp
f0100c81:	52                   	push   %edx
f0100c82:	50                   	push   %eax
f0100c83:	89 f2                	mov    %esi,%edx
f0100c85:	89 f8                	mov    %edi,%eax
f0100c87:	e8 94 ff ff ff       	call   f0100c20 <printnum>
f0100c8c:	83 c4 20             	add    $0x20,%esp
f0100c8f:	eb 11                	jmp    f0100ca2 <printnum+0x82>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c91:	83 ec 08             	sub    $0x8,%esp
f0100c94:	56                   	push   %esi
f0100c95:	ff 75 18             	pushl  0x18(%ebp)
f0100c98:	ff d7                	call   *%edi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c9a:	83 c4 10             	add    $0x10,%esp
f0100c9d:	83 eb 01             	sub    $0x1,%ebx
f0100ca0:	75 ef                	jne    f0100c91 <printnum+0x71>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100ca2:	83 ec 08             	sub    $0x8,%esp
f0100ca5:	56                   	push   %esi
f0100ca6:	83 ec 04             	sub    $0x4,%esp
f0100ca9:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100cac:	ff 75 e0             	pushl  -0x20(%ebp)
f0100caf:	ff 75 dc             	pushl  -0x24(%ebp)
f0100cb2:	ff 75 d8             	pushl  -0x28(%ebp)
f0100cb5:	e8 86 0b 00 00       	call   f0101840 <__umoddi3>
f0100cba:	83 c4 14             	add    $0x14,%esp
f0100cbd:	0f be 80 b9 1e 10 f0 	movsbl -0xfefe147(%eax),%eax
f0100cc4:	50                   	push   %eax
f0100cc5:	ff d7                	call   *%edi
f0100cc7:	83 c4 10             	add    $0x10,%esp
}
f0100cca:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ccd:	5b                   	pop    %ebx
f0100cce:	5e                   	pop    %esi
f0100ccf:	5f                   	pop    %edi
f0100cd0:	5d                   	pop    %ebp
f0100cd1:	c3                   	ret    

f0100cd2 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100cd2:	55                   	push   %ebp
f0100cd3:	89 e5                	mov    %esp,%ebp
f0100cd5:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100cd8:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100cdc:	8b 10                	mov    (%eax),%edx
f0100cde:	3b 50 04             	cmp    0x4(%eax),%edx
f0100ce1:	73 0a                	jae    f0100ced <sprintputch+0x1b>
		*b->buf++ = ch;
f0100ce3:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100ce6:	89 08                	mov    %ecx,(%eax)
f0100ce8:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ceb:	88 02                	mov    %al,(%edx)
}
f0100ced:	5d                   	pop    %ebp
f0100cee:	c3                   	ret    

f0100cef <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100cef:	55                   	push   %ebp
f0100cf0:	89 e5                	mov    %esp,%ebp
f0100cf2:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100cf5:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100cf8:	50                   	push   %eax
f0100cf9:	ff 75 10             	pushl  0x10(%ebp)
f0100cfc:	ff 75 0c             	pushl  0xc(%ebp)
f0100cff:	ff 75 08             	pushl  0x8(%ebp)
f0100d02:	e8 05 00 00 00       	call   f0100d0c <vprintfmt>
	va_end(ap);
f0100d07:	83 c4 10             	add    $0x10,%esp
}
f0100d0a:	c9                   	leave  
f0100d0b:	c3                   	ret    

f0100d0c <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d0c:	55                   	push   %ebp
f0100d0d:	89 e5                	mov    %esp,%ebp
f0100d0f:	57                   	push   %edi
f0100d10:	56                   	push   %esi
f0100d11:	53                   	push   %ebx
f0100d12:	83 ec 2c             	sub    $0x2c,%esp
f0100d15:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100d18:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d1b:	eb 03                	jmp    f0100d20 <vprintfmt+0x14>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f0100d1d:	89 75 10             	mov    %esi,0x10(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d20:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d23:	8d 70 01             	lea    0x1(%eax),%esi
f0100d26:	0f b6 00             	movzbl (%eax),%eax
f0100d29:	83 f8 25             	cmp    $0x25,%eax
f0100d2c:	74 27                	je     f0100d55 <vprintfmt+0x49>
			if (ch == '\0')
f0100d2e:	85 c0                	test   %eax,%eax
f0100d30:	75 0d                	jne    f0100d3f <vprintfmt+0x33>
f0100d32:	e9 69 04 00 00       	jmp    f01011a0 <vprintfmt+0x494>
f0100d37:	85 c0                	test   %eax,%eax
f0100d39:	0f 84 61 04 00 00    	je     f01011a0 <vprintfmt+0x494>
				return;
			putch(ch, putdat);
f0100d3f:	83 ec 08             	sub    $0x8,%esp
f0100d42:	53                   	push   %ebx
f0100d43:	50                   	push   %eax
f0100d44:	ff d7                	call   *%edi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d46:	83 c6 01             	add    $0x1,%esi
f0100d49:	0f b6 46 ff          	movzbl -0x1(%esi),%eax
f0100d4d:	83 c4 10             	add    $0x10,%esp
f0100d50:	83 f8 25             	cmp    $0x25,%eax
f0100d53:	75 e2                	jne    f0100d37 <vprintfmt+0x2b>
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100d55:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
f0100d59:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100d60:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100d67:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100d6e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d73:	eb 07                	jmp    f0100d7c <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d75:	8b 75 10             	mov    0x10(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100d78:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d7c:	8d 46 01             	lea    0x1(%esi),%eax
f0100d7f:	89 45 10             	mov    %eax,0x10(%ebp)
f0100d82:	0f b6 06             	movzbl (%esi),%eax
f0100d85:	0f b6 d0             	movzbl %al,%edx
f0100d88:	83 e8 23             	sub    $0x23,%eax
f0100d8b:	3c 55                	cmp    $0x55,%al
f0100d8d:	0f 87 ce 03 00 00    	ja     f0101161 <vprintfmt+0x455>
f0100d93:	0f b6 c0             	movzbl %al,%eax
f0100d96:	ff 24 85 48 1f 10 f0 	jmp    *-0xfefe0b8(,%eax,4)
f0100d9d:	8b 75 10             	mov    0x10(%ebp),%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100da0:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
f0100da4:	eb d6                	jmp    f0100d7c <vprintfmt+0x70>
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100da6:	8d 42 d0             	lea    -0x30(%edx),%eax
f0100da9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
f0100dac:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100db0:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100db3:	83 fa 09             	cmp    $0x9,%edx
f0100db6:	77 63                	ja     f0100e1b <vprintfmt+0x10f>
f0100db8:	8b 75 10             	mov    0x10(%ebp),%esi
f0100dbb:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0100dbe:	8b 55 d4             	mov    -0x2c(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100dc1:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100dc4:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100dc7:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100dcb:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100dce:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100dd1:	83 f9 09             	cmp    $0x9,%ecx
f0100dd4:	76 eb                	jbe    f0100dc1 <vprintfmt+0xb5>
f0100dd6:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100dd9:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0100ddc:	eb 40                	jmp    f0100e1e <vprintfmt+0x112>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100dde:	8b 45 14             	mov    0x14(%ebp),%eax
f0100de1:	8b 00                	mov    (%eax),%eax
f0100de3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100de6:	8b 45 14             	mov    0x14(%ebp),%eax
f0100de9:	8d 40 04             	lea    0x4(%eax),%eax
f0100dec:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100def:	8b 75 10             	mov    0x10(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100df2:	eb 2a                	jmp    f0100e1e <vprintfmt+0x112>
f0100df4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100df7:	85 c0                	test   %eax,%eax
f0100df9:	ba 00 00 00 00       	mov    $0x0,%edx
f0100dfe:	0f 49 d0             	cmovns %eax,%edx
f0100e01:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e04:	8b 75 10             	mov    0x10(%ebp),%esi
f0100e07:	e9 70 ff ff ff       	jmp    f0100d7c <vprintfmt+0x70>
f0100e0c:	8b 75 10             	mov    0x10(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e0f:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100e16:	e9 61 ff ff ff       	jmp    f0100d7c <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e1b:	8b 75 10             	mov    0x10(%ebp),%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100e1e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100e22:	0f 89 54 ff ff ff    	jns    f0100d7c <vprintfmt+0x70>
				width = precision, precision = -1;
f0100e28:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e2b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e2e:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100e35:	e9 42 ff ff ff       	jmp    f0100d7c <vprintfmt+0x70>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e3a:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e3d:	8b 75 10             	mov    0x10(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e40:	e9 37 ff ff ff       	jmp    f0100d7c <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e45:	8b 45 14             	mov    0x14(%ebp),%eax
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e48:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100e4c:	83 ec 08             	sub    $0x8,%esp
f0100e4f:	53                   	push   %ebx
f0100e50:	ff 30                	pushl  (%eax)
f0100e52:	ff d7                	call   *%edi
			break;
f0100e54:	83 c4 10             	add    $0x10,%esp
f0100e57:	e9 c4 fe ff ff       	jmp    f0100d20 <vprintfmt+0x14>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e5c:	8b 45 14             	mov    0x14(%ebp),%eax
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e5f:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100e63:	8b 00                	mov    (%eax),%eax
f0100e65:	99                   	cltd   
f0100e66:	31 d0                	xor    %edx,%eax
f0100e68:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100e6a:	83 f8 06             	cmp    $0x6,%eax
f0100e6d:	7f 0b                	jg     f0100e7a <vprintfmt+0x16e>
f0100e6f:	8b 14 85 a0 20 10 f0 	mov    -0xfefdf60(,%eax,4),%edx
f0100e76:	85 d2                	test   %edx,%edx
f0100e78:	75 15                	jne    f0100e8f <vprintfmt+0x183>
				printfmt(putch, putdat, "error %d", err);
f0100e7a:	50                   	push   %eax
f0100e7b:	68 d1 1e 10 f0       	push   $0xf0101ed1
f0100e80:	53                   	push   %ebx
f0100e81:	57                   	push   %edi
f0100e82:	e8 68 fe ff ff       	call   f0100cef <printfmt>
f0100e87:	83 c4 10             	add    $0x10,%esp
f0100e8a:	e9 91 fe ff ff       	jmp    f0100d20 <vprintfmt+0x14>
			else
				printfmt(putch, putdat, "%s", p);
f0100e8f:	52                   	push   %edx
f0100e90:	68 da 1e 10 f0       	push   $0xf0101eda
f0100e95:	53                   	push   %ebx
f0100e96:	57                   	push   %edi
f0100e97:	e8 53 fe ff ff       	call   f0100cef <printfmt>
f0100e9c:	83 c4 10             	add    $0x10,%esp
f0100e9f:	e9 7c fe ff ff       	jmp    f0100d20 <vprintfmt+0x14>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ea7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100eaa:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100ead:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100eb1:	8b 00                	mov    (%eax),%eax
				p = "(null)";
f0100eb3:	85 c0                	test   %eax,%eax
f0100eb5:	b9 ca 1e 10 f0       	mov    $0xf0101eca,%ecx
f0100eba:	0f 45 c8             	cmovne %eax,%ecx
f0100ebd:	89 4d d0             	mov    %ecx,-0x30(%ebp)
			if (width > 0 && padc != '-')
f0100ec0:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f0100ec4:	74 04                	je     f0100eca <vprintfmt+0x1be>
f0100ec6:	85 f6                	test   %esi,%esi
f0100ec8:	7f 19                	jg     f0100ee3 <vprintfmt+0x1d7>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100eca:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100ecd:	8d 70 01             	lea    0x1(%eax),%esi
f0100ed0:	0f b6 00             	movzbl (%eax),%eax
f0100ed3:	0f be d0             	movsbl %al,%edx
f0100ed6:	85 d2                	test   %edx,%edx
f0100ed8:	0f 85 9e 00 00 00    	jne    f0100f7c <vprintfmt+0x270>
f0100ede:	e9 8b 00 00 00       	jmp    f0100f6e <vprintfmt+0x262>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ee3:	83 ec 08             	sub    $0x8,%esp
f0100ee6:	52                   	push   %edx
f0100ee7:	ff 75 d0             	pushl  -0x30(%ebp)
f0100eea:	e8 1c 04 00 00       	call   f010130b <strnlen>
f0100eef:	89 f1                	mov    %esi,%ecx
f0100ef1:	29 c1                	sub    %eax,%ecx
f0100ef3:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100ef6:	83 c4 10             	add    $0x10,%esp
f0100ef9:	85 c9                	test   %ecx,%ecx
f0100efb:	0f 8e 86 02 00 00    	jle    f0101187 <vprintfmt+0x47b>
					putch(padc, putdat);
f0100f01:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0100f05:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f08:	89 cb                	mov    %ecx,%ebx
f0100f0a:	83 ec 08             	sub    $0x8,%esp
f0100f0d:	ff 75 0c             	pushl  0xc(%ebp)
f0100f10:	56                   	push   %esi
f0100f11:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f13:	83 c4 10             	add    $0x10,%esp
f0100f16:	83 eb 01             	sub    $0x1,%ebx
f0100f19:	75 ef                	jne    f0100f0a <vprintfmt+0x1fe>
f0100f1b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100f1e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f21:	e9 61 02 00 00       	jmp    f0101187 <vprintfmt+0x47b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f26:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f2a:	74 1b                	je     f0100f47 <vprintfmt+0x23b>
f0100f2c:	0f be c0             	movsbl %al,%eax
f0100f2f:	83 e8 20             	sub    $0x20,%eax
f0100f32:	83 f8 5e             	cmp    $0x5e,%eax
f0100f35:	76 10                	jbe    f0100f47 <vprintfmt+0x23b>
					putch('?', putdat);
f0100f37:	83 ec 08             	sub    $0x8,%esp
f0100f3a:	ff 75 0c             	pushl  0xc(%ebp)
f0100f3d:	6a 3f                	push   $0x3f
f0100f3f:	ff 55 08             	call   *0x8(%ebp)
f0100f42:	83 c4 10             	add    $0x10,%esp
f0100f45:	eb 0d                	jmp    f0100f54 <vprintfmt+0x248>
				else
					putch(ch, putdat);
f0100f47:	83 ec 08             	sub    $0x8,%esp
f0100f4a:	ff 75 0c             	pushl  0xc(%ebp)
f0100f4d:	52                   	push   %edx
f0100f4e:	ff 55 08             	call   *0x8(%ebp)
f0100f51:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f54:	83 eb 01             	sub    $0x1,%ebx
f0100f57:	83 c6 01             	add    $0x1,%esi
f0100f5a:	0f b6 46 ff          	movzbl -0x1(%esi),%eax
f0100f5e:	0f be d0             	movsbl %al,%edx
f0100f61:	85 d2                	test   %edx,%edx
f0100f63:	75 31                	jne    f0100f96 <vprintfmt+0x28a>
f0100f65:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100f68:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100f6b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f6e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100f71:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f75:	7f 33                	jg     f0100faa <vprintfmt+0x29e>
f0100f77:	e9 a4 fd ff ff       	jmp    f0100d20 <vprintfmt+0x14>
f0100f7c:	89 7d 08             	mov    %edi,0x8(%ebp)
f0100f7f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f82:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f85:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100f88:	eb 0c                	jmp    f0100f96 <vprintfmt+0x28a>
f0100f8a:	89 7d 08             	mov    %edi,0x8(%ebp)
f0100f8d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f90:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f93:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f96:	85 ff                	test   %edi,%edi
f0100f98:	78 8c                	js     f0100f26 <vprintfmt+0x21a>
f0100f9a:	83 ef 01             	sub    $0x1,%edi
f0100f9d:	79 87                	jns    f0100f26 <vprintfmt+0x21a>
f0100f9f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100fa2:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100fa5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fa8:	eb c4                	jmp    f0100f6e <vprintfmt+0x262>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100faa:	83 ec 08             	sub    $0x8,%esp
f0100fad:	53                   	push   %ebx
f0100fae:	6a 20                	push   $0x20
f0100fb0:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100fb2:	83 c4 10             	add    $0x10,%esp
f0100fb5:	83 ee 01             	sub    $0x1,%esi
f0100fb8:	75 f0                	jne    f0100faa <vprintfmt+0x29e>
f0100fba:	e9 61 fd ff ff       	jmp    f0100d20 <vprintfmt+0x14>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100fbf:	83 f9 01             	cmp    $0x1,%ecx
f0100fc2:	7e 19                	jle    f0100fdd <vprintfmt+0x2d1>
		return va_arg(*ap, long long);
f0100fc4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fc7:	8b 50 04             	mov    0x4(%eax),%edx
f0100fca:	8b 00                	mov    (%eax),%eax
f0100fcc:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100fcf:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100fd2:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd5:	8d 40 08             	lea    0x8(%eax),%eax
f0100fd8:	89 45 14             	mov    %eax,0x14(%ebp)
f0100fdb:	eb 38                	jmp    f0101015 <vprintfmt+0x309>
	else if (lflag)
f0100fdd:	85 c9                	test   %ecx,%ecx
f0100fdf:	74 1b                	je     f0100ffc <vprintfmt+0x2f0>
		return va_arg(*ap, long);
f0100fe1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fe4:	8b 30                	mov    (%eax),%esi
f0100fe6:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0100fe9:	89 f0                	mov    %esi,%eax
f0100feb:	c1 f8 1f             	sar    $0x1f,%eax
f0100fee:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100ff1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ff4:	8d 40 04             	lea    0x4(%eax),%eax
f0100ff7:	89 45 14             	mov    %eax,0x14(%ebp)
f0100ffa:	eb 19                	jmp    f0101015 <vprintfmt+0x309>
	else
		return va_arg(*ap, int);
f0100ffc:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fff:	8b 30                	mov    (%eax),%esi
f0101001:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0101004:	89 f0                	mov    %esi,%eax
f0101006:	c1 f8 1f             	sar    $0x1f,%eax
f0101009:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010100c:	8b 45 14             	mov    0x14(%ebp),%eax
f010100f:	8d 40 04             	lea    0x4(%eax),%eax
f0101012:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101015:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101018:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010101b:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101020:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101024:	0f 89 09 01 00 00    	jns    f0101133 <vprintfmt+0x427>
				putch('-', putdat);
f010102a:	83 ec 08             	sub    $0x8,%esp
f010102d:	53                   	push   %ebx
f010102e:	6a 2d                	push   $0x2d
f0101030:	ff d7                	call   *%edi
				num = -(long long) num;
f0101032:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101035:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101038:	f7 da                	neg    %edx
f010103a:	83 d1 00             	adc    $0x0,%ecx
f010103d:	f7 d9                	neg    %ecx
f010103f:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101042:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101047:	e9 e7 00 00 00       	jmp    f0101133 <vprintfmt+0x427>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010104c:	83 f9 01             	cmp    $0x1,%ecx
f010104f:	7e 18                	jle    f0101069 <vprintfmt+0x35d>
		return va_arg(*ap, unsigned long long);
f0101051:	8b 45 14             	mov    0x14(%ebp),%eax
f0101054:	8b 10                	mov    (%eax),%edx
f0101056:	8b 48 04             	mov    0x4(%eax),%ecx
f0101059:	8d 40 08             	lea    0x8(%eax),%eax
f010105c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010105f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101064:	e9 ca 00 00 00       	jmp    f0101133 <vprintfmt+0x427>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0101069:	85 c9                	test   %ecx,%ecx
f010106b:	74 1a                	je     f0101087 <vprintfmt+0x37b>
		return va_arg(*ap, unsigned long);
f010106d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101070:	8b 10                	mov    (%eax),%edx
f0101072:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101077:	8d 40 04             	lea    0x4(%eax),%eax
f010107a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010107d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101082:	e9 ac 00 00 00       	jmp    f0101133 <vprintfmt+0x427>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0101087:	8b 45 14             	mov    0x14(%ebp),%eax
f010108a:	8b 10                	mov    (%eax),%edx
f010108c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101091:	8d 40 04             	lea    0x4(%eax),%eax
f0101094:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101097:	b8 0a 00 00 00       	mov    $0xa,%eax
f010109c:	e9 92 00 00 00       	jmp    f0101133 <vprintfmt+0x427>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01010a1:	83 ec 08             	sub    $0x8,%esp
f01010a4:	53                   	push   %ebx
f01010a5:	6a 58                	push   $0x58
f01010a7:	ff d7                	call   *%edi
			putch('X', putdat);
f01010a9:	83 c4 08             	add    $0x8,%esp
f01010ac:	53                   	push   %ebx
f01010ad:	6a 58                	push   $0x58
f01010af:	ff d7                	call   *%edi
			putch('X', putdat);
f01010b1:	83 c4 08             	add    $0x8,%esp
f01010b4:	53                   	push   %ebx
f01010b5:	6a 58                	push   $0x58
f01010b7:	ff d7                	call   *%edi
			break;
f01010b9:	83 c4 10             	add    $0x10,%esp
f01010bc:	e9 5f fc ff ff       	jmp    f0100d20 <vprintfmt+0x14>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010c1:	8b 75 14             	mov    0x14(%ebp),%esi
			putch('X', putdat);
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f01010c4:	83 ec 08             	sub    $0x8,%esp
f01010c7:	53                   	push   %ebx
f01010c8:	6a 30                	push   $0x30
f01010ca:	ff d7                	call   *%edi
			putch('x', putdat);
f01010cc:	83 c4 08             	add    $0x8,%esp
f01010cf:	53                   	push   %ebx
f01010d0:	6a 78                	push   $0x78
f01010d2:	ff d7                	call   *%edi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01010d4:	83 45 14 04          	addl   $0x4,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01010d8:	8b 16                	mov    (%esi),%edx
f01010da:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01010df:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01010e2:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01010e7:	eb 4a                	jmp    f0101133 <vprintfmt+0x427>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010e9:	83 f9 01             	cmp    $0x1,%ecx
f01010ec:	7e 15                	jle    f0101103 <vprintfmt+0x3f7>
		return va_arg(*ap, unsigned long long);
f01010ee:	8b 45 14             	mov    0x14(%ebp),%eax
f01010f1:	8b 10                	mov    (%eax),%edx
f01010f3:	8b 48 04             	mov    0x4(%eax),%ecx
f01010f6:	8d 40 08             	lea    0x8(%eax),%eax
f01010f9:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01010fc:	b8 10 00 00 00       	mov    $0x10,%eax
f0101101:	eb 30                	jmp    f0101133 <vprintfmt+0x427>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0101103:	85 c9                	test   %ecx,%ecx
f0101105:	74 17                	je     f010111e <vprintfmt+0x412>
		return va_arg(*ap, unsigned long);
f0101107:	8b 45 14             	mov    0x14(%ebp),%eax
f010110a:	8b 10                	mov    (%eax),%edx
f010110c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101111:	8d 40 04             	lea    0x4(%eax),%eax
f0101114:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101117:	b8 10 00 00 00       	mov    $0x10,%eax
f010111c:	eb 15                	jmp    f0101133 <vprintfmt+0x427>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f010111e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101121:	8b 10                	mov    (%eax),%edx
f0101123:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101128:	8d 40 04             	lea    0x4(%eax),%eax
f010112b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010112e:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101133:	83 ec 0c             	sub    $0xc,%esp
f0101136:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f010113a:	56                   	push   %esi
f010113b:	ff 75 e4             	pushl  -0x1c(%ebp)
f010113e:	50                   	push   %eax
f010113f:	51                   	push   %ecx
f0101140:	52                   	push   %edx
f0101141:	89 da                	mov    %ebx,%edx
f0101143:	89 f8                	mov    %edi,%eax
f0101145:	e8 d6 fa ff ff       	call   f0100c20 <printnum>
			break;
f010114a:	83 c4 20             	add    $0x20,%esp
f010114d:	e9 ce fb ff ff       	jmp    f0100d20 <vprintfmt+0x14>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101152:	83 ec 08             	sub    $0x8,%esp
f0101155:	53                   	push   %ebx
f0101156:	52                   	push   %edx
f0101157:	ff d7                	call   *%edi
			break;
f0101159:	83 c4 10             	add    $0x10,%esp
f010115c:	e9 bf fb ff ff       	jmp    f0100d20 <vprintfmt+0x14>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101161:	83 ec 08             	sub    $0x8,%esp
f0101164:	53                   	push   %ebx
f0101165:	6a 25                	push   $0x25
f0101167:	ff d7                	call   *%edi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101169:	83 c4 10             	add    $0x10,%esp
f010116c:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101170:	0f 84 a7 fb ff ff    	je     f0100d1d <vprintfmt+0x11>
f0101176:	83 ee 01             	sub    $0x1,%esi
f0101179:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010117d:	75 f7                	jne    f0101176 <vprintfmt+0x46a>
f010117f:	89 75 10             	mov    %esi,0x10(%ebp)
f0101182:	e9 99 fb ff ff       	jmp    f0100d20 <vprintfmt+0x14>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101187:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010118a:	8d 70 01             	lea    0x1(%eax),%esi
f010118d:	0f b6 00             	movzbl (%eax),%eax
f0101190:	0f be d0             	movsbl %al,%edx
f0101193:	85 d2                	test   %edx,%edx
f0101195:	0f 85 ef fd ff ff    	jne    f0100f8a <vprintfmt+0x27e>
f010119b:	e9 80 fb ff ff       	jmp    f0100d20 <vprintfmt+0x14>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
f01011a0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011a3:	5b                   	pop    %ebx
f01011a4:	5e                   	pop    %esi
f01011a5:	5f                   	pop    %edi
f01011a6:	5d                   	pop    %ebp
f01011a7:	c3                   	ret    

f01011a8 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011a8:	55                   	push   %ebp
f01011a9:	89 e5                	mov    %esp,%ebp
f01011ab:	83 ec 18             	sub    $0x18,%esp
f01011ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01011b1:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011b4:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011b7:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011bb:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011be:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011c5:	85 c0                	test   %eax,%eax
f01011c7:	74 26                	je     f01011ef <vsnprintf+0x47>
f01011c9:	85 d2                	test   %edx,%edx
f01011cb:	7e 22                	jle    f01011ef <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011cd:	ff 75 14             	pushl  0x14(%ebp)
f01011d0:	ff 75 10             	pushl  0x10(%ebp)
f01011d3:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011d6:	50                   	push   %eax
f01011d7:	68 d2 0c 10 f0       	push   $0xf0100cd2
f01011dc:	e8 2b fb ff ff       	call   f0100d0c <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011e1:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011e4:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011ea:	83 c4 10             	add    $0x10,%esp
f01011ed:	eb 05                	jmp    f01011f4 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011ef:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011f4:	c9                   	leave  
f01011f5:	c3                   	ret    

f01011f6 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011f6:	55                   	push   %ebp
f01011f7:	89 e5                	mov    %esp,%ebp
f01011f9:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011fc:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011ff:	50                   	push   %eax
f0101200:	ff 75 10             	pushl  0x10(%ebp)
f0101203:	ff 75 0c             	pushl  0xc(%ebp)
f0101206:	ff 75 08             	pushl  0x8(%ebp)
f0101209:	e8 9a ff ff ff       	call   f01011a8 <vsnprintf>
	va_end(ap);

	return rc;
}
f010120e:	c9                   	leave  
f010120f:	c3                   	ret    

f0101210 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101210:	55                   	push   %ebp
f0101211:	89 e5                	mov    %esp,%ebp
f0101213:	57                   	push   %edi
f0101214:	56                   	push   %esi
f0101215:	53                   	push   %ebx
f0101216:	83 ec 0c             	sub    $0xc,%esp
f0101219:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010121c:	85 c0                	test   %eax,%eax
f010121e:	74 11                	je     f0101231 <readline+0x21>
		cprintf("%s", prompt);
f0101220:	83 ec 08             	sub    $0x8,%esp
f0101223:	50                   	push   %eax
f0101224:	68 da 1e 10 f0       	push   $0xf0101eda
f0101229:	e8 b1 f6 ff ff       	call   f01008df <cprintf>
f010122e:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101231:	83 ec 0c             	sub    $0xc,%esp
f0101234:	6a 00                	push   $0x0
f0101236:	e8 32 f4 ff ff       	call   f010066d <iscons>
f010123b:	89 c7                	mov    %eax,%edi
f010123d:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101240:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101245:	e8 12 f4 ff ff       	call   f010065c <getchar>
f010124a:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010124c:	85 c0                	test   %eax,%eax
f010124e:	79 18                	jns    f0101268 <readline+0x58>
			cprintf("read error: %e\n", c);
f0101250:	83 ec 08             	sub    $0x8,%esp
f0101253:	50                   	push   %eax
f0101254:	68 bc 20 10 f0       	push   $0xf01020bc
f0101259:	e8 81 f6 ff ff       	call   f01008df <cprintf>
			return NULL;
f010125e:	83 c4 10             	add    $0x10,%esp
f0101261:	b8 00 00 00 00       	mov    $0x0,%eax
f0101266:	eb 79                	jmp    f01012e1 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101268:	83 f8 7f             	cmp    $0x7f,%eax
f010126b:	0f 94 c2             	sete   %dl
f010126e:	83 f8 08             	cmp    $0x8,%eax
f0101271:	0f 94 c0             	sete   %al
f0101274:	08 c2                	or     %al,%dl
f0101276:	74 1a                	je     f0101292 <readline+0x82>
f0101278:	85 f6                	test   %esi,%esi
f010127a:	7e 16                	jle    f0101292 <readline+0x82>
			if (echoing)
f010127c:	85 ff                	test   %edi,%edi
f010127e:	74 0d                	je     f010128d <readline+0x7d>
				cputchar('\b');
f0101280:	83 ec 0c             	sub    $0xc,%esp
f0101283:	6a 08                	push   $0x8
f0101285:	e8 c2 f3 ff ff       	call   f010064c <cputchar>
f010128a:	83 c4 10             	add    $0x10,%esp
			i--;
f010128d:	83 ee 01             	sub    $0x1,%esi
f0101290:	eb b3                	jmp    f0101245 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101292:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101298:	7f 20                	jg     f01012ba <readline+0xaa>
f010129a:	83 fb 1f             	cmp    $0x1f,%ebx
f010129d:	7e 1b                	jle    f01012ba <readline+0xaa>
			if (echoing)
f010129f:	85 ff                	test   %edi,%edi
f01012a1:	74 0c                	je     f01012af <readline+0x9f>
				cputchar(c);
f01012a3:	83 ec 0c             	sub    $0xc,%esp
f01012a6:	53                   	push   %ebx
f01012a7:	e8 a0 f3 ff ff       	call   f010064c <cputchar>
f01012ac:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01012af:	88 9e c0 25 11 f0    	mov    %bl,-0xfeeda40(%esi)
f01012b5:	8d 76 01             	lea    0x1(%esi),%esi
f01012b8:	eb 8b                	jmp    f0101245 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01012ba:	83 fb 0d             	cmp    $0xd,%ebx
f01012bd:	74 05                	je     f01012c4 <readline+0xb4>
f01012bf:	83 fb 0a             	cmp    $0xa,%ebx
f01012c2:	75 81                	jne    f0101245 <readline+0x35>
			if (echoing)
f01012c4:	85 ff                	test   %edi,%edi
f01012c6:	74 0d                	je     f01012d5 <readline+0xc5>
				cputchar('\n');
f01012c8:	83 ec 0c             	sub    $0xc,%esp
f01012cb:	6a 0a                	push   $0xa
f01012cd:	e8 7a f3 ff ff       	call   f010064c <cputchar>
f01012d2:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01012d5:	c6 86 c0 25 11 f0 00 	movb   $0x0,-0xfeeda40(%esi)
			return buf;
f01012dc:	b8 c0 25 11 f0       	mov    $0xf01125c0,%eax
		}
	}
}
f01012e1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012e4:	5b                   	pop    %ebx
f01012e5:	5e                   	pop    %esi
f01012e6:	5f                   	pop    %edi
f01012e7:	5d                   	pop    %ebp
f01012e8:	c3                   	ret    

f01012e9 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012e9:	55                   	push   %ebp
f01012ea:	89 e5                	mov    %esp,%ebp
f01012ec:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012ef:	80 3a 00             	cmpb   $0x0,(%edx)
f01012f2:	74 10                	je     f0101304 <strlen+0x1b>
f01012f4:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01012f9:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012fc:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101300:	75 f7                	jne    f01012f9 <strlen+0x10>
f0101302:	eb 05                	jmp    f0101309 <strlen+0x20>
f0101304:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101309:	5d                   	pop    %ebp
f010130a:	c3                   	ret    

f010130b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010130b:	55                   	push   %ebp
f010130c:	89 e5                	mov    %esp,%ebp
f010130e:	53                   	push   %ebx
f010130f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101312:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101315:	85 c9                	test   %ecx,%ecx
f0101317:	74 1c                	je     f0101335 <strnlen+0x2a>
f0101319:	80 3b 00             	cmpb   $0x0,(%ebx)
f010131c:	74 1e                	je     f010133c <strnlen+0x31>
f010131e:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0101323:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101325:	39 ca                	cmp    %ecx,%edx
f0101327:	74 18                	je     f0101341 <strnlen+0x36>
f0101329:	83 c2 01             	add    $0x1,%edx
f010132c:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101331:	75 f0                	jne    f0101323 <strnlen+0x18>
f0101333:	eb 0c                	jmp    f0101341 <strnlen+0x36>
f0101335:	b8 00 00 00 00       	mov    $0x0,%eax
f010133a:	eb 05                	jmp    f0101341 <strnlen+0x36>
f010133c:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101341:	5b                   	pop    %ebx
f0101342:	5d                   	pop    %ebp
f0101343:	c3                   	ret    

f0101344 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101344:	55                   	push   %ebp
f0101345:	89 e5                	mov    %esp,%ebp
f0101347:	53                   	push   %ebx
f0101348:	8b 45 08             	mov    0x8(%ebp),%eax
f010134b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010134e:	89 c2                	mov    %eax,%edx
f0101350:	83 c2 01             	add    $0x1,%edx
f0101353:	83 c1 01             	add    $0x1,%ecx
f0101356:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010135a:	88 5a ff             	mov    %bl,-0x1(%edx)
f010135d:	84 db                	test   %bl,%bl
f010135f:	75 ef                	jne    f0101350 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101361:	5b                   	pop    %ebx
f0101362:	5d                   	pop    %ebp
f0101363:	c3                   	ret    

f0101364 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101364:	55                   	push   %ebp
f0101365:	89 e5                	mov    %esp,%ebp
f0101367:	56                   	push   %esi
f0101368:	53                   	push   %ebx
f0101369:	8b 75 08             	mov    0x8(%ebp),%esi
f010136c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010136f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101372:	85 db                	test   %ebx,%ebx
f0101374:	74 17                	je     f010138d <strncpy+0x29>
f0101376:	01 f3                	add    %esi,%ebx
f0101378:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f010137a:	83 c1 01             	add    $0x1,%ecx
f010137d:	0f b6 02             	movzbl (%edx),%eax
f0101380:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101383:	80 3a 01             	cmpb   $0x1,(%edx)
f0101386:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101389:	39 d9                	cmp    %ebx,%ecx
f010138b:	75 ed                	jne    f010137a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010138d:	89 f0                	mov    %esi,%eax
f010138f:	5b                   	pop    %ebx
f0101390:	5e                   	pop    %esi
f0101391:	5d                   	pop    %ebp
f0101392:	c3                   	ret    

f0101393 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101393:	55                   	push   %ebp
f0101394:	89 e5                	mov    %esp,%ebp
f0101396:	56                   	push   %esi
f0101397:	53                   	push   %ebx
f0101398:	8b 75 08             	mov    0x8(%ebp),%esi
f010139b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010139e:	8b 55 10             	mov    0x10(%ebp),%edx
f01013a1:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013a3:	85 d2                	test   %edx,%edx
f01013a5:	74 35                	je     f01013dc <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f01013a7:	89 d0                	mov    %edx,%eax
f01013a9:	83 e8 01             	sub    $0x1,%eax
f01013ac:	74 25                	je     f01013d3 <strlcpy+0x40>
f01013ae:	0f b6 0b             	movzbl (%ebx),%ecx
f01013b1:	84 c9                	test   %cl,%cl
f01013b3:	74 22                	je     f01013d7 <strlcpy+0x44>
f01013b5:	8d 53 01             	lea    0x1(%ebx),%edx
f01013b8:	01 c3                	add    %eax,%ebx
f01013ba:	89 f0                	mov    %esi,%eax
			*dst++ = *src++;
f01013bc:	83 c0 01             	add    $0x1,%eax
f01013bf:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013c2:	39 da                	cmp    %ebx,%edx
f01013c4:	74 13                	je     f01013d9 <strlcpy+0x46>
f01013c6:	83 c2 01             	add    $0x1,%edx
f01013c9:	0f b6 4a ff          	movzbl -0x1(%edx),%ecx
f01013cd:	84 c9                	test   %cl,%cl
f01013cf:	75 eb                	jne    f01013bc <strlcpy+0x29>
f01013d1:	eb 06                	jmp    f01013d9 <strlcpy+0x46>
f01013d3:	89 f0                	mov    %esi,%eax
f01013d5:	eb 02                	jmp    f01013d9 <strlcpy+0x46>
f01013d7:	89 f0                	mov    %esi,%eax
			*dst++ = *src++;
		*dst = '\0';
f01013d9:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01013dc:	29 f0                	sub    %esi,%eax
}
f01013de:	5b                   	pop    %ebx
f01013df:	5e                   	pop    %esi
f01013e0:	5d                   	pop    %ebp
f01013e1:	c3                   	ret    

f01013e2 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013e2:	55                   	push   %ebp
f01013e3:	89 e5                	mov    %esp,%ebp
f01013e5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013e8:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013eb:	0f b6 01             	movzbl (%ecx),%eax
f01013ee:	84 c0                	test   %al,%al
f01013f0:	74 15                	je     f0101407 <strcmp+0x25>
f01013f2:	3a 02                	cmp    (%edx),%al
f01013f4:	75 11                	jne    f0101407 <strcmp+0x25>
		p++, q++;
f01013f6:	83 c1 01             	add    $0x1,%ecx
f01013f9:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013fc:	0f b6 01             	movzbl (%ecx),%eax
f01013ff:	84 c0                	test   %al,%al
f0101401:	74 04                	je     f0101407 <strcmp+0x25>
f0101403:	3a 02                	cmp    (%edx),%al
f0101405:	74 ef                	je     f01013f6 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101407:	0f b6 c0             	movzbl %al,%eax
f010140a:	0f b6 12             	movzbl (%edx),%edx
f010140d:	29 d0                	sub    %edx,%eax
}
f010140f:	5d                   	pop    %ebp
f0101410:	c3                   	ret    

f0101411 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101411:	55                   	push   %ebp
f0101412:	89 e5                	mov    %esp,%ebp
f0101414:	56                   	push   %esi
f0101415:	53                   	push   %ebx
f0101416:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101419:	8b 55 0c             	mov    0xc(%ebp),%edx
f010141c:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f010141f:	85 f6                	test   %esi,%esi
f0101421:	74 29                	je     f010144c <strncmp+0x3b>
f0101423:	0f b6 03             	movzbl (%ebx),%eax
f0101426:	84 c0                	test   %al,%al
f0101428:	74 30                	je     f010145a <strncmp+0x49>
f010142a:	3a 02                	cmp    (%edx),%al
f010142c:	75 2c                	jne    f010145a <strncmp+0x49>
f010142e:	8d 43 01             	lea    0x1(%ebx),%eax
f0101431:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f0101433:	89 c3                	mov    %eax,%ebx
f0101435:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101438:	39 f0                	cmp    %esi,%eax
f010143a:	74 17                	je     f0101453 <strncmp+0x42>
f010143c:	0f b6 08             	movzbl (%eax),%ecx
f010143f:	84 c9                	test   %cl,%cl
f0101441:	74 17                	je     f010145a <strncmp+0x49>
f0101443:	83 c0 01             	add    $0x1,%eax
f0101446:	3a 0a                	cmp    (%edx),%cl
f0101448:	74 e9                	je     f0101433 <strncmp+0x22>
f010144a:	eb 0e                	jmp    f010145a <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f010144c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101451:	eb 0f                	jmp    f0101462 <strncmp+0x51>
f0101453:	b8 00 00 00 00       	mov    $0x0,%eax
f0101458:	eb 08                	jmp    f0101462 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010145a:	0f b6 03             	movzbl (%ebx),%eax
f010145d:	0f b6 12             	movzbl (%edx),%edx
f0101460:	29 d0                	sub    %edx,%eax
}
f0101462:	5b                   	pop    %ebx
f0101463:	5e                   	pop    %esi
f0101464:	5d                   	pop    %ebp
f0101465:	c3                   	ret    

f0101466 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101466:	55                   	push   %ebp
f0101467:	89 e5                	mov    %esp,%ebp
f0101469:	53                   	push   %ebx
f010146a:	8b 45 08             	mov    0x8(%ebp),%eax
f010146d:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0101470:	0f b6 18             	movzbl (%eax),%ebx
f0101473:	84 db                	test   %bl,%bl
f0101475:	74 1d                	je     f0101494 <strchr+0x2e>
f0101477:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101479:	38 d3                	cmp    %dl,%bl
f010147b:	75 06                	jne    f0101483 <strchr+0x1d>
f010147d:	eb 1a                	jmp    f0101499 <strchr+0x33>
f010147f:	38 ca                	cmp    %cl,%dl
f0101481:	74 16                	je     f0101499 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101483:	83 c0 01             	add    $0x1,%eax
f0101486:	0f b6 10             	movzbl (%eax),%edx
f0101489:	84 d2                	test   %dl,%dl
f010148b:	75 f2                	jne    f010147f <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f010148d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101492:	eb 05                	jmp    f0101499 <strchr+0x33>
f0101494:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101499:	5b                   	pop    %ebx
f010149a:	5d                   	pop    %ebp
f010149b:	c3                   	ret    

f010149c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010149c:	55                   	push   %ebp
f010149d:	89 e5                	mov    %esp,%ebp
f010149f:	53                   	push   %ebx
f01014a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01014a3:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f01014a6:	0f b6 18             	movzbl (%eax),%ebx
		if (*s == c)
f01014a9:	84 db                	test   %bl,%bl
f01014ab:	74 14                	je     f01014c1 <strfind+0x25>
f01014ad:	89 d1                	mov    %edx,%ecx
f01014af:	38 d3                	cmp    %dl,%bl
f01014b1:	74 0e                	je     f01014c1 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01014b3:	83 c0 01             	add    $0x1,%eax
f01014b6:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01014b9:	38 ca                	cmp    %cl,%dl
f01014bb:	74 04                	je     f01014c1 <strfind+0x25>
f01014bd:	84 d2                	test   %dl,%dl
f01014bf:	75 f2                	jne    f01014b3 <strfind+0x17>
			break;
	return (char *) s;
}
f01014c1:	5b                   	pop    %ebx
f01014c2:	5d                   	pop    %ebp
f01014c3:	c3                   	ret    

f01014c4 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01014c4:	55                   	push   %ebp
f01014c5:	89 e5                	mov    %esp,%ebp
f01014c7:	57                   	push   %edi
f01014c8:	56                   	push   %esi
f01014c9:	53                   	push   %ebx
f01014ca:	8b 7d 08             	mov    0x8(%ebp),%edi
f01014cd:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01014d0:	85 c9                	test   %ecx,%ecx
f01014d2:	74 36                	je     f010150a <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01014d4:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01014da:	75 28                	jne    f0101504 <memset+0x40>
f01014dc:	f6 c1 03             	test   $0x3,%cl
f01014df:	75 23                	jne    f0101504 <memset+0x40>
		c &= 0xFF;
f01014e1:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01014e5:	89 d3                	mov    %edx,%ebx
f01014e7:	c1 e3 08             	shl    $0x8,%ebx
f01014ea:	89 d6                	mov    %edx,%esi
f01014ec:	c1 e6 18             	shl    $0x18,%esi
f01014ef:	89 d0                	mov    %edx,%eax
f01014f1:	c1 e0 10             	shl    $0x10,%eax
f01014f4:	09 f0                	or     %esi,%eax
f01014f6:	09 c2                	or     %eax,%edx
f01014f8:	89 d0                	mov    %edx,%eax
f01014fa:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01014fc:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01014ff:	fc                   	cld    
f0101500:	f3 ab                	rep stos %eax,%es:(%edi)
f0101502:	eb 06                	jmp    f010150a <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101504:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101507:	fc                   	cld    
f0101508:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010150a:	89 f8                	mov    %edi,%eax
f010150c:	5b                   	pop    %ebx
f010150d:	5e                   	pop    %esi
f010150e:	5f                   	pop    %edi
f010150f:	5d                   	pop    %ebp
f0101510:	c3                   	ret    

f0101511 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101511:	55                   	push   %ebp
f0101512:	89 e5                	mov    %esp,%ebp
f0101514:	57                   	push   %edi
f0101515:	56                   	push   %esi
f0101516:	8b 45 08             	mov    0x8(%ebp),%eax
f0101519:	8b 75 0c             	mov    0xc(%ebp),%esi
f010151c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010151f:	39 c6                	cmp    %eax,%esi
f0101521:	73 35                	jae    f0101558 <memmove+0x47>
f0101523:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101526:	39 d0                	cmp    %edx,%eax
f0101528:	73 2e                	jae    f0101558 <memmove+0x47>
		s += n;
		d += n;
f010152a:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f010152d:	89 d6                	mov    %edx,%esi
f010152f:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101531:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101537:	75 13                	jne    f010154c <memmove+0x3b>
f0101539:	f6 c1 03             	test   $0x3,%cl
f010153c:	75 0e                	jne    f010154c <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010153e:	83 ef 04             	sub    $0x4,%edi
f0101541:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101544:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101547:	fd                   	std    
f0101548:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010154a:	eb 09                	jmp    f0101555 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010154c:	83 ef 01             	sub    $0x1,%edi
f010154f:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101552:	fd                   	std    
f0101553:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101555:	fc                   	cld    
f0101556:	eb 1d                	jmp    f0101575 <memmove+0x64>
f0101558:	89 f2                	mov    %esi,%edx
f010155a:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010155c:	f6 c2 03             	test   $0x3,%dl
f010155f:	75 0f                	jne    f0101570 <memmove+0x5f>
f0101561:	f6 c1 03             	test   $0x3,%cl
f0101564:	75 0a                	jne    f0101570 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101566:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101569:	89 c7                	mov    %eax,%edi
f010156b:	fc                   	cld    
f010156c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010156e:	eb 05                	jmp    f0101575 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101570:	89 c7                	mov    %eax,%edi
f0101572:	fc                   	cld    
f0101573:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101575:	5e                   	pop    %esi
f0101576:	5f                   	pop    %edi
f0101577:	5d                   	pop    %ebp
f0101578:	c3                   	ret    

f0101579 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0101579:	55                   	push   %ebp
f010157a:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010157c:	ff 75 10             	pushl  0x10(%ebp)
f010157f:	ff 75 0c             	pushl  0xc(%ebp)
f0101582:	ff 75 08             	pushl  0x8(%ebp)
f0101585:	e8 87 ff ff ff       	call   f0101511 <memmove>
}
f010158a:	c9                   	leave  
f010158b:	c3                   	ret    

f010158c <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010158c:	55                   	push   %ebp
f010158d:	89 e5                	mov    %esp,%ebp
f010158f:	57                   	push   %edi
f0101590:	56                   	push   %esi
f0101591:	53                   	push   %ebx
f0101592:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101595:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101598:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010159b:	8d 78 ff             	lea    -0x1(%eax),%edi
f010159e:	85 c0                	test   %eax,%eax
f01015a0:	74 36                	je     f01015d8 <memcmp+0x4c>
		if (*s1 != *s2)
f01015a2:	0f b6 13             	movzbl (%ebx),%edx
f01015a5:	0f b6 0e             	movzbl (%esi),%ecx
f01015a8:	38 ca                	cmp    %cl,%dl
f01015aa:	75 17                	jne    f01015c3 <memcmp+0x37>
f01015ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01015b1:	eb 1a                	jmp    f01015cd <memcmp+0x41>
f01015b3:	0f b6 54 03 01       	movzbl 0x1(%ebx,%eax,1),%edx
f01015b8:	83 c0 01             	add    $0x1,%eax
f01015bb:	0f b6 0c 06          	movzbl (%esi,%eax,1),%ecx
f01015bf:	38 ca                	cmp    %cl,%dl
f01015c1:	74 0a                	je     f01015cd <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f01015c3:	0f b6 c2             	movzbl %dl,%eax
f01015c6:	0f b6 c9             	movzbl %cl,%ecx
f01015c9:	29 c8                	sub    %ecx,%eax
f01015cb:	eb 10                	jmp    f01015dd <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01015cd:	39 f8                	cmp    %edi,%eax
f01015cf:	75 e2                	jne    f01015b3 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01015d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01015d6:	eb 05                	jmp    f01015dd <memcmp+0x51>
f01015d8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015dd:	5b                   	pop    %ebx
f01015de:	5e                   	pop    %esi
f01015df:	5f                   	pop    %edi
f01015e0:	5d                   	pop    %ebp
f01015e1:	c3                   	ret    

f01015e2 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01015e2:	55                   	push   %ebp
f01015e3:	89 e5                	mov    %esp,%ebp
f01015e5:	53                   	push   %ebx
f01015e6:	8b 55 08             	mov    0x8(%ebp),%edx
f01015e9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f01015ec:	89 d0                	mov    %edx,%eax
f01015ee:	03 45 10             	add    0x10(%ebp),%eax
	for (; s < ends; s++)
f01015f1:	39 c2                	cmp    %eax,%edx
f01015f3:	73 15                	jae    f010160a <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f01015f5:	89 d9                	mov    %ebx,%ecx
f01015f7:	38 1a                	cmp    %bl,(%edx)
f01015f9:	75 06                	jne    f0101601 <memfind+0x1f>
f01015fb:	eb 11                	jmp    f010160e <memfind+0x2c>
f01015fd:	38 0a                	cmp    %cl,(%edx)
f01015ff:	74 11                	je     f0101612 <memfind+0x30>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101601:	83 c2 01             	add    $0x1,%edx
f0101604:	39 c2                	cmp    %eax,%edx
f0101606:	75 f5                	jne    f01015fd <memfind+0x1b>
f0101608:	eb 0a                	jmp    f0101614 <memfind+0x32>
f010160a:	89 d0                	mov    %edx,%eax
f010160c:	eb 06                	jmp    f0101614 <memfind+0x32>
		if (*(const unsigned char *) s == (unsigned char) c)
f010160e:	89 d0                	mov    %edx,%eax
f0101610:	eb 02                	jmp    f0101614 <memfind+0x32>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101612:	89 d0                	mov    %edx,%eax
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101614:	5b                   	pop    %ebx
f0101615:	5d                   	pop    %ebp
f0101616:	c3                   	ret    

f0101617 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101617:	55                   	push   %ebp
f0101618:	89 e5                	mov    %esp,%ebp
f010161a:	57                   	push   %edi
f010161b:	56                   	push   %esi
f010161c:	53                   	push   %ebx
f010161d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101620:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101623:	0f b6 01             	movzbl (%ecx),%eax
f0101626:	3c 09                	cmp    $0x9,%al
f0101628:	74 04                	je     f010162e <strtol+0x17>
f010162a:	3c 20                	cmp    $0x20,%al
f010162c:	75 0e                	jne    f010163c <strtol+0x25>
		s++;
f010162e:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101631:	0f b6 01             	movzbl (%ecx),%eax
f0101634:	3c 09                	cmp    $0x9,%al
f0101636:	74 f6                	je     f010162e <strtol+0x17>
f0101638:	3c 20                	cmp    $0x20,%al
f010163a:	74 f2                	je     f010162e <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f010163c:	3c 2b                	cmp    $0x2b,%al
f010163e:	75 0a                	jne    f010164a <strtol+0x33>
		s++;
f0101640:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101643:	bf 00 00 00 00       	mov    $0x0,%edi
f0101648:	eb 10                	jmp    f010165a <strtol+0x43>
f010164a:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010164f:	3c 2d                	cmp    $0x2d,%al
f0101651:	75 07                	jne    f010165a <strtol+0x43>
		s++, neg = 1;
f0101653:	83 c1 01             	add    $0x1,%ecx
f0101656:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010165a:	85 db                	test   %ebx,%ebx
f010165c:	0f 94 c0             	sete   %al
f010165f:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101665:	75 19                	jne    f0101680 <strtol+0x69>
f0101667:	80 39 30             	cmpb   $0x30,(%ecx)
f010166a:	75 14                	jne    f0101680 <strtol+0x69>
f010166c:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101670:	0f 85 82 00 00 00    	jne    f01016f8 <strtol+0xe1>
		s += 2, base = 16;
f0101676:	83 c1 02             	add    $0x2,%ecx
f0101679:	bb 10 00 00 00       	mov    $0x10,%ebx
f010167e:	eb 16                	jmp    f0101696 <strtol+0x7f>
	else if (base == 0 && s[0] == '0')
f0101680:	84 c0                	test   %al,%al
f0101682:	74 12                	je     f0101696 <strtol+0x7f>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101684:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101689:	80 39 30             	cmpb   $0x30,(%ecx)
f010168c:	75 08                	jne    f0101696 <strtol+0x7f>
		s++, base = 8;
f010168e:	83 c1 01             	add    $0x1,%ecx
f0101691:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0101696:	b8 00 00 00 00       	mov    $0x0,%eax
f010169b:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010169e:	0f b6 11             	movzbl (%ecx),%edx
f01016a1:	8d 72 d0             	lea    -0x30(%edx),%esi
f01016a4:	89 f3                	mov    %esi,%ebx
f01016a6:	80 fb 09             	cmp    $0x9,%bl
f01016a9:	77 08                	ja     f01016b3 <strtol+0x9c>
			dig = *s - '0';
f01016ab:	0f be d2             	movsbl %dl,%edx
f01016ae:	83 ea 30             	sub    $0x30,%edx
f01016b1:	eb 22                	jmp    f01016d5 <strtol+0xbe>
		else if (*s >= 'a' && *s <= 'z')
f01016b3:	8d 72 9f             	lea    -0x61(%edx),%esi
f01016b6:	89 f3                	mov    %esi,%ebx
f01016b8:	80 fb 19             	cmp    $0x19,%bl
f01016bb:	77 08                	ja     f01016c5 <strtol+0xae>
			dig = *s - 'a' + 10;
f01016bd:	0f be d2             	movsbl %dl,%edx
f01016c0:	83 ea 57             	sub    $0x57,%edx
f01016c3:	eb 10                	jmp    f01016d5 <strtol+0xbe>
		else if (*s >= 'A' && *s <= 'Z')
f01016c5:	8d 72 bf             	lea    -0x41(%edx),%esi
f01016c8:	89 f3                	mov    %esi,%ebx
f01016ca:	80 fb 19             	cmp    $0x19,%bl
f01016cd:	77 16                	ja     f01016e5 <strtol+0xce>
			dig = *s - 'A' + 10;
f01016cf:	0f be d2             	movsbl %dl,%edx
f01016d2:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01016d5:	3b 55 10             	cmp    0x10(%ebp),%edx
f01016d8:	7d 0f                	jge    f01016e9 <strtol+0xd2>
			break;
		s++, val = (val * base) + dig;
f01016da:	83 c1 01             	add    $0x1,%ecx
f01016dd:	0f af 45 10          	imul   0x10(%ebp),%eax
f01016e1:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01016e3:	eb b9                	jmp    f010169e <strtol+0x87>
f01016e5:	89 c2                	mov    %eax,%edx
f01016e7:	eb 02                	jmp    f01016eb <strtol+0xd4>
f01016e9:	89 c2                	mov    %eax,%edx

	if (endptr)
f01016eb:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01016ef:	74 0d                	je     f01016fe <strtol+0xe7>
		*endptr = (char *) s;
f01016f1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016f4:	89 0e                	mov    %ecx,(%esi)
f01016f6:	eb 06                	jmp    f01016fe <strtol+0xe7>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016f8:	84 c0                	test   %al,%al
f01016fa:	75 92                	jne    f010168e <strtol+0x77>
f01016fc:	eb 98                	jmp    f0101696 <strtol+0x7f>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01016fe:	f7 da                	neg    %edx
f0101700:	85 ff                	test   %edi,%edi
f0101702:	0f 45 c2             	cmovne %edx,%eax
}
f0101705:	5b                   	pop    %ebx
f0101706:	5e                   	pop    %esi
f0101707:	5f                   	pop    %edi
f0101708:	5d                   	pop    %ebp
f0101709:	c3                   	ret    
f010170a:	66 90                	xchg   %ax,%ax
f010170c:	66 90                	xchg   %ax,%ax
f010170e:	66 90                	xchg   %ax,%ax

f0101710 <__udivdi3>:
f0101710:	55                   	push   %ebp
f0101711:	57                   	push   %edi
f0101712:	56                   	push   %esi
f0101713:	83 ec 10             	sub    $0x10,%esp
f0101716:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f010171a:	8b 7c 24 20          	mov    0x20(%esp),%edi
f010171e:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101722:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101726:	85 d2                	test   %edx,%edx
f0101728:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010172c:	89 34 24             	mov    %esi,(%esp)
f010172f:	89 c8                	mov    %ecx,%eax
f0101731:	75 35                	jne    f0101768 <__udivdi3+0x58>
f0101733:	39 f1                	cmp    %esi,%ecx
f0101735:	0f 87 bd 00 00 00    	ja     f01017f8 <__udivdi3+0xe8>
f010173b:	85 c9                	test   %ecx,%ecx
f010173d:	89 cd                	mov    %ecx,%ebp
f010173f:	75 0b                	jne    f010174c <__udivdi3+0x3c>
f0101741:	b8 01 00 00 00       	mov    $0x1,%eax
f0101746:	31 d2                	xor    %edx,%edx
f0101748:	f7 f1                	div    %ecx
f010174a:	89 c5                	mov    %eax,%ebp
f010174c:	89 f0                	mov    %esi,%eax
f010174e:	31 d2                	xor    %edx,%edx
f0101750:	f7 f5                	div    %ebp
f0101752:	89 c6                	mov    %eax,%esi
f0101754:	89 f8                	mov    %edi,%eax
f0101756:	f7 f5                	div    %ebp
f0101758:	89 f2                	mov    %esi,%edx
f010175a:	83 c4 10             	add    $0x10,%esp
f010175d:	5e                   	pop    %esi
f010175e:	5f                   	pop    %edi
f010175f:	5d                   	pop    %ebp
f0101760:	c3                   	ret    
f0101761:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101768:	3b 14 24             	cmp    (%esp),%edx
f010176b:	77 7b                	ja     f01017e8 <__udivdi3+0xd8>
f010176d:	0f bd f2             	bsr    %edx,%esi
f0101770:	83 f6 1f             	xor    $0x1f,%esi
f0101773:	0f 84 97 00 00 00    	je     f0101810 <__udivdi3+0x100>
f0101779:	bd 20 00 00 00       	mov    $0x20,%ebp
f010177e:	89 d7                	mov    %edx,%edi
f0101780:	89 f1                	mov    %esi,%ecx
f0101782:	29 f5                	sub    %esi,%ebp
f0101784:	d3 e7                	shl    %cl,%edi
f0101786:	89 c2                	mov    %eax,%edx
f0101788:	89 e9                	mov    %ebp,%ecx
f010178a:	d3 ea                	shr    %cl,%edx
f010178c:	89 f1                	mov    %esi,%ecx
f010178e:	09 fa                	or     %edi,%edx
f0101790:	8b 3c 24             	mov    (%esp),%edi
f0101793:	d3 e0                	shl    %cl,%eax
f0101795:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101799:	89 e9                	mov    %ebp,%ecx
f010179b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010179f:	8b 44 24 04          	mov    0x4(%esp),%eax
f01017a3:	89 fa                	mov    %edi,%edx
f01017a5:	d3 ea                	shr    %cl,%edx
f01017a7:	89 f1                	mov    %esi,%ecx
f01017a9:	d3 e7                	shl    %cl,%edi
f01017ab:	89 e9                	mov    %ebp,%ecx
f01017ad:	d3 e8                	shr    %cl,%eax
f01017af:	09 c7                	or     %eax,%edi
f01017b1:	89 f8                	mov    %edi,%eax
f01017b3:	f7 74 24 08          	divl   0x8(%esp)
f01017b7:	89 d5                	mov    %edx,%ebp
f01017b9:	89 c7                	mov    %eax,%edi
f01017bb:	f7 64 24 0c          	mull   0xc(%esp)
f01017bf:	39 d5                	cmp    %edx,%ebp
f01017c1:	89 14 24             	mov    %edx,(%esp)
f01017c4:	72 11                	jb     f01017d7 <__udivdi3+0xc7>
f01017c6:	8b 54 24 04          	mov    0x4(%esp),%edx
f01017ca:	89 f1                	mov    %esi,%ecx
f01017cc:	d3 e2                	shl    %cl,%edx
f01017ce:	39 c2                	cmp    %eax,%edx
f01017d0:	73 5e                	jae    f0101830 <__udivdi3+0x120>
f01017d2:	3b 2c 24             	cmp    (%esp),%ebp
f01017d5:	75 59                	jne    f0101830 <__udivdi3+0x120>
f01017d7:	8d 47 ff             	lea    -0x1(%edi),%eax
f01017da:	31 f6                	xor    %esi,%esi
f01017dc:	89 f2                	mov    %esi,%edx
f01017de:	83 c4 10             	add    $0x10,%esp
f01017e1:	5e                   	pop    %esi
f01017e2:	5f                   	pop    %edi
f01017e3:	5d                   	pop    %ebp
f01017e4:	c3                   	ret    
f01017e5:	8d 76 00             	lea    0x0(%esi),%esi
f01017e8:	31 f6                	xor    %esi,%esi
f01017ea:	31 c0                	xor    %eax,%eax
f01017ec:	89 f2                	mov    %esi,%edx
f01017ee:	83 c4 10             	add    $0x10,%esp
f01017f1:	5e                   	pop    %esi
f01017f2:	5f                   	pop    %edi
f01017f3:	5d                   	pop    %ebp
f01017f4:	c3                   	ret    
f01017f5:	8d 76 00             	lea    0x0(%esi),%esi
f01017f8:	89 f2                	mov    %esi,%edx
f01017fa:	31 f6                	xor    %esi,%esi
f01017fc:	89 f8                	mov    %edi,%eax
f01017fe:	f7 f1                	div    %ecx
f0101800:	89 f2                	mov    %esi,%edx
f0101802:	83 c4 10             	add    $0x10,%esp
f0101805:	5e                   	pop    %esi
f0101806:	5f                   	pop    %edi
f0101807:	5d                   	pop    %ebp
f0101808:	c3                   	ret    
f0101809:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101810:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0101814:	76 0b                	jbe    f0101821 <__udivdi3+0x111>
f0101816:	31 c0                	xor    %eax,%eax
f0101818:	3b 14 24             	cmp    (%esp),%edx
f010181b:	0f 83 37 ff ff ff    	jae    f0101758 <__udivdi3+0x48>
f0101821:	b8 01 00 00 00       	mov    $0x1,%eax
f0101826:	e9 2d ff ff ff       	jmp    f0101758 <__udivdi3+0x48>
f010182b:	90                   	nop
f010182c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101830:	89 f8                	mov    %edi,%eax
f0101832:	31 f6                	xor    %esi,%esi
f0101834:	e9 1f ff ff ff       	jmp    f0101758 <__udivdi3+0x48>
f0101839:	66 90                	xchg   %ax,%ax
f010183b:	66 90                	xchg   %ax,%ax
f010183d:	66 90                	xchg   %ax,%ax
f010183f:	90                   	nop

f0101840 <__umoddi3>:
f0101840:	55                   	push   %ebp
f0101841:	57                   	push   %edi
f0101842:	56                   	push   %esi
f0101843:	83 ec 20             	sub    $0x20,%esp
f0101846:	8b 44 24 34          	mov    0x34(%esp),%eax
f010184a:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010184e:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101852:	89 c6                	mov    %eax,%esi
f0101854:	89 44 24 10          	mov    %eax,0x10(%esp)
f0101858:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010185c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0101860:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101864:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0101868:	89 74 24 18          	mov    %esi,0x18(%esp)
f010186c:	85 c0                	test   %eax,%eax
f010186e:	89 c2                	mov    %eax,%edx
f0101870:	75 1e                	jne    f0101890 <__umoddi3+0x50>
f0101872:	39 f7                	cmp    %esi,%edi
f0101874:	76 52                	jbe    f01018c8 <__umoddi3+0x88>
f0101876:	89 c8                	mov    %ecx,%eax
f0101878:	89 f2                	mov    %esi,%edx
f010187a:	f7 f7                	div    %edi
f010187c:	89 d0                	mov    %edx,%eax
f010187e:	31 d2                	xor    %edx,%edx
f0101880:	83 c4 20             	add    $0x20,%esp
f0101883:	5e                   	pop    %esi
f0101884:	5f                   	pop    %edi
f0101885:	5d                   	pop    %ebp
f0101886:	c3                   	ret    
f0101887:	89 f6                	mov    %esi,%esi
f0101889:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101890:	39 f0                	cmp    %esi,%eax
f0101892:	77 5c                	ja     f01018f0 <__umoddi3+0xb0>
f0101894:	0f bd e8             	bsr    %eax,%ebp
f0101897:	83 f5 1f             	xor    $0x1f,%ebp
f010189a:	75 64                	jne    f0101900 <__umoddi3+0xc0>
f010189c:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f01018a0:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f01018a4:	0f 86 f6 00 00 00    	jbe    f01019a0 <__umoddi3+0x160>
f01018aa:	3b 44 24 18          	cmp    0x18(%esp),%eax
f01018ae:	0f 82 ec 00 00 00    	jb     f01019a0 <__umoddi3+0x160>
f01018b4:	8b 44 24 14          	mov    0x14(%esp),%eax
f01018b8:	8b 54 24 18          	mov    0x18(%esp),%edx
f01018bc:	83 c4 20             	add    $0x20,%esp
f01018bf:	5e                   	pop    %esi
f01018c0:	5f                   	pop    %edi
f01018c1:	5d                   	pop    %ebp
f01018c2:	c3                   	ret    
f01018c3:	90                   	nop
f01018c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018c8:	85 ff                	test   %edi,%edi
f01018ca:	89 fd                	mov    %edi,%ebp
f01018cc:	75 0b                	jne    f01018d9 <__umoddi3+0x99>
f01018ce:	b8 01 00 00 00       	mov    $0x1,%eax
f01018d3:	31 d2                	xor    %edx,%edx
f01018d5:	f7 f7                	div    %edi
f01018d7:	89 c5                	mov    %eax,%ebp
f01018d9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01018dd:	31 d2                	xor    %edx,%edx
f01018df:	f7 f5                	div    %ebp
f01018e1:	89 c8                	mov    %ecx,%eax
f01018e3:	f7 f5                	div    %ebp
f01018e5:	eb 95                	jmp    f010187c <__umoddi3+0x3c>
f01018e7:	89 f6                	mov    %esi,%esi
f01018e9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01018f0:	89 c8                	mov    %ecx,%eax
f01018f2:	89 f2                	mov    %esi,%edx
f01018f4:	83 c4 20             	add    $0x20,%esp
f01018f7:	5e                   	pop    %esi
f01018f8:	5f                   	pop    %edi
f01018f9:	5d                   	pop    %ebp
f01018fa:	c3                   	ret    
f01018fb:	90                   	nop
f01018fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101900:	b8 20 00 00 00       	mov    $0x20,%eax
f0101905:	89 e9                	mov    %ebp,%ecx
f0101907:	29 e8                	sub    %ebp,%eax
f0101909:	d3 e2                	shl    %cl,%edx
f010190b:	89 c7                	mov    %eax,%edi
f010190d:	89 44 24 18          	mov    %eax,0x18(%esp)
f0101911:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101915:	89 f9                	mov    %edi,%ecx
f0101917:	d3 e8                	shr    %cl,%eax
f0101919:	89 c1                	mov    %eax,%ecx
f010191b:	8b 44 24 0c          	mov    0xc(%esp),%eax
f010191f:	09 d1                	or     %edx,%ecx
f0101921:	89 fa                	mov    %edi,%edx
f0101923:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101927:	89 e9                	mov    %ebp,%ecx
f0101929:	d3 e0                	shl    %cl,%eax
f010192b:	89 f9                	mov    %edi,%ecx
f010192d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101931:	89 f0                	mov    %esi,%eax
f0101933:	d3 e8                	shr    %cl,%eax
f0101935:	89 e9                	mov    %ebp,%ecx
f0101937:	89 c7                	mov    %eax,%edi
f0101939:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f010193d:	d3 e6                	shl    %cl,%esi
f010193f:	89 d1                	mov    %edx,%ecx
f0101941:	89 fa                	mov    %edi,%edx
f0101943:	d3 e8                	shr    %cl,%eax
f0101945:	89 e9                	mov    %ebp,%ecx
f0101947:	09 f0                	or     %esi,%eax
f0101949:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f010194d:	f7 74 24 10          	divl   0x10(%esp)
f0101951:	d3 e6                	shl    %cl,%esi
f0101953:	89 d1                	mov    %edx,%ecx
f0101955:	f7 64 24 0c          	mull   0xc(%esp)
f0101959:	39 d1                	cmp    %edx,%ecx
f010195b:	89 74 24 14          	mov    %esi,0x14(%esp)
f010195f:	89 d7                	mov    %edx,%edi
f0101961:	89 c6                	mov    %eax,%esi
f0101963:	72 0a                	jb     f010196f <__umoddi3+0x12f>
f0101965:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0101969:	73 10                	jae    f010197b <__umoddi3+0x13b>
f010196b:	39 d1                	cmp    %edx,%ecx
f010196d:	75 0c                	jne    f010197b <__umoddi3+0x13b>
f010196f:	89 d7                	mov    %edx,%edi
f0101971:	89 c6                	mov    %eax,%esi
f0101973:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0101977:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f010197b:	89 ca                	mov    %ecx,%edx
f010197d:	89 e9                	mov    %ebp,%ecx
f010197f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101983:	29 f0                	sub    %esi,%eax
f0101985:	19 fa                	sbb    %edi,%edx
f0101987:	d3 e8                	shr    %cl,%eax
f0101989:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f010198e:	89 d7                	mov    %edx,%edi
f0101990:	d3 e7                	shl    %cl,%edi
f0101992:	89 e9                	mov    %ebp,%ecx
f0101994:	09 f8                	or     %edi,%eax
f0101996:	d3 ea                	shr    %cl,%edx
f0101998:	83 c4 20             	add    $0x20,%esp
f010199b:	5e                   	pop    %esi
f010199c:	5f                   	pop    %edi
f010199d:	5d                   	pop    %ebp
f010199e:	c3                   	ret    
f010199f:	90                   	nop
f01019a0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01019a4:	29 f9                	sub    %edi,%ecx
f01019a6:	19 c6                	sbb    %eax,%esi
f01019a8:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f01019ac:	89 74 24 18          	mov    %esi,0x18(%esp)
f01019b0:	e9 ff fe ff ff       	jmp    f01018b4 <__umoddi3+0x74>
