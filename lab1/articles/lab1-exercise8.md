## lab1-exercise 8

> Exercise 8. We have omitted a small fragment of code - the code necessary to print octal numbers using patterns of the form "%o". Find and fill in this code fragment.

---

### I will explain `console.c`, `stdio.h`, and `print.c && printfmt.c` separately.

* ### console.c

First, let's focus on `General device-independent console code` starts from line 376 in `console.c`, because this is much better to understand without too much detail with the hardwares.
A struct is used to represent the circular input buffer of console, check circular buffer [here](https://en.wikipedia.org/wiki/Circular_buffer):

```C
#define CONSBUFSIZE 512
static struct {
	uint8_t buf[CONSBUFSIZE];
	uint32_t rpos; // read position
	uint32_t wpos; // write position
} cons;
```
And here comes a function `static void cons_intr(int (*proc)(void))`, we can see that a function is passed to `cons_intr` through [function pointer](https://en.wikipedia.org/wiki/Function_pointer). `serial_intr(void)` and `kbd_intr(void)` invoke `cons_intr`.

**First let's see how `serial_intr(void)` works.**

```C
void serial_intr(void)
{
	if (serial_exists)
		cons_intr(serial_proc_data);//pass serial_proc_data to cons_intr
}
static int serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
	return inb(COM1+COM_RX);
}
```

We can see that actually the implementation code is in `int serial_proc_data(void)`, and it read character from `COM1+COM_LSR`, and then return it,  check the ports in the code :

```C
#define COM1		0x3F8
#define COM_LSR		5	// In:	Line Status Register
#define   COM_LSR_DATA	0x01	//   Data available
#define COM_RX		0	// In:	Receive buffer (DLAB=0)
```

We can check what the ports do [here](http://bochs.sourceforge.net/techspec/PORTS.LST):

```plain
03F8	w	serial port, transmitter holding register, which contains the
		character to be sent. Bit 0 is sent first.
		 bit 7-0   data bits when DLAB=0 (Divisor Latch Access Bit)
		r	receiver buffer register, which contains the received character
		Bit 0 is received first
		 bit 7-0   data bits when DLAB=0 (Divisor Latch Access Bit)
		r/w	divisor latch low byte when DLAB=1
03FD	r	line status register
		...
		bit 0 = 1  data ready. a complete incoming character has been
			    received and sent to the receiver buffer register.
```

This is what `serial_proc_data(void)` does:
**It check if the data is ready, if ready, return the character, if not, return -1 instead.**

Also, we can figure out what `cons_intr` does, when the parameter is `int serial_proc_data(void)`, basically, it write data which is read from port `03F8` to the struct `cons`.

**Now let's turn to `void kbd_intr(void)` to see what happens.**
`kbd_intr` passes `int kbd_proc_data(void)` as the parameter to the `cons_intr`, as the name `kbd_proc_data` indicates, this function is used to process the character read from keyboard, and return the character. `kbd_proc_data` is very charming, you can see how `CapsLock` and `Ctrl + Alt + Del` work here, and I am sure [this material](https://www.win.tue.nl/~aeb/linux/kbd/scancodes-1.html) will help a lot.

**Now we can look back to see what `cons_intr` does.** 
Basically, it reads character from serial(using `serial_proc_data`) and keyboard(using `kbd_proc_data`), and write characters to the buffer, maintaining the circular input buffer of console at the same time.

```C
// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		cons.buf[cons.wpos++] = c; // write the character to the buffer
		if (cons.wpos == CONSBUFSIZE) // if the buffer is full, restart from the start of the buffer
			cons.wpos = 0;
	}
}
```

**Here comes the next function I am going to talk about `int cons_getc(void)`**

Different from `cons_intr` we have talked about before, on the contrary, `cons_getc` is used for reading characters from the circular input buffer of console, not writing to it.

```C
// return the next input character from the console, or 0 if none waiting
int cons_getc(void)
{
	int c;

	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) { // if rpos == wpos, the buffer is empty
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE) // restart from start of buffer
			cons.rpos = 0;
		return c;
	}
	return 0; // return 0 if buffer is empty
}
```

And finally I decide to simply list the function of the functions left in `console.c`: 

* **`static void cons_putc(int c)` :** output a character to the console, including CGA, keyboard and serial.

* **`void cons_init(void)` :** initialize the console devices, including CGA, keyboard and serial.

* **`void cputchar(int c)` :** a wrap of `static void cons_putc(int c)`, same function.

* **`int getchar(void)` :** invokes `int cons_getc(void)`, grab character from buffer, if the buffer is empty and 0 returns, wait until a character returns.

* **`int iscons(int fdnum)` :** I'm not sure what this is used for, I think it receives a file descriptor and return if it is a console, buf I did not see any code but `return 1` in this function, can't figure out why for now.

* ### stdio.h

`inc/stdio.h` declares a series of `printf`, such as:

```C
// lib/printfmt.c
void	printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);
void	vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list);
int	snprintf(char *str, int size, const char *fmt, ...);
int	vsnprintf(char *str, int size, const char *fmt, va_list);

// lib/printf.c
int	cprintf(const char *fmt, ...);
int	vcprintf(const char *fmt, va_list);
```

And as the comments above show, these functions are implemented in some files at `lib` folder, so I am going to check those files.

However, there are some strange things:

* `lib/stdio.c` doesn't exist.
* `printf.c` is not in `lib`, it is in `kern` folder instead.
* `fprintf.c` doesn't exist.

According to the comments from the top of `print.c`:

> // Simple implementation of cprintf console output for the kernel,

> // based on printfmt() and the kernel console's cputchar().

`print.c` is based on `printfmt.c`, I would like to check these two files upside down, so I decide to check `lib/print.c` first.

* ### print.c && printfmt.c

First, let's see how `int cprintf(const char *fmt, ...)` works, you need to know the [usage of variable argument](http://www.cprogramming.com/tutorial/c/lesson17.html) and the [layout of va](http://stackoverflow.com/questions/12371450/how-are-variable-arguments-implemented-in-gcc):

```C
static void putch(int ch, int *cnt)
{
	cputchar(ch); // output character to console
	*cnt++;
}

int vcprintf(const char *fmt, va_list ap)
{
	int cnt = 0;

	vprintfmt((void*)putch, &cnt, fmt, ap);
	return cnt;
}

int cprintf(const char *fmt, ...) // fmt == format, such as %p, %d ...
{
	va_list ap;
	int cnt; // how many characters are output to console

	va_start(ap, fmt); // initializes the va_list
	cnt = vcprintf(fmt, ap);
	va_end(ap);

	return cnt;
}
```

Apprently, the code in `print.c` basically processes the variable arguments, and passes a output function, leads to `vprintfmt` in `printfmt.c`, so it is time to check `vprintfmt` in `printfmt.c`.

**The main skeleton of `vprintfmt` :**

#### Attention: the omitted fragment of code is here, we are going to solve exercise8 right now!!!

```C
while (1) {
	while ((ch = *(unsigned char *) fmt++) != '%') { // if it is not a format sign, just output it to the console
		if (ch == '\0')
			return;
		putch(ch, putdat); // output it
	}
	reswitch:
		switch (ch = *(unsigned char *) fmt++) { // if it is a format sign, check the character after '%', and processes it
		case '-':
			...
		case '%':
			...
		case 'd':
			...
		case 's':
			...
		case 'o': // here is where we need to fix in exercise8
			num = getuint(&ap, lflag);
			base = 8;
			goto number;
			break;
		...
	}
}
```



---


### Be able to answer the following questions:

### 1. Explain the interface between printf.c and console.c. Specifically, what function does console.c export? How is this function used by printf.c?

`console.c` exports three **'High'-level console I/O** function:

* `void cputchar(int c)`
* `int getchar(void)` 
*  `int iscons(int fdnum)`

`static void putch(int ch, int *cnt)` in `print.c` uses `cputchar` to output characters to the console.

---


### 2. Explain the following from console.c:

```C
1      if (crt_pos >= CRT_SIZE) {
2              int i;
3              memcpy(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
4              for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
5                      crt_buf[i] = 0x0700 | ' ';
6              crt_pos -= CRT_COLS;
7      }
```

First, let's find the definition of `CRT` stuff in `console.h`:

```C
#define CRT_ROWS	25
#define CRT_COLS	80
#define CRT_SIZE	(CRT_ROWS * CRT_COLS)
```

We should be aware that the `CRT` refers to the console, so, the macro above means that the console has 25 rows and 80 columns, and can display 2000 characters in total.

So now we can see what `if (crt_pos >= CRT_SIZE)` means, it means if the current position of console is greater than the size of console. In  old console, it doesn't scrollbar like nowadays, so the content of console must move upward so that a new line can be created.

```C
1      if (crt_pos >= CRT_SIZE) { // if the position meet the end of console
2              int i;
3              memcpy(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t)); // move the whole content one line above, so that a new line is created on the console
4              for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++) // fill the new line with whitespace
5                      crt_buf[i] = 0x0700 | ' ';
6              crt_pos -= CRT_COLS; // relocate the position
7      }
```

---

### 3. For the following questions you might wish to consult the notes for Lecture 2. These notes cover GCC's calling convention on the x86.
Trace the execution of the following code step-by-step:

```C
int x = 1, y = 3, z = 4;
cprintf("x %d, y %x, z %d\n", x, y, z);
```
* In the call to `cprintf()`, to what does `fmt` point? To what does `ap` point?
	* [How are variable arguments implemented in gcc?](http://stackoverflow.com/questions/12371450/how-are-variable-arguments-implemented-in-gcc)
	* `fmt` points to address of `"x %d, y %x, z %d\n"`.
	* `ap` points to address of `x`.

* List (in order of execution) each call to cons_putc, va_arg, and vcprintf. For cons_putc, list its argument as well. For va_arg, list what ap points to before and after the call. For vcprintf list the values of its two arguments.

	* **I will list most function which will be called during the execution of the code above in sequence, and replace the parameter with the actual value**
		* **--> means the sequence of execution**
		* **=> means equivalent**
	* int cprintf("x %d, y %x, z %d\n", x, y, z)
	* int vcprintf("x %d, y %x, z %d\n", {x, y, z})
	* void vprintfmt(putch(), 0, "x %d, y %x, z %d\n", {x, y, z}) --> `while ((ch = *(unsigned char *) fmt++) != '%')` --> ch == 'x'
	* static void putch('x', 0)
		* void cputchar('x')
		* static void cons_putc('x')
			* serial_putc('x')
			* lpt_putc('x')
			* cga_putc('x')
	* void vprintfmt(putch(), 1, "x %d, y %x, z %d\n", {y, z}) --> `while ((ch = *(unsigned char *) fmt++) != '%')` --> ch == ' '
	* static void putch(' ', 1)
	* ...
	* void vprintfmt(putch(), 2, "x %d, y %x, z %d\n", {y, z}) --> `while ((ch = *(unsigned char *) fmt++) != '%')` --> ch == '%'
	* case 'd' 
		* static long long getint({x, y, z}, 0) --> `return va_arg(*ap, int)` => return x => return 1
		* goto number --> printnum(putch(), 2, 1, 10, -1, ' ') --> putch('1', 2)
	* void vprintfmt(putch(), 3, "x %d, y %x, z %d\n", {y, z}) --> `while ((ch = *(unsigned char *) fmt++) != '%')` --> ch == ','
	* static void putch(',', 3)
	* ...
	* void vprintfmt(putch(), 4, "x %d, y %x, z %d\n", {y, z}) --> `while ((ch = *(unsigned char *) fmt++) != '%')` --> ch == ' '
	* static void putch(' ', 4)
	* ...
	* void vprintfmt(putch(), 5, "x %d, y %x, z %d\n", {y, z}) --> `while ((ch = *(unsigned char *) fmt++) != '%')` --> ch == 'y'
	* static void putch('y', 5)
	* ...
	* void vprintfmt(putch(), 6, "x %d, y %x, z %d\n", {y, z}) --> `while ((ch = *(unsigned char *) fmt++) != '%')` --> ch == ' '
	* static void putch(' ', 6)
	* ...
	* void vprintfmt(putch(), 7, "x %d, y %x, z %d\n", {y, z}) --> `while ((ch = *(unsigned char *) fmt++) != '%')` --> ch == '%'
	* case 'x' 
		* static unsigned long long getuint({y, z}, 0) --> `return va_arg(*ap, int)` => return y => return 3
		* goto number --> printnum(putch(), 7, 3, 16, -1, ' '); --> putch('3', 7)
	* void vprintfmt(putch(), 8, "x %d, y %x, z %d\n", {z}) --> `while ((ch = *(unsigned char *) fmt++) != '%')` --> ch == ','
	* static void putch(',', 8)
	* ...
	* void vprintfmt(putch(), 9, "x %d, y %x, z %d\n", {z}) --> `while ((ch = *(unsigned char *) fmt++) != '%')` --> ch == ' '
	* static void putch(' ', 9)
	* ...
	* void vprintfmt(putch(), 10, "x %d, y %x, z %d\n", {z}) --> `while ((ch = *(unsigned char *) fmt++) != '%')` --> ch == 'z'
	* static void putch('z', 10)
	* ...
	* void vprintfmt(putch(), 11, "x %d, y %x, z %d\n", {z}) --> `while ((ch = *(unsigned char *) fmt++) != '%')` --> ch == ' '
	* static void putch(' ', 11)
	* ...
	* void vprintfmt(putch(), 12, "x %d, y %x, z %d\n", {z}) --> `while ((ch = *(unsigned char *) fmt++) != '%')` --> ch == '%'
	* case 'd' 
		* static long long getint({z}, 0) --> `return va_arg(*ap, int)` => return z => return 4
		* goto number --> printnum(putch(), 12, 4, 10, -1, ' ') --> putch('4', 12)
	* void vprintfmt(putch(), 13, "x %d, y %x, z %d\n", {}) --> `while ((ch = *(unsigned char *) fmt++) != '%')` --> ch == '\\n'
	* static void putch('\\n', 13)
		* void cputchar('\\n')
		* void cons_putc('\\n')
			* static void cga_putc('\\n') -- > `case '\\n': crt_pos += CRT_COLS;`
	* **Finally, `"x %d, y %x, z %d\\n", x, y, z` is printed as `x 1, y 3, z 4`, `cprintf` return 14 because there are 14 byte printed to the console(including '\\n').**
	
---

### 4. Run the following code.

```C
    unsigned int i = 0x00646c72;
    cprintf("H%x Wo%s", 57616, &i);
```

**What is the output? Explain how this output is arrived at in the step-by-step manner of the previous exercise. Here's an [ASCII table](http://docs.linuxtone.org/ebooks/C&CPP/c/apas01.html) that maps bytes to characters.**

> The output depends on that fact that the x86 is little-endian. If the x86 were instead big-endian what would you set i to in order to yield the same output? Would you need to change 57616 to a different value?

> Here's a description of [little- and big-endian](http://www.webopedia.com/TERM/B/big_endian.html) and [a more whimsical description](http://www.networksorcery.com/enp/ien/ien137.txt).

First, we can add these code above to `kern/monitor.c`:

![](https://raw.githubusercontent.com/Jameeeees/MIT-JOS/master/lab1/articles/ex8_monitor.png)

And we can see the result of execution:

![](https://raw.githubusercontent.com/Jameeeees/MIT-JOS/master/lab1/articles/ex8_monitor_result.png)

Apprently, the result is `He110 World`. `He110` is easy to explain, because `57616` in decimal is `e110` in hex, but how about `World` ?

`0x00646c72` in little-endian machine is stored as `0x72 0x6c 0x64 0x00` which is `'r' 'l' 'd' '\0'` in ASCII, and when `cprintf` reads the `0x72 0x6c 0x64 0x00`, it will output as `rld`.


---

### 5. In the following code, what is going to be printed after 'y='? (note: the answer is not a specific value.) Why does this happen?

```C
    cprintf("x=%d y=%d", 3);
```

It will output a "random" value, actually it is the value adjacent to `0x00000003` , we can make a little test.

```C
int main()
{
	printf("x=%d y=%d", 3);
}
```

Test it in gdb, and we can see things below:

```gdb
(gdb) s
_IO_vfprintf_internal (s=0xb7fbdac0 <_IO_2_1_stdout_>, 
    format=format@entry=0x80484e0 "x=%d y=%d", ap=ap@entry=0xbffff124 "\003")
    at vfprintf.c:235
235	vfprintf.c: No such file or directory.
(gdb) x/4b ap
0xbffff124:	0x03	0x00	0x00	0x00
(gdb) x/4b ap+4
0xbffff128:	0x5b	0x84	0x04	0x08
(gdb) c
Continuing.
x=3 y=134513755
```

The value of y, 134513755, is `0x‭0804845B‬` in hex, which is the value of `ap+4`, I am not sure what the value is used for(I guess it is the return address of function `8048350 <__x86.get_pc_thunk.bx>`), but I know it's a undefined behavior which we need to avoid.

---

### 6. Let's say that GCC changed its calling convention so that it pushed arguments on the stack in declaration order, so that the last argument is pushed last. How would you have to change cprintf or its interface so that it would still be possible to pass it a variable number of arguments?

Let's say we have such test code `cprintf("%d%x%d", a, b, c);`.

These two stack layouts stand for the two different calling convention, `layout I` stands for the GCC original layout, `layout II` stands for the layout after we have changed the calling convention:

```plain
	   layout I				                 layout II
+------------------+                    +------------------+            
|   ret address    |                    |   ret address    |           
+------------------+  <- fmt            +------------------+          
|     "%d%x%d"     |                    |        c         |           
+------------------+  <- ap             +------------------+           
|        a  	   |                    |        b  	   |           
+------------------+                    +------------------+  <- ap         
|        b         |                    |        a         |           
+------------------+                    +------------------+  <- fmt        
|        c         |                    |     "%d%x%d"     |           
+------------------+                    +------------------+           
|                  |                    |                  |           
+------------------+                    +------------------+           
```

We should be aware that the ap will move upside down, so to change `cprintf("%d%x%d", a, b, c);` to `cprintf(c, b, a, "%d%x%d");` will do the job, they will print the same result. However, this way is absolutely hard to understand, I am sure there will be a more elegant way to change it. // TODO


---

### 7. Challenge Enhance the console to allow text to be printed in different colors. The traditional way to do this is to make it interpret [ANSI escape sequences](http://www.dee.ufcg.edu.br/~rrbrandt/tools/ansi.html) embedded in the text strings printed to the console, but you may use any mechanism you like. There is plenty of information on [the 6.828 reference page](https://pdos.csail.mit.edu/6.828/2011/reference.html) and elsewhere on the web on programming the VGA display hardware. If you're feeling really adventurous, you could try switching the VGA hardware into a graphics mode and making the console draw text onto the graphical frame buffer.

//TODO



















