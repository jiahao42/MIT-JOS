
obj/boot/boot.out:     file format elf32-i386


Disassembly of section .text:

00007a00 <start>:
.set CR0_PE_ON,      0x1         # protected mode enable flag

.globl start
start:
  .code16                     # Assemble for 16-bit mode
  cli                         # Disable interrupts
    7a00:	fa                   	cli    
  cld                         # String operations increment
    7a01:	fc                   	cld    

  # Set up the important data segment registers (DS, ES, SS).
  xorw    %ax,%ax             # Segment number zero
    7a02:	31 c0                	xor    %eax,%eax
  movw    %ax,%ds             # -> Data Segment
    7a04:	8e d8                	mov    %eax,%ds
  movw    %ax,%es             # -> Extra Segment
    7a06:	8e c0                	mov    %eax,%es
  movw    %ax,%ss             # -> Stack Segment
    7a08:	8e d0                	mov    %eax,%ss

00007a0a <seta20.1>:
  # Enable A20:
  #   For backwards compatibility with the earliest PCs, physical
  #   address line 20 is tied low, so that addresses higher than
  #   1MB wrap around to zero by default.  This code undoes this.
seta20.1:
  inb     $0x64,%al               # Wait for not busy
    7a0a:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7a0c:	a8 02                	test   $0x2,%al
  jnz     seta20.1
    7a0e:	75 fa                	jne    7a0a <seta20.1>

  movb    $0xd1,%al               # 0xd1 -> port 0x64
    7a10:	b0 d1                	mov    $0xd1,%al
  outb    %al,$0x64
    7a12:	e6 64                	out    %al,$0x64

00007a14 <seta20.2>:

seta20.2:
  inb     $0x64,%al               # Wait for not busy
    7a14:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7a16:	a8 02                	test   $0x2,%al
  jnz     seta20.2
    7a18:	75 fa                	jne    7a14 <seta20.2>

  movb    $0xdf,%al               # 0xdf -> port 0x60
    7a1a:	b0 df                	mov    $0xdf,%al
  outb    %al,$0x60
    7a1c:	e6 60                	out    %al,$0x60

  # Switch from real to protected mode, using a bootstrap GDT
  # and segment translation that makes virtual addresses 
  # identical to their physical addresses, so that the 
  # effective memory map does not change during the switch.
  lgdt    gdtdesc
    7a1e:	0f 01 16             	lgdtl  (%esi)
    7a21:	64                   	fs
    7a22:	7a 0f                	jp     7a33 <protcseg+0x1>
  movl    %cr0, %eax
    7a24:	20 c0                	and    %al,%al
  orl     $CR0_PE_ON, %eax
    7a26:	66 83 c8 01          	or     $0x1,%ax
  movl    %eax, %cr0
    7a2a:	0f 22 c0             	mov    %eax,%cr0
  
  # Jump to next instruction, but in 32-bit code segment.
  # Switches processor into 32-bit mode.
  ljmp    $PROT_MODE_CSEG, $protcseg
    7a2d:	ea 32 7a 08 00 66 b8 	ljmp   $0xb866,$0x87a32

00007a32 <protcseg>:

  .code32                     # Assemble for 32-bit mode
protcseg:
  # Set up the protected-mode data segment registers
  movw    $PROT_MODE_DSEG, %ax    # Our data segment selector
    7a32:	66 b8 10 00          	mov    $0x10,%ax
  movw    %ax, %ds                # -> DS: Data Segment
    7a36:	8e d8                	mov    %eax,%ds
  movw    %ax, %es                # -> ES: Extra Segment
    7a38:	8e c0                	mov    %eax,%es
  movw    %ax, %fs                # -> FS
    7a3a:	8e e0                	mov    %eax,%fs
  movw    %ax, %gs                # -> GS
    7a3c:	8e e8                	mov    %eax,%gs
  movw    %ax, %ss                # -> SS: Stack Segment
    7a3e:	8e d0                	mov    %eax,%ss
  
  # Set up the stack pointer and call into C.
  movl    $start, %esp
    7a40:	bc 00 7a 00 00       	mov    $0x7a00,%esp
  call bootmain
    7a45:	e8 c0 00 00 00       	call   7b0a <bootmain>

