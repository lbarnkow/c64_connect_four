#importonce

// TODO: rename these?
.const ptr_a = $fb
.const ptr_b = $fd

.macro disable_interrupts() {
    sei
}

.macro wait_for_space() {
    !loop:
        lda $dc01 // Scans keyboard buffer
        cmp #$ef  // Space == quit
        bne !loop-
}

// result in x, rest in a
.macro div_a(num) {
    ldx #0
    !loop:
        inx
        sec
        sbc #num
        bmi !end_loop+
        jmp !loop-

    !end_loop:
    clc
    adc #num
    dex
    txa
}
