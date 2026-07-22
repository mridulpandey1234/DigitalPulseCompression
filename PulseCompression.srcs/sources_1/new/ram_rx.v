`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Module Name : ram_rx
// Description : Parameterized Single-Port Synchronous RAM
//
// Features:
// - 16-bit data width (suitable for FFT input)
// - 4096 memory locations (12-bit address)
// - Synchronous write
// - Synchronous read
// - Optional memory initialization using $readmemh()
// - FPGA synthesizable (Vivado can infer Block RAM)
//////////////////////////////////////////////////////////////////////////////////

module ram_rx
#(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 12
)
(
    input  wire                     clk,
    input  wire                     cs,          // Chip Select
    input  wire                     we,          // Write Enable
    input  wire [ADDR_WIDTH-1:0]    address,     // Read/Write Address
    input  wire signed [DATA_WIDTH-1:0]    data_in_re,     // Real Data to be written
    input  wire signed [DATA_WIDTH-1:0]    data_in_im,     // Imaginary Data to be written
    output reg signed [DATA_WIDTH-1:0]    data_out_re,     // Data read from memory
    output reg signed [DATA_WIDTH-1:0]    data_out_im     // Data read from memory

);

    //----------------------------------------------------------
    // Memory Declaration ( Memories are signed due to real and imaginary data )
    //----------------------------------------------------------

    reg signed [DATA_WIDTH-1:0] mem_re_rx [0:(1<<ADDR_WIDTH)-1];
    
    reg signed [DATA_WIDTH-1:0] mem_im_rx [0:(1<<ADDR_WIDTH)-1];

    //----------------------------------------------------------
    // Uncomment during simulation
    //----------------------------------------------------------

    
   initial
begin
    data_out_re = 0;
    data_out_im = 0;

    $readmemh("rx_real.mem", mem_re_rx);
    $readmemh("rx_imag.mem", mem_im_rx);
end
   

    //----------------------------------------------------------
    // we = 1  -> Write Operation
    // we = 0  -> Read Operation
    //----------------------------------------------------------

    always @(posedge clk)
    begin

        if(cs)
        begin
            // WRITE
            if(we)
            begin
                mem_re_rx[address] <= data_in_re;
                mem_im_rx[address] <= data_in_im;

            end
            // READ
            else
            begin
                data_out_re <= mem_re_rx[address];
                data_out_im <= mem_im_rx[address];
            end
        end
     end
endmodule