00007a4a <spin>:

  # If bootmain returns (it shouldn't), loop.
spin:
  jmp spin
    7a4a:	eb fe                	jmp    7a4a <spin>

00007a4c <gdt>:
	...
    7a54:	ff                   	(bad)  
    7a55:	ff 00                	incl   (%eax)
    7a57:	00 00                	add    %al,(%eax)
    7a59:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    7a60:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

00007a64 <gdtdesc>:
    7a64:	17                   	pop    %ss
    7a65:	00 4c 7a 00          	add    %cl,0x0(%edx,%edi,2)
	...

00007a6a <waitdisk>:
	}
}

void
waitdisk(void)
{
    7a6a:	55                   	push   %ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
    7a6b:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7a70:	89 e5                	mov    %esp,%ebp
    7a72:	ec                   	in     (%dx),%al
	// wait for disk reaady
	while ((inb(0x1F7) & 0xC0) != 0x40)
    7a73:	83 e0 c0             	and    $0xffffffc0,%eax
    7a76:	3c 40                	cmp    $0x40,%al
    7a78:	75 f8                	jne    7a72 <waitdisk+0x8>
		/* do nothing */;
}
    7a7a:	5d                   	pop    %ebp
    7a7b:	c3                   	ret    

00007a7c <readsect>:

void
readsect(void *dst, uint32_t offset)
{
    7a7c:	55                   	push   %ebp
    7a7d:	89 e5                	mov    %esp,%ebp
    7a7f:	57                   	push   %edi
    7a80:	53                   	push   %ebx
    7a81:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// wait for disk to be ready
	waitdisk();
    7a84:	e8 e1 ff ff ff       	call   7a6a <waitdisk>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
    7a89:	ba f2 01 00 00       	mov    $0x1f2,%edx
    7a8e:	b0 01                	mov    $0x1,%al
    7a90:	ee                   	out    %al,(%dx)
    7a91:	0f b6 c3             	movzbl %bl,%eax
    7a94:	b2 f3                	mov    $0xf3,%dl
    7a96:	ee                   	out    %al,(%dx)
    7a97:	0f b6 c7             	movzbl %bh,%eax
    7a9a:	b2 f4                	mov    $0xf4,%dl
    7a9c:	ee                   	out    %al,(%dx)

	outb(0x1F2, 1);		// count = 1
	outb(0x1F3, offset);
	outb(0x1F4, offset >> 8);
	outb(0x1F5, offset >> 16);
    7a9d:	89 d8                	mov    %ebx,%eax
    7a9f:	b2 f5                	mov    $0xf5,%dl
    7aa1:	c1 e8 10             	shr    $0x10,%eax
    7aa4:	0f b6 c0             	movzbl %al,%eax
    7aa7:	ee                   	out    %al,(%dx)
	outb(0x1F6, (offset >> 24) | 0xE0);
    7aa8:	c1 eb 18             	shr    $0x18,%ebx
    7aab:	b2 f6                	mov    $0xf6,%dl
    7aad:	88 d8                	mov    %bl,%al
    7aaf:	83 c8 e0             	or     $0xffffffe0,%eax
    7ab2:	ee                   	out    %al,(%dx)
    7ab3:	b0 20                	mov    $0x20,%al
    7ab5:	b2 f7                	mov    $0xf7,%dl
    7ab7:	ee                   	out    %al,(%dx)
	outb(0x1F7, 0x20);	// cmd 0x20 - read sectors

	// wait for disk to be ready
	waitdisk();
    7ab8:	e8 ad ff ff ff       	call   7a6a <waitdisk>
}

