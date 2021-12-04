// RISCV32I CPU top module
// port modification allowed for debugging purposes

`include "config.vh"

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]          dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

always @(posedge clk_in)
  begin
    if (rst_in)
      begin
      
      end
    else if (!rdy_in)
      begin
      
      end
    else
      begin
      
      end
  end

wire                            alloc_to_if_gr;
wire                            alloc_to_if_en;
wire [`InstrWidth-1:0]          alloc_if_d;
wire                            alloc_to_lsb_r_gr;
wire                            alloc_to_lsb_r_en;
wire [`WordWidth-1:0]           alloc_lsb_d;
wire                            alloc_to_lsb_w_gr;
wire                            alloc_to_lsb_w_en;

Alloc alloc0(
  .clk_in                       (clk_in),
  .rst_in                       (rst_in),
  .rdy_in                       (rdy_in),

  .if_to_alloc_en_in            (if_to_alloc_en),
  .if_a_in                      (if_a),
  .if_offset_in                 (if_offset),
  .alloc_to_if_gr_out           (alloc_to_if_gr),
  .alloc_to_if_en_out           (alloc_to_if_en),
  .if_d_out                     (alloc_if_d),

  .lsb_to_alloc_r_en_in         (lsb_to_alloc_r_en),
  .lsb_r_offset_in              (lsb_r_offset),
  .lsb_r_a_in                   (lsb_r_a),
  .alloc_to_lsb_r_gr_out        (alloc_to_lsb_r_gr),
  .alloc_to_lsb_r_en_out        (alloc_to_lsb_r_en),
  .lsb_d_out                    (alloc_lsb_d),

  .lsb_to_alloc_w_en_in         (lsb_to_alloc_w_en),
  .lsb_w_offset_in              (lsb_w_offset),
  .lsb_w_a_in                   (lsb_w_a),
  .lsb_d_in                     (lsb_d),
  .alloc_to_lsb_w_gr_out        (alloc_to_lsb_w_gr),
  .alloc_to_lsb_w_en_out        (alloc_to_lsb_w_en),

  .clear_branch_in              (clear_branch),
  .io_buffer_full_in            (io_buffer_full),

  .mem_d_in                     (mem_din),
  .mem_a_out                    (mem_a),
  .mem_d_out                    (mem_dout),
  .mem_wr_out                   (mem_wr)
);

wire                            icache_to_if_en;
wire [`InstrWidth-1:0]          icache_to_if_d;
wire                            if_to_alloc_en;
wire [`AddrWidth-1:0]           if_a;
wire [`InstrBytesWidth-1:0]     if_offset;

ICache icache0(
  .clk_in                       (clk_in),
  .rst_in                       (rst_in),
  .rdy_in                       (rdy_in),

  .if_to_icache_en_in           (if_to_icache_en),
  .if_a_in                      (if_to_icache_a),
  
  .icache_to_if_en_out          (icache_to_if_en),
  .if_d_out                     (icache_to_if_d),

  .if_to_alloc_en_out           (if_to_alloc_en),
  .if_a_out                     (if_a),
  .if_offset_out                (if_offset),
  .alloc_to_if_gr_in            (alloc_to_if_gr),
  .alloc_to_if_en_in            (alloc_to_if_en),
  .if_d_in                      (alloc_if_d),

  .clear_branch_in              (clear_branch)
);

