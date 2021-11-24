// decode instruction

`include "config.vh"

module ID (
    input   wire [`InstrWidth-1:0]  instr_in,
    input   wire [`AddrWidth-1:0]   pc_in,

    output  reg [`InstrIdWidth-1:0] instr_id_out,
    output  reg [`ImmWidth-1:0]     imm_out,
    output  reg [`RegIdxWidth-1:0]  rs1_out, rs2_out, rd_out,
    output  wire [`AddrWidth-1:0]   pc_out
);

reg [`OpCodeWidth-1:0]  opcode;
reg [`Funct3Width-1:0]  funct3;
reg [`Funct7Width-1:0]  funct7;

always @(*) begin
    imm_out = {`ImmWidth{1'b0}};
    rs1_out = instr_in[19:15];
    rs2_out = instr_in[24:20];
    rd_out = instr_in[11:7];
    opcode = instr_in[6:0];
    funct3 = instr_in[14:12];
    funct7 = instr_in[31:25];
    case (opcode)
        7'b0110111, 7'b0010111: begin
            instr_id_out = opcode == 7'b0110111 ? `LUI : `AUIPC;
            imm_out[31:12] = instr_in[31:12];
            rs1_out = `ZERO;
            rs2_out = `ZERO;
        end 
        7'b1101111: begin
            instr_id_out = `JAL;
            imm_out[20] = instr_in[31];
            imm_out[10:1] = instr_in[30:21];
            imm_out[11] = instr_in[20];
            imm_out[19:12] = instr_in[19:12];
            imm_out = {{11{imm_out[20]}}, imm_out[20:0]};
            rs1_out = `ZERO;
            rs2_out = `ZERO;
        end
        7'b1100111, 7'b0000011, 7'b0010011: begin
            imm_out[11:0] = instr_in[31:20];
            imm_out = {{20{imm_out[11]}}, imm_out[11:0]};
            rs2_out = `ZERO;
            if (opcode == 7'b1100111)
                instr_id_out = `JALR;
            else if (opcode == 7'b0000011) begin
                case (funct3)
                    3'b000: instr_id_out = `LB;
                    3'b001: instr_id_out = `LH;
                    3'b010: instr_id_out = `LW;
                    3'b100: instr_id_out = `LBU;
                    3'b101: instr_id_out = `LHU;
                endcase
            end
            else begin
                if (funct3 == 3'b001 || funct3 == 3'b101) begin
                    imm_out = {`ImmWidth{1'b0}};
                    imm_out[4:0] = instr_in[24:20];
                end
                case (funct3)
                    3'b000: instr_id_out = `ADDI;
                    3'b010: instr_id_out = `SLTI;
                    3'b011: instr_id_out = `SLTIU;
                    3'b100: instr_id_out = `XORI;
                    3'b110: instr_id_out = `ORI;
                    3'b111: instr_id_out = `ANDI;
                    3'b001: instr_id_out = `SLLI;
                    3'b101: instr_id_out = funct7[5] ? `SRAI : `SRLI;
                endcase
            end
        end
        7'b1100011: begin
            imm_out[12] = instr_in[31];
            imm_out[10:5] = instr_in[30:25];
            imm_out[4:1] = instr_in[11:8];
            imm_out[11] = instr_in[7];
            imm_out = {{19{imm_out[12]}}, imm_out[12:0]};
            case (funct3)
                3'b000: instr_id_out = `BEQ;
                3'b001: instr_id_out = `BNE;
                3'b100: instr_id_out = `BLT;
                3'b101: instr_id_out = `BGE;
                3'b110: instr_id_out = `BLTU;
                3'b111: instr_id_out = `BGEU;
            endcase
        end
        7'b0100011: begin
            imm_out[11:5] = instr_in[31:25];
            imm_out[4:0] = instr_in[11:7];
            imm_out = {{20{imm_out[11]}}, imm_out[11:0]};
            case (funct3)
                3'b000: instr_id_out = `SB;
                3'b001: instr_id_out = `SH;
                3'b010: instr_id_out = `SW;
            endcase
        end
        7'b0110011: begin
            case (funct3)
                3'b000: instr_id_out = funct7[5] ? `SUB : `ADD;
                3'b001: instr_id_out = `SLL;
                3'b010: instr_id_out = `SLT;
                3'b011: instr_id_out = `SLTU;
                3'b100: instr_id_out = `XOR;
                3'b101: instr_id_out = funct7[5] ? `SRA : `SRL;
                3'b110: instr_id_out = `OR;
                3'b111: instr_id_out = `AND;
            endcase
        end
    endcase
end

assign pc_out = pc_in;

endmodule