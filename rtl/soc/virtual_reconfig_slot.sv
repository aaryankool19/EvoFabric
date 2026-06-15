`include "evofabric_defs.svh"

module virtual_reconfig_slot (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic        valid,
    input  logic [3:0]  selected_accel,
    input  logic [3:0]  opcode,
    input  logic [31:0] input_a,
    input  logic [31:0] input_b,
    input  logic [31:0] input_c,
    input  logic [31:0] input_d,
    input  logic        fault_inject,
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
    logic pop_done, pop_busy, pop_error;
    logic crc_done, crc_busy, crc_error;
    logic fir_done, fir_busy, fir_error;
    logic mat_done, mat_busy, mat_error;
    logic [31:0] pop_o0, pop_o1, pop_o2, pop_o3, pop_cycles;
    logic [31:0] crc_o0, crc_o1, crc_o2, crc_o3, crc_cycles;
    logic [31:0] fir_o0, fir_o1, fir_o2, fir_o3, fir_cycles;
    logic [31:0] mat_o0, mat_o1, mat_o2, mat_o3, mat_cycles;
    logic [3:0] pop_id, crc_id, fir_id, mat_id;

    popcount_accel u_popcount (
        .clk(clk), .rst_n(rst_n), .start(start && selected_accel == `EVO_ACCEL_POPCNT),
        .valid(valid), .opcode(opcode), .input_a(input_a), .input_b(input_b),
        .input_c(input_c), .input_d(input_d), .done(pop_done), .busy(pop_busy),
        .output_0(pop_o0), .output_1(pop_o1), .output_2(pop_o2), .output_3(pop_o3),
        .error(pop_error), .cycle_counter(pop_cycles), .accelerator_id(pop_id)
    );

    crc32_accel u_crc32 (
        .clk(clk), .rst_n(rst_n), .start(start && selected_accel == `EVO_ACCEL_CRC32),
        .valid(valid), .opcode(opcode), .input_a(input_a), .input_b(input_b),
        .input_c(input_c), .input_d(input_d), .done(crc_done), .busy(crc_busy),
        .output_0(crc_o0), .output_1(crc_o1), .output_2(crc_o2), .output_3(crc_o3),
        .error(crc_error), .cycle_counter(crc_cycles), .accelerator_id(crc_id)
    );

    fir_filter_accel u_fir (
        .clk(clk), .rst_n(rst_n), .start(start && selected_accel == `EVO_ACCEL_FIR),
        .valid(valid), .opcode(opcode), .input_a(input_a), .input_b(input_b),
        .input_c(input_c), .input_d(input_d), .done(fir_done), .busy(fir_busy),
        .output_0(fir_o0), .output_1(fir_o1), .output_2(fir_o2), .output_3(fir_o3),
        .error(fir_error), .cycle_counter(fir_cycles), .accelerator_id(fir_id)
    );

    matmul2x2_accel u_matmul (
        .clk(clk), .rst_n(rst_n), .start(start && selected_accel == `EVO_ACCEL_MATMUL),
        .valid(valid), .opcode(opcode), .input_a(input_a), .input_b(input_b),
        .input_c(input_c), .input_d(input_d), .done(mat_done), .busy(mat_busy),
        .output_0(mat_o0), .output_1(mat_o1), .output_2(mat_o2), .output_3(mat_o3),
        .error(mat_error), .cycle_counter(mat_cycles), .accelerator_id(mat_id)
    );

    always_comb begin
        done = 1'b0;
        busy = 1'b0;
        output_0 = 32'd0;
        output_1 = 32'd0;
        output_2 = 32'd0;
        output_3 = 32'd0;
        error = 1'b1;
        cycle_counter = 32'd0;
        accelerator_id = `EVO_ACCEL_NONE;

        case (selected_accel)
            `EVO_ACCEL_POPCNT: begin
                done = pop_done; busy = pop_busy; error = pop_error;
                output_0 = pop_o0; output_1 = pop_o1; output_2 = pop_o2; output_3 = pop_o3;
                cycle_counter = pop_cycles; accelerator_id = pop_id;
            end
            `EVO_ACCEL_CRC32: begin
                done = crc_done; busy = crc_busy; error = crc_error;
                output_0 = crc_o0; output_1 = crc_o1; output_2 = crc_o2; output_3 = crc_o3;
                cycle_counter = crc_cycles; accelerator_id = crc_id;
            end
            `EVO_ACCEL_FIR: begin
                done = fir_done; busy = fir_busy; error = fir_error;
                output_0 = fir_o0; output_1 = fir_o1; output_2 = fir_o2; output_3 = fir_o3;
                cycle_counter = fir_cycles; accelerator_id = fir_id;
            end
            `EVO_ACCEL_MATMUL: begin
                done = mat_done; busy = mat_busy; error = mat_error;
                output_0 = mat_o0; output_1 = mat_o1; output_2 = mat_o2; output_3 = mat_o3;
                cycle_counter = mat_cycles; accelerator_id = mat_id;
            end
            default: begin
                error = 1'b0;
            end
        endcase

        if (fault_inject) begin
            output_0 = output_0 ^ 32'h0000_0001;
        end
    end
endmodule
