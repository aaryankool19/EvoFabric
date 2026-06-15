`include "evofabric_defs.svh"

module accel_safety_checker (
    input  logic        valid,
    input  logic [3:0]  opcode,
    input  logic [31:0] input_a,
    input  logic [31:0] input_b,
    input  logic [31:0] input_c,
    input  logic [31:0] input_d,
    input  logic [31:0] accel_output_0,
    input  logic [31:0] accel_output_1,
    input  logic [31:0] accel_output_2,
    input  logic [31:0] accel_output_3,
    output logic        mismatch,
    output logic        fallback_forced,
    output logic [31:0] checked_output_0,
    output logic [31:0] checked_output_1,
    output logic [31:0] checked_output_2,
    output logic [31:0] checked_output_3
);
    logic [31:0] ref_0, ref_1, ref_2, ref_3;
    wire signed [15:0] a00 = input_a[15:0];
    wire signed [15:0] a01 = input_a[31:16];
    wire signed [15:0] a10 = input_b[15:0];
    wire signed [15:0] a11 = input_b[31:16];
    wire signed [15:0] b00 = input_c[15:0];
    wire signed [15:0] b01 = input_c[31:16];
    wire signed [15:0] b10 = input_d[15:0];
    wire signed [15:0] b11 = input_d[31:16];

    function automatic [31:0] popcount32(input logic [31:0] value);
        integer i;
        begin
            popcount32 = 32'd0;
            for (i = 0; i < 32; i = i + 1) popcount32 = popcount32 + value[i];
        end
    endfunction

    function automatic [31:0] crc32_word(input logic [31:0] value);
        integer i;
        logic [31:0] crc;
        begin
            crc = 32'hFFFF_FFFF ^ value;
            for (i = 0; i < 32; i = i + 1) begin
                crc = crc[0] ? ((crc >> 1) ^ 32'hEDB8_8320) : (crc >> 1);
            end
            crc32_word = ~crc;
        end
    endfunction

    always @* begin
        ref_0 = 32'd0;
        ref_1 = 32'd0;
        ref_2 = 32'd0;
        ref_3 = 32'd0;

        case (opcode)
            `EVO_OPCODE_POPCNT: ref_0 = popcount32(input_a);
            `EVO_OPCODE_CRC32:  ref_0 = crc32_word(input_a);
            `EVO_OPCODE_FIR:    ref_0 = $signed(input_a) + ($signed(input_b) <<< 1) + ($signed(input_c) * 32'sd3) + ($signed(input_d) <<< 2);
            `EVO_OPCODE_MATMUL: begin
                ref_0 = a00 * b00 + a01 * b10;
                ref_1 = a00 * b01 + a01 * b11;
                ref_2 = a10 * b00 + a11 * b10;
                ref_3 = a10 * b01 + a11 * b11;
            end
            default: begin
                ref_0 = 32'd0;
            end
        endcase

        mismatch = valid && ((accel_output_0 != ref_0) || (accel_output_1 != ref_1) ||
                             (accel_output_2 != ref_2) || (accel_output_3 != ref_3));
        fallback_forced = mismatch;
        checked_output_0 = mismatch ? ref_0 : accel_output_0;
        checked_output_1 = mismatch ? ref_1 : accel_output_1;
        checked_output_2 = mismatch ? ref_2 : accel_output_2;
        checked_output_3 = mismatch ? ref_3 : accel_output_3;
    end
endmodule
