`timescale 1ns / 1ps

module top_tb;

parameter CLK_PERIOD = 10;

//--------------------------------------------------
// Clock & Reset
//--------------------------------------------------

reg clk;
reg rstn;

initial
    clk = 1'b0;

always #(CLK_PERIOD/2)
    clk = ~clk;

initial
begin
    rstn = 1'b0;

    repeat(5) @(posedge clk);

    rstn = 1'b1;
end

//--------------------------------------------------
// DUT
//--------------------------------------------------

top DUT
(
    .clk  (clk),
    .rstn (rstn)
);

//--------------------------------------------------
// Monitor FFT RX Output
//--------------------------------------------------

always @(posedge clk)
begin
    if(DUT.fft_rx_out_tvalid)
    begin
        $display("TIME=%0t | FFT_RX = %h | TLAST=%b",
                  $time,
                  DUT.fft_rx_out_tdata,
                  DUT.fft_rx_out_tlast);
    end
end

//--------------------------------------------------
// Monitor FFT MF Output
//--------------------------------------------------

always @(posedge clk)
begin
    if(DUT.fft_mf_out_tvalid)
    begin
        $display("TIME=%0t | FFT_MF = %h | TLAST=%b",
                  $time,
                  DUT.fft_mf_out_tdata,
                  DUT.fft_mf_out_tlast);
    end
end

//--------------------------------------------------
// Monitor FFT Event Signals (RX)
//--------------------------------------------------

always @(posedge clk)
begin
    if(DUT.FFT_RX.event_frame_started)
        $display("RX Frame Started");

    if(DUT.FFT_RX.event_tlast_missing)
        $display("RX ERROR : Missing TLAST");

    if(DUT.FFT_RX.event_tlast_unexpected)
        $display("RX ERROR : Unexpected TLAST");

    if(DUT.FFT_RX.event_status_channel_halt)
        $display("RX ERROR : Status Channel Halt");

    if(DUT.FFT_RX.event_data_in_channel_halt)
        $display("RX ERROR : Data Input Halt");

    if(DUT.FFT_RX.event_data_out_channel_halt)
        $display("RX ERROR : Data Output Halt");
end

//--------------------------------------------------
// Monitor FFT Event Signals (MF)
//--------------------------------------------------

always @(posedge clk)
begin
    if(DUT.FFT_MF.event_frame_started)
        $display("MF Frame Started");

    if(DUT.FFT_MF.event_tlast_missing)
        $display("MF ERROR : Missing TLAST");

    if(DUT.FFT_MF.event_tlast_unexpected)
        $display("MF ERROR : Unexpected TLAST");

    if(DUT.FFT_MF.event_status_channel_halt)
        $display("MF ERROR : Status Channel Halt");

    if(DUT.FFT_MF.event_data_in_channel_halt)
        $display("MF ERROR : Data Input Halt");

    if(DUT.FFT_MF.event_data_out_channel_halt)
        $display("MF ERROR : Data Output Halt");
end

//--------------------------------------------------
// End Simulation
//--------------------------------------------------

initial
begin
    repeat(20000) @(posedge clk);

    $display("-----------------------------------------");
    $display("Simulation Finished");
    $display("-----------------------------------------");

    $finish;
end

endmodule