
__asm__(".section .text.start\n"
        ".global _start\n"
        "_start:\n"
        "    li sp, 1024\n"
        "    jal main\n");

#define DISPLAY_ADDR (volatile unsigned int*) 0x400

void delay(volatile int count) {
    while(count--) {
        __asm__ volatile ("nop");
    }
}

int main() {
    unsigned int digits[] = {
        0x3F, // 0
        0x06, // 1
        0x5B, // 2
        0x4F, // 3
        0x66, // 4
        0x6D, // 5
        0x7D, // 6
        0x07, // 7
        0x7F, // 8
        0x6F  // 9
    };

    for (int i = 0; i < 10; i++) {
        *DISPLAY_ADDR = digits[i];
        delay(50000); 
    }

    __asm__ volatile ("ebreak");

    while(1) {
        __asm__ volatile ("nop");
    }

    return 0;
}