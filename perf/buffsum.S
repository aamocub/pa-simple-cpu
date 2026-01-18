.text
_start:
addi	sp,sp,-544
sw	ra,540(sp)
sw	s0,536(sp)
addi	s0,sp,544
sw	zero,-20(s0)
sw	zero,-24(s0)
j	48 <_start+0x48>
lw	a4,-24(s0)
addi	a5,s0,-536
slli	a4,a4,0x2
add	a5,a4,a5
lw	a5,0(a5)
lw	a4,-20(s0)
add	a5,a4,a5
sw	a5,-20(s0)
lw	a5,-24(s0)
addi	a5,a5,1
sw	a5,-24(s0)
lw	a4,-24(s0)
li	a5,127
bge	a5,a4,1c <_start+0x1c>
nop
nop
lw	ra,540(sp)
lw	s0,536(sp)
addi	sp,sp,544