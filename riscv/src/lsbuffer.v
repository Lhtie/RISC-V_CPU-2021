// load & store buffer

`include "config.vh"

module LSBuffer (
    input   wire                        clk_in,
    input   wire                        rst_in,
    input   wire                        rdy_in,

    input   wire                        issue_to_lsb_en_in,

    input   wire [`LSBIdxWidth-1:0]     lsb_pos_in,
    input   wire [`ROBIdxWidth-1:0]     rob_pos_in,
    input   wire [`InstrIdWidth-1:0]    instr_id_in,
    input   wire [`ImmWidth-1:0]        imm_in,

    input   wire [`WordWidth-1:0]       rs1_reg_in,
    input   wire [`ROBIdxWidth-1:0]     rs1_tag_in,
    input   wire                        rs1_rob_stall_in,
    input   wire [`WordWidth-1:0]       rs1_rob_res_in,
    input   wire [`WordWidth-1:0]       rs2_reg_in,
    input   wire [`ROBIdxWidth-1:0]     rs2_tag_in,
    input   wire                        rs2_rob_stall_in,
    input   wire [`WordWidth-1:0]       rs2_rob_res_in,

    input   wire                        ex_to_lsb_en_in,
    input   wire [`ROBIdxWidth-1:0]     ex_to_lsb_rob_pos_in,
    input   wire [`WordWidth-1:0]       ex_to_lsb_res_in,

    input   wire                        lsb_to_lsb_en_in,
    input   wire [`ROBIdxWidth-1:0]     lsb_to_lsb_rob_pos_in,
    input   wire [`WordWidth-1:0]       lsb_to_lsb_res_in,

    output  reg                         lsb_to_alloc_r_en_out,
    output  reg [`WordBytesWidth-1:0]   lsb_r_offset_out,
    output  reg [`AddrWidth-1:0]        lsb_r_a_out,
    input   wire                        alloc_to_lsb_r_gr_in,
    input   wire                        alloc_to_lsb_r_en_in,
    input   wire [`WordWidth-1:0]       lsb_d_in,

    output  reg                         lsb_to_alloc_w_en_out,
    output  reg [`WordBytesWidth-1:0]   lsb_w_offset_out,
    output  reg [`AddrWidth-1:0]        lsb_w_a_out,
    output  reg [`WordWidth-1:0]        lsb_d_out,
    input   wire                        alloc_to_lsb_w_gr_in,
    input   wire                        alloc_to_lsb_w_en_in,

    output  reg                         lsb_to_rs_en_out,
    output  reg                         lsb_to_lsb_en_out,

    output  wire                        lsb_to_issue_empty_out,
    output  wire [`LSBIdxWidth-1:0]     lsb_to_issue_head_out, lsb_to_issue_tail_out,

    input   wire                        commit_to_lsb_r_io_en_in,
    input   wire                        commit_to_lsb_w_en_in,

    output  reg                         lsb_to_rob_r_en_out,
    output  reg                         lsb_to_rob_r_io_en_out,
    output  reg                         lsb_to_rob_w_en_out,
    output  reg [`WordWidth-1:0]        res_out,
    output  reg [`ROBIdxWidth-1:0]      rob_pos_r_out,
    output  reg [`ROBIdxWidth-1:0]      rob_pos_w_out,

    input   wire                        clear_branch_in
);
    
reg                         empty;
reg [`LSBIdxWidth-1:0]      head, tail;
reg [`LSBSize-1:0]          busy_status;
reg [`InstrIdWidth-1:0]     instr_id_que[`LSBSize-1:0];
reg [`ROBIdxWidth-1:0]      rob_id_que[`LSBSize-1:0];
reg [`ImmWidth-1:0]         imm_que[`LSBSize-1:0];
reg [`ROBIdxWidth-1:0]      q1_que[`LSBSize-1:0], q2_que[`LSBSize-1:0];
reg [`WordWidth-1:0]        v1_que[`LSBSize-1:0], v2_que[`LSBSize-1:0];

wire [`AddrWidth-1:0]       pos = v1_que[head] + imm_que[head];

