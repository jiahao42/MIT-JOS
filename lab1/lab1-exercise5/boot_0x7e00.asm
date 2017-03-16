
obj/boot/boot.out:     file format elf32-i386


Disassembly of section .text:

00007e00 <start>:
.set CR0_PE_ON,      0x1         # protected mode enable flag

.globl start
start:
  .code16                     # Assemble for 16-bit mode
  cli                         # Disable interrupts
    7e00:	fa                   	cli    
  cld                         # String operations increment
    7e01:	fc                   	cld    

  # Set up the important data segment registers (DS, ES, SS).
  xorw    %ax,%ax             # Segment number zero
    7e02:	31 c0                	xor    %eax,%eax
  movw    %ax,%ds             # -> Data Segment
    7e04:	8e d8                	mov    %eax,%ds
  movw    %ax,%es             # -> Extra Segment
    7e06:	8e c0                	mov    %eax,%es
  movw    %ax,%ss             # -> Stack Segment
    7e08:	8e d0                	mov    %eax,%ss

00007e0a <seta20.1>:
  # Enable A20:
  #   For backwards compatibility with the earliest PCs, physical
  #   address line 20 is tied low, so that addresses higher than
  #   1MB wrap around to zero by default.  This code undoes this.
seta20.1:
  inb     $0x64,%al               # Wait for not busy
    7e0a:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7e0c:	a8 02                	test   $0x2,%al
  jnz     seta20.1
    7e0e:	75 fa                	jne    7e0a <seta20.1>

  movb    $0xd1,%al               # 0xd1 -> port 0x64
    7e10:	b0 d1                	mov    $0xd1,%al
  outb    %al,$0x64
    7e12:	e6 64                	out    %al,$0x64

00007e14 <seta20.2>:

seta20.2:
  inb     $0x64,%al               # Wait for not busy
    7e14:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7e16:	a8 02                	test   $0x2,%al
  jnz     seta20.2
    7e18:	75 fa                	jne    7e14 <seta20.2>

  movb    $0xdf,%al               # 0xdf -> port 0x60
    7e1a:	b0 df                	mov    $0xdf,%al
  outb    %al,$0x60
    7e1c:	e6 60                	out    %al,$0x60

  # Switch from real to protected mode, using a bootstrap GDT
  # and segment translation that makes virtual addresses 
  # identical to their physical addresses, so that the 
  # effective memory map does not change during the switch.
  lgdt    gdtdesc
    7e1e:	0f 01 16             	lgdtl  (%esi)
    7e21:	64                   	fs
    7e22:	7e 0f                	jle    7e33 <protcseg+0x1>
  movl    %cr0, %eax
    7e24:	20 c0                	and    %al,%al
  orl     $CR0_PE_ON, %eax
    7e26:	66 83 c8 01          	or     $0x1,%ax
  movl    %eax, %cr0
    7e2a:	0f 22 c0             	mov    %eax,%cr0
  
  # Jump to next instruction, but in 32-bit code segment.
  # Switches processor into 32-bit mode.
  ljmp    $PROT_MODE_CSEG, $protcseg
    7e2d:	ea 32 7e 08 00 66 b8 	ljmp   $0xb866,$0x87e32

00007e32 <protcseg>:

  .code32                     # Assemble for 32-bit mode
protcseg:
  # Set up the protected-mode data segment registers
  movw    $PROT_MODE_DSEG, %ax    # Our data segment selector
    7e32:	66 b8 10 00          	mov    $0x10,%ax
  movw    %ax, %ds                # -> DS: Data Segment
    7e36:	8e d8                	mov    %eax,%ds
  movw    %ax, %es                # -> ES: Extra Segment
    7e38:	8e c0                	mov    %eax,%es
  movw    %ax, %fs                # -> FS
    7e3a:	8e e0                	mov    %eax,%fs
  movw    %ax, %gs                # -> GS
    7e3c:	8e e8                	mov    %eax,%gs
  movw    %ax, %ss                # -> SS: Stack Segment
    7e3e:	8e d0                	mov    %eax,%ss
  
  # Set up the stack pointer and call into C.
  movl    $start, %esp
    7e40:	bc 00 7e 00 00       	mov    $0x7e00,%esp
  call bootmain
    7e45:	e8 c0 00 00 00       	call   7f0a <bootmain>

