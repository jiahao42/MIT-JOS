
boot.o:     file format elf32-i386


Disassembly of section .text:

00000000 <start>:
   0:	fa                   	cli    
   1:	fc                   	cld    
   2:	31 c0                	xor    %eax,%eax
   4:	8e d8                	mov    %eax,%ds
   6:	8e c0                	mov    %eax,%es
   8:	8e d0                	mov    %eax,%ss

0000000a <seta20.1>:
   a:	e4 64                	in     $0x64,%al
   c:	a8 02                	test   $0x2,%al
   e:	75 fa                	jne    a <seta20.1>
  10:	b0 d1                	mov    $0xd1,%al
  12:	e6 64                	out    %al,$0x64

00000014 <seta20.2>:
  14:	e4 64                	in     $0x64,%al
  16:	a8 02                	test   $0x2,%al
  18:	75 fa                	jne    14 <seta20.2>
  1a:	b0 df                	mov    $0xdf,%al
  1c:	e6 60                	out    %al,$0x60
  1e:	0f 01 16             	lgdtl  (%esi)
  21:	64 00 0f             	add    %cl,%fs:(%edi)
  24:	20 c0                	and    %al,%al
  26:	66 83 c8 01          	or     $0x1,%ax
  2a:	0f 22 c0             	mov    %eax,%cr0
  2d:	ea 32 00 08 00 66 b8 	ljmp   $0xb866,$0x80032

00000032 <protcseg>:
  32:	66 b8 10 00          	mov    $0x10,%ax
  36:	8e d8                	mov    %eax,%ds
  38:	8e c0                	mov    %eax,%es
  3a:	8e e0                	mov    %eax,%fs
  3c:	8e e8                	mov    %eax,%gs
  3e:	8e d0                	mov    %eax,%ss
  40:	bc 00 00 00 00       	mov    $0x0,%esp
  45:	e8 fc ff ff ff       	call   46 <protcseg+0x14>

0000004a <spin>:
  4a:	eb fe                	jmp    4a <spin>

0000004c <gdt>:
	...
  54:	ff                   	(bad)  
  55:	ff 00                	incl   (%eax)
  57:	00 00                	add    %al,(%eax)
  59:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
  60:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

00000064 <gdtdesc>:
  64:	17                   	pop    %ss
  65:	00 4c 00 00          	add    %cl,0x0(%eax,%eax,1)
	...
