`timescale 1ns / 1ps

module button_counter(i_clock, i_button_inc, i_button_dec, i_button_reset, o_counter);
    // Uses 3 buttons to control a counter.
    parameter WIDTH = 4;

    input i_clock;
    input i_button_inc;
    input i_button_dec;
    input i_button_reset;
    output [WIDTH-1:0] o_counter;

    wire button_event;
    wire clean_button_inc;
    wire clean_button_dec;
    wire clean_button_reset;
    reg [WIDTH-1:0] counter = 0;

    assign button_event = clean_button_inc | clean_button_dec | clean_button_reset;
    assign o_counter = counter;

    always @(posedge button_event) begin
        if (clean_button_inc) begin
            counter <= counter + 1;
        end
        if (clean_button_reset) begin
            counter <= 0;
        end
        if (clean_button_dec) begin
            counter <= counter - 1;
        end
    end

    button_debouncer debouncer_inc(
        .i_clock(i_clock),
        .i_button(i_button_inc),
        .o_state(clean_button_inc)
    );

    button_debouncer debouncer_dec(
        .i_clock(i_clock),
        .i_button(i_button_dec),
        .o_state(clean_button_dec)
    );

    button_debouncer debouncer_reset(
        .i_clock(i_clock),
        .i_button(i_button_reset),
        .o_state(clean_button_reset)
    );
endmodule