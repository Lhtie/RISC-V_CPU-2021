// Fetch 4Byte instruction code from ram
`include "config.vh"

module IF (
    input   wire                        clk_in,
    input   wire                        rst_in,
    input   wire                        rdy_in,

    input   wire [`AddrWidth-1:0]       pc_in,
    output  reg                         if_to_pc_en_out,

    output  reg                         if_to_icache_en_out,
    output  reg [`AddrWidth-1:0]        if_a_out,
    input   wire                        icache_to_if_en_in,
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


always @(posedge clk_in) begin
    if (rst_in) begin
        head <= `ZERO;
        tail <= `ZERO;
        empty <= `TRUE;
        if_to_pc_en_out <= `FALSE;
        if_to_icache_en_out <= `FALSE;
        if_to_issue_en_out <= `FALSE;
        busy_for_read <= `FALSE;
    end
    else if (rdy_in && !clear_branch_in) begin
        if_to_pc_en_out <= `FALSE;
        if_to_issue_en_out <= `FALSE;
        if_to_icache_en_out <= `FALSE;
        if ((empty || head != tail) && !busy_for_read) begin
            busy_for_read <= `TRUE;
            if_to_pc_en_out <= `TRUE;
            if_to_icache_en_out <= `TRUE;
            if_a_out <= pc_in;
            pc_que[tail] <= pc_in;
        end
        if (icache_to_if_en_in) begin
            fetch_que[tail] <= if_d_in;
            tail <= tail + `IFIdxWidth'b1;
            empty <= `FALSE;
            busy_for_read <= `FALSE;
        end

        // try to issue
        if (issue_to_if_en_in) begin
            head <= head + `IFIdxWidth'b1;
            if (!icache_to_if_en_in)
                empty <= head + `IFIdxWidth'b1 == tail;
            if (head + `IFIdxWidth'b1 != tail) begin
                if_to_issue_en_out <= `TRUE;
                instr_out <= fetch_que[head + `IFIdxWidth'b1];
                pc_out <= pc_que[head + `IFIdxWidth'b1];
            end
        end
        else begin
            if (!empty) begin
                if_to_issue_en_out <= `TRUE;
                instr_out <= fetch_que[head];
                pc_out <= pc_que[head];
            end
        end
    end
end

always @(posedge clk_in) begin
    if (!rst_in && rdy_in && clear_branch_in) begin
        head <= `ZERO;
        tail <= `ZERO;
        empty <= `TRUE;
        if_to_pc_en_out <= `FALSE;
        if_to_icache_en_out <= `FALSE;
        if_to_issue_en_out <= `FALSE;
        busy_for_read <= `FALSE;
    end
end

endmodule