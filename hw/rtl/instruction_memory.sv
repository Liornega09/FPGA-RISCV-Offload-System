module instruction_memory #(
   parameter  NUM_BYTES = 128*1024  //Capacity of memory in bytes

) (

    input   logic   clk
   ,input   logic   rst_n

   ,output  logic         avmm_waitrequest
   ,input   logic         avmm_write
   ,input   logic         avmm_read
   ,input   logic [31:0]  avmm_address
   ,input   logic [31:0]  avmm_writedata
   ,input   logic  [3:0]  avmm_byteenable
   ,output  logic         avmm_readdatavalid
   ,output  logic [31:0]  avmm_readdata

);

//----------------------- Import Packages ---------------------------------


//----------------------- Internal Parameters -----------------------------
  localparam  NUM_BITS        = NUM_BYTES * 8;
  localparam  ADDR_WIDTH      = ((NUM_BITS % 32) > 0) ? $clog2(NUM_BITS / 32) + 1 : $clog2(NUM_BITS / 32);


//----------------------- Internal Register Declarations ------------------


//----------------------- Internal Wire Declarations ----------------------



//----------------------- Start of Code -----------------------------------


  /*  Instantiate memory  */
  generic_ram #(
     .DATA_WIDTH      (32)
    ,.ADDR_WIDTH      (ADDR_WIDTH)
    ,.MEM_TYPE        ("BRAM")
    ,.INIT_FILE       (INIT_FILE)

  ) mem (

    /*  input  logic                      */   .wr_clk      (clk)
    /*  input  logic [DATA_WIDTH-1:0]     */  ,.wr_data     (avmm_writedata)
    /*  input  logic [(DATA_WIDTH/8)-1:0] */  ,.wr_be       (avmm_byteenable)
    /*  input  logic [ADDR_WIDTH-1:0]     */  ,.wr_addr     (avmm_address[2 +: ADDR_WIDTH]) //avmm_address should be byte aligned
    /*  input  logic                      */  ,.wr_en       (avmm_write)

    /*  input  logic                      */  ,.rd_clk      (clk)
    /*  input  logic [ADDR_WIDTH-1:0]     */  ,.rd_addr     (avmm_address[2 +: ADDR_WIDTH]) //avmm_address should be byte aligned
    /*  output logic [DATA_WIDTH-1:0]     */  ,.rd_data     (avmm_readdata)

  );

  always@(posedge clk,  negedge rst_n)
  begin
    if(~rst_n)
    begin
      avmm_readdatavalid  <=  1'b0;
    end
    else
    begin
      avmm_readdatavalid  <=  avmm_read & ~avmm_waitrequest;
    end
  end

  assign  avmm_waitrequest = 1'b0;


endmodule 
