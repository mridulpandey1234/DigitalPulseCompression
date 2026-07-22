`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// fft_rx_tb.v  (CORRECTED)
//
// Two changes vs. your original:
//
// 1. FFT CONFIG WORD: s_axis_config_tdata = 16'h0000 sets bit0=0 (INVERSE
//    transform -- confirmed against AMD's own tb_fft_mf.vhd for this exact
//    IP customization, where FWD explicitly means tdata(0)='1') and leaves
//    the scaling schedule (bits 12:1) at all zeros, i.e. no scaling at any
//    of the 6 radix-4 stages for your 4096-point (NFFT_MAX=12) transform.
//    With real Q1.15 fixed-point radar data and no scaling, intermediate
//    sums can overflow/wrap. Changed to 16'h1557: bit0=1 (forward),
//    bits[12:1] = the vendor default "largest safe scaling per stage"
//    schedule for this exact C_ARCH=3 / NFFT_MAX=12 / C_HAS_SCALING=1
//    customization (derived directly from tb_fft_mf.vhd's config_stimuli
//    process). Re-derive from PG109 if you ever change NFFT/architecture.
//
// 2. COMPLETION WAIT: "repeat(5000) @(posedge clk)" after the last input
//    sample assumes you already know the core's pipeline latency and that
//    it's under 5000 cycles. AMD's own generated testbench for this exact
//    core (tb_fft_mf.vhd) never guesses a cycle count -- it does
//    "wait until m_axis_data_tlast = '1';" and lets the simulation run as
//    long as it needs to. Changed to the same approach, with a generous
//    timeout as a safety net so the sim can't hang forever if something is
//    genuinely broken.
//////////////////////////////////////////////////////////////////////////////////

module fft_rx_tb;

    parameter DATA_WIDTH = 16;
    parameter FFT_POINTS = 4096;
    parameter TIMEOUT_CYCLES = 60000;   // generous safety net, not a guess at latency

    reg clk = 0;
    always #5 clk = ~clk;

    reg signed [15:0] rx_real [0:FFT_POINTS-1];
    reg signed [15:0] rx_imag [0:FFT_POINTS-1];

    reg [15:0] s_axis_config_tdata;
    reg        s_axis_config_tvalid;
    wire       s_axis_config_tready;

    reg  [31:0] s_axis_data_tdata;
    reg         s_axis_data_tvalid;
    wire        s_axis_data_tready;
    reg         s_axis_data_tlast;

    wire [31:0] m_axis_data_tdata;
    wire        m_axis_data_tvalid;
    wire        m_axis_data_tlast;

    wire event_frame_started;
    wire event_tlast_unexpected;
    wire event_tlast_missing;
    wire event_status_channel_halt;
    wire event_data_in_channel_halt;
    wire event_data_out_channel_halt;

    fft_rx DUT
    (
        .aclk(clk),

        .s_axis_config_tdata(s_axis_config_tdata),
        .s_axis_config_tvalid(s_axis_config_tvalid),
        .s_axis_config_tready(s_axis_config_tready),

        .s_axis_data_tdata(s_axis_data_tdata),
        .s_axis_data_tvalid(s_axis_data_tvalid),
        .s_axis_data_tready(s_axis_data_tready),
        .s_axis_data_tlast(s_axis_data_tlast),

        .m_axis_data_tdata(m_axis_data_tdata),
        .m_axis_data_tvalid(m_axis_data_tvalid),
        .m_axis_data_tready(1'b1),
        .m_axis_data_tlast(m_axis_data_tlast),

        .event_frame_started(event_frame_started),
        .event_tlast_unexpected(event_tlast_unexpected),
        .event_tlast_missing(event_tlast_missing),
        .event_status_channel_halt(event_status_channel_halt),
        .event_data_in_channel_halt(event_data_in_channel_halt),
        .event_data_out_channel_halt(event_data_out_channel_halt)
    );

    integer i;
    integer cycle_count;
    integer produced;
    reg     saw_tlast;

    initial
    begin
        $readmemh("rx_real.mem", rx_real);
        $readmemh("rx_imag.mem", rx_imag);
    end

    initial
    begin
        s_axis_config_tdata  = 16'h0000;
        s_axis_config_tvalid = 0;

        s_axis_data_tdata  = 0;
        s_axis_data_tvalid = 0;
        s_axis_data_tlast  = 0;

        cycle_count = 0;
        produced    = 0;
        saw_tlast   = 1'b0;

        repeat(5) @(posedge clk);

        $display("Sending FFT Configuration...");

        // bit0=1 forward, bits[12:1]=default safe scale schedule for this
        // core (see header note) -- was 16'h0000 (inverse, no scaling)
        s_axis_config_tdata  = 16'h1557;
        s_axis_config_tvalid = 1;

        while(!s_axis_config_tready)
            @(posedge clk);

        @(posedge clk);

        s_axis_config_tvalid = 0;

        $display("Configuration Accepted.");

        for(i=0;i<FFT_POINTS;i=i+1)
        begin
            s_axis_data_tdata  = {rx_imag[i],rx_real[i]};
            s_axis_data_tvalid = 1'b1;
            s_axis_data_tlast  = (i == FFT_POINTS-1);

            while(!s_axis_data_tready)
                @(posedge clk);

            @(posedge clk);
        end

        s_axis_data_tvalid = 0;
        s_axis_data_tlast  = 0;

        $display("Finished Sending Frame.");

        // Wait for the core's own TLAST, not a fixed guessed cycle count.
        while (!saw_tlast && cycle_count < TIMEOUT_CYCLES) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            if (m_axis_data_tvalid) produced = produced + 1;
            if (m_axis_data_tvalid && m_axis_data_tlast) saw_tlast = 1'b1;
        end

        if (!saw_tlast)
            $display("TIMEOUT after %0d cycles -- no output TLAST seen. Either the core is still draining (raise TIMEOUT_CYCLES / check PG109 for documented latency) or something upstream is actually broken.", cycle_count);
        else
            $display("Simulation Finished: %0d output samples, TLAST seen after %0d cycles.", produced, cycle_count);

        $finish;
    end

    always @(posedge clk)
    begin
        if(m_axis_data_tvalid)
            $display("TIME=%0t  FFT_OUT=%h  TLAST=%b", $time, m_axis_data_tdata, m_axis_data_tlast);
    end

    always @(posedge clk)
    begin
        if(event_frame_started)         $display("Frame Started @ %0t",$time);
        if(event_tlast_missing)         $display("ERROR : TLAST Missing");
        if(event_tlast_unexpected)      $display("ERROR : Unexpected TLAST");
        if(event_status_channel_halt)   $display("ERROR : Status Channel Halt");
        if(event_data_in_channel_halt)  $display("ERROR : Data Input Halt");
        if(event_data_out_channel_halt) $display("ERROR : Data Output Halt");
    end

endmodule