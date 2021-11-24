// pc pointer either plus 4 or jump

`include "config.vh"

module PC (
    input   wire                    clk_in,
    input   wire                    rst_in,
    input   wire                    rdy_in,

    input   wire                    if_to_pc_en_in,
    input   wire                    commit_to_pc_en_in,
    input   wire [`AddrWidth-1:0]   commit_to_pc_in,

    output  reg                     pc_to_if_en_out,
    output  wire [`AddrWidth-1:0]   pc_out
);

reg [`AddrWidth-1:0]    pc;

always @(posedge clk_in) begin
    if (rst_in) begin
        pc <= `ZERO;
        pc_to_if_en_out <= `TRUE;
    end
    else if (rdy_in) begin
        pc_to_if_en_out <= `TRUE;
        if (commit_to_pc_en_in)
            pc <= commit_to_pc_in;
        else if (if_to_pc_en_in)
            pc <= pc + `InstrBytes;
        else pc_to_if_en_out <= `FALSE;
    end
end

assign pc_out = pc;
    
endmodule