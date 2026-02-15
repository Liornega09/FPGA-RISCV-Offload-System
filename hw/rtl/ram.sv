`timescale 1ns / 10ps


module generic_ram #(
//----------------------- Global parameters Declarations ------------------
   parameter          DATA_WIDTH    = 8*1     //Should be in multiples of bytes
  ,parameter          ADDR_WIDTH    = 4
  ,parameter  string  MEM_TYPE      = "BRAM"  //supported values are BRAM & REG
  ,parameter          INIT_FILE     = ""

) (
//----------------------- Write Interface ------------------------------
   input  logic                       wr_clk
  ,input  logic [DATA_WIDTH-1:0]      wr_data
  ,input  logic [(DATA_WIDTH/8)-1:0]  wr_be
  ,input  logic [ADDR_WIDTH-1:0]      wr_addr
  ,input  logic                       wr_en

//----------------------- Read Interface  ------------------------------
  ,input  logic                       rd_clk
  ,input  logic [ADDR_WIDTH-1:0]      rd_addr
  ,output logic [DATA_WIDTH-1:0]      rd_data

);


//----------------------- Start of Code -----------------------------------

  generate
    if((DATA_WIDTH % 8) != 0)
    begin
      invalid_data_width  data_width_not_multiple_of_bytes ();
    end

    if(MEM_TYPE ==  "BRAM")
    begin
      reg [(DATA_WIDTH/8)-1:0] [7:0]  ram [0:2**ADDR_WIDTH-1];

      if(INIT_FILE  !=  "")
      begin
        initial
        begin
          $readmemb(INIT_FILE,  ram);
        end
      end

      /*  Write Logic */
      always@(posedge wr_clk)
      begin
        if(wr_en)
        begin
          for(int i=0; i<(DATA_WIDTH/8); i++)
          begin
               if (wr_be[i] ) 
                   ram[wr_addr][i] <=  wr_data[(i*8) +:  8];

           // ram[wr_addr][i] <=  wr_be[i]  ? wr_data[(i*8) +:  8];
          end
        end
      end

      /*  Read Logic */
      always@(posedge rd_clk)
      begin
        rd_data <=  ram[rd_addr];
      end
    end
    else if(MEM_TYPE  ==  "REG")
    begin
      reg [(2**ADDR_WIDTH)-1:0][(DATA_WIDTH/8)-1:0][7:0]  ram;

      if(INIT_FILE  !=  "")
      begin
        initial
        begin
          $readmemb(INIT_FILE,  ram);
        end
      end

      /*  Write Logic */
      always@(posedge wr_clk)
      begin
        if(wr_en)
        begin
          for(int i=0; i<(DATA_WIDTH/8); i++)
          begin
              if (wr_be[i] ) 
                   ram[wr_addr][i] <=  wr_data[(i*8) +:  8];
              
          end
        end
      end

      /*  Read Logic */
      always@(posedge rd_clk)
      begin
        rd_data <=  ram[rd_addr];
      end
    end
    else  //MEM_TYPE unsupported
    begin
      unsupported_MEM_TYPE  mem();
    end
  endgenerate

endmodule // generic_simple_dual_port_ram_byte_enable
