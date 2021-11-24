#include "io.h"
int main()
{
    double x = 1;
    for (int i = 0; i < 3; i++)
    {
        outl(x);
        x = (x + 3/x)/2;
    }
    
}