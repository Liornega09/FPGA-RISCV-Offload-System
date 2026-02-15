module register_file #(
           parameter USE_RISCV = 0
                    )
  (
  input   wire user_rst_n,

  output  wire sw_reset,

  input   wire clk,
  input   wire rst_n,

  output  wire interrupt,

//AXIMM  
  output  wire 	        axi_awready,
  input   wire 	        axi_awvalid,
  input   wire  [19:0]  axi_awaddr,
  //input   wire  [1:0]   axi_awlen,
  //input   wire  [2:0]   axi_awsize,
  input   wire  [7:0]   axi_awid,


  input   wire 	        axi_wvalid,
  output  wire 	        axi_wready,
  //input   wire  [15:0]  axi_wid,
  input   wire  [15:0]  axi_wstrb,
  input   wire 	        axi_wlast,
  input   wire  [127:0] axi_wdata,


  input   wire 	        axi_bready,
  output  reg   [7:0]   axi_bid,
  output  wire  [1:0]   axi_bresp,
  output  wire 	        axi_bvalid,

  input   wire  [19:0]  axi_araddr,
  //input   wire  [1:0]   axi_arlen,
  //input   wire  [2:0]   axi_arsize,
  output  wire 	        axi_arready,
  input   wire  [7:0]   axi_arid,
  input   wire 	        axi_arvalid,

  input   wire 	        axi_rready,
  output  wire 	        axi_rvalid,
  output  reg   [127:0] axi_rdata,
  output  reg   [7:0]   axi_rid,
  output  wire  [1:0]   axi_rresp,
  output  wire 	        axi_rlast,


  output reg [31:0] risc_V_instruction_mem_address,
  output reg [31:0] risc_V_instruction_mem_data,
  output reg        risc_V_instruction_mem_wr,
  input wire        risc_V_instruction_mem_waitrequest,
  output reg        risc_V_instruction_mem_select,
  output reg        risc_V_reset_n
);
 //risc_V
  reg [31:0]  risc_V_status;                            
  reg         use_riscv_register;                        
  reg         riscv_counter_enable;                     
  reg [31:0]  riscv_counter;                            
  wire risc_V_instruction_mem_wr_done;

   //the following lines describe a state machine that is coresponding with the AXIMM input
  always @ (posedge FGC_clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_addr       <= 20'h0_0000;
      axi_rid       <= 8'h00;
      axi_bid       <= 8'b0;
      current_state <=IDLE ;
    end
    else begin
      case (current_state)
        IDLE : 
        begin
          //when an AWVALID and AWREADY are '1' 
          if (axi_awready && axi_awvalid) // WRITE
          begin 
	              axi_bid       <= axi_awid;
                wr_addr       <= axi_awaddr;
                current_state <= WRITE;
          end 
          else if (axi_arready && axi_arvalid) // READ
          begin
          //when an ARVALID and ARREADY are '1'
                //rd_addr       <= axi_araddr;
                axi_rid       <= axi_arid;
                current_state <= READ;
          end
        end//IDLE

        WRITE : 
        begin //when an WVALID and WREADY and WLAST are '1'
          if (axi_wready && axi_wvalid && axi_wlast) 
          begin
	              current_state <= RESP;
                axi_bid       <= axi_bid;
          end
        end//WRITE

	      RESP : 
        begin
          //when an BVALID and BREADY are '1'
          if (axi_bready && axi_bvalid) 
          begin
                current_state <= IDLE;
                axi_bid       <= 8'b0;
          end
        end//WRITE

        READ : 
        begin
          //when an RVALID and RREADY are '1'
          if (axi_rready && axi_rvalid) 
          begin
                current_state <= IDLE;
          end
        end//READ

      endcase//current_state
    end//else
  end//always

  //////////////// RISC-V ///////////////////

//risc_V_instruction_mem_address
  always @ (posedge FGC_clk or negedge rst_n)
    begin
      if (!rst_n)
      begin
	       risc_V_instruction_mem_address <= 32'b0;
      end
      else
	    begin
	      if ((wr_en) & (wr_addr==20'h0_0000) & (axi_wstrb[3:0] == 4'hf))
        begin 
          risc_V_instruction_mem_address <=  axi_wdata[31:0];
        end
	      else
        begin
          risc_V_instruction_mem_address <=  risc_V_instruction_mem_address;
        end
	    end
    end 
  //risc_V_instruction_mem_data
  always @ (posedge FGC_clk or negedge rst_n)
    begin
      if (!rst_n)
      begin
	       risc_V_instruction_mem_data <= 32'b0;
      end
      else
	    begin
	      if ((wr_en) & (wr_addr==20'h0_0004) & (axi_wstrb[7:4] == 4'hf))
        begin 
          risc_V_instruction_mem_data <=  axi_wdata[63:32];
        end
	      else
        begin
          risc_V_instruction_mem_data <=  risc_V_instruction_mem_data;
        end
	    end
    end 
   //risc_V_instruction_mem_wr
  always @ (posedge FGC_clk or negedge rst_n)
    begin
      if (!rst_n)
      begin
	       risc_V_instruction_mem_wr <= 1'b0;
      end
      else
	    begin
	      if (risc_V_instruction_mem_wr_done == 1'b1)
        begin
          risc_V_instruction_mem_wr <=  1'b0;
        end
        else if ((wr_en) & (wr_addr==20'h0_0008) & (axi_wstrb[11:8] == 4'hf))
        begin 
          risc_V_instruction_mem_wr <=  1'b1;
        end
	      else
        begin
          risc_V_instruction_mem_wr <= risc_V_instruction_mem_wr ;
        end
	    end
    end 

//risc_V_instruction_mem_wr_done
   assign risc_V_instruction_mem_wr_done = (risc_V_instruction_mem_wr == 1'b1 & risc_V_instruction_mem_waitrequest == 1'b0)  ?  1'b1 : 1'b0;

//risc_V_instruction_mem_select 
 always @ (posedge FGC_clk or negedge rst_n)
    begin
      if (!rst_n)
      begin
	       risc_V_instruction_mem_select <= 1'b0;
      end
      else
	    begin
	      if ((wr_en) & (wr_addr==20'h0_000c) & (axi_wstrb[15:12] == 4'hf))
        begin 
          risc_V_instruction_mem_select <=  axi_wdata[96];
        end
	      else
        begin
          risc_V_instruction_mem_select <=  risc_V_instruction_mem_select;
        end
	    end
    end

//risc_V_reset_n
 always @ (posedge FGC_clk or negedge rst_n)
    begin
      if (!rst_n)
      begin
	       risc_V_reset_n <= 1'b0;
      end
      else
	    begin
	      if ((wr_en) & (wr_addr==20'h0_0010) & (axi_wstrb[3:0] == 4'hf))
        begin 
          risc_V_reset_n <=  axi_wdata[0];
        end
	      else
        begin
          risc_V_reset_n <=  risc_V_reset_n;
        end
	    end
    end
//risc_V_status
 always @ (posedge FGC_clk or negedge rst_n)
    begin
      if (!rst_n)
      begin
	       risc_V_status <= 32'b0;
      end
      else
	    begin
	      if ((wr_en) & (wr_addr==20'h1_0014) & (axi_wstrb[7:4] == 4'hf))
        begin 
          risc_V_status <=  axi_wdata[63:32];
        end
	      else
        begin
          risc_V_status <=  risc_V_status;
        end
	    end
    end
//USE_RISCV_register 
  always @ (posedge FGC_clk or negedge rst_n)
    begin
      if (!rst_n) begin
      	use_riscv_register  <= 1'b0;
      end
      else begin
        use_riscv_register  <= USE_RISCV;
      end
    end
//risc_V_counter_enable 
 always @ (posedge FGC_clk or negedge rst_n)
    begin
      if (!rst_n)
      begin
	        riscv_counter_enable <= 1'b0;
      end
      else
	    begin
	      if ((wr_en) & (wr_addr==20'h0_001c) & (axi_wstrb[15:12] == 4'hf))
        begin 
           riscv_counter_enable<=  axi_wdata[96];
        end
	      else
        begin
           riscv_counter_enable<=  riscv_counter_enable;
        end
	    end
    end
  //riscv_counter
  always @ (posedge FGC_clk or negedge rst_n)
  begin    
    if (!rst_n)
      begin
	      riscv_counter <= 256'h0;
      end 
    else    
	  begin
	    if (riscv_counter_enable) 
      begin  
         riscv_counter <= riscv_counter + 1;
      end
      else
      begin
        riscv_counter <= riscv_counter;
      end 
    end
  end 
  always @ (posedge FGC_clk or negedge rst_n)
  begin
    if (!rst_n) 
    begin      
      axi_rdata[127:0] <= 128'h0000_0000_0000_0000;
    end
    else
    begin	
      case (axi_araddr[19:0]) 
          20'h0_0000 : axi_rdata  <= {96'h0,risc_V_instruction_mem_address};
          20'h0_0004 : axi_rdata  <= {64'h0,risc_V_instruction_mem_data,32'h0};
          20'h0_0008 : axi_rdata  <= {32'h0,30'h0,risc_V_instruction_mem_wr,risc_V_instruction_mem_wr_done,64'h0}; //bit[0] mem_wr_done, bit[1] mem_wr
          20'h0_000c : axi_rdata  <= {31'h0,risc_V_instruction_mem_select,96'h0}; //bit[0] mem_select
          20'h0_0010 : axi_rdata  <= {96'h0,31'h0,risc_V_reset_n};
          20'h0_0014 : axi_rdata  <= {64'h0,risc_V_status,32'h0};
          20'h0_0018 : axi_rdata  <= {31'h0,use_riscv_register,64'h0};
          20'h0_001c : axi_rdata  <= {31'h0,riscv_counter_enable,96'h0};
          20'h0_0020 : axi_rdata  <= {96'h0,riscv_counter};
          default    : axi_rdata  <= {32'hf000dead,32'hf000dead,32'hf000dead,32'hf000dead};
	    endcase // case (rd_addr)
    end
  end

  endmodule

