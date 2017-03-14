#include <stdio.h>
#include <stdlib.h>

void
f(void)
{
    int a[4];
    int *b = malloc(16);
    int *c;
    int i;

    /*
     * a = address of *a
     * b = address of *b
     * c = address of *c
     *
     */
    printf("1: a = %p, b = %p, c = %p\n", a, b, c);

    c = a;//c points to a
    for (i = 0; i < 4; i++)
	a[i] = 100 + i;//a[4] = {100, 101, 102, 103};
    c[0] = 200;//a[4] = {200, 101, 102, 103};
    printf("2: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
	   a[0], a[1], a[2], a[3]);

    c[1] = 300;//a[4] = {200, 300, 102, 103};
    *(c + 2) = 301;//a[4] = {200, 300, 301, 103};
    3[c] = 302;//a[4] = {200, 300, 301, 302};
    printf("3: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
	   a[0], a[1], a[2], a[3]);

    c = c + 1;//c now points to a[1]
    *c = 400;//a[4] = {200, 400, 301, 302};
    printf("4: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
	   a[0], a[1], a[2], a[3]);

    c = (int *) ((char *) c + 1);//mov 1 bit to the right
    *c = 500;//a[4] = {200, 31, 1073742224, 302};
    printf("5: a[0] = %d, a[1] = %d, a[2] = %d, a[3] = %d\n",
	   a[0], a[1], a[2], a[3]);

    b = (int *) a + 1;//b points to a[1] = 31
    c = (int *) ((char *) a + 1);//c = 3200
    printf("6: a = %p, b = %p, c = %p\n", a, b, c);
}

int
main(int ac, char **av)
{
    f();
    return 0;
}

