`ifndef EVOFABRIC_DEFS_SVH
`define EVOFABRIC_DEFS_SVH

`define EVO_OPCODE_NONE    4'd0
`define EVO_OPCODE_POPCNT  4'd1
`define EVO_OPCODE_CRC32   4'd2
`define EVO_OPCODE_FIR     4'd3
`define EVO_OPCODE_MATMUL  4'd4

`define EVO_ACCEL_NONE     4'd0
`define EVO_ACCEL_POPCNT   4'd1
`define EVO_ACCEL_CRC32    4'd2
`define EVO_ACCEL_FIR      4'd3
`define EVO_ACCEL_MATMUL   4'd4
`define EVO_ACCEL_FALLBACK 4'd15

`endif
