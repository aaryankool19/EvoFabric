`include "evofabric_defs.svh"

module evofabric_top (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        bus_valid,
    input  logic        bus_write,
    input  logic [31:0] bus_addr,
    input  logic [31:0] bus_wdata,
    input  logic        fault_inject,
    input  logic [4:1]  accel_available,
    output logic [31:0] bus_rdata,
    output logic        bus_ready,
    output logic        irq_done
);
    localparam [31:0] REG_CONTROL = 32'h0000_0000;
    localparam [31:0] REG_INPUT_A = 32'h0000_0004;
    localparam [31:0] REG_INPUT_B = 32'h0000_0008;
    localparam [31:0] REG_INPUT_C = 32'h0000_000C;
    localparam [31:0] REG_INPUT_D = 32'h0000_0010;
    localparam [31:0] REG_OUTPUT0 = 32'h0000_0014;
    localparam [31:0] REG_OUTPUT1 = 32'h0000_0018;
    localparam [31:0] REG_OUTPUT2 = 32'h0000_001C;
    localparam [31:0] REG_OUTPUT3 = 32'h0000_0020;
    localparam [31:0] REG_STATUS  = 32'h0000_0024;

    logic accel_write, accel_read, perf_read;
    logic [31:0] local_addr, local_wdata, accel_rdata, perf_rdata;
    logic [3:0] opcode_reg;
    logic [31:0] input_a_reg, input_b_reg, input_c_reg, input_d_reg;
    logic [31:0] result_0, result_1, result_2, result_3;
    logic start_request, clear_perf;
    logic slot_start, op_active, ctrl_complete, use_fallback;
    logic [3:0] selected_accel;
    logic [4:1] disabled_accels;
    logic slot_done, slot_busy, slot_error;
    logic [31:0] slot_o0, slot_o1, slot_o2, slot_o3, slot_cycles;
    logic [3:0] slot_id;
    logic mismatch, fallback_forced;
    logic [4:1] disabled_accels_d;
    logic       perf_failed_event;
    logic [31:0] checked_o0, checked_o1, checked_o2, checked_o3;
    logic [31:0] total_cycles, calls, failures, last_latency, best_latency;
    logic [3:0] last_selected;

    mmio_bus u_bus (
        .bus_valid(bus_valid), .bus_write(bus_write), .bus_addr(bus_addr), .bus_wdata(bus_wdata),
        .accel_rdata(accel_rdata), .perf_rdata(perf_rdata), .accel_write(accel_write),
        .accel_read(accel_read), .perf_read(perf_read), .local_addr(local_addr),
        .local_wdata(local_wdata), .bus_rdata(bus_rdata), .bus_ready(bus_ready)
    );

    adaptive_controller u_controller (
        .clk(clk), .rst_n(rst_n), .request_valid(start_request), .opcode(opcode_reg),
        .availability(accel_available), .accel_done(slot_done), .accel_error(slot_error),
        .checker_mismatch(mismatch), .accel_start(slot_start), .op_active(op_active),
        .complete(ctrl_complete), .use_fallback(use_fallback), .selected_accel(selected_accel),
        .disabled_accels(disabled_accels)
    );

    virtual_reconfig_slot u_slot (
        .clk(clk), .rst_n(rst_n), .start(slot_start), .valid(op_active), .selected_accel(selected_accel),
        .opcode(opcode_reg), .input_a(input_a_reg), .input_b(input_b_reg), .input_c(input_c_reg),
        .input_d(input_d_reg), .fault_inject(fault_inject), .done(slot_done), .busy(slot_busy),
        .output_0(slot_o0), .output_1(slot_o1), .output_2(slot_o2), .output_3(slot_o3),
        .error(slot_error), .cycle_counter(slot_cycles), .accelerator_id(slot_id)
    );

    accel_safety_checker u_checker (
        .valid(slot_done || use_fallback), .opcode(opcode_reg), .input_a(input_a_reg),
        .input_b(input_b_reg), .input_c(input_c_reg), .input_d(input_d_reg),
        .accel_output_0(slot_o0), .accel_output_1(slot_o1), .accel_output_2(slot_o2),
        .accel_output_3(slot_o3), .mismatch(mismatch), .fallback_forced(fallback_forced),
        .checked_output_0(checked_o0), .checked_output_1(checked_o1),
        .checked_output_2(checked_o2), .checked_output_3(checked_o3)
    );

    performance_counters u_perf (
        .clk(clk), .rst_n(rst_n), .clear(clear_perf), .op_start(start_request),
        .op_complete(ctrl_complete), .op_failed(perf_failed_event), .selected_accel(selected_accel),
        .latency_value(use_fallback ? 32'd1 : slot_cycles), .total_cycles(total_cycles),
        .calls(calls), .failures(failures), .last_selected_accel(last_selected),
        .last_latency(last_latency), .best_latency(best_latency)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            opcode_reg <= `EVO_OPCODE_NONE;
            input_a_reg <= 32'd0;
            input_b_reg <= 32'd0;
            input_c_reg <= 32'd0;
            input_d_reg <= 32'd0;
            result_0 <= 32'd0;
            result_1 <= 32'd0;
            result_2 <= 32'd0;
            result_3 <= 32'd0;
            irq_done <= 1'b0;
            start_request <= 1'b0;
            clear_perf <= 1'b0;
            disabled_accels_d <= 4'b0000;
            perf_failed_event <= 1'b0;
        end else begin
            start_request <= 1'b0;
            clear_perf <= 1'b0;
            irq_done <= 1'b0;
            perf_failed_event <= |(disabled_accels & ~disabled_accels_d);
            disabled_accels_d <= disabled_accels;

            if (accel_write) begin
                case (local_addr)
                    REG_CONTROL: begin
                        opcode_reg <= local_wdata[7:4];
                        start_request <= local_wdata[0];
                        clear_perf <= local_wdata[8];
                    end
                    REG_INPUT_A: input_a_reg <= local_wdata;
                    REG_INPUT_B: input_b_reg <= local_wdata;
                    REG_INPUT_C: input_c_reg <= local_wdata;
                    REG_INPUT_D: input_d_reg <= local_wdata;
                    default: begin end
                endcase
            end

            if (ctrl_complete) begin
                result_0 <= checked_o0;
                result_1 <= checked_o1;
                result_2 <= checked_o2;
                result_3 <= checked_o3;
                irq_done <= 1'b1;
            end
        end
    end

    always_comb begin
        accel_rdata = 32'd0;
        case (local_addr)
            REG_CONTROL: accel_rdata = {24'd0, opcode_reg, 3'd0, start_request};
            REG_INPUT_A: accel_rdata = input_a_reg;
            REG_INPUT_B: accel_rdata = input_b_reg;
            REG_INPUT_C: accel_rdata = input_c_reg;
            REG_INPUT_D: accel_rdata = input_d_reg;
            REG_OUTPUT0: accel_rdata = result_0;
            REG_OUTPUT1: accel_rdata = result_1;
            REG_OUTPUT2: accel_rdata = result_2;
            REG_OUTPUT3: accel_rdata = result_3;
            REG_STATUS:  accel_rdata = {12'd0, disabled_accels, selected_accel, slot_busy, use_fallback, fallback_forced, irq_done, 6'd0, op_active, slot_error};
            default:     accel_rdata = 32'd0;
        endcase

        perf_rdata = 32'd0;
        case (local_addr)
            32'h0000_0100: perf_rdata = total_cycles;
            32'h0000_0104: perf_rdata = calls;
            32'h0000_0108: perf_rdata = failures;
            32'h0000_010C: perf_rdata = {28'd0, last_selected};
            32'h0000_0110: perf_rdata = last_latency;
            32'h0000_0114: perf_rdata = best_latency;
            default:       perf_rdata = 32'd0;
        endcase
    end
endmodule
