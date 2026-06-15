`include "evofabric_defs.svh"

module tb_bad_result_fallback;
    logic clk = 1'b0, rst_n = 1'b0, bus_valid, bus_write, fault_inject, bus_ready, irq_done;
    logic [31:0] bus_addr, bus_wdata, bus_rdata, status_word, read_data;
    always #5 clk = ~clk;

    localparam [31:0] REG_CONTROL = 32'h0000_0000;
    localparam [31:0] REG_INPUT_A = 32'h0000_0004;
    localparam [31:0] REG_OUTPUT0 = 32'h0000_0014;
    localparam [31:0] REG_STATUS  = 32'h0000_0024;
    localparam [31:0] REG_CALLS   = 32'h0000_0104;
    localparam [31:0] REG_FAILURES = 32'h0000_0108;

    task automatic fail(input string message);
        begin
            $display("FAIL tb_bad_result_fallback: %s", message);
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

    initial begin
        $dumpfile("waves/tb_bad_result_fallback.vcd");
        $dumpvars(0, tb_bad_result_fallback);
        bus_valid = 1'b0; bus_write = 1'b0; bus_addr = 32'd0; bus_wdata = 32'd0; fault_inject = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        write_reg(REG_CONTROL, 32'h0000_0100);
        repeat (2) @(posedge clk);

        // Simulation-only safety test: deliberately corrupt the selected accelerator output.
        fault_inject = 1'b1;
        write_reg(REG_INPUT_A, 32'hFFFF_0000);
        write_reg(REG_CONTROL, {24'd0, `EVO_OPCODE_POPCNT, 3'd0, 1'b1});
        wait (dut.mismatch);
        @(negedge clk);
        if (!dut.mismatch) fail("checker_error/mismatch did not assert on forced bad result");
        wait (dut.use_fallback);
        wait (irq_done);
        fault_inject = 1'b0;

        read_reg(REG_OUTPUT0, read_data);
        read_reg(REG_STATUS, status_word);
        if (read_data != 32'd16) fail("fallback did not repair bad result");
        if (status_word[16] != 1'b1) fail("popcount accelerator was not disabled");
        read_reg(REG_FAILURES, read_data);
        if (read_data != 32'd1) fail("failed_calls/failures counter did not increment");
        read_reg(REG_CALLS, read_data);
        if (read_data != 32'd1) fail("calls counter was wrong after injected fault");

        write_reg(REG_CONTROL, {24'd0, `EVO_OPCODE_POPCNT, 3'd0, 1'b1});
        wait (irq_done);
        read_reg(REG_OUTPUT0, read_data);
        if (read_data != 32'd16) fail("fallback path did not serve later request");
        read_reg(REG_FAILURES, read_data);
        if (read_data != 32'd1) fail("failure counter changed during later fallback request");
        read_reg(REG_CALLS, read_data);
        if (read_data != 32'd2) fail("calls counter was wrong after later fallback request");

        $display("PASS tb_bad_result_fallback");
        $finish;
    end
endmodule
