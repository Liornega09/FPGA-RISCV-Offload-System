`timescale 1ns / 10ps


module riscv_top #(
   parameter  IMEM_NUM_BYTES = 128*1024  //Capacity of imem in bytes
  ,parameter  IMEM_INIT_FILE = ""

) (
    input   logic   clk
   ,input   logic   rst_n
   
    // AXI-MM interface
    ,output logic [7:0]   dmem_aximm_awid
    ,output logic [31:0]  dmem_aximm_awaddr
    ,output logic         dmem_aximm_awvalid
    ,input  logic         dmem_aximm_awready
    ,output logic [7:0]   dmem_aximm_awlen
    ,output logic [2:0]   dmem_aximm_awsize
    ,output logic [1:0]   dmem_aximm_awburst
    ,output logic [2:0]   dmem_aximm_awprot
    ,output logic [3:0]   dmem_aximm_awqos
    ,output logic [3:0]   dmem_aximm_awcache
    ,output logic         dmem_aximm_awlock

    ,output logic [127:0] dmem_aximm_wdata
    ,output logic [15:0]  dmem_aximm_wstrb
    ,output logic         dmem_aximm_wvalid
    ,input  logic         dmem_aximm_wready
    ,output logic         dmem_aximm_wlast

    ,input  logic[7:0]    dmem_aximm_bid
    ,input logic[1:0]     dmem_aximm_bresp
    ,input  logic         dmem_aximm_bvalid
    ,output logic         dmem_aximm_bready

    ,output logic [31:0]  dmem_aximm_araddr
    ,output logic         dmem_aximm_arvalid
    ,input  logic         dmem_aximm_arready
    ,output logic [7:0]   dmem_aximm_arid
    ,output logic [7:0]   dmem_aximm_arlen
    ,output logic [2:0]   dmem_aximm_arsize
    ,output logic [1:0]   dmem_aximm_arburst
    ,output logic [2:0]   dmem_aximm_arprot
    ,output logic [3:0]   dmem_aximm_arqos
    ,output logic [3:0]   dmem_aximm_arcache
    ,output logic         dmem_aximm_arlock

    ,input  logic         dmem_aximm_rlast
    ,input  logic [1:0]   dmem_aximm_rresp
    ,input  logic [7:0]   dmem_aximm_rid
    ,input  logic [127:0] dmem_aximm_rdata
    ,input  logic         dmem_aximm_rvalid
    ,output logic         dmem_aximm_rready
   

   ,input   logic [31:0]  risc_V_instruction_mem_address_rf_ctrl
   ,input   logic [31:0]  risc_V_instruction_mem_data_rf_ctrl 
   ,input   logic         risc_V_instruction_mem_wr_rf_ctrl
   ,output   logic         risc_V_instruction_mem_waitrequest_rf_ctrl
   ,input   logic         risc_V_instruction_mem_select_rf_ctrl 


);

//----------------------- Import Packages ---------------------------------


//----------------------- Internal Parameters -----------------------------


//----------------------- Internal Register Declarations ------------------


//----------------------- Internal Wire Declarations ----------------------

  wire  [31:0]                risc_V_instruction_mem_readdata_rf_ctrl;
  wire                        risc_V_instruction_mem_readdatavalid_rf_ctrl;
  wire                        imem_avmm_waitrequest;
  wire                        imem_avmm_write;
  wire                        imem_avmm_read;
  wire  [31:0]                imem_avmm_address;
  wire  [31:0]                imem_avmm_writedata;
  wire   [3:0]                imem_avmm_byteenable;
  wire                        imem_avmm_readdatavalid;
  wire  [31:0]                imem_avmm_readdata;
  
  wire                        imem_avmm_waitrequest_mux;
  wire                        imem_avmm_write_mux;
  wire                        imem_avmm_read_mux;
  wire  [31:0]                imem_avmm_address_mux;
  wire  [31:0]                imem_avmm_writedata_mux;
  wire   [3:0]                imem_avmm_byteenable_mux;
  wire                        imem_avmm_readdatavalid_mux;
  wire  [31:0]                imem_avmm_readdata_mux;
  
  
  wire                        dmem_avmm_waitrequest;
  wire                        dmem_avmm_write;
  wire                        dmem_avmm_read;
  wire  [31:0]                dmem_avmm_address;
  wire  [31:0]                dmem_avmm_writedata;
  wire   [3:0]                dmem_avmm_byteenable;
  wire                        dmem_avmm_readdatavalid;
  wire  [31:0]                dmem_avmm_readdata;

  
 

//----------------------- Start of Code -----------------------------------


  /*  CPU */
  riscv_cpu       cpu
  (
      .clk                        (clk)
     ,.rst_n                      (rst_n)

     ,.imem_avmm_waitrequest      (imem_avmm_waitrequest     )
     ,.imem_avmm_write            (imem_avmm_write            )
     ,.imem_avmm_read             (imem_avmm_read             )
     ,.imem_avmm_address          (imem_avmm_address          )
     ,.imem_avmm_writedata        (imem_avmm_writedata       )
     ,.imem_avmm_byteenable       (imem_avmm_byteenable      )
     ,.imem_avmm_readdatavalid    (imem_avmm_readdatavalid  )
     ,.imem_avmm_readdata         (imem_avmm_readdata        )

     ,.dmem_avmm_waitrequest      (dmem_avmm_waitrequest     )
     ,.dmem_avmm_write            (dmem_avmm_write            )
     ,.dmem_avmm_read             (dmem_avmm_read             )
     ,.dmem_avmm_address          (dmem_avmm_address          )
     ,.dmem_avmm_writedata        (dmem_avmm_writedata       )
     ,.dmem_avmm_byteenable       (dmem_avmm_byteenable      )
     ,.dmem_avmm_readdatavalid    (dmem_avmm_readdatavalid  )
     ,.dmem_avmm_readdata         (dmem_avmm_readdata        )

  );

  /*  Instruction Memory  */
  instruction_memory #(
      .NUM_BYTES  (IMEM_NUM_BYTES)
     ,.INIT_FILE  (IMEM_INIT_FILE)

  ) imem (

      .clk                        (clk)
     ,.rst_n                      (rst_n)

     ,.avmm_waitrequest           (imem_avmm_waitrequest_mux          )
     ,.avmm_write                 (imem_avmm_write_mux                 )
     ,.avmm_read                  (imem_avmm_read_mux                  )
     ,.avmm_address               (imem_avmm_address_mux               )
     ,.avmm_writedata             (imem_avmm_writedata_mux            )
     ,.avmm_byteenable            (imem_avmm_byteenable_mux           )
     ,.avmm_readdatavalid         (imem_avmm_readdatavalid_mux       )
     ,.avmm_readdata              (imem_avmm_readdata_mux             )

  );



avalonmm_mux #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(32)
) avalon_mux_inst (
    .clk(clk),
    .reset(~rst_n),
    .select              (risc_V_instruction_mem_select_rf_ctrl), 
    // Avalon-MM Master 0 from rf cntrl
    .avalonm0_address    (risc_V_instruction_mem_address_rf_ctrl),
    .avalonm0_writedata  (risc_V_instruction_mem_data_rf_ctrl),
    .avalonm0_write      (risc_V_instruction_mem_wr_rf_ctrl),
    .avalonm0_read       (1'b0),
    .avalonm0_readdata   (risc_V_instruction_mem_readdata_rf_ctrl),
    .avalonm0_waitrequest(risc_V_instruction_mem_waitrequest_rf_ctrl),
    .avalonm0_byteenable (4'b1111),           
    .avalonm0_readdatavalid(risc_V_instruction_mem_readdatavalid_rf_ctrl), 
    // Avalon-MM Master 1 from risc-V cpu
    .avalonm1_address    (imem_avmm_address),
    .avalonm1_writedata  (imem_avmm_writedata),
    .avalonm1_write      (imem_avmm_write),
    .avalonm1_read       (imem_avmm_read),
    .avalonm1_readdata   (imem_avmm_readdata),
    .avalonm1_waitrequest(imem_avmm_waitrequest),
    .avalonm1_byteenable(imem_avmm_byteenable),           
    .avalonm1_readdatavalid(imem_avmm_readdatavalid),

    .avalonm_out_address(imem_avmm_address_mux),
    .avalonm_out_writedata(imem_avmm_writedata_mux),
    .avalonm_out_write(imem_avmm_write_mux),
    .avalonm_out_read(imem_avmm_read_mux),
    .avalonm_out_readdata(imem_avmm_readdata_mux),
    .avalonm_out_waitrequest(imem_avmm_waitrequest_mux),
    .avalonm_out_byteenable(imem_avmm_byteenable_mux),           
    .avalonm_out_readdatavalid(imem_avmm_readdatavalid_mux)
);

avalonmm2aximm_bridge u_avalonmm2aximm_bridge (
    .clk                        (clk),
    .reset_n                    (rst_n),

    // Avalon-MM interface (from RISC-V)
    .avalon_write               (dmem_avmm_write),
    .avalon_read                (dmem_avmm_read),
    .avalon_address             (dmem_avmm_address),
    .avalon_writedata           (dmem_avmm_writedata),
    .avalon_byteenable          (dmem_avmm_byteenable),
    .avalon_waitrequest         (dmem_avmm_waitrequest),
    .avalon_readdata            (dmem_avmm_readdata),
    .avalon_readdatavalid       (dmem_avmm_readdatavalid),

    // AXI-MM interface (to AXI crossbar port 1)
    .aximm_awaddr               (dmem_aximm_awaddr),
    .aximm_awvalid              (dmem_aximm_awvalid),
    .aximm_awready              (dmem_aximm_awready),
    .aximm_awid                 (dmem_aximm_awid),
    .aximm_awlen                (dmem_aximm_awlen),
    .aximm_awsize               (dmem_aximm_awsize),
    .aximm_awburst              (dmem_aximm_awburst),
    .aximm_awlock               (dmem_aximm_awlock),
    .aximm_awcache              (dmem_aximm_awcache),
    .aximm_awprot               (dmem_aximm_awprot),
    .aximm_awqos                (dmem_aximm_awqos),

    .aximm_wdata                (dmem_aximm_wdata),
    .aximm_wstrb                (dmem_aximm_wstrb),
    .aximm_wvalid               (dmem_aximm_wvalid),
    .aximm_wready               (dmem_aximm_wready),
    .aximm_wlast                (dmem_aximm_wlast),
    
    .aximm_bid                  (dmem_aximm_bid),
    .aximm_bresp                (dmem_aximm_bresp),
    .aximm_bvalid               (dmem_aximm_bvalid),
    .aximm_bready               (dmem_aximm_bready),

    .aximm_araddr               (dmem_aximm_araddr),
    .aximm_arvalid              (dmem_aximm_arvalid),
    .aximm_arready              (dmem_aximm_arready),
    .aximm_arid                 (dmem_aximm_arid),
    .aximm_arlen                (dmem_aximm_arlen),
    .aximm_arsize               (dmem_aximm_arsize),
    .aximm_arburst              (dmem_aximm_arburst),
    .aximm_arlock               (dmem_aximm_arlock),
    .aximm_arcache              (dmem_aximm_arcache),
    .aximm_arprot               (dmem_aximm_arprot),
    .aximm_arqos                (dmem_aximm_arqos),

    .aximm_rid                  (dmem_aximm_rid),
    .aximm_rresp                (dmem_aximm_rresp),
    .aximm_rdata                (dmem_aximm_rdata),
    .aximm_rvalid               (dmem_aximm_rvalid),
    .aximm_rready               (dmem_aximm_rready),
    .aximm_rlast                (dmem_aximm_rlast)
);

endmodule

