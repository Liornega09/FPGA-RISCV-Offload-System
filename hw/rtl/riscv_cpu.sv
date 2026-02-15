`timescale 1ns / 10ps


module riscv_cpu
(
    input   logic   clk
   ,input   logic   rst_n

   ,input   logic         imem_avmm_waitrequest
   ,output  logic         imem_avmm_write
   ,output  logic         imem_avmm_read
   ,output  logic [31:0]  imem_avmm_address
   ,output  logic [31:0]  imem_avmm_writedata
   ,output  logic  [3:0]  imem_avmm_byteenable
   ,input   logic         imem_avmm_readdatavalid
   ,input   logic [31:0]  imem_avmm_readdata

   ,input   logic         dmem_avmm_waitrequest
   ,output  logic         dmem_avmm_write
   ,output  logic         dmem_avmm_read
   ,output  logic [23:0]  dmem_avmm_address
   ,output  logic [31:0]  dmem_avmm_writedata
   ,output  logic  [3:0]  dmem_avmm_byteenable
   ,input   logic         dmem_avmm_readdatavalid
   ,input   logic [31:0]  dmem_avmm_readdata

);



//----------------------- Internal Register Declarations ------------------
  logic                       mem_valid_1d;


//----------------------- Internal Wire Declarations ----------------------
  wire                        mem_valid_p;

  logic                       mem_valid;
  logic                       mem_instr;
  logic                       mem_ready;

  logic [31:0]                mem_addr;
  logic [31:0]                mem_wdata;
  logic [ 3:0]                mem_wstrb;
  logic [31:0]                mem_rdata;



//----------------------- Start of Code -----------------------------------


  /*  RISC-V CPU  */
  picorv32 #(
    .ENABLE_COUNTERS     (1),
    .ENABLE_COUNTERS64   (1),
    .ENABLE_REGS_16_31   (1),
    .ENABLE_REGS_DUALPORT(1),
    .TWO_STAGE_SHIFT     (1),
    .BARREL_SHIFTER      (0),
    .TWO_CYCLE_COMPARE   (0),
    .TWO_CYCLE_ALU       (0),
    .COMPRESSED_ISA      (1),
    .CATCH_MISALIGN      (1),
    .CATCH_ILLINSN       (1),
    .ENABLE_PCPI         (0),
    .ENABLE_MUL          (1),
    .ENABLE_FAST_MUL     (0),
    .ENABLE_DIV          (1),
    .ENABLE_IRQ          (1),
    .ENABLE_IRQ_QREGS    (1),
    .ENABLE_IRQ_TIMER    (1),
    .ENABLE_TRACE        (1),
    .REGS_INIT_ZERO      (0),
    .MASKED_IRQ          (32'h0),
    .LATCHED_IRQ         (32'hffff_ffff),
    .PROGADDR_RESET      (32'h0),
    .PROGADDR_IRQ        (32'h0000_0010),
    .STACKADDR           (32'hffff_ffff)

   ) core (

    .clk      (clk   ),
    .resetn   (rst_n ),
    .trap     (trap  ),
  
    .mem_valid(mem_valid),
    .mem_addr (mem_addr ),
    .mem_wdata(mem_wdata),
    .mem_wstrb(mem_wstrb),
    .mem_instr(mem_instr),
    .mem_ready(mem_ready),
    .mem_rdata(mem_rdata),
  
    .pcpi_valid(),
    .pcpi_insn (),
    .pcpi_rs1  (),
    .pcpi_rs2  (),
    .pcpi_wr   ('h0),
    .pcpi_rd   ('h0),
    .pcpi_wait ('h0),
    .pcpi_ready('h0),
  
    .irq('h0),
    .eoi(),
  
    .trace_valid(),
    .trace_data ()
  );


  /*  Convert Mem i/f to AVMM */
  assign  imem_avmm_address     = mem_addr;
  assign  imem_avmm_writedata  = mem_wdata;
  assign  imem_avmm_byteenable = mem_wstrb;

  assign  dmem_avmm_address     = mem_addr[23:0];
  assign  dmem_avmm_writedata  = mem_wdata;
  assign  dmem_avmm_byteenable = mem_wstrb;

  always@(posedge clk,  negedge rst_n)
  begin
    if(~rst_n)
    begin
      mem_valid_1d            <=  1'b0;

      imem_avmm_write         <=  1'b0;
      imem_avmm_read          <=  1'b0;

      dmem_avmm_write         <=  1'b0;
      dmem_avmm_read          <=  1'b0;
    end
    else
    begin
      if(mem_ready)
      begin
        mem_valid_1d          <=  1'b0;
      end
      else if(mem_valid)
      begin
        mem_valid_1d          <=  mem_addr[31]  ? ~dmem_avmm_waitrequest  : ~imem_avmm_waitrequest;
      end
      else
      begin
        mem_valid_1d          <=  1'b0;
      end

      if(imem_avmm_write | imem_avmm_read)
      begin
        imem_avmm_write       <=  imem_avmm_waitrequest  ? imem_avmm_write : 1'b0;
        imem_avmm_read        <=  imem_avmm_waitrequest  ? imem_avmm_read  : 1'b0;
      end
      else
      begin
        imem_avmm_write       <=  (mem_wstrb == 4'h0) ? 1'b0  : mem_valid_p & ~mem_addr[31];
        imem_avmm_read        <=  (mem_wstrb != 4'h0) ? 1'b0  : mem_valid_p & ~mem_addr[31];
      end

      if(dmem_avmm_write | dmem_avmm_read)
      begin
        dmem_avmm_write       <=  dmem_avmm_waitrequest  ? dmem_avmm_write : 1'b0;
        dmem_avmm_read        <=  dmem_avmm_waitrequest  ? dmem_avmm_read  : 1'b0;
      end
      else
      begin
        dmem_avmm_write       <=  (mem_wstrb == 4'h0) ? 1'b0  : mem_valid_p & mem_addr[31];
        dmem_avmm_read        <=  (mem_wstrb != 4'h0) ? 1'b0  : mem_valid_p & mem_addr[31];
      end
    end
  end

  assign  mem_valid_p = mem_valid & ~mem_valid_1d;

  always_comb
  begin
    mem_ready   = 1'b0;
    mem_rdata   = imem_avmm_readdata;

    if(~mem_addr[31])
    begin
      if(mem_wstrb  !=  4'h0)
      begin
        mem_ready = imem_avmm_write & ~imem_avmm_waitrequest;
      end
      else
      begin
        mem_ready = imem_avmm_readdatavalid;
        mem_rdata = imem_avmm_readdata;
      end
    end
    else
    begin
      if(mem_wstrb  !=  4'h0)
      begin
        mem_ready = dmem_avmm_write & ~dmem_avmm_waitrequest;
      end
      else
      begin
        mem_ready = dmem_avmm_readdatavalid;
        mem_rdata = dmem_avmm_readdata;
      end
    end
  end


endmodule // risc_cpu  
