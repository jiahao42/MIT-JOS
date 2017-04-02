## lab1-exercise 4
> Exercise 4. Read about programming with pointers in C. The best reference for the C language is The C Programming Language by Brian Kernighan and Dennis Ritchie (known as 'K&R'). We recommend that students purchase this book (here is an Amazon Link) or find one of MIT's 7 copies.

> Read 5.1 (Pointers and Addresses) through 5.5 (Character Pointers and Functions) in K&R. Then download the code for pointers.c, run it, and make sure you understand where all of the printed values come from. In particular, make sure you understand where the pointer addresses in lines 1 and 6 come from, how all the values in lines 2 through 4 get there, and why the values printed in line 5 are seemingly corrupted.

> There are other references on pointers in C, though not as strongly recommended. A tutorial by Ted Jensen that cites K&R heavily is available in the course readings.

> Warning: Unless you are already thoroughly versed in C, do not skip or even skim this reading exercise. If you do not really understand pointers in C, you will suffer untold pain and misery in subsequent labs, and then eventually come to understand them the hard way. Trust us; you don't want to find out what "the hard way" is.

```C
void f(void)
{
    int a[4];
    int *b = malloc(16);
    int *c;
    int i;

    /*
     * %p will print the pointer address
     * a : address of a[0], from stack
     * b : address of what b points, from heap
     * c : undefined behavior! pointer to a random place in the memory
     */
    printf("1: a = %p, b = %p, c = %p\n", a, b, c);

    /*
     * c points to a[0]
     */
    c = a;
    for (i = 0; i < 4; i++)
	  a[i] = 100 + i;//a[4] = {100, 101, 102, 103}
    c[0] = 200;//a[4] = {200, 101, 102, 103}
    printf("2: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
	   a[0], a[1], a[2], a[3]);

     /*
      * c[1] is equivalent to a[1]
      * *(c + 2) is equivalent to c[2] and a[2]
      * 3[c] is equivalent to *(3 + c), also c[3] and a[3]
      */
    c[1] = 300;//a[4] = {200, 300, 102, 103}
    *(c + 2) = 301;//a[4] = {200, 300, 301, 103}
    3[c] = 302;//a[4] = {200, 300, 301, 302}
    printf("3: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
	   a[0], a[1], a[2], a[3]);


    c = c + 1;//now c points to a[1]
    *c = 400;//a[4] = {200, 400, 301, 302}
    printf("4: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
	   a[0], a[1], a[2], a[3]);

     /*
      * (char *)c converts c to char*, then plus 1
      * it will make c to move one byte further from a[0]
      * Since an int is 4 bytes size, and it is stored as little-endian.
      * a[1] = 0x190, and is stored as {0x90, 0x01, 0x00, 0x00}
      * a[2] = 0x12D, and is stored as {0x2D, 0x01, 0x00, 0x00}
      * c = (int *) ((char *) c + 1)
      * and c points to {0x01, 0x00, 0x00, 0x2D}
      * after executing *c = 500, which is 0x1F4 in hex
      * *c is stored as {0xF4, 0x01, 0x00, 0x00}
      * a[1] = 128144 and is stored as {0x90, 0xF4, 0x01, 0x00}
      * a[2] = 128 and is stored as {0x00, 0x01, 0x00, 0x00}
      */
    c = (int *) ((char *) c + 1);
    *c = 500;
    printf("5: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
	   a[0], a[1], a[2], a[3]);

    b = (int *) a + 1;//b = a[1] = (int)&a + 0x4
    c = (int *) ((char *) a + 1);//c = (int)a + 0x1
    printf("6: a = %p, b = %p, c = %p\n", a, b, c);
}
```
