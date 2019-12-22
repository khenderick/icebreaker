`timescale 1ns / 1ps
`define bits_for(n) (n <  2 ? 1 : \
                     n <  4 ? 2 : \
                     n <  8 ? 3 : \
                     n < 16 ? 4 : \
                     n < 32 ? 5 : \
                     n < 64 ? 6 : 7)

// This files contains modules for playing around with the LED panel
// It uses the LED pabel PMOD connected to PMOD 1A and 1B

module top(CLOCK, BREAK_BUTTON_1, BREAK_BUTTON_2, LP_CLOCK, LP_LATCH, LP_BLANK, LP_RGB_0, LP_RGB_1, LP_ADDRESS);
    // Press and hold the native button to activate. Releasing it will turn everything off
    // The native red and green leds will indicate the mode

    parameter COLOR_DEPTH = 1;
    parameter COLS = 32;
    parameter ROWS = 16;

    input CLOCK;
    input BREAK_BUTTON_1;
    input BREAK_BUTTON_2;
    output LP_CLOCK;
    output LP_LATCH;
    output LP_BLANK;
    output [2:0] LP_RGB_0;
    output [2:0] LP_RGB_1;
    output [4:0] LP_ADDRESS;

    localparam RGB_WIDTH = COLOR_DEPTH * 3;
    localparam COL_BITS = `bits_for(COLS - 1);
    localparam ROW_BITS = `bits_for(ROWS - 1);
    localparam ADDRESS_BITS = `bits_for((ROWS / 2) - 1);
    localparam S_START = 0,
               S_LOAD = 1,
               S_CLOCK1 = 2,
               S_CLOCK2 = 3,
               S_LATCH1 = 4,
               S_LATCH2 = 5,
               S_BLANK = 6,
               S_UNBLANK = 7,
               S_PWM = 8;

    wire slow_clock;

    reg [3:0] state = S_START;
    reg [ADDRESS_BITS - 1:0] address;
    reg [ADDRESS_BITS - 1:0] address_next;
    reg led_red;
    reg led_green;
    reg latch;
    reg panel_clock;
    reg blank;
    reg [COLOR_DEPTH - 1:0] pwm_threshold;
    reg [COL_BITS - 1:0] col_pointer;
    reg [ROW_BITS - 1:0] row_pointer = 0;

    reg r_0, g_0, b_0;
    reg r_1, g_1, b_1;

    // Framebuffer
    reg [(COLS * RGB_WIDTH) - 1:0] frame_buffer [ROWS - 1:0];

    assign LP_LATCH = latch;
    assign LP_BLANK = blank;
    assign LP_CLOCK = panel_clock;
    assign LP_ADDRESS = address[ADDRESS_BITS-1:0];
    assign LP_RGB_0 = {b_0, g_0, r_0}; // Red and blue inverted
    assign LP_RGB_1 = {b_1, g_1, r_1}; // Red and blue inverted

    initial begin
        frame_buffer[0] = {COLS{3'b111}};
        for (row_pointer = 1; row_pointer < ROWS - 1; row_pointer = row_pointer + 1) begin
            frame_buffer[row_pointer] = {3'b111, {COLS - 2{3'b000}}, 3'b111};
        end
        frame_buffer[ROWS - 1] = {COLS{3'b111}};
    end

    always @(posedge CLOCK) begin
        if (BREAK_BUTTON_1) begin
            blank <= 1;
            state <= S_START;
        end else begin
            case (state)
                S_START: begin
                    // Make sure all registers are set on sane start values
                    blank <= 1;
                    panel_clock <= 0;
                    latch <= 0;
                    col_pointer <= COLS - 1;
                    address <= 0;
                    address_next <= 0;
                    pwm_threshold <= 0;
                    state <= S_LOAD;
                end
                S_LOAD: begin
                    // Load the RGB values for both channels
                    r_0 <= frame_buffer[address_next][(col_pointer * RGB_WIDTH) + (COLOR_DEPTH * 2)+(COLOR_DEPTH - 1):(col_pointer * RGB_WIDTH) + (COLOR_DEPTH * 2)] > pwm_threshold;
                    g_0 <= frame_buffer[address_next][(col_pointer * RGB_WIDTH) + (COLOR_DEPTH * 1)+(COLOR_DEPTH - 1):(col_pointer * RGB_WIDTH) + (COLOR_DEPTH * 1)] > pwm_threshold;
                    b_0 <= frame_buffer[address_next][(col_pointer * RGB_WIDTH) + (COLOR_DEPTH * 0)+(COLOR_DEPTH - 1):(col_pointer * RGB_WIDTH) + (COLOR_DEPTH * 0)] > pwm_threshold;
                    r_1 <= frame_buffer[address_next + (ROWS / 2)][(col_pointer * RGB_WIDTH) + (COLOR_DEPTH * 2) + (COLOR_DEPTH - 1):(col_pointer * RGB_WIDTH) + (COLOR_DEPTH * 2)] > pwm_threshold;
                    g_1 <= frame_buffer[address_next + (ROWS / 2)][(col_pointer * RGB_WIDTH) + (COLOR_DEPTH * 1) + (COLOR_DEPTH - 1):(col_pointer * RGB_WIDTH) + (COLOR_DEPTH * 1)] > pwm_threshold;
                    b_1 <= frame_buffer[address_next + (ROWS / 2)][(col_pointer * RGB_WIDTH) + (COLOR_DEPTH * 0) + (COLOR_DEPTH - 1):(col_pointer * RGB_WIDTH) + (COLOR_DEPTH * 0)] > pwm_threshold;
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
                    if (col_pointer == 0) begin
                        // Continue if a full row is shifted in
                        state <= S_BLANK;
                    end else begin
                        // Keep shifing bits in
                        col_pointer <= col_pointer - 1;
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
                    address <= address_next;
                    address_next <= address_next + 1;
                    col_pointer <= COLS - 1;
                    state <= S_PWM;
                end
                S_PWM: begin
                    if (address_next == 0) begin
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
        .SCALE(8)
    ) divider(
        .i_clock(CLOCK),
        .o_clock(slow_clock)
    );
endmodule
