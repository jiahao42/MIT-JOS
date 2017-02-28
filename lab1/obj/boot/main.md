```
main.o:     file format elf32-i386


Disassembly of section .text:

00000000 <waitdisk>:
   0:	55                   	push   %ebp ; don't need to start new frame
   1:	ba f7 01 00 00       	mov    $0x1f7,%edx
   6:	89 e5                	mov    %esp,%ebp
   8:	ec                   	in     (%dx),%al
   9:	83 e0 c0             	and    $0xffffffc0,%eax
   c:	3c 40                	cmp    $0x40,%al
   e:	75 f8                	jne    8 <waitdisk+0x8>
  10:	5d                   	pop    %ebp
  11:	c3                   	ret    

00000012 <readsect>:
  12:	55                   	push   %ebp
  13:	89 e5                	mov    %esp,%ebp ; start a new stack frame
  15:	57                   	push   %edi 
  16:	53                   	push   %ebx ; save the value
  17:	8b 5d 0c             	mov    0xc(%ebp),%ebx ; ebx = 1
  1a:	e8 fc ff ff ff       	call   1b <readsect+0x9> ; call waitdisk
  1f:	ba f2 01 00 00       	mov    $0x1f2,%edx ;; start to manipulate devices
  24:	b0 01                	mov    $0x1,%al
  26:	ee                   	out    %al,(%dx)
  27:	0f b6 c3             	movzbl %bl,%eax
  2a:	b2 f3                	mov    $0xf3,%dl
  2c:	ee                   	out    %al,(%dx)
  2d:	0f b6 c7             	movzbl %bh,%eax
  30:	b2 f4                	mov    $0xf4,%dl
  32:	ee                   	out    %al,(%dx)
  33:	89 d8                	mov    %ebx,%eax
  35:	b2 f5                	mov    $0xf5,%dl
  37:	c1 e8 10             	shr    $0x10,%eax
  3a:	0f b6 c0             	movzbl %al,%eax
  3d:	ee                   	out    %al,(%dx)
  3e:	c1 eb 18             	shr    $0x18,%ebx
  41:	b2 f6                	mov    $0xf6,%dl
  43:	88 d8                	mov    %bl,%al
  45:	83 c8 e0             	or     $0xffffffe0,%eax
  48:	ee                   	out    %al,(%dx)
  49:	b0 20                	mov    $0x20,%al
  4b:	b2 f7                	mov    $0xf7,%dl
  4d:	ee                   	out    %al,(%dx) ;; end of manipulating devices
  4e:	e8 fc ff ff ff       	call   4f <readsect+0x3d> ; call waitdisk
  53:	8b 7d 08             	mov    0x8(%ebp),%edi ; edi = 0x11000
  56:	b9 80 00 00 00       	mov    $0x80,%ecx ; ecx = 0x80
  5b:	ba f0 01 00 00       	mov    $0x1f0,%edx ; edx = 0x1f0
  60:	fc                   	cld    ; df = 0
  61:	f2 6d                	repnz insl (%dx),%es:(%edi) ; edi=0x10000 at first
  63:	5b                   	pop    %ebx
  64:	5f                   	pop    %edi
  65:	5d                   	pop    %ebp
  66:	c3                   	ret    

00000067 <readseg>:
  67:	55                   	push   %ebp
  68:	89 e5                	mov    %esp,%ebp ; start new stack frame
  6a:	57                   	push   %edi ; save the value
  6b:	8b 7d 0c             	mov    0xc(%ebp),%edi ; edi = 0x1000
  6e:	56                   	push   %esi ; esi = 0
  6f:	8b 75 10             	mov    0x10(%ebp),%esi ; esi = 0
  72:	53                   	push   %ebx ; ebx = 0
  73:	8b 5d 08             	mov    0x8(%ebp),%ebx ; ebx = 0x10000
  76:	c1 ee 09             	shr    $0x9,%esi ; esi = 0x200 = 512
  79:	01 df                	add    %ebx,%edi ; edi = 0x11000
  7b:	46                   	inc    %esi ; esi = 0x1
  7c:	81 e3 00 fe ff ff    	and    $0xfffffe00,%ebx ; ebx = 0x10000
  82:	39 fb                	cmp    %edi,%ebx ; 0x11000 > 0x10000
  84:	73 12                	jae    98 <readseg+0x31> 
  86:	56                   	push   %esi ; offset = 1
  87:	46                   	inc    %esi
  88:	53                   	push   %ebx ; pa = 0x10000
  89:	81 c3 00 02 00 00    	add    $0x200,%ebx ; why?
  8f:	e8 fc ff ff ff       	call   90 <readseg+0x29> ; call readsect
  94:	58                   	pop    %eax
  95:	5a                   	pop    %edx
  96:	eb ea                	jmp    82 <readseg+0x1b>
  98:	8d 65 f4             	lea    -0xc(%ebp),%esp
  9b:	5b                   	pop    %ebx
  9c:	5e                   	pop    %esi
  9d:	5f                   	pop    %edi
  9e:	5d                   	pop    %ebp
  9f:	c3                   	ret    

000000a0 <bootmain>:
  a0:	55                   	push   %ebp 
  a1:	89 e5                	mov    %esp,%ebp ;start new stack frame
  a3:	56                   	push   %esi
  a4:	53                   	push   %ebx ; save the value
  a5:	6a 00                	push   $0x0
  a7:	68 00 10 00 00       	push   $0x1000
  ac:	68 00 00 01 00       	push   $0x10000 ; push 3 parameters
  b1:	e8 fc ff ff ff       	call   b2 <bootmain+0x12> ; jmp to readseg
  b6:	83 c4 0c             	add    $0xc,%esp ; fix stack
  b9:	81 3d 00 00 01 00 7f 	cmpl   $0x464c457f,0x10000
  c0:	45 4c 46 
  c3:	75 38                	jne    fd <bootmain+0x5d>
  c5:	a1 1c 00 01 00       	mov    0x1001c,%eax
  ca:	8d 98 00 00 01 00    	lea    0x10000(%eax),%ebx
  d0:	0f b7 05 2c 00 01 00 	movzwl 0x1002c,%eax
  d7:	c1 e0 05             	shl    $0x5,%eax
  da:	8d 34 03             	lea    (%ebx,%eax,1),%esi
  dd:	39 f3                	cmp    %esi,%ebx
  df:	73 16                	jae    f7 <bootmain+0x57>
  e1:	ff 73 04             	pushl  0x4(%ebx)
  e4:	83 c3 20             	add    $0x20,%ebx
  e7:	ff 73 f4             	pushl  -0xc(%ebx)
  ea:	ff 73 ec             	pushl  -0x14(%ebx)
  ed:	e8 fc ff ff ff       	call   ee <bootmain+0x4e>
  f2:	83 c4 0c             	add    $0xc,%esp
  f5:	eb e6                	jmp    dd <bootmain+0x3d>
  f7:	ff 15 18 00 01 00    	call   *0x10018
  fd:	ba 00 8a 00 00       	mov    $0x8a00,%edx
 102:	b8 00 8a ff ff       	mov    $0xffff8a00,%eax
 107:	66 ef                	out    %ax,(%dx)
 109:	b8 00 8e ff ff       	mov    $0xffff8e00,%eax
 10e:	66 ef                	out    %ax,(%dx)
 110:	eb fe                	jmp    110 <bootmain+0x70>
 ```
