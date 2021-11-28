// implementation of 32 regfile

`include "config.vh"

module Regfile (
    input   wire                        clk_in,
    input   wire                        rst_in,
    input   wire                        rdy_in,

    input   wire                        issue_to_regfile_en_in,
    input   wire [`RegIdxWidth-1:0]     issue_to_regfile_rs1_in,
    input   wire [`RegIdxWidth-1:0]     issue_to_regfile_rs2_in,
    input   wire [`RegIdxWidth-1:0]     issue_to_regfile_rd_in,
    input   wire [`ROBIdxWidth-1:0]     issue_to_regfile_rob_pos_in,

    output  wire [`WordWidth-1:0]       rs1_reg_out,
    output  wire [`ROBIdxWidth-1:0]     rs1_tag_out,
    output  wire [`WordWidth-1:0]       rs2_reg_out,
    output  wire [`ROBIdxWidth-1:0]     rs2_tag_out,

    input   wire                        commit_to_regfile_en_in,
    input   wire [`InstrIdWidth-1:0]    commit_to_regfile_instr_id_in,
    input   wire [`RegIdxWidth-1:0]     commit_to_regfile_rd_in,
    input   wire [`ROBIdxWidth-1:0]     commit_to_regfile_rob_pos_in,
    input   wire [`WordWidth-1:0]       commit_to_regfile_res_in,

    input   wire                        clear_branch_in
);

reg [`WordWidth-1:0]    regs[`RegSize-1:0];
reg [`ROBIdxWidth-1:0]  tags[`RegSize-1:0];

wire [`WordWidth-1:0]   dbg_regs_12 = regs[12];
wire [`WordWidth-1:0]   dbg_regs_16 = regs[16];

integer i;

always @(posedge clk_in) begin
    if (rst_in) begin
        for (i = 0; i < `RegSize; i = i + 1) begin
            regs[i] <= `ZERO;
            tags[i] <= `ZERO;
        end
    end
    else if (rdy_in) begin
        if (issue_to_regfile_en_in)
            tags[issue_to_regfile_rd_in] <= issue_to_regfile_rob_pos_in;
        if (commit_to_regfile_en_in) begin
            if (commit_to_regfile_instr_id_in <= `LHU || commit_to_regfile_instr_id_in >= `LUI)
                if (commit_to_regfile_rd_in != `ZERO) begin
                    regs[commit_to_regfile_rd_in] <= commit_to_regfile_res_in;
                    if (tags[commit_to_regfile_rd_in] == commit_to_regfile_rob_pos_in)
                        tags[commit_to_regfile_rd_in] <= 0;
                end 
        end
        if (clear_branch_in) begin
            for (i = 0; i < `RegSize; i = i + 1) begin
                tags[i] <= `ZERO;
            end
        end
    end
end

 assign rs1_reg_out = regs[issue_to_regfile_rs1_in];
 assign rs1_tag_out = tags[issue_to_regfile_rs1_in];
 assign rs2_reg_out = regs[issue_to_regfile_rs2_in];
 assign rs2_tag_out = tags[issue_to_regfile_rs2_in];
    
endmodule