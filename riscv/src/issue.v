// issue instruction to rs, lsb or rob

`include "config.vh"

module Issue (
    input   wire                        if_to_issue_en_in,

    input   wire [`InstrIdWidth-1:0]    instr_id_in,
    input   wire [`RegIdxWidth-1:0]     rd_in,

    input   wire [`RSSize-1:0]          rs_busy_status_in,
    output  reg                         issue_to_rs_en_out,
    output  reg [`RSIdxWidth-1:0]       rs_pos_out,

    input   wire                        lsb_empty_in,
    input   wire [`LSBIdxWidth-1:0]     lsb_head_in, lsb_tail_in,
    output  reg                         issue_to_lsb_en_out,
    output  wire [`LSBIdxWidth-1:0]     lsb_pos_out,

    input   wire                        rob_empty_in,
    input   wire [`ROBIdxWidth-1:0]     rob_head_in, rob_tail_in,
    output  reg                         issue_to_rob_en_out,
    output  wire [`ROBIdxWidth-1:0]     rob_pos_out,

    output  reg                         issue_to_if_en_out,
    output  reg                         issue_to_regfile_en_out
);

integer i;
reg     valid;

always @(*) begin
    rs_pos_out = `ZERO;
    valid = `FALSE;
    for (i = 0; i < `RSSize; i = i + 1)
        if (!rs_busy_status_in[i]) begin
            valid = `TRUE;
            rs_pos_out = i;
        end
end

assign lsb_pos_out = lsb_tail_in;
assign rob_pos_out = rob_tail_in;

always @(*) begin
    issue_to_if_en_out = (rob_empty_in || rob_head_in != rob_tail_in)
        && valid && (lsb_empty_in || lsb_head_in != lsb_tail_in);
    issue_to_rs_en_out = `FALSE;
    issue_to_lsb_en_out = `FALSE;
    issue_to_rob_en_out = `FALSE;
    issue_to_regfile_en_out = `FALSE;
    if (if_to_issue_en_in) begin
        if (rob_empty_in || rob_head_in != rob_tail_in) begin
            if (instr_id_in > `SW) begin    // issue to RS
                if (valid) begin
                    issue_to_rs_en_out = `TRUE;
                    if (instr_id_in >= `LUI && instr_id_in <= `JALR || instr_id_in >= `ADDI)
                        if (rd_in) issue_to_regfile_en_out = `TRUE;
                    issue_to_rob_en_out = `TRUE;
                end
            end
            else begin                      // issue to LSB
                if (lsb_empty_in || lsb_head_in != lsb_tail_in) begin
                    issue_to_lsb_en_out = `TRUE;
                    if (instr_id_in <= `LHU)
                        if (rd_in) issue_to_regfile_en_out = `TRUE;
                    issue_to_rob_en_out = `TRUE;
                end
            end
        end
    end
end
    
endmodule