module avalonmm_mux #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    input  wire                    clk,
    input  wire                    reset,

    // Avalon-MM Master 0 from rf cntrl
    input  wire [ADDR_WIDTH-1:0]    avalonm0_address,
    input  wire [DATA_WIDTH-1:0]    avalonm0_writedata,
    input  wire                     avalonm0_write,
    input  wire                     avalonm0_read,
    output wire [DATA_WIDTH-1:0]    avalonm0_readdata,
    output wire                     avalonm0_waitrequest,
    input  wire [3:0]               avalonm0_byteenable,           
    output  wire                    avalonm0_readdatavalid,  
    // Avalon-MM Master 1 from risc-V cntrl
    input  wire [ADDR_WIDTH-1:0]    avalonm1_address,
    input  wire [DATA_WIDTH-1:0]    avalonm1_writedata,
    input  wire                     avalonm1_write,
    input  wire                     avalonm1_read,
    output wire [DATA_WIDTH-1:0]    avalonm1_readdata,
    output wire                     avalonm1_waitrequest,
    input  wire  [3:0]              avalonm1_byteenable,           
    output  wire                    avalonm1_readdatavalid,  
    // Select Signal (0 = Master 0, 1 = Master 1)
    input  wire                     select,
    // Avalon-MM Output (Multiplexed)
    output wire [ADDR_WIDTH-1:0]    avalonm_out_address,
    output wire [DATA_WIDTH-1:0]    avalonm_out_writedata,
    output wire                     avalonm_out_write,
    output wire                     avalonm_out_read,
    input  wire [DATA_WIDTH-1:0]    avalonm_out_readdata,
    input  wire                     avalonm_out_waitrequest,
    output wire [3:0]               avalonm_out_byteenable,           
    input  wire                     avalonm_out_readdatavalid  
);

    // Multiplexing address, write data, write and read signals
    assign avalonm_out_byteenable   = (select == 1'b0) ? avalonm0_byteenable  :avalonm1_byteenable;
    assign avalonm_out_address   = (select == 1'b0) ? avalonm0_address   : avalonm1_address;
    assign avalonm_out_writedata = (select == 1'b0) ? avalonm0_writedata : avalonm1_writedata;
    assign avalonm_out_write     = (select == 1'b0) ? avalonm0_write     : avalonm1_write;
    assign avalonm_out_read      = (select == 1'b0) ? avalonm0_read      : avalonm1_read;

    // Handling read data and wait request return
    assign avalonm0_readdata    = (select == 1'b0) ? avalonm_out_readdata : {DATA_WIDTH{1'b0}};
    assign avalonm1_readdata    = (select == 1'b1) ? avalonm_out_readdata : {DATA_WIDTH{1'b0}};
    assign avalonm0_readdatavalid    = (select == 1'b0) ? avalonm_out_readdatavalid : 1'b0;
    assign avalonm1_readdatavalid    = (select == 1'b1) ? avalonm_out_readdatavalid : 1'b0;

    assign avalonm0_waitrequest = (select == 1'b0) ? avalonm_out_waitrequest : 1'b1;
    assign avalonm1_waitrequest = (select == 1'b1) ? avalonm_out_waitrequest : 1'b1;

endmodule
