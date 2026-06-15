`include "evofabric_defs.svh"

module tb_top_workload_switching;
    logic clk = 1'b0, rst_n = 1'b0, bus_valid, bus_write, fault_inject, bus_ready, irq_done;
    logic [31:0] bus_addr, bus_wdata, bus_rdata, read_data;
    always #5 clk = ~clk;

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
    localparam [31:0] REG_CALLS   = 32'h0000_0104;
    localparam [31:0] REG_FAILURES = 32'h0000_0108;
    localparam [31:0] REG_LAST_LATENCY = 32'h0000_0110;
    localparam [31:0] REG_BEST_LATENCY = 32'h0000_0114;

    task automatic fail(input string message);
        begin
            $display("FAIL tb_top_workload_switching: %s", message);
            $fatal(1);
        end
    endtask

    evofabric_top dut (
        .clk(clk), .rst_n(rst_n), .bus_valid(bus_valid), .bus_write(bus_write),
        .bus_addr(bus_addr), .bus_wdata(bus_wdata), .fault_inject(fault_inject),
        .accel_available(4'b1111), .bus_rdata(bus_rdata), .bus_ready(bus_ready), .irq_done(irq_done)
    );

    task automatic write_reg(input [31:0] addr, input [31:0] data);
        begin
            @(posedge clk); bus_valid = 1'b1; bus_write = 1'b1; bus_addr = addr; bus_wdata = data;
            @(posedge clk); bus_valid = 1'b0; bus_write = 1'b0;
        end
    endtask

    task automatic read_reg(input [31:0] addr, output [31:0] data);
        begin
            @(posedge clk); bus_valid = 1'b1; bus_write = 1'b0; bus_addr = addr;
            @(posedge clk); data = bus_rdata; bus_valid = 1'b0;
        end
    endtask

    task automatic start_operation(input [3:0] opcode, input [3:0] expected_id);
        begin
            write_reg(REG_CONTROL, {24'd0, opcode, 3'd0, 1'b1});
            @(negedge clk);
            if (!dut.start_request) fail("top-level start request did not pulse");

            wait (dut.slot_start);
            @(negedge clk);
            if (!dut.op_active) fail("controller valid/op_active did not assert");
            if (dut.selected_accel !== expected_id) fail("selected_accelerator_id did not change as expected");

            wait (dut.slot_busy);
            @(negedge clk);
            if (!dut.slot_busy) fail("busy did not remain visible during operation");

            wait (irq_done);
            @(negedge clk);
            if (dut.slot_error) fail("slot error asserted during clean workload");
        end
    endtask

    task automatic check_calls(input [31:0] expected_calls);
        begin
            read_reg(REG_CALLS, read_data);
            if (read_data !== expected_calls) fail("performance calls counter did not increment");
            read_reg(REG_FAILURES, read_data);
            if (read_data !== 32'd0) fail("failure counter changed during clean workload");
            read_reg(REG_LAST_LATENCY, read_data);
            if (read_data === 32'd0) fail("last latency did not update");
            read_reg(REG_BEST_LATENCY, read_data);
            if (read_data === 32'hFFFF_FFFF) fail("best latency did not update");
        end
    endtask

    initial begin
        $dumpfile("waves/tb_top_workload_switching.vcd");
        $dumpvars(0, tb_top_workload_switching);
        bus_valid = 1'b0; bus_write = 1'b0; bus_addr = 32'd0; bus_wdata = 32'd0; fault_inject = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        @(negedge clk);
        if (irq_done || dut.op_active || dut.slot_busy) fail("reset state was not clean");

        write_reg(REG_CONTROL, 32'h0000_0100);
        repeat (2) @(posedge clk);

        write_reg(REG_INPUT_A, 32'hFFFF_0000);
        start_operation(`EVO_OPCODE_POPCNT, `EVO_ACCEL_POPCNT);
        read_reg(REG_OUTPUT0, read_data);
        if (read_data !== 32'd16) fail("top popcount workload failed");
        read_reg(REG_STATUS, read_data);
        if (read_data[15:12] !== `EVO_ACCEL_POPCNT || read_data[10] || read_data[9]) fail("bad status after popcount workload");
        check_calls(32'd1);

        write_reg(REG_INPUT_A, 32'h1234_5678);
        start_operation(`EVO_OPCODE_CRC32, `EVO_ACCEL_CRC32);
        read_reg(REG_OUTPUT0, read_data);
        if (read_data !== 32'hAF6D_87D2) fail("top CRC32 workload failed");
        read_reg(REG_STATUS, read_data);
        if (read_data[15:12] !== `EVO_ACCEL_CRC32) fail("bad selected accelerator after CRC32 workload");
        check_calls(32'd2);

        write_reg(REG_INPUT_A, 32'd1);
        write_reg(REG_INPUT_B, 32'd2);
        write_reg(REG_INPUT_C, 32'd3);
        write_reg(REG_INPUT_D, 32'd4);
        start_operation(`EVO_OPCODE_FIR, `EVO_ACCEL_FIR);
        read_reg(REG_OUTPUT0, read_data);
        if (read_data !== 32'd30) fail("top FIR workload failed");
        read_reg(REG_STATUS, read_data);
        if (read_data[15:12] !== `EVO_ACCEL_FIR) fail("bad selected accelerator after FIR workload");
        check_calls(32'd3);

        write_reg(REG_INPUT_A, {16'd2, 16'd1});
        write_reg(REG_INPUT_B, {16'd4, 16'd3});
        write_reg(REG_INPUT_C, {16'd6, 16'd5});
        write_reg(REG_INPUT_D, {16'd8, 16'd7});
        start_operation(`EVO_OPCODE_MATMUL, `EVO_ACCEL_MATMUL);
        read_reg(REG_OUTPUT0, read_data);
        if (read_data !== 32'd19) fail("top MATMUL output_0 failed");
        read_reg(REG_OUTPUT1, read_data);
        if (read_data !== 32'd22) fail("top MATMUL output_1 failed");
        read_reg(REG_OUTPUT2, read_data);
        if (read_data !== 32'd43) fail("top MATMUL output_2 failed");
        read_reg(REG_OUTPUT3, read_data);
        if (read_data !== 32'd50) fail("top MATMUL output_3 failed");
        read_reg(REG_STATUS, read_data);
        if (read_data[15:12] !== `EVO_ACCEL_MATMUL) fail("bad selected accelerator after MATMUL workload");
        check_calls(32'd4);

        $display("PASS tb_top_workload_switching");
        $finish;
    end
endmodule
