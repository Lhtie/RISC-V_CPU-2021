// ReOrder Buffer

`include "config.vh"

module ROB (
    input   wire                        clk_in,
    input   wire                        rst_in,
    input   wire                        rdy_in,

    input   wire                        issue_to_rob_en_in,
    input   wire [`ROBIdxWidth-1:0]     issue_rob_pos_in,
    input   wire [`InstrIdWidth-1:0]    instr_id_in,
    input   wire [`RegIdxWidth-1:0]     rd_in,
    input   wire [`AddrWidth-1:0]       pc_in,
    input   wire                        bp_in,

    input   wire                        ex_to_rob_en_in,
    input   wire [`WordWidth-1:0]       ex_res_in,
    input   wire                        ex_jump_en_in,
    input   wire [`AddrWidth-1:0]       ex_jump_a_in,
    input   wire [`ROBIdxWidth-1:0]     ex_rob_pos_in,

    input   wire                        lsb_to_rob_r_en_in,
    input   wire                        lsb_to_rob_r_io_en_in,
    input   wire                        lsb_to_rob_w_en_in,
    input   wire [`WordWidth-1:0]       lsb_res_in,
    input   wire [`ROBIdxWidth-1:0]     lsb_rob_pos_r_in,
    input   wire [`ROBIdxWidth-1:0]     lsb_rob_pos_w_in,

    output  wire                        rob_to_issue_empty_out,
    output  wire [`ROBIdxWidth-1:0]     rob_to_issue_head_out, rob_to_issue_tail_out,

    input   wire [`ROBIdxWidth-1:0]     rs1_rob_pos_in,
    input   wire [`ROBIdxWidth-1:0]     rs2_rob_pos_in,
    output  wire                        rs1_stall_out,
    output  wire [`WordWidth-1:0]       rs1_res_out,
    output  wire                        rs2_stall_out,
    output  wire [`WordWidth-1:0]       rs2_res_out,

    output  reg                         rob_to_commit_en_out,
    output  reg [`InstrIdWidth-1:0]     instr_id_out,
    output  reg [`RSIdxWidth-1:0]       rd_out,
    output  reg [`ROBIdxWidth-1:0]      rob_pos_out,
    output  reg [`WordWidth-1:0]        res_out,
    output  reg                         jump_en_out,
    output  reg [`AddrWidth-1:0]        jump_a_out,
    output  reg [`AddrWidth-1:0]        pc_out,
    output  reg                         bp_out,
    output  reg                         commit_to_lsb_r_io_en_out,

    input   wire                        clear_branch_in
);

reg                     empty;
reg [`ROBIdxWidth-1:0]  head, tail;
reg [`ROBSize-1:0]      stall_status, io_read;
reg [`InstrWidth-1:0]   instr_id_que[`ROBSize-1:1];
reg [`AddrWidth-1:0]    rd_que[`ROBSize-1:1];
reg [`WordWidth-1:0]    res_que[`ROBSize-1:1];
reg                     jump_en_que[`ROBSize-1:1];
reg [`AddrWidth-1:0]    jump_a_que[`ROBSize-1:1];
reg [`AddrWidth-1:0]    pc_que[`ROBSize-1:1];
reg                     bp_que[`ROBSize-1:1];

always @(posedge clk_in) begin
    if (rst_in) begin
        empty <= `TRUE;
        head <= `ONE;
        tail <= `ONE;
        rob_to_commit_en_out <= `FALSE;
        commit_to_lsb_r_io_en_out <= `FALSE;
    end
    else if (rdy_in) begin
        // expand ROB from issue
        if (issue_to_rob_en_in) begin
            tail <= tail % (`ROBSize - 1) + `ROBIdxWidth'b1;
            empty <= `FALSE;
            stall_status[issue_rob_pos_in] <= `TRUE;
            io_read[issue_rob_pos_in] <= `FALSE;
            instr_id_que[issue_rob_pos_in] <= instr_id_in;
            rd_que[issue_rob_pos_in] <= rd_in;
            pc_que[issue_rob_pos_in] <= pc_in;
            bp_que[issue_rob_pos_in] <= bp_in;
        end
        if (ex_to_rob_en_in) begin
            res_que[ex_rob_pos_in] <= ex_res_in;
            jump_en_que[ex_rob_pos_in] <= ex_jump_en_in;
            jump_a_que[ex_rob_pos_in] <= ex_jump_a_in;
            stall_status[ex_rob_pos_in] <= `FALSE;
        end
        if (lsb_to_rob_r_en_in) begin
            res_que[lsb_rob_pos_r_in] <= lsb_res_in;
            stall_status[lsb_rob_pos_r_in] <= `FALSE;
        end
        if (lsb_to_rob_r_io_en_in)
            io_read[lsb_rob_pos_r_in] <= `TRUE;
        if (lsb_to_rob_w_en_in)
            stall_status[lsb_rob_pos_w_in] <= `FALSE;

        // try to commit
        rob_to_commit_en_out <= `FALSE;
        commit_to_lsb_r_io_en_out <= `FALSE;
        if (!empty && !stall_status[head]) begin
            rob_to_commit_en_out <= `TRUE;
            instr_id_out <= instr_id_que[head];
            rd_out <= rd_que[head];
            rob_pos_out <= head;
            res_out <= res_que[head];
            jump_en_out <= jump_en_que[head];
            jump_a_out <= jump_a_que[head];
            pc_out <= pc_que[head];
            bp_out <= bp_que[head];

            head <= head % (`ROBSize - 1) + `ROBIdxWidth'b1;
            if (!issue_to_rob_en_in)
                empty <= head % (`ROBSize - 1) + `ROBIdxWidth'b1 == tail;
        end
        else if (!empty && io_read[head]) begin
            commit_to_lsb_r_io_en_out <= `TRUE;
            io_read[head] <= `FALSE;
        end

        if (clear_branch_in) begin
            empty <= `TRUE;
            head <= `ONE;
            tail <= `ONE;
            stall_status <= `ZERO;
            io_read <= `ZERO;
            rob_to_commit_en_out <= `FALSE;
            commit_to_lsb_r_io_en_out <= `FALSE;
        end
    end
end

assign rob_to_issue_empty_out = empty;
assign rob_to_issue_head_out = head;
assign rob_to_issue_tail_out = tail;

assign rs1_stall_out = stall_status[rs1_rob_pos_in];
assign rs1_res_out = res_que[rs1_rob_pos_in];
assign rs2_stall_out = stall_status[rs2_rob_pos_in];
assign rs2_res_out = res_que[rs2_rob_pos_in];
    
endmodule