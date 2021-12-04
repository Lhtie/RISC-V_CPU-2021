// Fetch 4Byte instruction code from ram
`include "config.vh"

module IF (
    input   wire                        clk_in,
    input   wire                        rst_in,
    input   wire                        rdy_in,

    input   wire                        commit_to_if_en_in,
    input   wire [`AddrWidth-1:0]       commit_to_if_pc_in,
    input   wire                        commit_to_if_bpres_in,

    output  reg                         if_to_icache_en_out,
    output  reg [`AddrWidth-1:0]        if_a_out,
    input   wire                        icache_to_if_en_in,
    input   wire [`InstrWidth-1:0]      if_d_in,

    output  reg [`InstrWidth-1:0]       instr_out,
    output  reg [`AddrWidth-1:0]        pc_out,
    output  reg                         bp_out,

    input   wire                        issue_to_if_en_in,
    output  reg                         if_to_issue_en_out,

    input   wire                        commit_to_pc_en_in,
    input   wire [`AddrWidth-1:0]       commit_to_pc_in,

    input   wire                        clear_branch_in
);

reg [`AddrWidth-1:0]    pc;

reg                     empty;
reg [`IFIdxWidth-1:0]   head, tail;
reg [`InstrWidth-1:0]   fetch_que[`IFQueueSize-1:0];
reg [`AddrWidth-1:0]    pc_que[`IFQueueSize-1:0];
reg                     busy_for_read;
reg [1:0]               bp_table[`BpTableSize-1:0];
reg                     bp_que[`IFQueueSize-1:0];

integer i;

always @(posedge clk_in) begin
    if (rst_in) begin
        pc <= `ZERO;
        head <= `ZERO;
        tail <= `ZERO;
        empty <= `TRUE;
        if_to_icache_en_out <= `FALSE;
        if_to_issue_en_out <= `FALSE;
        busy_for_read <= `FALSE;
        for (i = 0; i < `BpTableSize; i = i + 1)
            bp_table[i] <= `ZERO;
    end
    else if (rdy_in) begin
        // prepare instr
        if_to_issue_en_out <= `FALSE;
        if_to_icache_en_out <= `FALSE;
        if ((empty || head != tail) && !busy_for_read) begin
            busy_for_read <= `TRUE;
            if_to_icache_en_out <= `TRUE;
            if_a_out <= pc;
            pc_que[tail] <= pc;
        end
        if (icache_to_if_en_in) begin
            fetch_que[tail] <= if_d_in;
            tail <= tail + `IFIdxWidth'b1;
            empty <= `FALSE;
            busy_for_read <= `FALSE;

            // branch prediction
            if (if_d_in[`OpCodeRange] == 7'b1101111) begin
                bp_que[tail] <= `TRUE;
                pc <= pc + {{11{if_d_in[20]}}, if_d_in[20], if_d_in[19:12], if_d_in[20], if_d_in[30:21], `ZERO};
            end
            else if (if_d_in[`OpCodeRange] == 7'b1100111) begin
                bp_que[tail] <= `FALSE;
                pc <= pc + `InstrBytes;
            end
            else if (if_d_in[`OpCodeRange] == 7'b1100011) begin
                bp_que[tail] <= bp_table[pc_que[tail][`BpPCIdRange]][1];
                if (bp_table[pc_que[tail][`BpPCIdRange]][1])
                    pc <= pc + {{19{if_d_in[31]}}, if_d_in[31], if_d_in[7], if_d_in[30:25], if_d_in[11:8], `ZERO};
                else pc <= pc + `InstrBytes;
            end
            else pc <= pc + `InstrBytes;
        end

        // try to issue
        if (!empty && issue_to_if_en_in) begin
            if_to_issue_en_out <= `TRUE;
            instr_out <= fetch_que[head];
            pc_out <= pc_que[head];
            bp_out <= bp_que[head];
            head <= head + `IFIdxWidth'b1;
            if (!icache_to_if_en_in)
                empty <= head + `IFIdxWidth'b1 == tail;
        end

        // update branch prediction
        if (commit_to_if_en_in) begin
            if (commit_to_if_bpres_in) begin
                if (bp_table[commit_to_if_pc_in[`BpPCIdRange]] < 2'b11)
                      bp_table[commit_to_if_pc_in[`BpPCIdRange]] <= bp_table[commit_to_if_pc_in[`BpPCIdRange]] + 1;
            end
            else begin
               if (bp_table[commit_to_if_pc_in[`BpPCIdRange]] > 2'b00)
                      bp_table[commit_to_if_pc_in[`BpPCIdRange]] <= bp_table[commit_to_if_pc_in[`BpPCIdRange]] - 1;
            end
        end

        // update pc from commit
        if (commit_to_pc_en_in)
            pc <= commit_to_pc_in;
    end
    if (clear_branch_in) begin
        head <= `ZERO;
        tail <= `ZERO;
        empty <= `TRUE;
        if_to_icache_en_out <= `FALSE;
        if_to_issue_en_out <= `FALSE;
        busy_for_read <= `FALSE;
    end
end

endmodule