static __inline void
insl(int port, void *addr, int cnt)
{
	__asm __volatile("cld\n\trepne\n\tinsl"			:
    7abd:	8b 7d 08             	mov    0x8(%ebp),%edi
    7ac0:	b9 80 00 00 00       	mov    $0x80,%ecx
    7ac5:	ba f0 01 00 00       	mov    $0x1f0,%edx
    7aca:	fc                   	cld    
    7acb:	f2 6d                	repnz insl (%dx),%es:(%edi)

	// read a sector
	insl(0x1F0, dst, SECTSIZE/4);//read 4 bytes a time, need 128 times
}
    7acd:	5b                   	pop    %ebx
    7ace:	5f                   	pop    %edi
    7acf:	5d                   	pop    %ebp
    7ad0:	c3                   	ret    

00007ad1 <readseg>:
// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked
void
readseg(uint32_t pa, uint32_t count, uint32_t offset)//pa = 0x10000 count = 0x1000 offset = 0
//pa = 0x100000 count = 0x72ca offset = 0x1000
{
    7ad1:	55                   	push   %ebp
    7ad2:	89 e5                	mov    %esp,%ebp
    7ad4:	57                   	push   %edi
	uint32_t end_pa;

	end_pa = pa + count;//0x110000
    7ad5:	8b 7d 0c             	mov    0xc(%ebp),%edi
// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked
void
readseg(uint32_t pa, uint32_t count, uint32_t offset)//pa = 0x10000 count = 0x1000 offset = 0
//pa = 0x100000 count = 0x72ca offset = 0x1000
{
    7ad8:	56                   	push   %esi
    7ad9:	8b 75 10             	mov    0x10(%ebp),%esi
    7adc:	53                   	push   %ebx
    7add:	8b 5d 08             	mov    0x8(%ebp),%ebx
	
	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);//0x10000

	// translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;//1
    7ae0:	c1 ee 09             	shr    $0x9,%esi
readseg(uint32_t pa, uint32_t count, uint32_t offset)//pa = 0x10000 count = 0x1000 offset = 0
//pa = 0x100000 count = 0x72ca offset = 0x1000
{
	uint32_t end_pa;

	end_pa = pa + count;//0x110000
    7ae3:	01 df                	add    %ebx,%edi
	
	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);//0x10000

	// translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;//1
    7ae5:	46                   	inc    %esi
	uint32_t end_pa;

	end_pa = pa + count;//0x110000
	
	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);//0x10000
    7ae6:	81 e3 00 fe ff ff    	and    $0xfffffe00,%ebx
	offset = (offset / SECTSIZE) + 1;//1

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (pa < end_pa) {
    7aec:	39 fb                	cmp    %edi,%ebx
    7aee:	73 12                	jae    7b02 <readseg+0x31>
		// Since we haven't enabled paging yet and we're using
		// an identity segment mapping (see boot.S), we can
		// use physical addresses directly.  This won't be the
		// case once JOS enables the MMU.
		readsect((uint8_t*) pa, offset);
    7af0:	56                   	push   %esi
		pa += SECTSIZE;
		offset++;
    7af1:	46                   	inc    %esi
	while (pa < end_pa) {
		// Since we haven't enabled paging yet and we're using
		// an identity segment mapping (see boot.S), we can
		// use physical addresses directly.  This won't be the
		// case once JOS enables the MMU.
		readsect((uint8_t*) pa, offset);
    7af2:	53                   	push   %ebx
		pa += SECTSIZE;
    7af3:	81 c3 00 02 00 00    	add    $0x200,%ebx
	while (pa < end_pa) {
		// Since we haven't enabled paging yet and we're using
		// an identity segment mapping (see boot.S), we can
		// use physical addresses directly.  This won't be the
		// case once JOS enables the MMU.
		readsect((uint8_t*) pa, offset);
    7af9:	e8 7e ff ff ff       	call   7a7c <readsect>
		pa += SECTSIZE;
		offset++;
    7afe:	58                   	pop    %eax
    7aff:	5a                   	pop    %edx
    7b00:	eb ea                	jmp    7aec <readseg+0x1b>
	}
}
    7b02:	8d 65 f4             	lea    -0xc(%ebp),%esp
    7b05:	5b                   	pop    %ebx
    7b06:	5e                   	pop    %esi
    7b07:	5f                   	pop    %edi
    7b08:	5d                   	pop    %ebp
    7b09:	c3                   	ret    

00007b0a <bootmain>:
void readsect(void*, uint32_t);
void readseg(uint32_t, uint32_t, uint32_t);

void
bootmain(void)
{
    7b0a:	55                   	push   %ebp
    7b0b:	89 e5                	mov    %esp,%ebp
    7b0d:	56                   	push   %esi
    7b0e:	53                   	push   %ebx
	struct Proghdr *ph, *eph;

	// read 1st page off disk
	readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);
    7b0f:	6a 00                	push   $0x0
    7b11:	68 00 10 00 00       	push   $0x1000
    7b16:	68 00 00 01 00       	push   $0x10000
    7b1b:	e8 b1 ff ff ff       	call   7ad1 <readseg>

	// is this a valid ELF?
	if (ELFHDR->e_magic != ELF_MAGIC)
    7b20:	83 c4 0c             	add    $0xc,%esp
    7b23:	81 3d 00 00 01 00 7f 	cmpl   $0x464c457f,0x10000
    7b2a:	45 4c 46 
    7b2d:	75 38                	jne    7b67 <bootmain+0x5d>
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    7b2f:	a1 1c 00 01 00       	mov    0x1001c,%eax
    7b34:	8d 98 00 00 01 00    	lea    0x10000(%eax),%ebx
	eph = ph + ELFHDR->e_phnum;
    7b3a:	0f b7 05 2c 00 01 00 	movzwl 0x1002c,%eax
    7b41:	c1 e0 05             	shl    $0x5,%eax
    7b44:	8d 34 03             	lea    (%ebx,%eax,1),%esi
	for (; ph < eph; ph++)
    7b47:	39 f3                	cmp    %esi,%ebx
    7b49:	73 16                	jae    7b61 <bootmain+0x57>
		// p_pa is the load address of this segment (as well
		// as the physical address)
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
    7b4b:	ff 73 04             	pushl  0x4(%ebx)
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	for (; ph < eph; ph++)
    7b4e:	83 c3 20             	add    $0x20,%ebx
		// p_pa is the load address of this segment (as well
		// as the physical address)
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
    7b51:	ff 73 f4             	pushl  -0xc(%ebx)
    7b54:	ff 73 ec             	pushl  -0x14(%ebx)
    7b57:	e8 75 ff ff ff       	call   7ad1 <readseg>
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	for (; ph < eph; ph++)
    7b5c:	83 c4 0c             	add    $0xc,%esp
    7b5f:	eb e6                	jmp    7b47 <bootmain+0x3d>
		// as the physical address)
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);

	// call the entry point from the ELF header
	// note: does not return!
	((void (*)(void)) (ELFHDR->e_entry))();
    7b61:	ff 15 18 00 01 00    	call   *0x10018
}

static __inline void
outw(int port, uint16_t data)
{
	__asm __volatile("outw %0,%w1" : : "a" (data), "d" (port));
    7b67:	ba 00 8a 00 00       	mov    $0x8a00,%edx
    7b6c:	b8 00 8a ff ff       	mov    $0xffff8a00,%eax
    7b71:	66 ef                	out    %ax,(%dx)
    7b73:	b8 00 8e ff ff       	mov    $0xffff8e00,%eax
    7b78:	66 ef                	out    %ax,(%dx)
    7b7a:	eb fe                	jmp    7b7a <bootmain+0x70>
