// reservation station

`include "config.vh"

module Reservation (
    input   wire                        clk_in,
    input   wire                        rst_in,
    input   wire                        rdy_in,

    input   wire                        issue_to_rs_en_in,

    input   wire [`RSIdxWidth-1:0]      rs_pos_in,
    input   wire [`ROBIdxWidth-1:0]     rob_pos_in,
    input   wire [`InstrIdWidth-1:0]    instr_id_in,
    input   wire [`ImmWidth-1:0]        imm_in,
    input   wire [`RegIdxWidth-1:0]     rs1_in, rs2_in, rd_in,
    input   wire [`AddrWidth-1:0]       pc_in,

    input   wire [`WordWidth-1:0]       rs1_reg_in,
    input   wire [`ROBIdxWidth-1:0]     rs1_tag_in,
    input   wire                        rs1_rob_stall_in,
    input   wire [`WordWidth-1:0]       rs1_rob_res_in,
    input   wire [`WordWidth-1:0]       rs2_reg_in,
    input   wire [`ROBIdxWidth-1:0]     rs2_tag_in,
    input   wire                        rs2_rob_stall_in,
    input   wire [`WordWidth-1:0]       rs2_rob_res_in,

    input   wire                        ex_to_rs_en_in,
    input   wire [`ROBIdxWidth-1:0]     ex_to_rs_rob_pos_in,
    input   wire [`WordWidth-1:0]       ex_to_rs_res_in,

    input   wire                        lsb_to_rs_en_in,
    input   wire [`ROBIdxWidth-1:0]     lsb_to_rs_rob_pos_in,
    input   wire [`WordWidth-1:0]       lsb_to_rs_res_in,

    output  wire [`RSSize-1:0]          rs_to_issue_busy_status_out,

    // output to ex
    output  reg                         rs_to_ex_en_out,
    output  reg [`InstrIdWidth-1:0]     instr_id_out,
    output  reg [`ImmWidth-1:0]         imm_out,
    output  reg [`WordWidth-1:0]        rs1_out, rs2_out,
    output  reg [`AddrWidth-1:0]        pc_out,
    output  reg [`ROBIdxWidth-1:0]      rob_pos_out,

    input   wire                        clear_branch_in
);

reg [`RSSize-1:0]           busy_status;
reg [`InstrIdWidth-1:0]     instr_id[`RSSize-1:0];
reg [`ROBIdxWidth-1:0]      rob_id[`RSSize-1:0];
reg [`ImmWidth-1:0]         imm[`RSSize-1:0];
reg [`ROBIdxWidth-1:0]      q1[`RSSize-1:0], q2[`RSSize-1:0];
reg [`WordWidth-1:0]        v1[`RSSize-1:0], v2[`RSSize-1:0];
reg [`RegIdxWidth-1:0]      rd[`RSSize-1:0];
reg [`AddrWidth-1:0]        pc[`RSSize-1:0];
    
integer i;

always @(posedge clk_in) begin
    if (rst_in) begin
        busy_status <= `ZERO;
    end
    else if (rdy_in && !clear_branch_in) begin
        if (issue_to_rs_en_in) begin
            busy_status[rs_pos_in] <= `TRUE;
            instr_id[rs_pos_in] <= instr_id_in;
            imm[rs_pos_in] <= imm_in;
            rd[rs_pos_in] <= rd_in;
            pc[rs_pos_in] <= pc_in;
            rob_id[rs_pos_in] <= rob_pos_in;
            if (rs1_tag_in == `ZERO) begin
                q1[rs_pos_in] <= 0;
                v1[rs_pos_in] <= rs1_reg_in;
            end
            else begin
                if (ex_to_rs_en_in && ex_to_rs_rob_pos_in == rs1_tag_in) begin
                    q1[rs_pos_in] <= 0;
                    v1[rs_pos_in] <= ex_to_rs_res_in;
                end
                else if (lsb_to_rs_en_in && lsb_to_rs_rob_pos_in == rs1_tag_in) begin
                    q1[rs_pos_in] <= 0;
                    v1[rs_pos_in] <= lsb_to_rs_res_in;
                end
                else if (rs1_rob_stall_in == `FALSE) begin
                    q1[rs_pos_in] <= 0;
                    v1[rs_pos_in] <= rs1_rob_res_in;
                end
                else q1[rs_pos_in] <= rs1_tag_in;
            end
            if (rs2_tag_in == `ZERO) begin
                q2[rs_pos_in] <= 0;
                v2[rs_pos_in] <= rs2_reg_in;
            end
            else begin
                if (ex_to_rs_en_in && ex_to_rs_rob_pos_in == rs2_tag_in) begin
                    q2[rs_pos_in] <= 0;
                    v2[rs_pos_in] <= ex_to_rs_res_in;
                end
                else if (lsb_to_rs_en_in && lsb_to_rs_rob_pos_in == rs2_tag_in) begin
                    q2[rs_pos_in] <= 0;
                    v2[rs_pos_in] <= lsb_to_rs_res_in;
                end
                else if (rs2_rob_stall_in == `FALSE) begin
                    q2[rs_pos_in] <= 0;
                    v2[rs_pos_in] <= rs2_rob_res_in;
                end
                else q2[rs_pos_in] <= rs2_tag_in;
            end
        end
        for (i = 0; i < `RSSize; i = i + 1) begin
            if (busy_status[i]) begin
                if (ex_to_rs_en_in && q1[i] == ex_to_rs_rob_pos_in) begin
                    q1[i] <= 0;
                    v1[i] <= ex_to_rs_res_in;
                end
                if (ex_to_rs_en_in && q2[i] == ex_to_rs_rob_pos_in) begin
                    q2[i] <= 0;
                    v2[i] <= ex_to_rs_res_in;
                end
                if (lsb_to_rs_en_in && q1[i] == lsb_to_rs_rob_pos_in) begin
                    q1[i] <= 0;
                    v1[i] <= lsb_to_rs_res_in;
                end
                if (lsb_to_rs_en_in && q2[i] == lsb_to_rs_rob_pos_in) begin
                    q2[i] <= 0;
                    v2[i] <= lsb_to_rs_res_in;
                end
            end
        end
    end
end

reg                     has_rdy;
reg [`RSIdxWidth-1:0]   rdy_to_ex;

always @(*) begin
    has_rdy = `FALSE;
    for (i = 0; i < `RSSize; i = i + 1)
        if (busy_status[i] && q1[i] == `ZERO && q2[i] == `ZERO) begin
            has_rdy = `TRUE;
            rdy_to_ex = i;
        end
end

always @(posedge clk_in) begin
    if (rst_in) begin
        has_rdy <= `FALSE;
        rs_to_ex_en_out <= `FALSE;
    end
    else if (rdy_in && !clear_branch_in) begin
        rs_to_ex_en_out <= `FALSE;
        if (has_rdy) begin
            rs_to_ex_en_out <= `TRUE;
            instr_id_out <= instr_id[rdy_to_ex];
            imm_out <= imm[rdy_to_ex];
            rs1_out <= v1[rdy_to_ex];
            rs2_out <= v2[rdy_to_ex];
            pc_out <= pc[rdy_to_ex];
            rob_pos_out <= rob_id[rdy_to_ex];
            busy_status[rdy_to_ex] <= `FALSE;
        end
    end
end

always @(posedge clk_in) begin
    if (!rst_in && rdy_in && clear_branch_in) begin
        busy_status <= `ZERO;
        has_rdy <= `FALSE;
        rs_to_ex_en_out <= `FALSE;
    end
end

assign rs_to_issue_busy_status_out = busy_status;

endmodule