// commit for ROB

`include "config.vh"

module Commit (
    input   wire                        rob_to_commit_en_in,

    input   wire [`InstrIdWidth-1:0]    instr_id_in,
    input   wire                        jump_en_in,
    input   wire [`AddrWidth-1:0]       jump_a_in,

    output  reg                         commit_to_regfile_en_out,
    output  reg                         commit_to_lsb_en_out,

    output  reg                         commit_to_pc_en_out,
    output  reg [`AddrWidth-1:0]        commit_to_pc_out,
    output  reg                         clear_branch_out
);

always @(*) begin
    commit_to_regfile_en_out = `FALSE;
    commit_to_lsb_en_out = `FALSE;
    commit_to_pc_en_out = `FALSE;
    commit_to_pc_out = `ZERO;
    clear_branch_out = `FALSE;
    if (rob_to_commit_en_in) begin
        if (instr_id_in <= `LHU || instr_id_in >= `LUI && instr_id_in <= `JALR || instr_id_in >= `ADDI) begin
            commit_to_regfile_en_out = `TRUE;
        end
        if (instr_id_in >= `JAL && instr_id_in <= `BGEU)
            if (jump_en_in) begin
                commit_to_pc_en_out = `TRUE;
                commit_to_pc_out = jump_a_in;
                clear_branch_out = `TRUE;
            end
        if (instr_id_in >= `SB && instr_id_in <= `SW) begin
            commit_to_lsb_en_out = `TRUE;
        end
    end
end
    
endmodule