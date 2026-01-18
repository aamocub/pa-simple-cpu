__asm__ (
        "li sp, 0x800\n"
        "mv s0,sp\n"
);
void _start(void) {
    int a[128], b[128];
    for (int i=0; i<128; i++) { a[i] = 5; }
    for (int i=0; i<128; i++) { b[i] = a[i]; }
    __asm__ volatile ("ecall");
}