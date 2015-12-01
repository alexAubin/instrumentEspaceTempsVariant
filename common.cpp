
#include "common.h"

void appendString(char* output, char* input)
{
    int i = 0;
    for (i = 0 ; ; i++) { if (output[i] == '\0') break; }

    for (int j = 0 ; input[j] != '\0' ; j++)
    {
        output[i++] = input[j];
    }
    output[i] = '\0';

    return;
}

void printFloat(float f)
{
    if (f < 0)
    {
        DEBUG_NOLN('-');
        f = -f;
    }

    if (f > 1) { DEBUG_NOLN(int(f)); }
    else { DEBUG_NOLN('0'); }

    DEBUG_NOLN('.');

    f = f - int(f);    int a = int(f *    10);  DEBUG_NOLN(a);
    f = f - a * 0.1;   int b = int(f *   100);  DEBUG_NOLN(b);
    f = f - b * 0.01;  int c = int(f *  1000);  DEBUG_NOLN(c);
    f = f - c * 0.001; int d = int(f * 10000);  DEBUG_NOLN(d);
}

void printFloatInString(char* output, float f)
{
    int index = 0;
    if (f < 0)
    {
        output[index++] = '-';
        f = -f;
    }

    if (f > 1) output[index++] = (int(f)+48);
    else output[index++] = '0';

    output[index++] = '.';

    f -= int(f);    int a = int(f *    10); output[index++] = a+48;
    f -= a * 0.1;   int b = int(f *   100); output[index++] = b+48;
    f -= b * 0.01;  int c = int(f *  1000); output[index++] = c+48;
    f -= c * 0.001; int d = int(f * 10000); output[index++] = d+48;

    output[index] = '\0';

    return;
}

/* Find out what's going on here
void printIntInString(char* output, int i)
{
    int index = 0;
    if (i < 0)
    {
        output[index++] = '-';
        i = -i;
    }

    if (i >= 10)
    {
        output[index++] = (int(i/10)+48);
    i = (int) (i / 10);
    }

    output[index++] = (int(i)+48);
    output[index] = '\0';

    return;
}
*/


void printHourInString(char* output, int h, int m, char separator)
{
    int index = 0;

    if (h >= 10) output[index++] = int(h/10)+48;
    else output[index++] = '0';
    if (h > 1)  output[index++] = int(h - (h/10)*10)+48;
    else output[index++] = '0';


    output[index++] = separator;

    if (m >= 10) output[index++] = int(m/10)+48;
    else output[index++] = '0';
    if (m > 1)  output[index++] = int(m - (m/10)*10)+48;
    else output[index++] = '0';

    output[index] = '\0';

    return;
}

void printFloatln(float f)
{
    printFloat(f);
    DEBUG_NOLN('\n');
}



