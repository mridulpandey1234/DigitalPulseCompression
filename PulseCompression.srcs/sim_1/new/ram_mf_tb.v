`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Testbench for ram_mf
//
// Reads all 4096 locations from:
//      mf_real.mem
//      mf_imag.mem
//
// Displays:
//      Address
//      Real Part
//      Imaginary Part
//////////////////////////////////////////////////////////////////////////////////

module ram_mf_tb;

    //--------------------------------------------------
    // Parameters
    //--------------------------------------------------

    parameter DATA_WIDTH = 16;
    parameter ADDR_WIDTH = 12;

    //--------------------------------------------------
    // Testbench Signals
    //--------------------------------------------------

    reg clk;
    reg cs;
    reg we;

    reg [ADDR_WIDTH-1:0] address;

    reg signed [DATA_WIDTH-1:0] data_in_re;
    reg signed [DATA_WIDTH-1:0] data_in_im;

    wire signed [DATA_WIDTH-1:0] data_out_re;
    wire signed [DATA_WIDTH-1:0] data_out_im;

    integer i;

    //--------------------------------------------------
    // Instantiate RAM
    //--------------------------------------------------

    ram_mf DUT
    (
        .clk(clk),
        .cs(cs),
        .we(we),
        .address(address),

        .data_in_re(data_in_re),
        .data_in_im(data_in_im),

        .data_out_re(data_out_re),
        .data_out_im(data_out_im)
    );

    //--------------------------------------------------
    // Clock Generation
    //--------------------------------------------------

    initial
    begin
        clk = 1'b0;

        forever
            #5 clk = ~clk;
    end

    //--------------------------------------------------
    // Read Entire Memory
    //--------------------------------------------------

    initial
    begin

        cs = 1'b1;
        we = 1'b0;      // Read Mode

        address = 0;

        data_in_re = 0;
        data_in_im = 0;

        // Wait for memory initialization
        #20;

        //--------------------------------------------------
        // Read all 4096 locations
        //--------------------------------------------------

        for(i = 0; i < 4096; i = i + 1)
        begin

            address = i;

            // Wait for synchronous read
            @(posedge clk);

            // Wait for non-blocking assignment to update
            #1;

            $display("----------------------------------------------");
            $display("Address      : %4d", address);
            $display("Real Part    : %6d (0x%04h)", data_out_re, data_out_re);
            $display("Imag Part    : %6d (0x%04h)", data_out_im, data_out_im);

        end

        $display("----------------------------------------------");
        $display("Finished reading all 4096 locations.");
        $display("----------------------------------------------");

        $finish;

    end

endmodule