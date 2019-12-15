`timescale 1ns / 1ps

module button_debouncer(i_clock, i_button, o_state, o_press_event, o_release_event);
    // This debouncer will shortly pulse an event when the given button is
    // pressed or released and outputs a stable/debounced output state
    parameter DELAY = 12;

    input i_clock;
    input i_button;
    output o_state;
    output o_press_event;
    output o_release_event;

    wire slow_clock;

    reg state = 0;
    reg press_event = 0;
    reg release_event = 0;

    reg previous_state = 0;
    reg current_state = 0;

    assign o_state = state;
    assign o_press_event = press_event;
    assign o_release_event = release_event;

    always @(posedge slow_clock) begin
        current_state = i_button;
        if (current_state == previous_state) begin // Button was not pressed not released
            press_event <= 0;
            release_event <= 0;
        end else begin // Button was pressed or released
            state <= current_state;
            // Update events
            press_event <= current_state; // If the current state is 1, the button is pressed
            release_event <= previous_state; // If the previous state is 1, the current state is 0, so the button is released
            // Store the old state
            previous_state <= current_state;
        end
    end

    clock_divider #(
        .SCALE(DELAY)
    ) divider(
        .i_clock(i_clock),
        .o_clock(slow_clock)
    );
endmodule