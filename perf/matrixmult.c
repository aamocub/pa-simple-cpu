__asm__ (
        "li sp, 0x800\n"
        "mv s0,sp\n"
);
void _start(void) {
    int a[128][128], b[128][128], c[128][128];
    for (int i=0; i<128; i++) {
         for( int j =0;j<128;j++) {
              c[i][j] = 0;
              for(int k = 0; k <128; k++ ) {
                    c[i][j] = c[i][j] + a[i][k] * b[k][j];
              }
         }
    }
    __asm__ volatile ("ecall");
}