reg                         busy_for_read;
reg                         busy_for_write;
reg [`InstrIdWidth-1:0]     read_type;
reg [`ROBIdxWidth-1:0]      rob_pos_for_read;
reg [`InstrIdWidth-1:0]     write_type;
reg [`AddrWidth-1:0]        pos_for_write;
reg [`WordWidth-1:0]        data_for_write;

integer i;

always @(posedge clk_in) begin
    if (rst_in) begin
        empty <= `TRUE;
        head <= `ZERO;
        tail <= `ZERO;
        busy_status <= `ZERO;
        busy_for_read <= `FALSE;
        lsb_to_rs_en_out <= `FALSE;
        lsb_to_lsb_en_out <= `FALSE;
        lsb_to_rob_r_en_out <= `FALSE;
        lsb_to_alloc_r_en_out <= `FALSE;
        busy_for_write <= `FALSE;
        lsb_to_rob_w_en_out <= `FALSE;
        lsb_to_alloc_w_en_out <= `FALSE;
    end
    else if (rdy_in) begin
        // expand LSBuffer from issue
        if (issue_to_lsb_en_in) begin
            tail <= tail + `LSBIdxWidth'b1;
            empty <= `FALSE;
            busy_status[lsb_pos_in] <= `TRUE;
            instr_id_que[lsb_pos_in] <= instr_id_in;
            rob_id_que[lsb_pos_in] <= rob_pos_in;
            imm_que[lsb_pos_in] <= imm_in;
            if (rs1_tag_in == `ZERO) begin
                q1_que[lsb_pos_in] <= 0;
                v1_que[lsb_pos_in] <= rs1_reg_in;
            end
            else begin
                if (ex_to_lsb_en_in && ex_to_lsb_rob_pos_in == rs1_tag_in) begin
                    q1_que[lsb_pos_in] <= 0;
                    v1_que[lsb_pos_in] <= ex_to_lsb_res_in;
                end
                else if (lsb_to_lsb_en_in && lsb_to_lsb_rob_pos_in == rs1_tag_in) begin
                    q1_que[lsb_pos_in] <= 0;
                    v1_que[lsb_pos_in] <= lsb_to_lsb_res_in;
                end
                else if (rs1_rob_stall_in == `FALSE) begin
                    q1_que[lsb_pos_in] <= 0;
                    v1_que[lsb_pos_in] <= rs1_rob_res_in;
                end
                else q1_que[lsb_pos_in] <= rs1_tag_in;
            end
            if (rs2_tag_in == `ZERO) begin
                q2_que[lsb_pos_in] <= 0;
                v2_que[lsb_pos_in] <= rs2_reg_in;
            end
            else begin
                if (ex_to_lsb_en_in && ex_to_lsb_rob_pos_in == rs2_tag_in) begin
                    q2_que[lsb_pos_in] <= 0;
                    v2_que[lsb_pos_in] <= ex_to_lsb_res_in;
                end
                else if (lsb_to_lsb_en_in && lsb_to_lsb_rob_pos_in == rs2_tag_in) begin
                    q2_que[lsb_pos_in] <= 0;
                    v2_que[lsb_pos_in] <= lsb_to_lsb_res_in;
                end
                else if (rs2_rob_stall_in == `FALSE) begin
                    q2_que[lsb_pos_in] <= 0;
                    v2_que[lsb_pos_in] <= rs2_rob_res_in;
                end
                else q2_que[lsb_pos_in] <= rs2_tag_in;
            end
        end
        for (i = 0; i < `LSBSize; i = i + 1) begin
            if (busy_status[i]) begin
                if (ex_to_lsb_en_in && q1_que[i] == ex_to_lsb_rob_pos_in) begin
                    q1_que[i] <= 0;
                    v1_que[i] <= ex_to_lsb_res_in;
                end
                if (ex_to_lsb_en_in && q2_que[i] == ex_to_lsb_rob_pos_in) begin
                    q2_que[i] <= 0;
                    v2_que[i] <= ex_to_lsb_res_in;
                end
                if (lsb_to_lsb_en_in && q1_que[i] == lsb_to_lsb_rob_pos_in) begin
                    q1_que[i] <= 0;
                    v1_que[i] <= lsb_to_lsb_res_in;
                end
                if (lsb_to_lsb_en_in && q2_que[i] == lsb_to_lsb_rob_pos_in) begin
                    q2_que[i] <= 0;
                    v2_que[i] <= lsb_to_lsb_res_in;
                end
            end
        end
        
        // try to load
        lsb_to_rs_en_out <= `FALSE;
        lsb_to_lsb_en_out <= `FALSE;
        lsb_to_rob_r_en_out <= `FALSE;
        lsb_to_rob_r_io_en_out <= `FALSE;
        if (!empty)
            if (q1_que[head] == `ZERO && q2_que[head] == `ZERO)
                if (instr_id_que[head] <= `LHU) begin
                    if (!busy_for_read && !busy_for_write) begin
                        busy_for_read <= `TRUE;
                        lsb_r_a_out <= pos;
                        case (instr_id_que[head])
                            `LB, `LBU: lsb_r_offset_out <= 0;
                            `LH, `LHU: lsb_r_offset_out <= 1;
                            `LW: lsb_r_offset_out <= 3;
                        endcase
                        read_type <= instr_id_que[head];
                        rob_pos_for_read <= rob_id_que[head];
                        if (pos[17:16] == 2'b11) begin
                            lsb_to_rob_r_io_en_out <= `TRUE;
                            rob_pos_r_out <= rob_id_que[head];
                        end
                        else begin
                            lsb_to_alloc_r_en_out <= `TRUE;
                        end

                        busy_status[head] <= `FALSE;
                        head <= head + `LSBIdxWidth'b1;
                        if (!issue_to_lsb_en_in)
                            empty <= head + `LSBIdxWidth'b1 == tail;
                    end
                end
        if (alloc_to_lsb_r_gr_in && busy_for_read)
            lsb_to_alloc_r_en_out <= `FALSE;
        if (alloc_to_lsb_r_en_in && busy_for_read) begin
            res_out <= lsb_d_in;
            if (read_type == `LB)
                res_out <= {{24{lsb_d_in[7]}}, lsb_d_in[7:0]};
            if (read_type == `LH)
                res_out <= {{16{lsb_d_in[15]}}, lsb_d_in[15:0]};
            rob_pos_r_out <= rob_pos_for_read;
            lsb_to_rob_r_en_out <= `TRUE;
            lsb_to_rs_en_out <= `TRUE;
            lsb_to_lsb_en_out <= `TRUE;
            busy_for_read <= `FALSE;
        end
        if (commit_to_lsb_r_io_en_in) begin
            lsb_to_alloc_r_en_out <= `TRUE;
        end

        // try to write
        lsb_to_rob_w_en_out <= `FALSE;
        if (!empty)
            if (q1_que[head] == `ZERO && q2_que[head] == `ZERO)
                if (instr_id_que[head] > `LHU) begin
                    if (!busy_for_write && !busy_for_read) begin
                        lsb_to_rob_w_en_out <= `TRUE;
                        rob_pos_w_out <= rob_id_que[head];
                        write_type <= instr_id_que[head];
                        pos_for_write <= pos;
                        data_for_write <= v2_que[head];
                    end
                end
        if (commit_to_lsb_w_en_in) begin
            busy_for_write <= `TRUE;
            lsb_to_alloc_w_en_out <= `TRUE;
            lsb_w_a_out <= pos_for_write;
            lsb_d_out <= data_for_write;
            case (write_type)
                `SB: lsb_w_offset_out <= 0;
                `SH: lsb_w_offset_out <= 1;
                `SW: lsb_w_offset_out <= 3;
            endcase

            busy_status[head] <= `FALSE;
            head <= head + `LSBIdxWidth'b1;
            if (!issue_to_lsb_en_in)
                empty <= head + `LSBIdxWidth'b1 == tail;
        end
        if (alloc_to_lsb_w_gr_in && busy_for_write)
            lsb_to_alloc_w_en_out <= `FALSE;
        if (alloc_to_lsb_w_en_in && busy_for_write)
            busy_for_write <= `FALSE;

        if (clear_branch_in) begin
            empty <= `TRUE;
            head <= `ZERO;
            tail <= `ZERO;
            busy_status <= `ZERO;
            busy_for_read <= `FALSE;
            lsb_to_rs_en_out <= `FALSE;
            lsb_to_lsb_en_out <= `FALSE;
            lsb_to_rob_r_en_out <= `FALSE;
            lsb_to_rob_r_io_en_out <= `FALSE;
            lsb_to_rob_w_en_out <= `FALSE;
            lsb_to_alloc_r_en_out <= `FALSE;
        end
    end
end

assign lsb_to_issue_empty_out = empty;
assign lsb_to_issue_head_out = head;
assign lsb_to_issue_tail_out = tail;

endmodule