00007e4a <spin>:

  # If bootmain returns (it shouldn't), loop.
spin:
  jmp spin
    7e4a:	eb fe                	jmp    7e4a <spin>

00007e4c <gdt>:
	...
    7e54:	ff                   	(bad)  
    7e55:	ff 00                	incl   (%eax)
    7e57:	00 00                	add    %al,(%eax)
    7e59:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    7e60:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

00007e64 <gdtdesc>:
    7e64:	17                   	pop    %ss
    7e65:	00 4c 7e 00          	add    %cl,0x0(%esi,%edi,2)
	...

00007e6a <waitdisk>:
	}
}

void
waitdisk(void)
{
    7e6a:	55                   	push   %ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
    7e6b:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7e70:	89 e5                	mov    %esp,%ebp
    7e72:	ec                   	in     (%dx),%al
	// wait for disk reaady
	while ((inb(0x1F7) & 0xC0) != 0x40)
    7e73:	83 e0 c0             	and    $0xffffffc0,%eax
    7e76:	3c 40                	cmp    $0x40,%al
    7e78:	75 f8                	jne    7e72 <waitdisk+0x8>
		/* do nothing */;
}
    7e7a:	5d                   	pop    %ebp
    7e7b:	c3                   	ret    

00007e7c <readsect>:

void
readsect(void *dst, uint32_t offset)
{
    7e7c:	55                   	push   %ebp
    7e7d:	89 e5                	mov    %esp,%ebp
    7e7f:	57                   	push   %edi
    7e80:	53                   	push   %ebx
    7e81:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// wait for disk to be ready
	waitdisk();
    7e84:	e8 e1 ff ff ff       	call   7e6a <waitdisk>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
    7e89:	ba f2 01 00 00       	mov    $0x1f2,%edx
    7e8e:	b0 01                	mov    $0x1,%al
    7e90:	ee                   	out    %al,(%dx)
    7e91:	0f b6 c3             	movzbl %bl,%eax
    7e94:	b2 f3                	mov    $0xf3,%dl
    7e96:	ee                   	out    %al,(%dx)
    7e97:	0f b6 c7             	movzbl %bh,%eax
    7e9a:	b2 f4                	mov    $0xf4,%dl
    7e9c:	ee                   	out    %al,(%dx)

	outb(0x1F2, 1);		// count = 1
	outb(0x1F3, offset);
	outb(0x1F4, offset >> 8);
	outb(0x1F5, offset >> 16);
    7e9d:	89 d8                	mov    %ebx,%eax
    7e9f:	b2 f5                	mov    $0xf5,%dl
    7ea1:	c1 e8 10             	shr    $0x10,%eax
    7ea4:	0f b6 c0             	movzbl %al,%eax
    7ea7:	ee                   	out    %al,(%dx)
	outb(0x1F6, (offset >> 24) | 0xE0);
    7ea8:	c1 eb 18             	shr    $0x18,%ebx
    7eab:	b2 f6                	mov    $0xf6,%dl
    7ead:	88 d8                	mov    %bl,%al
    7eaf:	83 c8 e0             	or     $0xffffffe0,%eax
    7eb2:	ee                   	out    %al,(%dx)
    7eb3:	b0 20                	mov    $0x20,%al
    7eb5:	b2 f7                	mov    $0xf7,%dl
    7eb7:	ee                   	out    %al,(%dx)
	outb(0x1F7, 0x20);	// cmd 0x20 - read sectors

	// wait for disk to be ready
	waitdisk();
    7eb8:	e8 ad ff ff ff       	call   7e6a <waitdisk>
}

