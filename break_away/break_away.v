`timescale 1ns / 1ps

// This files contains modules for playing around with the break-away PMOD.

// Rename one of below module names to `top` before compilation. Make sure there is
// only one module `top` at any given time.

module top(CLOCK, BREAK_BUTTON_1, BREAK_BUTTON_2, BREAK_BUTTON_3, BREAK_LEDS);
    // Use the 3 horizontal leds as a 3-bit counter. Control the counter
    // with the buttons; B1 increments, B2 resets and B3 decrements the counter

    input CLOCK;
    input BREAK_BUTTON_1;
	input BREAK_BUTTON_2;
	input BREAK_BUTTON_3;
    output [4:0] BREAK_LEDS;

    wire button_event;
    wire clean_button_1;
    wire clean_button_2;
    wire clean_button_3;
    reg [2:0] counter = 0;

    assign BREAK_LEDS[0] = counter[1]; // clean_button_2;
    assign BREAK_LEDS[1] = 0;
    assign BREAK_LEDS[2] = 0;
    assign BREAK_LEDS[3] = counter[0]; // clean_button_1;
    assign BREAK_LEDS[4] = counter[2]; // clean_button_3;

    assign button_event = clean_button_1 | clean_button_2 | clean_button_3;

    always @(posedge button_event) begin
        if (clean_button_1) begin
            counter <= counter + 1;
        end
        if (clean_button_2) begin
            counter <= 0;
        end
        if (clean_button_3) begin
            counter <= counter - 1;
        end
    end

    button_debouncer debouncer_1(
        .i_clock(CLOCK),
        .i_button(BREAK_BUTTON_1),
        .o_state(clean_button_1)
    );

    button_debouncer debouncer_2(
        .i_clock(CLOCK),
        .i_button(BREAK_BUTTON_2),
        .o_state(clean_button_2)
    );

    button_debouncer debouncer_3(
        .i_clock(CLOCK),
        .i_button(BREAK_BUTTON_3),
        .o_state(clean_button_3)
    );
endmodule

module top_2(CLOCK, BREAK_LEDS);
    // Use the 3 horizontal leds as a 3-bit counter

    input CLOCK;
    output [4:0] BREAK_LEDS;

    wire slow_clock;
    reg [2:0] counter = 0;

    assign BREAK_LEDS[0] = counter[1];
    assign BREAK_LEDS[1] = 0;
    assign BREAK_LEDS[2] = 0;
    assign BREAK_LEDS[3] = counter[0];
    assign BREAK_LEDS[4] = counter[2];

    always @(posedge slow_clock) begin
        counter <= counter + 1;
    end

    clock_divider divider(
        .i_clock(CLOCK),
        .o_clock(slow_clock)
    );
endmodule

module top_3(BREAK_BUTTON_1, BREAK_BUTTON_2, BREAK_BUTTON_3, BREAK_LEDS);
    // Link the 3 horizonal leds to the buttons

	input BREAK_BUTTON_1;
	input BREAK_BUTTON_2;
	input BREAK_BUTTON_3;
	output [4:0] BREAK_LEDS;

    assign BREAK_LEDS[0] = BREAK_BUTTON_2;
    assign BREAK_LEDS[1] = 0;
    assign BREAK_LEDS[2] = 0;
    assign BREAK_LEDS[3] = BREAK_BUTTON_1;
    assign BREAK_LEDS[4] = BREAK_BUTTON_3;
endmodule