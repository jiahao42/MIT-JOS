### lab1-exercise 8

> Exercise 8. We have omitted a small fragment of code - the code necessary to print octal numbers using patterns of the form "%o". Find and fill in this code fragment.

#### Be able to answer the following questions:

**1. Explain the interface between printf.c and console.c. Specifically, what function does console.c export? How is this function used by printf.c?**

* console.c
First, we can see what `console.c` exports from `kern/console.h`:
```C
void cons_init(void);
int cons_getc(void);

void kbd_intr(void); // irq 1
void serial_intr(void); // irq 4
```
`cons_init` is used for initializing the console devices,


* stdio.h
Second, `inc/stdio.h` declares a series of `printf`, such as:
```
// lib/printfmt.c
void	printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);
void	vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list);
int	snprintf(char *str, int size, const char *fmt, ...);
int	vsnprintf(char *str, int size, const char *fmt, va_list);

// lib/printf.c
int	cprintf(const char *fmt, ...);
int	vcprintf(const char *fmt, va_list);
```
And as the comments above show, these functions are implemented in `lib/printfmt.c` and `lib/printf.c`.



**2. Explain the following from console.c:**
```C
1      if (crt_pos >= CRT_SIZE) {
2              int i;
3              memcpy(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
4              for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
5                      crt_buf[i] = 0x0700 | ' ';
6              crt_pos -= CRT_COLS;
7      }
```


**3. For the following questions you might wish to consult the notes for Lecture 2. These notes cover GCC's calling convention on the x86.
Trace the execution of the following code step-by-step:**
```C
int x = 1, y = 3, z = 4;
cprintf("x %d, y %x, z %d\n", x, y, z);
```
* In the call to cprintf(), to what does fmt point? To what does ap point?
* List (in order of execution) each call to cons_putc, va_arg, and vcprintf. For cons_putc, list its argument as well. For va_arg, list what ap points to before and after the call. For vcprintf list the values of its two arguments.


**4. Run the following code.**
```C
    unsigned int i = 0x00646c72;
    cprintf("H%x Wo%s", 57616, &i);
```
**What is the output? Explain how this output is arrived at in the step-by-step manner of the previous exercise. Here's an ASCII table that maps bytes to characters.
The output depends on that fact that the x86 is little-endian. If the x86 were instead big-endian what would you set i to in order to yield the same output? Would you need to change 57616 to a different value?

Here's a description of [little- and big-endian](http://www.webopedia.com/TERM/B/big_endian.html) and [a more whimsical description](http://www.networksorcery.com/enp/ien/ien137.txt).**


**5. In the following code, what is going to be printed after 'y='? (note: the answer is not a specific value.) Why does this happen?**
```C
    cprintf("x=%d y=%d", 3);
```

**6. Let's say that GCC changed its calling convention so that it pushed arguments on the stack in declaration order, so that the last argument is pushed last. How would you have to change cprintf or its interface so that it would still be possible to pass it a variable number of arguments?**

**7. Challenge Enhance the console to allow text to be printed in different colors. The traditional way to do this is to make it interpret [ANSI escape sequences](http://www.dee.ufcg.edu.br/~rrbrandt/tools/ansi.html) embedded in the text strings printed to the console, but you may use any mechanism you like. There is plenty of information on [the 6.828 reference page](https://pdos.csail.mit.edu/6.828/2011/reference.html) and elsewhere on the web on programming the VGA display hardware. If you're feeling really adventurous, you could try switching the VGA hardware into a graphics mode and making the console draw text onto the graphical frame buffer.**