static __inline void
insl(int port, void *addr, int cnt)
{
	__asm __volatile("cld\n\trepne\n\tinsl"			:
    7ebd:	8b 7d 08             	mov    0x8(%ebp),%edi
    7ec0:	b9 80 00 00 00       	mov    $0x80,%ecx
    7ec5:	ba f0 01 00 00       	mov    $0x1f0,%edx
    7eca:	fc                   	cld    
    7ecb:	f2 6d                	repnz insl (%dx),%es:(%edi)

	// read a sector
	insl(0x1F0, dst, SECTSIZE/4);//read 4 bytes a time, need 128 times
}
    7ecd:	5b                   	pop    %ebx
    7ece:	5f                   	pop    %edi
    7ecf:	5d                   	pop    %ebp
    7ed0:	c3                   	ret    

00007ed1 <readseg>:
// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked
void
readseg(uint32_t pa, uint32_t count, uint32_t offset)//pa = 0x10000 count = 0x1000 offset = 0
//pa = 0x100000 count = 0x72ca offset = 0x1000
{
    7ed1:	55                   	push   %ebp
    7ed2:	89 e5                	mov    %esp,%ebp
    7ed4:	57                   	push   %edi
	uint32_t end_pa;

	end_pa = pa + count;//0x110000
    7ed5:	8b 7d 0c             	mov    0xc(%ebp),%edi
// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked
void
readseg(uint32_t pa, uint32_t count, uint32_t offset)//pa = 0x10000 count = 0x1000 offset = 0
//pa = 0x100000 count = 0x72ca offset = 0x1000
{
    7ed8:	56                   	push   %esi
    7ed9:	8b 75 10             	mov    0x10(%ebp),%esi
    7edc:	53                   	push   %ebx
    7edd:	8b 5d 08             	mov    0x8(%ebp),%ebx
	
	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);//0x10000

	// translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;//1
    7ee0:	c1 ee 09             	shr    $0x9,%esi
readseg(uint32_t pa, uint32_t count, uint32_t offset)//pa = 0x10000 count = 0x1000 offset = 0
//pa = 0x100000 count = 0x72ca offset = 0x1000
{
	uint32_t end_pa;

	end_pa = pa + count;//0x110000
    7ee3:	01 df                	add    %ebx,%edi
	
	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);//0x10000

	// translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;//1
    7ee5:	46                   	inc    %esi
	uint32_t end_pa;

	end_pa = pa + count;//0x110000
	
	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);//0x10000
    7ee6:	81 e3 00 fe ff ff    	and    $0xfffffe00,%ebx
	offset = (offset / SECTSIZE) + 1;//1

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (pa < end_pa) {
    7eec:	39 fb                	cmp    %edi,%ebx
    7eee:	73 12                	jae    7f02 <readseg+0x31>
		// Since we haven't enabled paging yet and we're using
		// an identity segment mapping (see boot.S), we can
		// use physical addresses directly.  This won't be the
		// case once JOS enables the MMU.
		readsect((uint8_t*) pa, offset);
    7ef0:	56                   	push   %esi
		pa += SECTSIZE;
		offset++;
    7ef1:	46                   	inc    %esi
	while (pa < end_pa) {
		// Since we haven't enabled paging yet and we're using
		// an identity segment mapping (see boot.S), we can
		// use physical addresses directly.  This won't be the
		// case once JOS enables the MMU.
		readsect((uint8_t*) pa, offset);
    7ef2:	53                   	push   %ebx
		pa += SECTSIZE;
    7ef3:	81 c3 00 02 00 00    	add    $0x200,%ebx
	while (pa < end_pa) {
		// Since we haven't enabled paging yet and we're using
		// an identity segment mapping (see boot.S), we can
		// use physical addresses directly.  This won't be the
		// case once JOS enables the MMU.
		readsect((uint8_t*) pa, offset);
    7ef9:	e8 7e ff ff ff       	call   7e7c <readsect>
		pa += SECTSIZE;
		offset++;
    7efe:	58                   	pop    %eax
    7eff:	5a                   	pop    %edx
    7f00:	eb ea                	jmp    7eec <readseg+0x1b>
	}
}
    7f02:	8d 65 f4             	lea    -0xc(%ebp),%esp
    7f05:	5b                   	pop    %ebx
    7f06:	5e                   	pop    %esi
    7f07:	5f                   	pop    %edi
    7f08:	5d                   	pop    %ebp
    7f09:	c3                   	ret    

00007f0a <bootmain>:
void readsect(void*, uint32_t);
void readseg(uint32_t, uint32_t, uint32_t);

void
bootmain(void)
{
    7f0a:	55                   	push   %ebp
    7f0b:	89 e5                	mov    %esp,%ebp
    7f0d:	56                   	push   %esi
    7f0e:	53                   	push   %ebx
	struct Proghdr *ph, *eph;

	// read 1st page off disk
	readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);
    7f0f:	6a 00                	push   $0x0
    7f11:	68 00 10 00 00       	push   $0x1000
    7f16:	68 00 00 01 00       	push   $0x10000
    7f1b:	e8 b1 ff ff ff       	call   7ed1 <readseg>

	// is this a valid ELF?
	if (ELFHDR->e_magic != ELF_MAGIC)
    7f20:	83 c4 0c             	add    $0xc,%esp
    7f23:	81 3d 00 00 01 00 7f 	cmpl   $0x464c457f,0x10000
    7f2a:	45 4c 46 
    7f2d:	75 38                	jne    7f67 <bootmain+0x5d>
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    7f2f:	a1 1c 00 01 00       	mov    0x1001c,%eax
    7f34:	8d 98 00 00 01 00    	lea    0x10000(%eax),%ebx
	eph = ph + ELFHDR->e_phnum;
    7f3a:	0f b7 05 2c 00 01 00 	movzwl 0x1002c,%eax
    7f41:	c1 e0 05             	shl    $0x5,%eax
    7f44:	8d 34 03             	lea    (%ebx,%eax,1),%esi
	for (; ph < eph; ph++)
    7f47:	39 f3                	cmp    %esi,%ebx
    7f49:	73 16                	jae    7f61 <bootmain+0x57>
		// p_pa is the load address of this segment (as well
		// as the physical address)
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
    7f4b:	ff 73 04             	pushl  0x4(%ebx)
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	for (; ph < eph; ph++)
    7f4e:	83 c3 20             	add    $0x20,%ebx
		// p_pa is the load address of this segment (as well
		// as the physical address)
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
    7f51:	ff 73 f4             	pushl  -0xc(%ebx)
    7f54:	ff 73 ec             	pushl  -0x14(%ebx)
    7f57:	e8 75 ff ff ff       	call   7ed1 <readseg>
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	for (; ph < eph; ph++)
    7f5c:	83 c4 0c             	add    $0xc,%esp
    7f5f:	eb e6                	jmp    7f47 <bootmain+0x3d>
		// as the physical address)
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);

	// call the entry point from the ELF header
	// note: does not return!
	((void (*)(void)) (ELFHDR->e_entry))();
    7f61:	ff 15 18 00 01 00    	call   *0x10018
}

static __inline void
outw(int port, uint16_t data)
{
	__asm __volatile("outw %0,%w1" : : "a" (data), "d" (port));
    7f67:	ba 00 8a 00 00       	mov    $0x8a00,%edx
    7f6c:	b8 00 8a ff ff       	mov    $0xffff8a00,%eax
    7f71:	66 ef                	out    %ax,(%dx)
    7f73:	b8 00 8e ff ff       	mov    $0xffff8e00,%eax
    7f78:	66 ef                	out    %ax,(%dx)
    7f7a:	eb fe                	jmp    7f7a <bootmain+0x70>
