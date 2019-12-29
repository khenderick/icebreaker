`timescale 1ns / 1ps
`define bits_for(n) (n <  2 ? 1 : \
                     n <  4 ? 2 : \
                     n <  8 ? 3 : \
                     n < 16 ? 4 : \
                     n < 32 ? 5 : \
                     n < 64 ? 6 : 7)

// This files contains modules for playing around with the LED panel
// It uses the LED pabel PMOD connected to PMOD 1A and 1B

module top(CLOCK, BREAK_BUTTON_1, BREAK_BUTTON_2, BREAK_BUTTON_3, LP_CLOCK, LP_LATCH, LP_BLANK, LP_RGB_0, LP_RGB_1, LP_ADDRESS);
    // Press and hold the native button to activate. Releasing it will turn everything off
    // The native red and green leds will indicate the mode

    parameter COLOR_DEPTH = 1;
    parameter COLS = 64;
    parameter ROWS = 64;

    input CLOCK;
    input BREAK_BUTTON_1;
    input BREAK_BUTTON_2;
    input BREAK_BUTTON_3;
    output LP_CLOCK;
    output LP_LATCH;
    output LP_BLANK;
    output [2:0] LP_RGB_0;
    output [2:0] LP_RGB_1;
    output [4:0] LP_ADDRESS;

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
    wire clean_button_1;
    wire clean_button_2;
    wire clean_button_3;
    wire button_state;

    reg [3:0] display_state = S_START;
    reg [ADDRESS_BITS - 1:0] address;
    reg [ADDRESS_BITS - 1:0] address_next;
    reg led_red;
    reg led_green;
    reg latch;
    reg panel_clock;
    reg blank;
    reg [COLOR_DEPTH - 1:0] pwm_threshold;
    reg [COL_BITS - 1:0] col_pointer;
    reg [ROW_BITS - 1:0] row_pointer;

    reg [COL_BITS - 1:0] cursor_x;
    reg [ROW_BITS - 1:0] cursor_y;

    reg r_0, g_0, b_0;
    reg r_1, g_1, b_1;

    // Framebuffer
    reg [(COLS * COLOR_DEPTH * 3) - 1:0] frame_buffer [ROWS - 1:0];
    reg [(COLS * COLOR_DEPTH * 3) - 1:0] row_buffer_0;
    reg [(COLS * COLOR_DEPTH * 3) - 1:0] row_buffer_1;
    reg [(COLS * COLOR_DEPTH * 3) - 1:0] draw_buffer;
    
    assign LP_LATCH = latch;
    assign LP_BLANK = blank;
    assign LP_CLOCK = panel_clock;
    assign LP_ADDRESS = address[ADDRESS_BITS-1:0];
    assign LP_RGB_0 = {b_0, g_0, r_0}; // Red and blue inverted
    assign LP_RGB_1 = {b_1, g_1, r_1}; // Red and blue inverted
    assign button_state = clean_button_1 | clean_button_2 | clean_button_3;

    initial begin
        $readmemh("64x64x1.mem", frame_buffer);
    end

    always @(posedge button_state) begin
        if (clean_button_2) begin
            cursor_y <= cursor_y + 1;
        end
        if (clean_button_3) begin
            cursor_x <= cursor_x + 1;
        end
        if (clean_button_1) begin
            //frame_buffer[cursor_y] <= draw_buffer | (3'b001 << (cursor_x * 3));
        end
    end

    always @(negedge button_state) begin
        if (clean_button_1) begin
            //draw_buffer <= frame_buffer[cursor_y];
        end
    end

    always @(posedge CLOCK) begin  
        if (display_state == S_UNBLANK) begin
            row_buffer_0 <= frame_buffer[address_next];
            row_buffer_1 <= frame_buffer[address_next + (ROWS / 2)]; 
        end
    end

    always @(posedge CLOCK) begin        
        case (display_state)
            S_START: begin
                // Make sure all registers are set on sane start values
                blank <= 1;
                panel_clock <= 0;
                latch <= 0;
                col_pointer <= COLS - 1;
                address <= 0;
                address_next <= 0;
                pwm_threshold <= 0;
                display_state <= S_LOAD;
            end
            S_LOAD: begin
                // Load the RGB values for both channels
                r_0 <= row_buffer_0[(col_pointer * COLOR_DEPTH * 3) + (COLOR_DEPTH * 3) - 1:(col_pointer * COLOR_DEPTH * 3) + (COLOR_DEPTH * 2)] > pwm_threshold || col_pointer == cursor_y;
                g_0 <= row_buffer_0[(col_pointer * COLOR_DEPTH * 3) + (COLOR_DEPTH * 2) - 1:(col_pointer * COLOR_DEPTH * 3) + (COLOR_DEPTH * 1)] > pwm_threshold || address_next == cursor_x;
                b_0 <= row_buffer_0[(col_pointer * COLOR_DEPTH * 3) + (COLOR_DEPTH * 1) - 1:(col_pointer * COLOR_DEPTH * 3) + (COLOR_DEPTH * 0)] > pwm_threshold;
                r_1 <= row_buffer_1[(col_pointer * COLOR_DEPTH * 3) + (COLOR_DEPTH * 3) - 1:(col_pointer * COLOR_DEPTH * 3) + (COLOR_DEPTH * 2)] > pwm_threshold || col_pointer == cursor_y;
                g_1 <= row_buffer_1[(col_pointer * COLOR_DEPTH * 3) + (COLOR_DEPTH * 2) - 1:(col_pointer * COLOR_DEPTH * 3) + (COLOR_DEPTH * 1)] > pwm_threshold || address_next + (ROWS / 2) == cursor_x;
                b_1 <= row_buffer_1[(col_pointer * COLOR_DEPTH * 3) + (COLOR_DEPTH * 1) - 1:(col_pointer * COLOR_DEPTH * 3) + (COLOR_DEPTH * 0)] > pwm_threshold;
                display_state <= S_CLOCK1;
            end
            S_CLOCK1: begin
                // Set clock high
                panel_clock <= 1;
                display_state <= S_CLOCK2;
            end
            S_CLOCK2: begin
                // Set cock low
                panel_clock <= 0;
                if (col_pointer == 0) begin
                    // Continue if a full row is shifted in
                    display_state <= S_BLANK;
                end else begin
                    // Keep shifing bits in
                    col_pointer <= col_pointer - 1;
                    display_state <= S_LOAD;
                end
            end
            S_BLANK: begin
                // Blank display while data is latched
                blank <= 1;
                display_state <= S_LATCH1;
            end
            S_LATCH1: begin
                // Latch high
                latch <= 1;
                display_state <= S_LATCH2;
            end
            S_LATCH2: begin
                // Latch low
                latch <= 0;
                // Prepare for loading new row on next address
                address <= address_next;
                address_next <= address_next + 1;
                display_state <= S_UNBLANK;
            end
            S_UNBLANK: begin
                // Display new data
                blank <= 0;
                // Reset column pointer
                col_pointer <= COLS - 1;
                display_state <= S_PWM;
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
                display_state <= S_LOAD;
            end
        endcase
    end

    clock_divider #(
        .SCALE(12)
    ) divider(
        .i_clock(CLOCK),
        .o_clock(slow_clock)
    );

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
