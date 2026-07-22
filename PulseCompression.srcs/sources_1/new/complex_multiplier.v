`timescale 1ns / 1ps

module complex_multiplier(

    input  wire signed [15:0] ar,
    input  wire signed [15:0] ai,
    input  wire signed [15:0] br,
    input  wire signed [15:0] bi,

    output wire signed [63:0] out_data

);

//------------------------------------------------------
// Q1.15 × Q1.15 = Q2.30 (32-bit)
//------------------------------------------------------

wire signed [31:0] real_temp;
wire signed [31:0] imag_temp;

//------------------------------------------------------
// Complex multiplication
//------------------------------------------------------

assign real_temp = (ar * br) - (ai * bi);
assign imag_temp = (ar * bi) + (ai * br);

//------------------------------------------------------
// Output
//------------------------------------------------------

assign out_data = {imag_temp, real_temp};

endmodule