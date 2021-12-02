// pc pointer either plus 4 or jump

`include "config.vh"

module PC (
    input   wire                    clk_in,
    input   wire                    rst_in,
    input   wire                    rdy_in,

    input   wire                    if_to_pc_en_in,
    input   wire                    commit_to_pc_en_in,
    input   wire [`AddrWidth-1:0]   commit_to_pc_in,

    output  wire [`AddrWidth-1:0]   pc_out
);

reg [`AddrWidth-1:0]    pc;

always @(posedge clk_in) begin
    if (rst_in) begin
        pc <= `ZERO;
    end
    else if (rdy_in) begin
        if (commit_to_pc_en_in)
            pc <= commit_to_pc_in;
        else if (if_to_pc_en_in)
            pc <= pc + `InstrBytes;
    end
end

assign pc_out = pc;
    
endmodule