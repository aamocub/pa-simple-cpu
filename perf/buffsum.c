__asm__ (
        "li sp, 0x800\n"
        "mv s0,sp\n"
);

void _start(void) {
    int a[128], sum = 0;
    for (int i=0; i<128; i++) { sum += a[i]; }
    __asm__ volatile ("ecall");
}