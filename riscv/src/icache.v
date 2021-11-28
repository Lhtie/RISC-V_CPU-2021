// instr cache between IF and alloc

`include "config.vh"

module ICache (
    input wire                          clk_in,
    input wire                          rst_in,
    input wire                          rdy_in,

    input wire                          if_to_icache_en_in,
    input wire [`AddrWidth-1:0]         if_a_in,

    output  reg                         icache_to_if_en_out,
    output  reg [`InstrWidth-1:0]       if_d_out,

    output  reg                         if_to_alloc_en_out,
    output  reg [`AddrWidth-1:0]        if_a_out,
    output  wire [`InstrBytesWidth-1:0] if_offset_out,
    input   wire                        alloc_to_if_gr_in,
    input   wire                        alloc_to_if_en_in,
    input   wire [`InstrWidth-1:0]      if_d_in,

    input   wire                        clear_branch_in
);

reg [`ICacheEntries-1:0]    ready;
reg [`ICacheTagWidth-1:0]   tags[`ICacheEntries-1:0];
reg [`InstrWidth-1:0]       instrs[`ICacheEntries-1:0];
reg                         busy_for_read;

always @(posedge clk_in) begin
    if (rst_in) begin
        ready <= `ZERO;  
        icache_to_if_en_out <= `FALSE;
        if_to_alloc_en_out <= `FALSE;
    end
    else if (rdy_in && !clear_branch_in) begin
        icache_to_if_en_out <= `FALSE;
        if (if_to_icache_en_in) begin
            if (ready[if_a_in[`InstrIdxRange]] && tags[if_a_in[`InstrIdxRange]] == if_a_in[`InstrTagRange]) begin
                icache_to_if_en_out <= `TRUE;
                if_d_out <= instrs[if_a_in[`InstrIdxRange]];
            end
            else begin
                if_to_alloc_en_out <= `TRUE;
                if_a_out <= if_a_in;
            end
        end
        if (alloc_to_if_gr_in)
            if_to_alloc_en_out <= `FALSE;
        if (alloc_to_if_en_in) begin
            icache_to_if_en_out <= `TRUE;
            if_d_out <= if_d_in;
            
            ready[if_a_in[`InstrIdxRange]] <= `TRUE;
            tags[if_a_in[`InstrIdxRange]] <= if_a_in[`InstrTagRange];
            instrs[if_a_in[`InstrIdxRange]] <= if_d_in;
        end
    end
end

always @(posedge clk_in) begin
    if (!rst_in && rdy_in && clear_branch_in) begin
        icache_to_if_en_out <= `FALSE;
        if_to_alloc_en_out <= `FALSE;
    end
end

assign if_offset_out = `InstrBytes - 1;
    
endmodule