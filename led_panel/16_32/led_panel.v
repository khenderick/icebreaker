`timescale 1ns / 1ps

// This files contains modules for playing around with the LED panel
// It uses the LED pabel PMOD connected to PMOD 1A and 1B

module top(CLOCK, BREAK_BUTTON_1, LP_CLOCK, LP_LATCH, LP_BLANK, LP_RGB_0, LP_RGB_1, LP_ADDRESS_3, BREAK_LEDS);
    // Press and hold the native button to activate. Releasing it will turn everything off
    // The native red and green leds will indicate the mode

    parameter COLOR_DEPTH = 2;

    input CLOCK;
    input BREAK_BUTTON_1;
    output LP_CLOCK;
    output LP_LATCH;
    output LP_BLANK;
    output [2:0] LP_RGB_0;
    output [2:0] LP_RGB_1;
    output [2:0] LP_ADDRESS_3;
    output [4:0] BREAK_LEDS;

    wire slow_clock;

    reg [3:0] state;
    reg [2:0] address;
    reg led_red;
    reg led_green;
    reg latch;
    reg panel_clock;
    reg blank;

    reg [COLOR_DEPTH-1:0] r_0_value = 0;
    reg [COLOR_DEPTH-1:0] g_0_value = 0;
    reg [COLOR_DEPTH-1:0] b_0_value = 0;
    reg [COLOR_DEPTH-1:0] r_1_value = 0;
    reg [COLOR_DEPTH-1:0] g_1_value = 0;
    reg [COLOR_DEPTH-1:0] b_1_value = 0;
    
    reg [COLOR_DEPTH-1:0] pwm_threshold;

    reg r_0, g_0, b_0;
    reg r_1, g_1, b_1;

    reg [5:0] counter; // 5-bit counter, 0-31

    assign BREAK_LEDS[0] = led_red;
    assign BREAK_LEDS[1] = led_green;
    assign BREAK_LEDS[2] = latch;
    assign BREAK_LEDS[3] = blank;
    assign BREAK_LEDS[4] = slow_clock;
    assign LP_LATCH = latch;
    assign LP_BLANK = blank;
    assign LP_CLOCK = panel_clock;
    assign LP_ADDRESS_3 = address;
    // Blue and red inverted
    assign LP_RGB_0 = {b_0, g_0, r_0};
    assign LP_RGB_1 = {b_1, g_1, r_1};

    localparam S_START = 0,
               S_LOAD = 1,
               S_CLOCK1 = 2,
               S_CLOCK2 = 3,
               S_BLANK = 4, 
               S_LATCH1 = 5,
               S_LATCH2 = 6,
               S_UNBLANK = 7,
               S_PWM = 8;

    always @(posedge slow_clock) begin
        r_0_value <= r_0_value + 1;
        g_1_value <= g_1_value + 1;
    end

    always @(posedge CLOCK or negedge BREAK_BUTTON_1) begin
        if (!BREAK_BUTTON_1) begin
            // Inform that program is inactive
            led_green <= 0;
            led_red <= 1;
            // Blank the panel
            blank <= 1;
            // Ready for release
            state <= S_START;
        end else begin
            // Inform that program is active
            led_green <= 1;
            led_red <= 0;

            case (state)
                S_START: begin
                    // Make sure all registers are set on sane start values
                    blank <= 0;
                    panel_clock <= 0;
                    latch <= 0;
                    counter <= 31;
                    address <= 0;
                    pwm_threshold <= 0;
                    state <= S_LOAD;
                end
                S_LOAD: begin
                    // Load the RGB values for both channels
                    r_0 <= r_0_value > pwm_threshold;
                    g_0 <= g_0_value > pwm_threshold;
                    b_0 <= b_0_value > pwm_threshold;
                    r_1 <= r_1_value > pwm_threshold;
                    g_1 <= g_1_value > pwm_threshold;
                    b_1 <= b_1_value > pwm_threshold;
                    state <= S_CLOCK1;
                end
                S_CLOCK1: begin
                    // Set clock high
                    panel_clock <= 1;
                    state <= S_CLOCK2;
                end
                S_CLOCK2: begin
                    // Set cock low
                    panel_clock <= 0;
                    if (counter == 0) begin
                        // Continue if a full row is shifted in
                        state <= S_BLANK;
                    end else begin
                        // Keep shifing bits in
                        counter <= counter - 1;
                        state <= S_LOAD;
                    end
                end
                S_BLANK: begin
                    // Blank display while data is latched
                    blank <= 1;
                    state <= S_LATCH1;
                end
                S_LATCH1: begin
                    // Latch high
                    latch <= 1;
                    state <= S_LATCH2;
                end
                S_LATCH2: begin
                    // Latch low
                    latch <= 0;
                    state <= S_UNBLANK;
                end
                S_UNBLANK: begin
                    // Display new data
                    blank <= 0;
                    // Prepare for loading new row on next address
                    address <= address + 1;
                    counter <= 31;
                    state <= S_PWM;
                end
                S_PWM: begin
                    if (address == 0) begin
                        // On every full cycle, we need to update the PWM threshold
                        if (COLOR_DEPTH > 1) begin
                            if (&pwm_threshold[COLOR_DEPTH-1:1] == 1 & pwm_threshold[0] == 0) begin
                                pwm_threshold <= 0;
                            end else begin
                                pwm_threshold <= pwm_threshold + 1;
                            end
                        end
                    end
                    state <= S_LOAD;
                end
            endcase
        end
    end

    clock_divider #(
        .SCALE(21)
    ) divider(
        .i_clock(CLOCK),
        .o_clock(slow_clock)
    );
endmodule