wire                            if_to_pc_en;
wire                            if_to_icache_en;
wire [`AddrWidth-1:0]           if_to_icache_a;
wire [`InstrWidth-1:0]          if_instr;
wire [`AddrWidth-1:0]           if_pc;
wire                            if_bp;
wire                            if_to_issue_en;

IF if0(
  .clk_in                       (clk_in),
  .rst_in                       (rst_in),
  .rdy_in                       (rdy_in),

  .commit_to_if_en_in           (commit_to_if_en),
  .commit_to_if_pc_in           (commit_to_if_pc),
  .commit_to_if_bpres_in        (commit_to_if_bpres),

  .if_to_icache_en_out          (if_to_icache_en),
  .if_a_out                     (if_to_icache_a),
  .icache_to_if_en_in           (icache_to_if_en),
  .if_d_in                      (icache_to_if_d),

  .instr_out                    (if_instr),
  .pc_out                       (if_pc),
  .bp_out                       (if_bp),

  .issue_to_if_en_in            (issue_to_if_en),
  .if_to_issue_en_out           (if_to_issue_en),

  .commit_to_pc_en_in           (commit_to_pc_en),
  .commit_to_pc_in              (commit_pc),

  .clear_branch_in              (clear_branch)
);

wire [`InstrIdWidth-1:0]        id_instr_id;
wire [`ImmWidth-1:0]            id_imm;
wire [`RegIdxWidth-1:0]         id_rs1, id_rs2, id_rd;

ID id0(
  .instr_in                     (if_instr),

  .instr_id_out                 (id_instr_id),
  .imm_out                      (id_imm),
  .rs1_out                      (id_rs1),
  .rs2_out                      (id_rs2),
  .rd_out                       (id_rd)
);

wire                            issue_to_rs_en;
wire [`RSIdxWidth-1:0]          issue_rs_pos;
wire                            issue_to_lsb_en;
wire [`LSBIdxWidth-1:0]         issue_lsb_pos;
wire                            issue_to_rob_en;
wire [`ROBIdxWidth-1:0]         issue_rob_pos;
wire                            issue_to_if_en;
wire                            issue_to_regfile_en;

Issue issue0(
  .if_to_issue_en_in            (if_to_issue_en),

  .instr_id_in                  (id_instr_id),
  .rd_in                        (id_rd),

  .rs_busy_status_in            (rs_busy_status),
  .issue_to_rs_en_out           (issue_to_rs_en),
  .rs_pos_out                   (issue_rs_pos),

  .lsb_empty_in                 (lsb_empty),
  .lsb_head_in                  (lsb_head),
  .lsb_tail_in                  (lsb_tail),
  .issue_to_lsb_en_out          (issue_to_lsb_en),
  .lsb_pos_out                  (issue_lsb_pos),

  .rob_empty_in                 (rob_empty),
  .rob_head_in                  (rob_head),
  .rob_tail_in                  (rob_tail),
  .issue_to_rob_en_out          (issue_to_rob_en),
  .rob_pos_out                  (issue_rob_pos),

  .issue_to_if_en_out           (issue_to_if_en),
  .issue_to_regfile_en_out      (issue_to_regfile_en)
);

wire [`WordWidth-1:0]           regfile_rs1_reg, regfile_rs2_reg;
wire [`ROBIdxWidth-1:0]         regfile_rs1_tag, regfile_rs2_tag;

Regfile regfile0(
  .clk_in                       (clk_in),
  .rst_in                       (rst_in),
  .rdy_in                       (rdy_in),

  .issue_to_regfile_en_in       (issue_to_regfile_en),
  .issue_to_regfile_rs1_in      (id_rs1),
  .issue_to_regfile_rs2_in      (id_rs2),
  .issue_to_regfile_rd_in       (id_rd),
  .issue_to_regfile_rob_pos_in  (issue_rob_pos),

  .rs1_reg_out                  (regfile_rs1_reg),
  .rs1_tag_out                  (regfile_rs1_tag),
  .rs2_reg_out                  (regfile_rs2_reg),
  .rs2_tag_out                  (regfile_rs2_tag),
  .commit_to_regfile_en_in      (commit_to_regfile_en),
  .commit_to_regfile_instr_id_in(rob_instr_id),
  .commit_to_regfile_rd_in      (rob_rd),
  .commit_to_regfile_rob_pos_in (rob_rob_pos),
  .commit_to_regfile_res_in     (rob_res),

  .clear_branch_in              (clear_branch)
);

wire [`RSSize-1:0]              rs_busy_status;
wire                            rs_to_ex_en;
wire [`InstrIdWidth-1:0]        rs_instr_id;
wire [`ImmWidth-1:0]            rs_imm;
wire [`WordWidth-1:0]           rs_rs1, rs_rs2;
wire [`AddrWidth-1:0]           rs_pc;
wire [`ROBIdxWidth-1:0]         rs_rob_pos;

Reservation rs0(
  .clk_in                       (clk_in),
  .rst_in                       (rst_in),
  .rdy_in                       (rdy_in),

  .issue_to_rs_en_in            (issue_to_rs_en),

  .rs_pos_in                    (issue_rs_pos),
  .rob_pos_in                   (issue_rob_pos),
  .instr_id_in                  (id_instr_id),
  .imm_in                       (id_imm),
  .pc_in                        (if_pc),

  .rs1_reg_in                   (regfile_rs1_reg),
  .rs1_tag_in                   (regfile_rs1_tag),
  .rs1_rob_stall_in             (rob_rs1_stall),
  .rs1_rob_res_in               (rob_rs1_res),
  .rs2_reg_in                   (regfile_rs2_reg),
  .rs2_tag_in                   (regfile_rs2_tag),
  .rs2_rob_stall_in             (rob_rs2_stall),
  .rs2_rob_res_in               (rob_rs2_res),

  .ex_to_rs_en_in               (ex_to_rs_en),
  .ex_to_rs_rob_pos_in          (ex_rob_pos),
  .ex_to_rs_res_in              (ex_res),

  .lsb_to_rs_en_in              (lsb_to_rs_en),
  .lsb_to_rs_rob_pos_in         (lsb_rob_pos_r),
  .lsb_to_rs_res_in             (lsb_res),

  .rs_to_issue_busy_status_out  (rs_busy_status),

  .rs_to_ex_en_out              (rs_to_ex_en),
  .instr_id_out                 (rs_instr_id),
  .imm_out                      (rs_imm),
  .rs1_out                      (rs_rs1),
  .rs2_out                      (rs_rs2),
  .pc_out                       (rs_pc),
  .rob_pos_out                  (rs_rob_pos),

  .clear_branch_in              (clear_branch)
);

wire                            ex_to_rs_en;
wire                            ex_to_lsb_en;
wire                            ex_to_rob_en;
wire [`WordWidth-1:0]           ex_res;
wire                            ex_jump_en;
wire [`AddrWidth-1:0]           ex_jump_a;
wire [`ROBIdxWidth-1:0]         ex_rob_pos;

