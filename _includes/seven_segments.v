`timescale 1ns / 1ps

module seven_segments(i_clock, i_segments_digit_0, i_segments_digit_1, o_sev_segments, o_sev_seg_cathode);
    // Displays two digits to the seven segment PMOD by fast alternating between the two digits

    input i_clock;
    input [6:0] i_segments_digit_0;
    input [6:0] i_segments_digit_1;
    output [6:0] o_sev_segments;
    output o_sev_seg_cathode;

    reg digit_select = 0;
    reg [6:0] sev_segments;
    reg sev_seg_cathode;

    assign o_sev_segments = ~sev_segments; // Active low
    assign o_sev_seg_cathode = sev_seg_cathode;

    always @(posedge i_clock) begin
        sev_seg_cathode <= digit_select;
        if (digit_select == 0) begin // Active low
            sev_segments <= i_segments_digit_1;
        end else begin
            sev_segments <= i_segments_digit_0;
        end
        digit_select <= ~digit_select;
    end
endmodule