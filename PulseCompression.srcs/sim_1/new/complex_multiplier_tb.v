`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.07.2026 23:35:32
// Design Name: 
// Module Name: complex_multiplier_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module complex_multiplier_tb;

// Inputs
reg signed [15:0] ar;
reg signed [15:0] ai;
reg signed [15:0] br;
reg signed [15:0] bi;

// Output
wire signed [31:0] out_data;

// Instantiate DUT
complex_multiplier uut (

    .ar(ar),
    .ai(ai),
    .br(br),
    .bi(bi),
    .out_data(out_data)

);

initial begin

    // Test Case 1
    ar = 16'd1000;
    ai = 16'd500;
    br = 16'd2000;
    bi = 16'd1000;
    #20;

    // Test Case 2
    ar = 16'd3000;
    ai = -16'd1000;
    br = 16'd1500;
    bi = 16'd2500;
    #20;

    // Test Case 3
    ar = -16'd2000;
    ai = 16'd1000;
    br = 16'd4000;
    bi = -16'd1500;
    #20;

    // Test Case 4
    ar = 16'd0;
    ai = 16'd0;
    br = 16'd5000;
    bi = 16'd2000;
    #20;

    $finish;

end

endmodule