EX ex0(
  .rs_to_ex_en_in               (rs_to_ex_en),
  .instr_id_in                  (rs_instr_id),
  .imm_in                       (rs_imm),
  .rs1_in                       (rs_rs1),
  .rs2_in                       (rs_rs2),
  .pc_in                        (rs_pc),
  .rob_pos_in                   (rs_rob_pos),

  .ex_to_rs_en_out              (ex_to_rs_en),
  .ex_to_lsb_en_out             (ex_to_lsb_en),
  .ex_to_rob_en_out             (ex_to_rob_en),
  .res_out                      (ex_res),
  .jump_en_out                  (ex_jump_en),
  .jump_a_out                   (ex_jump_a),
  .rob_pos_out                  (ex_rob_pos)
);

wire                            lsb_to_alloc_r_en;
wire [`WordBytesWidth-1:0]      lsb_r_offset;
wire [`AddrWidth-1:0]           lsb_r_a;
wire                            lsb_to_alloc_w_en;
wire [`WordBytesWidth-1:0]      lsb_w_offset;
wire [`AddrWidth-1:0]           lsb_w_a;
wire [`WordWidth-1:0]           lsb_d;
wire                            lsb_to_rs_en;
wire                            lsb_to_lsb_en;
wire                            lsb_empty;
wire [`LSBIdxWidth-1:0]         lsb_head, lsb_tail;
wire                            lsb_to_rob_r_en;
wire                            lsb_to_rob_r_io_en;
wire                            lsb_to_rob_w_en;
wire [`WordWidth-1:0]           lsb_res;
wire [`ROBIdxWidth-1:0]         lsb_rob_pos_r;
wire [`ROBIdxWidth-1:0]         lsb_rob_pos_w;

LSBuffer lsb0(
  .clk_in                       (clk_in),
  .rst_in                       (rst_in),
  .rdy_in                       (rdy_in),

  .issue_to_lsb_en_in           (issue_to_lsb_en),
  .lsb_pos_in                   (issue_lsb_pos),
  .rob_pos_in                   (issue_rob_pos),
  .instr_id_in                  (id_instr_id),
  .imm_in                       (id_imm),

  .rs1_reg_in                   (regfile_rs1_reg),
  .rs1_tag_in                   (regfile_rs1_tag),
  .rs1_rob_stall_in             (rob_rs1_stall),
  .rs1_rob_res_in               (rob_rs1_res),
  .rs2_reg_in                   (regfile_rs2_reg),
  .rs2_tag_in                   (regfile_rs2_tag),
  .rs2_rob_stall_in             (rob_rs2_stall),
  .rs2_rob_res_in               (rob_rs2_res),

  .ex_to_lsb_en_in              (ex_to_lsb_en),
  .ex_to_lsb_rob_pos_in         (ex_rob_pos),
  .ex_to_lsb_res_in             (ex_res),

  .lsb_to_lsb_en_in             (lsb_to_lsb_en),
  .lsb_to_lsb_rob_pos_in        (lsb_rob_pos_r),
  .lsb_to_lsb_res_in            (lsb_res),

  .lsb_to_alloc_r_en_out        (lsb_to_alloc_r_en),
  .lsb_r_offset_out             (lsb_r_offset),
  .lsb_r_a_out                  (lsb_r_a),
  .alloc_to_lsb_r_gr_in         (alloc_to_lsb_r_gr),
  .alloc_to_lsb_r_en_in         (alloc_to_lsb_r_en),
  .lsb_d_in                     (alloc_lsb_d),
  
  .lsb_to_alloc_w_en_out        (lsb_to_alloc_w_en),
  .lsb_w_offset_out             (lsb_w_offset),
  .lsb_w_a_out                  (lsb_w_a),
  .lsb_d_out                    (lsb_d),
  .alloc_to_lsb_w_gr_in         (alloc_to_lsb_w_gr),
  .alloc_to_lsb_w_en_in         (alloc_to_lsb_w_en),

  .lsb_to_rs_en_out             (lsb_to_rs_en),
  .lsb_to_lsb_en_out            (lsb_to_lsb_en),

  .lsb_to_issue_empty_out       (lsb_empty),
  .lsb_to_issue_head_out        (lsb_head),
  .lsb_to_issue_tail_out        (lsb_tail),

  .commit_to_lsb_r_io_en_in     (commit_to_lsb_r_io_en),
  .commit_to_lsb_w_en_in        (commit_to_lsb_w_en),

  .lsb_to_rob_r_en_out          (lsb_to_rob_r_en),
  .lsb_to_rob_r_io_en_out       (lsb_to_rob_r_io_en),
  .lsb_to_rob_w_en_out          (lsb_to_rob_w_en),
  .res_out                      (lsb_res),
  .rob_pos_r_out                (lsb_rob_pos_r),
  .rob_pos_w_out                (lsb_rob_pos_w),
  
  .clear_branch_in              (clear_branch)
);

wire                            rob_empty;
wire [`ROBIdxWidth-1:0]         rob_head, rob_tail;
wire                            rob_rs1_stall;
wire [`WordWidth-1:0]           rob_rs1_res;
wire                            rob_rs2_stall;
wire [`WordWidth-1:0]           rob_rs2_res;
wire                            rob_to_commit_en;
wire [`InstrIdWidth-1:0]        rob_instr_id;
wire [`RegIdxWidth-1:0]         rob_rd;
wire [`ROBIdxWidth-1:0]         rob_rob_pos;
wire [`LSBIdxWidth-1:0]         rob_lsb_pos;
wire [`WordWidth-1:0]           rob_res;
wire                            rob_jump_en;
wire [`AddrWidth-1:0]           rob_jump_a;
wire [`AddrWidth-1:0]           rob_pc;
wire                            rob_bp;
wire                            commit_to_lsb_r_io_en;

ROB rob0(
  .clk_in                       (clk_in),
  .rst_in                       (rst_in),
  .rdy_in                       (rdy_in),

  .issue_to_rob_en_in           (issue_to_rob_en),
  .issue_rob_pos_in             (issue_rob_pos),
  .instr_id_in                  (id_instr_id),
  .rd_in                        (id_rd),
  .pc_in                        (if_pc),
  .bp_in                        (if_bp),

  .ex_to_rob_en_in              (ex_to_rob_en),
  .ex_res_in                    (ex_res),
  .ex_jump_en_in                (ex_jump_en),
  .ex_jump_a_in                 (ex_jump_a),
  .ex_rob_pos_in                (ex_rob_pos),

  .lsb_to_rob_r_en_in           (lsb_to_rob_r_en),
  .lsb_to_rob_r_io_en_in        (lsb_to_rob_r_io_en),
  .lsb_to_rob_w_en_in           (lsb_to_rob_w_en),
  .lsb_res_in                   (lsb_res),
  .lsb_rob_pos_r_in             (lsb_rob_pos_r),
  .lsb_rob_pos_w_in             (lsb_rob_pos_w),

  .rob_to_issue_empty_out       (rob_empty),
  .rob_to_issue_head_out        (rob_head),
  .rob_to_issue_tail_out        (rob_tail),

  .rs1_rob_pos_in               (regfile_rs1_tag),
  .rs2_rob_pos_in               (regfile_rs2_tag),
  .rs1_stall_out                (rob_rs1_stall),
  .rs1_res_out                  (rob_rs1_res),
  .rs2_stall_out                (rob_rs2_stall),
  .rs2_res_out                  (rob_rs2_res),

  .rob_to_commit_en_out         (rob_to_commit_en),
  .instr_id_out                 (rob_instr_id),
  .rd_out                       (rob_rd),
  .rob_pos_out                  (rob_rob_pos),
  .res_out                      (rob_res),
  .jump_en_out                  (rob_jump_en),
  .jump_a_out                   (rob_jump_a),
  .pc_out                       (rob_pc),
  .bp_out                       (rob_bp),
  .commit_to_lsb_r_io_en_out    (commit_to_lsb_r_io_en),

  .clear_branch_in              (clear_branch)
);

wire                            commit_to_regfile_en;
wire                            commit_to_lsb_w_en;
wire                            commit_to_pc_en;
wire [`AddrWidth-1:0]           commit_pc;
wire                            commit_to_if_en;
wire [`AddrWidth-1:0]           commit_to_if_pc;
wire                            commit_to_if_bpres;
wire                            clear_branch;

Commit  commit0(
  .rob_to_commit_en_in          (rob_to_commit_en),

  .instr_id_in                  (rob_instr_id),
  .jump_en_in                   (rob_jump_en),
  .jump_a_in                    (rob_jump_a),
  .pc_in                        (rob_pc),
  .bp_in                        (rob_bp),

  .commit_to_regfile_en_out     (commit_to_regfile_en),
  .commit_to_lsb_w_en_out       (commit_to_lsb_w_en),
  
  .commit_to_pc_en_out          (commit_to_pc_en),
  .commit_to_pc_out             (commit_pc),

  .commit_to_if_en_out          (commit_to_if_en),
  .commit_to_if_pc_out          (commit_to_if_pc),
  .commit_to_if_bpres_out       (commit_to_if_bpres),

  .clear_branch_out             (clear_branch)
);

endmodule