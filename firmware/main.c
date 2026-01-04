#define DISPLAY_ADDR (volatile unsigned int*) 0x400
int main() {
    *DISPLAY_ADDR = 0x3F;
    *DISPLAY_ADDR = 0x06;
    *DISPLAY_ADDR = 0x5B;
    *DISPLAY_ADDR = 0x4F;
    *DISPLAY_ADDR = 0x5B;
    *DISPLAY_ADDR = 0x6D;
    *DISPLAY_ADDR = 0x7D;
    *DISPLAY_ADDR = 0x07;
    *DISPLAY_ADDR = 0x7F;
    *DISPLAY_ADDR = 0x6F;
    __asm__ volatile ("ebreak");
    return 0;
}