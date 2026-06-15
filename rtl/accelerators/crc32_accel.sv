`include "evofabric_defs.svh"

module crc32_accel (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic        valid,
    input  logic [3:0]  opcode,
    input  logic [31:0] input_a,
    input  logic [31:0] input_b,
    input  logic [31:0] input_c,
    input  logic [31:0] input_d,
    output logic        done,
    output logic        busy,
    output logic [31:0] output_0,
    output logic [31:0] output_1,
    output logic [31:0] output_2,
    output logic [31:0] output_3,
    output logic        error,
    output logic [31:0] cycle_counter,
    output logic [3:0]  accelerator_id
);
    assign accelerator_id = `EVO_ACCEL_CRC32;

    function automatic [31:0] crc32_word(input logic [31:0] value);
        integer i;
        logic [31:0] crc;
        begin
            crc = 32'hFFFF_FFFF ^ value;
            for (i = 0; i < 32; i = i + 1) begin
                if (crc[0]) begin
                    crc = (crc >> 1) ^ 32'hEDB8_8320;
                end else begin
                    crc = crc >> 1;
                end
            end
            crc32_word = ~crc;
        end
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done <= 1'b0;
            busy <= 1'b0;
            output_0 <= 32'd0;
            output_1 <= 32'd0;
            output_2 <= 32'd0;
            output_3 <= 32'd0;
            error <= 1'b0;
            cycle_counter <= 32'd0;
        end else begin
            done <= 1'b0;
            if (start && valid && !busy) begin
                busy <= 1'b1;
                cycle_counter <= 32'd1;
                output_0 <= crc32_word(input_a);
                output_1 <= 32'd0;
                output_2 <= 32'd0;
                output_3 <= 32'd0;
                error <= (opcode != `EVO_OPCODE_CRC32);
            end else if (busy) begin
                busy <= 1'b0;
                done <= 1'b1;
            end
        end
    end
endmodule
