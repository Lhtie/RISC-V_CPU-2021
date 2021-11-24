// allocate memory read/write for IF & LSB

`include "config.vh"

module Alloc (
    input   wire                        clk_in,
    input   wire                        rst_in,
    input   wire                        rdy_in,

    // alloc IF
    input   wire                        if_to_alloc_en_in,
    input   wire [`AddrWidth-1:0]       if_a_in,
    input   wire [`InstrBytesWidth-1:0] if_offset_in,
    output  wire                        alloc_to_if_gr_out,
    output  reg                         alloc_to_if_en_out,
    output  reg [`InstrWidth-1:0]       if_d_out,

    // alloc LSB
    input   wire [`AddrWidth-1:0]       lsb_a_in,

    input   wire                        lsb_to_alloc_r_en_in,
    input   wire [`WordBytesWidth-1:0]  lsb_r_offset_in,
    output  wire                        alloc_to_lsb_r_gr_out,
    output  reg                         alloc_to_lsb_r_en_out,
    output  reg [`WordWidth-1:0]        lsb_d_out,

    input   wire                        lsb_to_alloc_w_en_in,
    input   wire [`WordBytesWidth-1:0]  lsb_w_offset_in,
    input   wire [`WordWidth-1:0]       lsb_d_in,
    output  wire                        alloc_to_lsb_w_gr_out,
    output  reg                         alloc_to_lsb_w_en_out,

    input   wire                        clear_branch_in,
    
    // mem interface
    input   wire [`MemDataWidth-1:0]    mem_d_in,
    output  reg [`AddrWidth-1:0]        mem_a_out,
    output  reg [`MemDataWidth-1:0]     mem_d_out,
    output  reg                         mem_wr_out
);

reg [`AllocCycWidth-1:0]    alloc_cyc;
reg                         alloc_free;
reg                         grant_if, grant_lsb_r, grant_lsb_w;
reg [`AllocMaxIOWidth-1:0]  cur_send_pos;

assign alloc_to_if_gr_out = grant_if;
assign alloc_to_lsb_r_gr_out = grant_lsb_r;
assign alloc_to_lsb_w_gr_out = grant_lsb_w;

`define grantIf\
begin\
    grant_if <= `TRUE;\
    mem_a_out <= if_a_in;\
    cur_send_pos <= `ZERO;\
    if (if_offset_in != `ZERO)\
        alloc_free <= `FALSE;\
    alloc_cyc <= (alloc_cyc + 1) % `AllocCycSize;\
end

`define grantLsbR\
begin\
    grant_lsb_r <= `TRUE;\
    mem_a_out <= lsb_a_in;\
    cur_send_pos <= `ZERO;\
    if (lsb_r_offset_in != `ZERO)\
        alloc_free <= `FALSE;\
    alloc_cyc <= (alloc_cyc + 1) % `AllocCycSize;\
end

`define grantLsbW\
begin\
    grant_lsb_w <= `TRUE;\
    cur_send_pos <= `ZERO;\
    alloc_free <= `FALSE;\
    alloc_cyc <= (alloc_cyc + 1) % `AllocCycSize;\
end

always @(posedge clk_in) begin
    if (rst_in) begin
        alloc_cyc <= `ZERO;
        alloc_free <= `TRUE;
        grant_if <= `FALSE;
        grant_lsb_r <= `FALSE;
        grant_lsb_w <= `FALSE;
        mem_a_out <= `ZERO;
        mem_d_out <= `ZERO;
        mem_wr_out <= `FALSE;
    end
    else if (rdy_in && alloc_free && !clear_branch_in) begin
        grant_if <= `FALSE;
        grant_lsb_r <= `FALSE;
        grant_lsb_w <= `FALSE;
        mem_a_out <= `ZERO;
        mem_d_out <= `ZERO;
        mem_wr_out <= `FALSE;
        case (alloc_cyc)
            2'b00: begin
                if (if_to_alloc_en_in) `grantIf
                else if (lsb_to_alloc_r_en_in) `grantLsbR
                else if (lsb_to_alloc_w_en_in) `grantLsbW
            end
            2'b01: begin
                if (lsb_to_alloc_r_en_in) `grantLsbR
                else if (lsb_to_alloc_w_en_in) `grantLsbW
                else if (if_to_alloc_en_in) `grantIf
            end
            2'b10: begin
                if (lsb_to_alloc_w_en_in) `grantLsbW
                else if (if_to_alloc_en_in) `grantIf
                else if (lsb_to_alloc_r_en_in) `grantLsbR
            end
        endcase
    end
end

// send request to mem

