
.const JOY_UP    = %00000001
.const JOY_DOWN  = %00000010
.const JOY_LEFT  = %00000100
.const JOY_RIGHT = %00001000
.const JOY_FIRE  = %00010000

.const JOY_PORT_2 = $dc00
.const JOY_PORT_1 = $dc01

joy_1_previous_raw: .byte $ff
joy_2_previous_raw: .byte $ff
joy_1_current_raw: .byte $ff
joy_2_current_raw: .byte $ff
joy_1_state: .byte $ff
joy_2_state: .byte $ff
joy_tmp: .byte $ff

.macro read_joysticks() {
    lda joy_1_current_raw
    sta joy_1_previous_raw
    lda joy_2_current_raw
    sta joy_2_previous_raw

    lda JOY_PORT_1
    sta joy_1_current_raw
    lda JOY_PORT_2
    sta joy_2_current_raw

    lda joy_1_current_raw
    eor #$ff
    sta joy_tmp
    lda joy_1_previous_raw
    eor joy_1_current_raw
    and joy_tmp
    sta joy_1_state

    lda joy_2_current_raw
    eor #$ff
    sta joy_tmp
    lda joy_2_previous_raw
    eor joy_2_current_raw
    and joy_tmp
    sta joy_2_state
}

/*

prev   0111 1111
curr   0111 1110

xor    0000 0001
!c     1000 0001
and    0000 0001


prev   0111 1110
curr   0111 1110

xor    0000 0000
!c     1000 0001
and    0000 0000


*/
