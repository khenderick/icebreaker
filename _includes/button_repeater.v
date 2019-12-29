`timescale 1ns / 1ps
`define bits_for(n) (n <  2 ? 1 : \
                     n <  4 ? 2 : \
                     n <  8 ? 3 : \
                     n < 16 ? 4 : \
                     n < 32 ? 5 : \
                     n < 64 ? 6 : 7)

module button_repeater(i_clock, i_button, o_button);
    // Input and output button are held together, but when the input button is hold down, the output
    // button will start "repeating" at a given frequency
    parameter REPEAT_WAIT = 6;
    parameter REPEAT_FREQ = 2;

    input i_clock;
    input i_button;
    output o_button;

    localparam S_FOLLOW = 0,
               S_REPEAT = 1;

    wire slow_clock;
    wire button;
    wire clean_button;

    reg button_state = 1;
    reg state = S_FOLLOW;
    reg [REPEAT_WAIT-1:0] wait_counter = 1;
    reg [REPEAT_FREQ-1:0] freq_counter = 1;

    assign o_button = state == S_FOLLOW ? clean_button : button_state;

    always @(posedge slow_clock) begin
        if (clean_button) begin
            case (state)
                S_FOLLOW: begin
                    button_state <= 1;
                    if (wait_counter == 0) begin
                        state <= S_REPEAT;
                    end else begin
                        wait_counter <= wait_counter + 1;
                    end
                end
                S_REPEAT: begin
                    if (freq_counter == 0) begin
                        button_state <= ~button_state;
                    end
                    freq_counter <= freq_counter + 1;
                end
            endcase
        end else begin
            wait_counter <= 1;
            freq_counter <= 1;
            state <= S_FOLLOW;
        end
    end

    button_debouncer debouncer(
        .i_clock(i_clock),
        .i_button(i_button),
        .o_state(clean_button)
    );

    clock_divider #(
        .SCALE(15)
    ) divider(
        .i_clock(i_clock),
        .o_clock(slow_clock)
    );
endmodule