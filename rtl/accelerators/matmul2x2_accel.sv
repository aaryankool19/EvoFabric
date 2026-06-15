`include "evofabric_defs.svh"

module matmul2x2_accel (
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
    assign accelerator_id = `EVO_ACCEL_MATMUL;

    wire signed [15:0] a00 = input_a[15:0];
    wire signed [15:0] a01 = input_a[31:16];
    wire signed [15:0] a10 = input_b[15:0];
    wire signed [15:0] a11 = input_b[31:16];
    wire signed [15:0] b00 = input_c[15:0];
    wire signed [15:0] b01 = input_c[31:16];
    wire signed [15:0] b10 = input_d[15:0];
    wire signed [15:0] b11 = input_d[31:16];
    logic [1:0] step;

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
            step <= 2'd0;
        end else begin
            done <= 1'b0;
            if (start && valid && !busy) begin
                busy <= 1'b1;
                cycle_counter <= 32'd1;
                step <= 2'd0;
                error <= (opcode != `EVO_OPCODE_MATMUL);
            end else if (busy) begin
                cycle_counter <= cycle_counter + 32'd1;
                if (step == 2'd0) begin
                    output_0 <= a00 * b00 + a01 * b10;
                    output_1 <= a00 * b01 + a01 * b11;
                    step <= 2'd1;
                end else begin
                    output_2 <= a10 * b00 + a11 * b10;
                    output_3 <= a10 * b01 + a11 * b11;
                    busy <= 1'b0;
                    done <= 1'b1;
                end
            end
        end
    end
endmodule