always @(posedge clk_in) begin
    if (rst_in) begin
        cur_send_pos <= `ZERO;
        alloc_to_lsb_w_en_out <= `FALSE;
    end
    else if (rdy_in && !clear_branch_in) begin
        alloc_to_lsb_w_en_out <= `FALSE;
        if (!alloc_free) begin
            mem_a_out <= `ZERO;
            mem_d_out <= `ZERO;
            mem_wr_out <= `FALSE;
            if (grant_if) begin
                if (cur_send_pos < if_offset_in)
                    mem_a_out <= if_a_in + cur_send_pos + 1;
                cur_send_pos <= cur_send_pos + 1;
                if (cur_send_pos + 1 == if_offset_in)
                    alloc_free <= `TRUE;
            end
            if (grant_lsb_r) begin
                if (cur_send_pos < lsb_r_offset_in)
                    mem_a_out <= lsb_a_in + cur_send_pos + 1;
                cur_send_pos <= cur_send_pos + 1;
                if (cur_send_pos + 1 == lsb_r_offset_in)
                    alloc_free <= `TRUE;
            end
            if (grant_lsb_w) begin
                if (cur_send_pos <= lsb_w_offset_in) begin
                    mem_wr_out <= `TRUE;
                    mem_a_out <= lsb_a_in + cur_send_pos;
                    case (cur_send_pos)
                        2'b00: mem_d_out <= lsb_d_in[`FirstByte];
                        2'b01: mem_d_out <= lsb_d_in[`SecondByte];
                        2'b10: mem_d_out <= lsb_d_in[`ThirdByte];
                        2'b11: mem_d_out <= lsb_d_in[`FourthByte];
                    endcase
                end
                cur_send_pos <= cur_send_pos + 1;
                if (cur_send_pos == lsb_w_offset_in) begin
                    alloc_free <= `TRUE;
                    alloc_to_lsb_w_en_out <= `TRUE;
                end
            end
        end
    end
end

// receive result from mem
reg                         receive_if, receive_lsb;
reg [`AllocMaxIOWidth-1:0]  cur_receive_pos;

always @(posedge clk_in) begin
    if (rst_in) begin
        receive_if <= `FALSE;
        receive_lsb <= `FALSE;
        cur_receive_pos <= `ZERO;
        alloc_to_if_en_out <= `FALSE;
        alloc_to_lsb_r_en_out <= `FALSE;
    end
    else if (rdy_in && !clear_branch_in) begin
        alloc_to_if_en_out <= `FALSE;
        alloc_to_lsb_r_en_out <= `FALSE;
        receive_if <= grant_if;
        receive_lsb <= grant_lsb_r;
        if (receive_if) begin
            case (cur_receive_pos)
                2'b00: begin
                    if_d_out <= {`WordWidth{`ZERO}};
                    if_d_out[`FirstByte] <= mem_d_in;
                end
                2'b01: if_d_out[`SecondByte] <= mem_d_in;
                2'b10: if_d_out[`ThirdByte] <= mem_d_in;
                2'b11: if_d_out[`FourthByte] <= mem_d_in;
            endcase
            cur_receive_pos <= cur_receive_pos + 1;
            if (cur_receive_pos == if_offset_in) begin
                cur_receive_pos <= 0;
                alloc_to_if_en_out <= `TRUE;
            end
        end
        if (receive_lsb) begin
            case (cur_receive_pos)
                2'b00: begin
                    lsb_d_out <= {`WordWidth{`ZERO}};
                    lsb_d_out[`FirstByte] <= mem_d_in;
                end
                2'b01: lsb_d_out[`SecondByte] <= mem_d_in;
                2'b10: lsb_d_out[`ThirdByte] <= mem_d_in;
                2'b11: lsb_d_out[`FourthByte] <= mem_d_in;
            endcase
            cur_receive_pos <= cur_receive_pos + 1;
            if (cur_receive_pos == lsb_r_offset_in) begin
                cur_receive_pos <= 0;
                alloc_to_lsb_r_en_out <= `TRUE;
            end
        end
    end
end

always @(posedge clk_in) begin
    if (!rst_in && rdy_in && clear_branch_in) begin
        alloc_free <= `TRUE;
        grant_if <= `FALSE;
        grant_lsb_r <= `FALSE;
        grant_lsb_w <= `FALSE;
        mem_a_out <= `ZERO;
        mem_d_out <= `ZERO;
        mem_wr_out <= `FALSE;
        alloc_to_lsb_w_en_out <= `FALSE;
        receive_if <= `FALSE;
        receive_lsb <= `FALSE;
        cur_receive_pos <= `ZERO;
        alloc_to_if_en_out <= `FALSE;
        alloc_to_lsb_r_en_out <= `FALSE;
    end
end
    
endmodule