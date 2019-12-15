`timescale 1ns / 1ps

// This files contains modules for playing around with the seven segment PMOD.
// It uses the seven segment PMOD connected to PMOD 1A and the break-away PMOD (still)
// connected to PMOD 2

// Rename one of below module names to `top` before compilation. Make sure there is
// only one module `top` at any given time.

module top(CLOCK, BREAK_BUTTON_1, BREAK_BUTTON_2, BREAK_BUTTON_3, SEV_SEGMENT, SEV_SEG_CATHODE);
    // Uses the seven segment displays to display an 8-bit counter in HEX. Control the counter
    // with the buttons; B1 increments, B2 resets and B3 decrements the counter

    input CLOCK;
    input BREAK_BUTTON_1;
    input BREAK_BUTTON_2;
    input BREAK_BUTTON_3;
    output [6:0] SEV_SEGMENT;
    output SEV_SEG_CATHODE;

    reg [7:0] counter;
    reg [6:0] digit_0_segments;
    reg [6:0] digit_1_segments;

    button_counter #(
        .WIDTH(8)
    ) b_counter(
        .i_clock(CLOCK),
        .i_button_inc(BREAK_BUTTON_1),
        .i_button_dec(BREAK_BUTTON_3),
        .i_button_reset(BREAK_BUTTON_2),
        .o_counter(counter)
    );

    bcd digit_0(
        .i_nibble(counter[3:0]),
        .o_segments(digit_0_segments)
    );

    bcd digit_1(
        .i_nibble(counter[7:4]),
        .o_segments(digit_1_segments)
    );

    seven_segments display(
        .i_clock(CLOCK),
        .i_segments_digit_0(digit_0_segments),
        .i_segments_digit_1(digit_1_segments),
        .o_sev_segments(SEV_SEGMENT),
        .o_sev_seg_cathode(SEV_SEG_CATHODE)
    );
endmodule
