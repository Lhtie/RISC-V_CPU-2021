// pc pointer either plus 4 or jump

`include "config.vh"

module PC (
    input   wire                    clk_in,
    input   wire                    rst_in,
    input   wire                    rdy_in,

    input   wire                    if_to_pc_en_in,
    input   wire                    commit_to_pc_en_in,
    input   wire [`AddrWidth-1:0]   commit_to_pc_in,

    output  reg [`AddrWidth-1:0]    pc_out
);

reg [`AddrWidth-1:0]    pc;

always @(posedge clk_in) begin
    if (rst_in) begin
        pc <= `ZERO;
        pc_out <= `ZERO;
    end
    else if (rdy_in) begin
        if (commit_to_pc_en_in) begin
            pc <= commit_to_pc_in;
            pc_out <= commit_to_pc_in;
        end
        else if (if_to_pc_en_in) begin
            pc <= pc + `InstrBytes;
            pc_out <= pc + `InstrBytes;
        end
        else pc_out <= pc;
    end
end
    
endmodule