#importonce

#import "misc.asm"

// Resolution
// Pixels: 320x200 ==> 64.000
// Tiles: 40x25 ==> 1.000

// char-codes
// A -> #65 / #$41
// a -> #1 / #$1
// 0 -> #48 / #$30

.const SPACE = $20
.const ZERO = $30

.const RES_X = 40
.const RES_Y = 25

.const BG_COLOR = $d021
.const FG_COLOR = $d020
.const SCREEN_RAM = $0400
.const COLOR_RAM = $d800

.const RASTER_COUNTER = $d012
.const RASTER_COUNTER_CARRY = $d011
.const RASTER_TOP = 49
.const RASTER_BOTTOM = 251

.const CELL_WIDTH = 3
.const CELL_HEIGHT = 3
.const CELL_OFFSET_X = 1
.const CELL_OFFSET_Y = 3
.const CELL_BASE_PTR = SCREEN_RAM + CELL_OFFSET_X + CELL_OFFSET_Y * RES_X
.const COLOR_BASE_PTR = COLOR_RAM + CELL_OFFSET_X + CELL_OFFSET_Y * RES_X

.const COLS = 7
.const ROWS = 6
arr_byte_cell_ptrs:
.for (var y = 0; y < ROWS; y++) {
    .for (var x = 0; x < COLS; x++) {
        .word CELL_BASE_PTR + (y * CELL_HEIGHT * RES_X) + (x * CELL_WIDTH)
    }
}
arr_byte_color_ptrs:
.for (var y = 0; y < ROWS; y++) {
    .for (var x = 0; x < COLS; x++) {
        .word COLOR_BASE_PTR + (y * CELL_HEIGHT * RES_X) + (x * CELL_WIDTH)
    }
}


.macro clear_screen() {
    lda #SPACE

    // fill $0400 -> $06ff
    ldx #0
    !loop:
        sta SCREEN_RAM,x
        sta SCREEN_RAM+$0100,x
        sta SCREEN_RAM+$0200,x
        inx
        bne !loop-

    // fill $0700 -> $07e7
    ldx #0
    !loop:
        sta SCREEN_RAM+$0300,x
        inx
        cpx #$e8
        bne !loop-
}

.macro shifted_chars() {
    lda #%00000010
    ora $d018
    sta $d018
}

.macro unshifted_chars() {
    lda #%11111101
    and $d018
    sta $d018
}

.macro set_background(color) {
    lda #color
    sta BG_COLOR
}

.macro set_foreground(color) {
    lda #color
    sta FG_COLOR
}

.macro draw_screen(screen) {
    .var tiles = screen+2
    .var colors = tiles+1000

    lda screen
    sta FG_COLOR
    lda screen+1
    sta BG_COLOR

    // fill $0400 -> $06ff
    ldx #0
    !loop:
        lda tiles,x
        sta SCREEN_RAM,x
        lda colors,x
        sta COLOR_RAM,x

        lda tiles+$0100,x
        sta SCREEN_RAM+$0100,x
        lda colors+$0100,x
        sta COLOR_RAM+$0100,x

        lda tiles+$0200,x
        sta SCREEN_RAM+$0200,x
        lda colors+$0200,x
        sta COLOR_RAM+$0200,x

        inx
        bne !loop-

    // fill $0700 -> $07e7
    ldx #0
    !loop:
        lda tiles+$0300,x
        sta SCREEN_RAM+$0300,x
        lda colors+$0300,x
        sta COLOR_RAM+$0300,x

        inx
        cpx #$e8
        bne !loop-
}

.macro draw_score(player, score) {
    ldx #0
    hundreds:
        lda score
        .for (var i = 2; i > 0; i--) {
            cmp #i*100
            bcc !skip+
            pha
            lda #ZERO+i
            .if (player == 1) {
                sta SCREEN_RAM+30+5*RES_X,x
            } else {
                sta SCREEN_RAM+30+11*RES_X,x
            }
            pla
            sec
            sbc #i*100
            inx
            jmp tens

            !skip:
        }

    tens:
        .for (var i = 9; i >= 0; i--) {
            .if (i == 0) {
                cpx #0
                beq !skip+
            }
            cmp #i*10
            bcc !skip+
            pha
            lda #ZERO+i
            .if (player == 1) {
                sta SCREEN_RAM+30+5*RES_X,x
            } else {
                sta SCREEN_RAM+30+11*RES_X,x
            }
            pla
            sec
            sbc #i*10
            inx
            jmp ones

            !skip:
        }

    ones:
        clc
        adc #ZERO
        .if (player == 1) {
            sta SCREEN_RAM+30+5*RES_X,x
        } else {
            sta SCREEN_RAM+30+11*RES_X,x
        }

    !loop:
        cpx #2
        beq !loop+
        inx
        lda #SPACE
        .if (player == 1) {
            sta SCREEN_RAM+30+5*RES_X,x
        } else {
            sta SCREEN_RAM+30+11*RES_X,x
        }
        jmp !loop-
    !loop:
}

.macro put_cell_ptr_to_ptr_a(src_ptr_arr, selected_cell) {
    // create a pointer (ptr_b) to the array element
    lda #<src_ptr_arr
    ldx #>src_ptr_arr
    clc
    adc selected_cell
    bcc !skip+
    inx
    clc
    !skip:
    adc selected_cell
    bcc !skip+
    inx
    !skip:
    sta ptr_b
    stx ptr_b + 1

    // read array element to get address to tile on screen, save to ptr_a
    ldy #0
    lda (ptr_b),y
    sta ptr_a
    iny
    lda (ptr_b),y
    sta ptr_a + 1
}

.macro fill_cell(selected_cell) {
    put_cell_ptr_to_ptr_a(arr_byte_cell_ptrs, selected_cell)

    lda #$a0
    ldy #RES_X + 1
    sta (ptr_a),y
}

.macro color_cell(selected_cell, color) {
    put_cell_ptr_to_ptr_a(arr_byte_color_ptrs, selected_cell)

    lda color
    ldy #0
    sta (ptr_a),y
    iny
    sta (ptr_a),y
    iny
    sta (ptr_a),y
    ldy #RES_X
    sta (ptr_a),y
    iny
    sta (ptr_a),y
    iny
    sta (ptr_a),y
    ldy #2*RES_X
    sta (ptr_a),y
    iny
    sta (ptr_a),y
    iny
    sta (ptr_a),y
}

.macro wait_for_vblank() {
    !loop:
        // wait for raster counter to be < 255
        lda RASTER_COUNTER_CARRY
        and #%10000000
        bne !loop-

    !loop:
        // wait for raster counter to hit RASTER_BOTTOM-1
        lda RASTER_COUNTER
        cmp #RASTER_BOTTOM-1
        bne !loop-
    !loop:
        // wait for raster counter to hit RASTER_BOTTOM
        lda RASTER_COUNTER
        cmp #RASTER_BOTTOM
        bne !loop-
}
