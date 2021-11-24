// Fetch 4Byte instruction code from ram
`include "config.vh"

module IF (
    input   wire                        clk_in,
    input   wire                        rst_in,
    input   wire                        rdy_in,

    input   wire                        pc_to_if_en_in,
    input   wire [`AddrWidth-1:0]       pc_in,
    output  reg                         if_to_pc_en_out,

    output  reg                         if_to_alloc_en_out,
    output  wire [`AddrWidth-1:0]       if_a_out,
    output  wire [`InstrBytesWidth-1:0] if_offset_out,
    input   wire                        alloc_to_if_gr_in,
    input   wire                        alloc_to_if_en_in,
    input   wire [`InstrWidth-1:0]      if_d_in,

    output  reg [`InstrWidth-1:0]       instr_out,
    output  reg [`AddrWidth-1:0]        pc_out,

    input   wire                        issue_to_if_en_in,
    output  reg                         if_to_issue_en_out,

    input   wire                        clear_branch_in
);

reg                     empty;
reg [`IFIdxWidth-1:0]   head, tail;
reg [`InstrWidth-1:0]   fetch_que[`IFQueueSize-1:0];
reg [`AddrWidth-1:0]    pc_que[`IFQueueSize-1:0];
reg                     busy_for_read;
reg                     dirty_read;


always @(posedge clk_in) begin
    if (rst_in) begin
        head <= `ZERO;
        tail <= `ZERO;
        empty <= `TRUE;
        if_to_pc_en_out <= `FALSE;
        if_to_alloc_en_out <= `FALSE;
        busy_for_read <= `FALSE;
    end
    else if (rdy_in && !clear_branch_in) begin
        if_to_pc_en_out <= `FALSE;
        if (pc_to_if_en_in && (empty || head != tail) && !busy_for_read) begin
            busy_for_read <= `TRUE;
            if_to_alloc_en_out <= `TRUE;
            pc_que[tail] <= pc_in;
        end
        if (alloc_to_if_gr_in && busy_for_read)
            if_to_alloc_en_out <= `FALSE;
        if (alloc_to_if_en_in) begin
            if (dirty_read) begin
                dirty_read <= `FALSE;
            end
            else begin
                if_to_pc_en_out <= `TRUE;
                fetch_que[tail] <= if_d_in;
                tail <= tail + `IFIdxWidth'b1;
                empty <= `FALSE;
                busy_for_read <= `FALSE;
            end
        end
    end
end

always @(posedge clk_in) begin
    if (rst_in) begin
        if_to_issue_en_out <= `FALSE;
    end
    else if (rdy_in && !clear_branch_in) begin
        if_to_issue_en_out <= `FALSE;
        if (issue_to_if_en_in) begin
            head <= head + `IFIdxWidth'b1;
            if (alloc_to_if_en_in)
                empty <= head == tail;
            else empty <= head + `IFIdxWidth'b1 == tail;
            if_to_issue_en_out <= head + `IFIdxWidth'b1 != tail;
            instr_out <= fetch_que[head + `IFIdxWidth'b1];
            pc_out <= pc_que[head + `IFIdxWidth'b1];
        end
        else  begin
            if_to_issue_en_out <= !empty;
            instr_out <= fetch_que[head];
            pc_out <= pc_que[head];
        end
    end
end

always @(posedge clk_in) begin
    if (rst_in) begin
        dirty_read <= `FALSE;
    end
    else if (rdy_in && clear_branch_in) begin
        head <= `ZERO;
        tail <= `ZERO;
        empty <= `TRUE;
        if_to_pc_en_out <= `FALSE;
        if_to_alloc_en_out <= `FALSE;
        if_to_issue_en_out <= `FALSE;
        if (busy_for_read && !alloc_to_if_en_in)
            dirty_read <= `TRUE;
        busy_for_read <= `FALSE;
    end
end

assign if_a_out = pc_in;
assign if_offset_out = `InstrBytes - 1;

endmodule