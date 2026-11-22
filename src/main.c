#include <stdio.h>
#include <unistd.h>

int main(void)
{
    puts("Hello from CardputerZero!");
    if (isatty(STDIN_FILENO) && isatty(STDOUT_FILENO)) {
        puts("Press Enter to exit.");
        fflush(stdout);
        int key;
        do {
            key = getchar();
        } while (key != '\n' && key != EOF);
    }
    return 0;
}
