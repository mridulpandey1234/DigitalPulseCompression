`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Module Name : ram_mf
// Description : Single-Port Synchronous RAM for Matched Filter
//
// Stores complex matched filter coefficients.
//
// mem_re -> Real Part
// mem_im -> Imaginary Part
//////////////////////////////////////////////////////////////////////////////////

module ram_mf
#(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 12
)
(
    input  wire                             clk,
    input  wire                             cs,
    input  wire                             we,
    input  wire [ADDR_WIDTH-1:0]            address,

    // Write Inputs
    input  wire signed [DATA_WIDTH-1:0]     data_in_re,
    input  wire signed [DATA_WIDTH-1:0]     data_in_im,

    // Read Outputs
    output reg  signed [DATA_WIDTH-1:0]     data_out_re,
    output reg  signed [DATA_WIDTH-1:0]     data_out_im
);

    //----------------------------------------------------------
    // Memory Declaration
    //----------------------------------------------------------

    reg signed [DATA_WIDTH-1:0] mem_re [0:(1<<ADDR_WIDTH)-1];
    reg signed [DATA_WIDTH-1:0] mem_im [0:(1<<ADDR_WIDTH)-1];

    //----------------------------------------------------------
    // Memory Initialization
    //----------------------------------------------------------

    initial
    begin
        data_out_re = 0;
        data_out_im = 0;

        $readmemh("mf_real.mem", mem_re);
        $readmemh("mf_imag.mem", mem_im);
    end

    //----------------------------------------------------------
    // Read / Write Logic
    //----------------------------------------------------------

    always @(posedge clk)
    begin
        if(cs)
        begin
            if(we)
            begin
                // Write Operation
                mem_re[address] <= data_in_re;
                mem_im[address] <= data_in_im;
            end
            else
            begin
                // Read Operation
                data_out_re <= mem_re[address];
                data_out_im <= mem_im[address];
            end
        end
    end

endmodule