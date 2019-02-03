* = $0801 "Basic Upstart"
BasicUpstart2(setup)

* = $0810 "Main"



#import "assets/screens_main.asm"

#import "lib/misc.asm"
#import "lib/joystick.asm"
#import "lib/video.asm"

.const HUMAN = 0
.const CPU = 1
.const FALSE = 0
.const TRUE = 1

.const INITIAL_SELECTED_COL = 3
.const INITIAL_SELECTED_CELL = (COLS * ROWS - ROWS - 1) + INITIAL_SELECTED_COL

byte_score_1: .byte 0
byte_score_2: .byte 0
byte_player_1: .byte HUMAN
byte_player_2: .byte HUMAN
byte_active_player: .byte 1
byte_selected_col: .byte INITIAL_SELECTED_COL
byte_selected_dir: .byte 0
byte_selected_cell: .byte INITIAL_SELECTED_CELL
byte_commit_selection: .byte FALSE
byte_commit_color: .byte RED
byte_highlighted_cell: .byte INITIAL_SELECTED_CELL
byte_highlighted_color: .byte RED

arr_byte_cells: .fill COLS*ROWS, 0

byte_frame_counter: .byte 0


setup: {
    disable_interrupts()

    set_background(BLACK)
    set_foreground(BLACK)

    clear_screen()
    shifted_chars()

    jmp game
}


game: {
    draw_screen(screens_main)

    draw_score(1, byte_score_1)
    draw_score(2, byte_score_2)

    init_vars()
    read_joysticks()

    !loop:
        read_joysticks()

        handle_game_logic()

        set_foreground(GREEN)
        wait_for_vblank()
        set_foreground(RED)
        update_screen()
        set_foreground(YELLOW)
        inc_and_wrap_frame_counter()

        jmp !loop-
    !loop:

    jmp setup
}


try_selection_change:
{
    //.break
    lda byte_selected_col
    clc
    adc byte_selected_dir

    !while:
    {
        cmp #-1
        beq !end_while+
        cmp #COLS
        beq !end_while+

        !if:
        tax
        ldy arr_byte_cells,x
        bne !end_if+
        !then:
        {
            tay
            clc
            adc #(ROWS*COLS-COLS)
            tax
            tya
            !for:
            {
                cpx #0
                bmi !end_for+

                !if:
                ldy arr_byte_cells,x
                cpy #0
                bne !end_if+
                !then:
                {
                    lda byte_selected_col
                    clc
                    adc byte_selected_dir
                    sta byte_selected_col
                    stx byte_selected_cell
                    lda #0
                    sta byte_frame_counter
                    lda #TRUE
                    jmp !end_while+
                }
                !end_if:


                tay
                txa
                clc
                adc #-COLS
                tax
                tya
                jmp !for-
            }
            !end_for:
        }
        !end_if:

        clc
        adc byte_selected_dir
        jmp !while-
    }
    !end_while:
    lda #FALSE
    rts
}


.macro switch_active_player() {
    ldx byte_active_player
    inx
    cpx #3
    bne !end_if+
        ldx #1
    !end_if:
    stx byte_active_player
}


.macro handle_game_logic() {
    // joystick: left or right pressed?
    lda joy_2_state
    and #JOY_LEFT
    beq !skip+
        lda #-1
        sta byte_selected_dir
        jsr try_selection_change
    !skip:

    lda joy_2_state
    and #JOY_RIGHT
    beq !skip+
        lda #1
        sta byte_selected_dir
        jsr try_selection_change
    !skip:

    // TODO: Delete, just for debugging
    lda byte_selected_col
    sta byte_score_1
    lda byte_selected_cell
    sta byte_score_2
    // TODO: Delete, just for debugging

    // joystick: fire button pressed?
    lda joy_2_state
    and #JOY_FIRE
    beq !skip+
        lda #TRUE
        sta byte_commit_selection
        lda byte_active_player
        ldx byte_selected_cell
        sta arr_byte_cells,x
        set_highlighted_color_from_active_player()
        lda byte_highlighted_color
        sta byte_commit_color
        switch_active_player()
    !skip:
}


.macro set_highlighted_color_from_active_player() {
    lda byte_active_player
    cmp #1
    bne !else+
        lda #RED
        sta byte_highlighted_color
        jmp !endif+
    !else:
        lda #YELLOW
        sta byte_highlighted_color
    !endif:
}


.macro update_screen() {
    draw_score(1, byte_score_1)
    draw_score(2, byte_score_2)

    // clear highlight
    lda #WHITE
    sta byte_highlighted_color
    color_cell(byte_highlighted_cell, byte_highlighted_color)


    lda byte_commit_selection
    cmp #TRUE
    bne !skip+
        fill_cell(byte_selected_cell)
        color_cell(byte_selected_cell, byte_commit_color)

        lda #FALSE
        sta byte_commit_selection
    !skip:

    // paint highlighted cell
    lda #25
    cmp byte_frame_counter
    bmi !skip_highlight+
        set_highlighted_color_from_active_player()
        lda byte_selected_cell
        sta byte_highlighted_cell
        color_cell(byte_highlighted_cell, byte_highlighted_color)
    !skip_highlight:
}


.macro init_vars() {
    lda #0
    sta byte_score_1
    sta byte_score_2
    sta byte_selected_col
    sta byte_frame_counter

    lda #1
    sta byte_active_player

    lda #0
    ldx #0
    !loop:
        cpx #ROWS*COLS
        beq !loop+
        sta arr_byte_cells,x
        inx
        jmp !loop-
    !loop:

    lda #INITIAL_SELECTED_COL
    sta byte_selected_col

    lda #INITIAL_SELECTED_CELL
    sta byte_selected_cell
    sta byte_highlighted_cell

    lda #HUMAN
    sta byte_player_1
    sta byte_player_2

    lda #FALSE
    sta byte_commit_selection
}


.macro inc_and_wrap_frame_counter() {
    inc byte_frame_counter
    lda byte_frame_counter
    cmp #50
    bne !skip+
        lda #0
        sta byte_frame_counter
    !skip:
}