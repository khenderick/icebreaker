`timescale 1ns / 1ps

// This files contains modules for playing around with the LED panel
// It uses the LED pabel PMOD connected to PMOD 1A and 1B

module top(CLOCK, BREAK_BUTTON_1, LP_CLOCK, LP_LATCH, LP_BLANK, LP_RGB_0, LP_RGB_1, LP_ADDRESS_3, BREAK_LEDS);
    // Press and hold the native button to activate. Releasing it will turn everything off
    // The native red and green leds will indicate the mode

    input CLOCK;
    input BREAK_BUTTON_1;
    output LP_CLOCK;
    output LP_LATCH;
    output LP_BLANK;
    output [2:0] LP_RGB_0;
    output [2:0] LP_RGB_1;
    output [2:0] LP_ADDRESS_3;
    output [4:0] BREAK_LEDS;

    reg [3:0] state;
    reg [2:0] address;
    reg led_red;
    reg led_green;
    reg latch;
    reg panel_clock;
    reg blank;

    reg [2:0] rgb_0;
    reg [2:0] rgb_1;

    reg [5:0] counter;

    assign BREAK_LEDS[0] = led_red;
    assign BREAK_LEDS[1] = led_green;
    assign BREAK_LEDS[2] = latch;
    assign BREAK_LEDS[3] = blank;
    assign BREAK_LEDS[4] = panel_clock;
    assign LP_LATCH = latch;
    assign LP_BLANK = blank;
    assign LP_CLOCK = panel_clock;
    assign LP_ADDRESS_3 = address;
    assign LP_RGB_0 = rgb_0;
    assign LP_RGB_1 = rgb_1;

    localparam S_START = 0,
               S_LOAD = 1,
               S_CLOCK1 = 2,
               S_CLOCK2 = 3,
               S_BLANK = 4, 
               S_LATCH1 = 5,
               S_LATCH2 = 6,
               S_UNBLANK = 7;

    always @(posedge CLOCK or negedge BREAK_BUTTON_1) begin
        if (!BREAK_BUTTON_1) begin
            // Inform that program is inactive
            led_green <= 0;
            led_red <= 1;
            // Blank the panel
            blank <= 1;
            // Init counters
            state <= S_START;
        end else begin
            // Inform that program is active
            led_green <= 1;
            led_red <= 0;

            case (state)
                S_START: begin
                    blank <= 0;
                    panel_clock <= 0;
                    latch <= 0;
                    counter <= 31;
                    address <= 0;
                    state <= S_LOAD;
                end
                S_LOAD: begin
                    rgb_0 <= 7; //counter[2:0];
                    rgb_1 <= 7; //counter[5:3];
                    state <= S_CLOCK1;
                end
                S_CLOCK1: begin
                    panel_clock <= 1;
                    state <= S_CLOCK2;
                end
                S_CLOCK2: begin
                    panel_clock <= 0;
                    if (counter == 0) begin
                        state <= S_BLANK;
                    end else begin
                        counter <= counter - 1;
                        state <= S_LOAD;
                    end
                end
                S_BLANK: begin
                    blank <= 1;
                    state <= S_LATCH1;
                end
                S_LATCH1: begin
                    latch <= 1;
                    state <= S_LATCH2;
                end
                S_LATCH2: begin
                    latch <= 0;
                    state <= S_UNBLANK;
                end
                S_UNBLANK: begin
                    address <= address + 1;
                    blank <= 0;
                    counter <= 31;
                    state <= S_LOAD;
                end
            endcase
        end
    end
endmodule
