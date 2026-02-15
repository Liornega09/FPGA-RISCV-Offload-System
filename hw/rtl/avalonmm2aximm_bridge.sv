
module avalonmm2aximm_bridge (
    input  logic         clk,
    input  logic         reset_n,

    // Avalon-MM interface
    input  logic         avalon_write,
    input  logic         avalon_read,
    input  logic [31:0]  avalon_address,
    input  logic [31:0]  avalon_writedata,
    input  logic [3:0]   avalon_byteenable,
    output logic         avalon_waitrequest,
    output logic [31:0]  avalon_readdata,
    output logic         avalon_readdatavalid,

    // AXI-MM interface
    output logic [7:0]   aximm_awid,
    output logic [31:0]  aximm_awaddr,
    output logic         aximm_awvalid,
    input  logic         aximm_awready,
    output logic [7:0]   aximm_awlen,
    output logic [2:0]   aximm_awsize,
    output logic [1:0]   aximm_awburst,
    output logic [2:0]   aximm_awprot,
    output logic [3:0]   aximm_awqos,
    output logic [3:0]   aximm_awcache,
    output logic         aximm_awlock,

    output logic [127:0] aximm_wdata,
    output logic [15:0]  aximm_wstrb,
    output logic         aximm_wvalid,
    input  logic         aximm_wready,
    output logic         aximm_wlast,

    input  logic[7:0]    aximm_bid,
    input logic[1:0]    aximm_bresp,
    input  logic         aximm_bvalid,
    output logic         aximm_bready,

    output logic [31:0]  aximm_araddr,
    output logic         aximm_arvalid,
    input  logic         aximm_arready,
    output logic [7:0]   aximm_arid,
    output logic [7:0]   aximm_arlen,
    output logic [2:0]   aximm_arsize,
    output logic [1:0]   aximm_arburst,
    output logic [2:0]   aximm_arprot,
    output logic [3:0]   aximm_arqos,
    output logic [3:0]   aximm_arcache,
    output logic         aximm_arlock,

    input  logic         aximm_rlast,
    input  logic [1:0]   aximm_rresp,
    input  logic [7:0]   aximm_rid,
    input  logic [127:0] aximm_rdata,
    input  logic         aximm_rvalid,
    output logic         aximm_rready
);
    localparam MAX_OUTSTANDING = 8'hff;
    // FSM states (localparams)
    localparam IDLE        = 4'd0;
    localparam W_ADDR      = 4'd1;
    localparam WRITE       = 4'd2;
    localparam R_ADDR      = 4'd3;
    localparam READ        = 4'd4;
    localparam READDATA    = 4'd5;
    localparam WAIT_64     = 4'd6;
    localparam READ_1DW    = 4'd7;
    localparam WAIT_READ   = 4'd8;

    logic [3:0]  state;
    logic [31:0] sec_dw;
    logic [3:0]  addr_offset;
    logic avalon_waitrequest_int;
    logic [7:0] write_count;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state                    <= IDLE;
            aximm_awaddr             <= 1'b0;
            aximm_awvalid            <= 1'b0;
            aximm_wvalid             <= 1'b0;
            aximm_wlast              <= 1'b0;
            //aximm_bready             <= 1'b0;
            aximm_araddr             <= 1'b0;
            aximm_arvalid            <= 1'b0;
            aximm_rready             <= 1'b0;
            avalon_readdatavalid     <= 1'b0;
            avalon_readdata          <= 1'b0;          
            avalon_waitrequest_int   <= 1'b0;
            aximm_wdata              <= 128'b0;
            aximm_wstrb              <= 16'b0;
        end else begin
            case (state)
                IDLE: begin
                    aximm_wdata <= 128'b0;
                    aximm_wstrb <= 16'b0;
                    if (avalon_write && (write_count < MAX_OUTSTANDING)) begin
                        avalon_waitrequest_int <= 1'b1;
                        case (avalon_address[3:0])
                            4'h0: begin aximm_wdata[31:0]    <= avalon_writedata; aximm_wstrb[3:0]    <= avalon_byteenable; end
                            4'h4: begin aximm_wdata[63:32]   <= avalon_writedata; aximm_wstrb[7:4]    <= avalon_byteenable; end
                            4'h8: begin aximm_wdata[95:64]   <= avalon_writedata; aximm_wstrb[11:8]   <= avalon_byteenable; end
                            4'hC: begin aximm_wdata[127:96]  <= avalon_writedata; aximm_wstrb[15:12]  <= avalon_byteenable; end
                        endcase
                        aximm_awaddr  <= avalon_address;
                        aximm_awvalid <= 1'b1;
                        state         <= W_ADDR;
                    end
                    else if (avalon_read) begin
                        avalon_waitrequest_int    <= 1'b1;
                        aximm_araddr              <= avalon_address;
                        aximm_arvalid             <= 1'b1;
                        addr_offset               <= avalon_address[3:0];
                        state                     <= R_ADDR;
                        if (avalon_address[23:20] != 4'hf && avalon_address[19:16] == 4'h0 && avalon_address[15:12]==4'h1) begin 
                          aximm_arsize=3'd3;
                        end
                        else begin aximm_arsize=3'd0; end
                    end
                end

                W_ADDR: begin
                    if (aximm_awready) begin
                        aximm_awvalid <= 1'b0;
                        if (avalon_address[23:20] != 4'hf && avalon_address[19:16] == 4'h0 && avalon_address[15:12]==4'h1) begin 
                        state         <= WAIT_64;
                        avalon_waitrequest_int <= 1'b0;
                      end 
                      else begin
                        state         <= WRITE;
                        aximm_wvalid  <= 1'b1;
                        aximm_wlast   <= 1'b1;
                      end
                    end
                end
                WAIT_64: begin
                    if (avalon_write) begin
                        avalon_waitrequest_int <= 1'b1;
                        aximm_wdata[63:32]   <= avalon_writedata; 
                        aximm_wstrb[7:4]     <= avalon_byteenable; 
                        aximm_wdata[95:64]   <= 0; 
                        aximm_wstrb[11:8]    <= 4'hf; 
                        aximm_wdata[127:96]  <= 0; 
                        aximm_wstrb[15:12]   <= 4'hf;                         
                        state         <= WRITE;
                        aximm_wvalid  <= 1'b1;
                        aximm_wlast   <= 1'b1;                                           
                    end
                end
                WRITE: begin
                    if (aximm_wready) begin                    
                        aximm_wvalid  <= 1'b0;  
                        aximm_wlast   <= 1'b0;  
                        avalon_waitrequest_int <= 1'b0;
                        state                  <= IDLE;                    
                    end
                end

                R_ADDR: begin
                    if (aximm_arready) begin
                        aximm_arvalid <= 1'b0;
                        aximm_rready  <= 1'b1;
                        if (avalon_address[23:20] != 4'hf && avalon_address[19:16] == 4'h0 && avalon_address[15:12]==4'h1) begin 
                        state         <= READ_1DW;
                      end 
                      else begin
                        state         <= READ;
                      end
                    end
                end


                READ_1DW: begin
                    if (aximm_rvalid) begin
                        avalon_waitrequest_int <= 1'b0;
                        avalon_readdata <= aximm_rdata[31:0];
                        sec_dw          <= aximm_rdata[63:32];
                        state         <= WAIT_READ;
                        avalon_readdatavalid     <= 1'b1;
                    end
                end

                WAIT_READ: begin
                    if (avalon_read) begin
                       // avalon_waitrequest_int <= 1'b1; 
                        avalon_readdata <= sec_dw;                     
                        state         <= READDATA; 
                        avalon_readdatavalid     <= 1'b1;                        
                    end
                    else begin
                     avalon_readdatavalid     <= 1'b0;
                     end
                end
                READ: begin
                    if (aximm_rvalid) begin
                        aximm_rready <= 1'b0;
                        case (addr_offset)
                            4'h0: avalon_readdata <= aximm_rdata[31:0];
                            4'h4: avalon_readdata <= aximm_rdata[63:32];
                            4'h8: avalon_readdata <= aximm_rdata[95:64];
                            4'hC: avalon_readdata <= aximm_rdata[127:96];
                        endcase
                        avalon_readdatavalid     <= 1'b1;
                        avalon_waitrequest_int   <= 1'b0;
                        state                    <= READDATA;
                    end
                end
                READDATA: begin    
                    avalon_readdatavalid     <= 1'b0;                        
                    state                    <= IDLE;
                    end
            endcase
        end
    end


    // --- Outstanding Transactions Counter ---
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            write_count <= 4'd0;
        end else begin
            case ({ (aximm_awvalid && aximm_awready), (aximm_bvalid && aximm_bready) })
                2'b10: write_count <= write_count + 1'b1; // New write issued
                2'b01: write_count <= write_count - 1'b1; // Response received
                default: write_count <= write_count;      // Both or none
            endcase
        end
    end


  assign      aximm_arid=8'h80;
  assign      aximm_arlen=8'b0;
 // assign      aximm_arsize=3'b0;
  assign      aximm_arburst=2'b0;
  assign      aximm_arprot=3'b0;
  assign      aximm_arqos=4'b0;
  assign      aximm_arcache=4'b0;
  assign      aximm_arlock=1'b0;
  assign      aximm_bready = 1'b1;
  assign      aximm_awid=8'h80;
  assign      aximm_awlen=8'b0;
  assign      aximm_awsize=3'b0;
  assign      aximm_awburst=2'b0;
  assign      aximm_awprot=3'b0;
  assign      aximm_awqos=4'b0;
  assign      aximm_awcache=4'b0;
  assign      aximm_awlock=1'b0;

  assign      avalon_waitrequest=((avalon_waitrequest_int == 1'b1 || avalon_read ==1'b1 || (write_count >= MAX_OUTSTANDING)) && avalon_readdatavalid == 1'b0) ? 1'b1 : 1'b0;

endmodule
