`timescale 1ns / 1ps

module clock_divider(i_clock, o_clock);
    parameter SCALE = 20;

    input i_clock;
    output o_clock;

    reg [SCALE-1:0] counter;
    reg clock_flag = 1;
    reg output_clock = 0;

    assign o_clock = output_clock;

    always @(posedge i_clock) begin
        if (counter) begin
            counter <= counter + 1;
        end else begin
            output_clock <= clock_flag;
            clock_flag <= ~clock_flag;
            counter <= counter + 1;
        end
    end
endmodule