// execute instruction for rs

`include "config.vh"

module EX (
    input   wire                        rs_to_ex_en_in,
    input   wire [`InstrIdWidth-1:0]    instr_id_in,
    input   wire [`ImmWidth-1:0]        imm_in,
    input   wire [`WordWidth-1:0]       rs1_in, rs2_in,
    input   wire [`AddrWidth-1:0]       pc_in,
    input   wire [`ROBIdxWidth-1:0]     rob_pos_in,

    output  wire                        ex_to_rs_en_out,
    output  wire                        ex_to_lsb_en_out,
    output  wire                        ex_to_rob_en_out,
    output  reg [`WordWidth-1:0]        res_out,
    output  reg                         jump_en_out,
    output  reg [`AddrWidth-1:0]        jump_a_out,
    output  reg [`ROBIdxWidth-1:0]      rob_pos_out
);

wire [`AddrWidth-1:0]   jump_a = pc_in + imm_in;
wire [`AddrWidth-1:0]   jalr_jump_a = (rs1_in + imm_in) & ~`WordWidth'b1;

always @(*) begin
    res_out = {`ImmWidth{1'b0}};
    jump_en_out = `FALSE;
    jump_a_out = `ZERO;
    rob_pos_out = rob_pos_in;
    case (instr_id_in)
        `BEQ, `BNE, `BLT, `BGE, `BLTU, `BGEU:
            jump_a_out = jump_a;
    endcase
    case (instr_id_in)
        `LUI: res_out = imm_in;
        `AUIPC: res_out = jump_a;
        `JAL, `JALR: begin
            res_out = pc_in + `InstrBytes;
            jump_en_out = `TRUE;
            jump_a_out = instr_id_in == `JAL ? jump_a : jalr_jump_a;
        end
        `BEQ: jump_en_out = rs1_in == rs2_in;
        `BNE: jump_en_out = rs1_in != rs2_in;
        `BLT: jump_en_out = $signed(rs1_in) < $signed(rs2_in);
        `BGE: jump_en_out = $signed(rs1_in) >= $signed(rs2_in);
        `BLTU: jump_en_out = rs1_in < rs2_in;
        `BGEU: jump_en_out = rs1_in >= rs2_in;
        `ADDI: res_out = rs1_in + imm_in;
        `SLTI: res_out = $signed(rs1_in) < $signed(imm_in);
        `SLTIU: res_out = rs1_in < imm_in;
        `XORI: res_out = rs1_in ^ imm_in;
        `ORI: res_out = rs1_in | imm_in;
        `ANDI: res_out = rs1_in & imm_in;
        `SLLI: res_out = rs1_in << imm_in;
        `SRLI: res_out = rs1_in >> imm_in;
        `SRAI: res_out = rs1_in >>> imm_in;
        `ADD: res_out = rs1_in + rs2_in;
        `SUB: res_out = rs1_in - rs2_in;
        `SLL: res_out = rs1_in << rs2_in[4:0];
        `SLT: res_out = $signed(rs1_in) < $signed(rs2_in);
        `SLTU: res_out = rs1_in < rs2_in;
        `XOR: res_out = rs1_in ^ rs2_in;
        `SRL: res_out = rs1_in >> rs2_in[4:0];
        `SRA: res_out = rs1_in >>> rs2_in[4:0];
        `OR: res_out = rs1_in | rs2_in;
        `AND: res_out = rs1_in & rs2_in;
    endcase
end

assign ex_to_rs_en_out = rs_to_ex_en_in;
assign ex_to_lsb_en_out = rs_to_ex_en_in;
assign ex_to_rob_en_out = rs_to_ex_en_in;
    
endmodule