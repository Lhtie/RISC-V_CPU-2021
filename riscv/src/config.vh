`ifndef __CONFIGH_HEAD__
`define __CONFIGH_HEAD__

`default_nettype none

`define TRUE            1'b1
`define FALSE           1'b0
`define ZERO            1'b0
`define ONE             1'b1

`define AddrWidth       32
`define InstrWidth      32
`define InstrBytes      4
`define InstrBytesWidth 2
`define WordWidth       32
`define WordBytes       4
`define WordBytesWidth  2
`define MemDataWidth    8

`define ICacheTagWidth  24
`define ICacheEntries   256
`define InstrTagRange   31:8
`define InstrIdxRange   7:0

`define OpCodeRange     6:0
`define BpTableSize     512
`define BpPCIdRange     8:0

`define AllocCycSize    3
`define AllocCycWidth   2
`define AllocMaxIOWidth 2

`define FirstByte       7:0
`define SecondByte      15:8
`define ThirdByte       23:16
`define FourthByte      31:24

`define OpCodeWidth     7
`define Funct3Width     3
`define Funct7Width     7
`define ImmWidth        32
`define InstrScale      37
`define InstrIdWidth    6

`define RegSize         32
`define RegIdxWidth     5
`define IFQueueSize     32
`define IFIdxWidth      5
`define RSSize          32
`define RSIdxWidth      5
`define LSBSize         32
`define LSBIdxWidth     5
`define ROBSize         64
`define ROBIdxWidth     6

`define LB              6'b000000
`define LH              6'b000001
`define LW              6'b000010
`define LBU             6'b000011
`define LHU             6'b000100
`define SB              6'b000101
`define SH              6'b000110
`define SW              6'b000111
`define LUI             6'b001000
`define AUIPC           6'b001001
`define JAL             6'b001010
`define JALR            6'b001011
`define BEQ             6'b001100
`define BNE             6'b001101
`define BLT             6'b001110
`define BGE             6'b001111
`define BLTU            6'b010000
`define BGEU            6'b010001
`define ADDI            6'b010010
`define SLTI            6'b010011
`define SLTIU           6'b010100
`define XORI            6'b010101
`define ORI             6'b010110
`define ANDI            6'b010111
`define SLLI            6'b011000
`define SRLI            6'b011001
`define SRAI            6'b011010
`define ADD             6'b011011
`define SUB             6'b011100
`define SLL             6'b011101
`define SLT             6'b011110
`define SLTU            6'b011111
`define XOR             6'b100000
`define SRL             6'b100001
`define SRA             6'b100010
`define OR              6'b100011
`define AND             6'b100100

`endif