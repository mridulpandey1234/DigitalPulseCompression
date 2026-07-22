`timescale 1ns / 1ps


module top
#(
    parameter DATA_WIDTH = 16,
    parameter FFT_POINTS = 4096,
    parameter ADDR_WIDTH = 12
)
(
    input wire clk,
    input wire rstn
);

//----------------------------------------
// Local Parameters
//----------------------------------------

localparam FFT_CONFIG = 16'h1557;
localparam IFFT_CONFIG = 16'h1556;

//---------------------------------------
// Internal Wires
//---------------------------------------

// RAM Outputs
//
reg [ADDR_WIDTH-1:0] rx_address;   
reg [ADDR_WIDTH-1:0] mf_address;   
    
//===========================================================================================   
// We're keeping address as reg as we need to update it at every cycle in the address counter 
//============================================================================================
//
// FFT RX AXI-Stream
//

wire [15:0] fft_config_rx_tdata;
wire        fft_config_rx_tvalid;
wire        fft_config_rx_tready;


wire [31:0] fft_rx_out_tdata;
wire        fft_rx_out_tvalid;
wire        fft_rx_input_tready;
wire        fft_rx_out_tlast;

//
// FFT MF AXI-Stream
//

wire [15:0] fft_config_mf_tdata;
wire        fft_config_mf_tvalid;
wire        fft_config_mf_tready;


wire [31:0] fft_mf_out_tdata;
wire        fft_mf_out_tvalid;
wire        fft_mf_input_tready;
wire        fft_mf_out_tlast;

//
// Complex Multiplier
//

wire signed [31:0] mult_real;
wire signed [31:0] mult_imag;

//
// IFFT AXI-Stream
//

wire [15:0] ifft_config_tdata;
wire        ifft_config_tvalid;
wire        ifft_config_tready;

wire [63:0] ifft_out_tdata;
wire        ifft_out_tvalid;
wire        ifft_out_tready;
wire        ifft_out_tlast;

//-------------------------=======================================================
// FFT MF Input Registers ( IN order to prevent clock misatch between fft and RAM
//-------------------------=======================================================

reg [31:0] fft_mf_input_tdata;
reg        fft_mf_input_tvalid;
reg        fft_mf_input_tlast;

//---------------------------------------
// FFT RX Input Registers
//---------------------------------------

reg [31:0] fft_rx_input_tdata;
reg        fft_rx_input_tvalid;
reg        fft_rx_input_tlast;


//-------------------===========================
// Address Counter   ONLY UNTIL FSM IS NOT MADE 
//-------------------===========================

always @(posedge clk)
begin
    if (!rstn)
    begin
        rx_address <= 0;
        mf_address <= 0;
    end
    else
    begin
        if (fft_rx_input_tvalid && fft_rx_input_tready &&
            rx_address < FFT_POINTS-1)
            rx_address <= rx_address + 1;

        if (fft_mf_input_tvalid && fft_mf_input_tready &&
            mf_address < FFT_POINTS-1)
            mf_address <= mf_address + 1;
    end
end
//---------------------------------------
// RAM RX
//---------------------------------------

wire signed [DATA_WIDTH-1:0] rx_real;
wire signed [DATA_WIDTH-1:0] rx_imag;

ram_rx #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
)
RX_RAM
(
    .clk         (clk),
    .cs          (1'b1),
    .we          (1'b0),
    .address     (rx_address),
                                        
    .data_in_re  ({DATA_WIDTH{1'b0}}),  
    .data_in_im  ({DATA_WIDTH{1'b0}}), 
    
    //====================================================
    //these can be zero as we are just reading the output
    //====================================================
    .data_out_re (rx_real),    
    .data_out_im (rx_imag)     
);                             
//================================================================================
// These rx_real and rx_imag are just the wires that connect with data_out_re & im 
//=================================================================================

//---------------------------------------
// RAM Mf
//---------------------------------------
wire signed [DATA_WIDTH-1:0] mf_real;
wire signed [DATA_WIDTH-1:0] mf_imag;

ram_mf #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
)
MF_RAM
(
    .clk         (clk),
    .cs          (1'b1),
    .we          (1'b0),
    .address     (mf_address),

    .data_in_re  ({DATA_WIDTH{1'b0}}),
    .data_in_im  ({DATA_WIDTH{1'b0}}),

    .data_out_re (mf_real),
    .data_out_im (mf_imag)
);


//---------------------==========================
// Pack RAM Outputs and Give them to AXI register
//---------------------==========================

//assign fft_rx_data = {rx_imag, rx_real};
//assign fft_mf_data = {mf_imag, mf_real}; 

//THIS IS REDUNDANT NOW THAT WE ARE PROCEDURALLY ASSIGNING THIS TO THE REGISTER

reg [ADDR_WIDTH-1:0] mf_address_d ; 

//==============================================================================================
//We make this new address that gets updated 1 clock later so that we can accurately show tlast
//==============================================================================================

always@(posedge clk)
begin
    if (!rstn)
    begin
        mf_address_d <= 0 ;

        fft_mf_input_tdata  <= 32'd0;
        fft_mf_input_tvalid <= 1'b0;
        fft_mf_input_tlast  <= 1'b0;
    end
    else if (fft_mf_input_tready)
    begin
        mf_address_d <= mf_address;
        
        fft_mf_input_tdata  <= {mf_imag, mf_real};
        fft_mf_input_tvalid <= 1'b1;
        fft_mf_input_tlast  <= (mf_address_d == FFT_POINTS-1);
    end
end


reg [ADDR_WIDTH-1:0] rx_address_d ; 
//=============================================================================================
//We make this new address that gets updated 1 clock later so that we can accurately show tlast
//==============================================================================================
always @(posedge clk)
begin
    if (!rstn)
    begin
        rx_address_d <= 0;

        fft_rx_input_tdata  <= 0;
        fft_rx_input_tvalid <= 0;
        fft_rx_input_tlast  <= 0;
    end
    else if (fft_rx_input_tready)
    begin
        rx_address_d <= rx_address;

        fft_rx_input_tdata  <= {rx_imag, rx_real};
        fft_rx_input_tvalid <= 1'b1;
        fft_rx_input_tlast  <= (rx_address_d == FFT_POINTS-1);
    end
end

//---------------------------------------
// FFT Configuration
//---------------------------------------   

assign fft_config_rx_tdata  = FFT_CONFIG;   
assign fft_config_rx_tvalid = 1'b1;       

assign fft_config_mf_tdata  = FFT_CONFIG;
assign fft_config_mf_tvalid = 1'b1;

//---------------------------------------
// FFT RX
//---------------------------------------

fft_rx FFT_RX
(
    .aclk(clk),

    .s_axis_config_tdata  (fft_config_rx_tdata),
    .s_axis_config_tvalid (fft_config_rx_tvalid),
    .s_axis_config_tready (fft_config_rx_tready),

    .s_axis_data_tdata  (fft_rx_input_tdata),
    .s_axis_data_tvalid (fft_rx_input_tvalid),
    .s_axis_data_tready (fft_rx_input_tready),
    .s_axis_data_tlast  (fft_rx_input_tlast),

    .m_axis_data_tdata    (fft_rx_out_tdata),
    .m_axis_data_tvalid   (fft_rx_out_tvalid),
    .m_axis_data_tready   (1'b1),
    .m_axis_data_tlast    (fft_rx_out_tlast),

    .event_frame_started(),
    .event_tlast_unexpected(),
    .event_tlast_missing(),
    .event_status_channel_halt(),
    .event_data_in_channel_halt(),
    .event_data_out_channel_halt()
);

//---------------------------------------
// FFT MF
//---------------------------------------

fft_mf FFT_MF
(
    .aclk(clk),

    .s_axis_config_tdata  (fft_config_mf_tdata),
    .s_axis_config_tvalid (fft_config_mf_tvalid),
    .s_axis_config_tready (fft_config_mf_tready),

    .s_axis_data_tdata  (fft_mf_input_tdata),
    .s_axis_data_tvalid (fft_mf_input_tvalid),
    .s_axis_data_tready (fft_mf_input_tready),
    .s_axis_data_tlast  (fft_mf_input_tlast),

    .m_axis_data_tdata    (fft_mf_out_tdata),
    .m_axis_data_tvalid   (fft_mf_out_tvalid),
    .m_axis_data_tready   (1'b1),
    .m_axis_data_tlast    (fft_mf_out_tlast),

    .event_frame_started(),
    .event_tlast_unexpected(),
    .event_tlast_missing(),
    .event_status_channel_halt(),
    .event_data_in_channel_halt(),
    .event_data_out_channel_halt()
);

//---------------------------------------
// Complex Multiplier
//---------------------------------------

wire [63:0] mult_out_data;

complex_multiplier MULT
(
    .ar (fft_rx_out_tdata[15:0]),
    .ai (fft_rx_out_tdata[31:16]),

    .br (fft_mf_out_tdata[15:0]),
    .bi (fft_mf_out_tdata[31:16]),

    .out_data (mult_out_data)
);

//---------------------------------------
// IFFT
//---------------------------------------

wire [63:0] ifft_input_tdata;
wire        ifft_input_tvalid;
wire        ifft_input_tready;
wire        ifft_input_tlast;


//assignments 

assign ifft_config_tdata = IFFT_CONFIG ;
assign ifft_config_tvalid = 1'b1;
assign ifft_input_tvalid = fft_rx_out_tvalid & fft_mf_out_tvalid;
assign ifft_input_tlast  = fft_rx_out_tlast & fft_mf_out_tlast;
assign ifft_input_tdata = mult_out_data;

ifft_pc IFFT
(
    .aclk(clk),

    .s_axis_config_tdata(ifft_config_tdata),
    .s_axis_config_tvalid(ifft_config_tvalid),
    .s_axis_config_tready(ifft_config_tready),

    .s_axis_data_tdata(ifft_input_tdata),
    .s_axis_data_tvalid(ifft_input_tvalid),
    .s_axis_data_tready(ifft_input_tready),
    .s_axis_data_tlast(ifft_input_tlast),

    .m_axis_data_tdata(ifft_out_tdata),
    .m_axis_data_tvalid(ifft_out_tvalid),
    .m_axis_data_tready(1'b1),
    .m_axis_data_tlast(ifft_out_tlast),

    .event_frame_started(),
    .event_tlast_unexpected(),
    .event_tlast_missing(),
    .event_status_channel_halt(),
    .event_data_in_channel_halt(),
    .event_data_out_channel_halt()
);

//=====================================================
// Save IFFT output to a file
//=====================================================

integer fp;

initial begin
    fp = $fopen("ifft_output.txt", "w");
end

always @(posedge clk)
begin
    if (ifft_out_tvalid)
    begin
        $fdisplay(fp,"%d %d",
                  $signed(ifft_out_tdata[31:0]),
                  $signed(ifft_out_tdata[63:32]));
    end
end


endmodule