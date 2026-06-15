`include "evofabric_defs.svh"

module tb_adaptive_controller;
    logic clk = 1'b0, rst_n = 1'b0, request_valid, accel_done, accel_error, checker_mismatch;
    logic [3:0] opcode;
    logic [4:1] availability;
    logic accel_start, op_active, complete, use_fallback;
    logic [3:0] selected_accel;
    logic [4:1] disabled_accels;
    always #5 clk = ~clk;

    task automatic fail(input string message);
        begin
            $display("FAIL tb_adaptive_controller: %s", message);
            $fatal(1);
        end
    endtask

    adaptive_controller dut (
        .clk(clk), .rst_n(rst_n), .request_valid(request_valid), .opcode(opcode),
        .availability(availability), .accel_done(accel_done), .accel_error(accel_error),
        .checker_mismatch(checker_mismatch), .accel_start(accel_start), .op_active(op_active),
        .complete(complete), .use_fallback(use_fallback), .selected_accel(selected_accel),
        .disabled_accels(disabled_accels)
    );

    task automatic request_and_complete(input [3:0] op, input [3:0] expected_id, input bit inject_mismatch);
        begin
            opcode = op;
            @(posedge clk); request_valid = 1'b1;
            @(posedge clk); request_valid = 1'b0;
            @(negedge clk);
            if (selected_accel !== expected_id) fail("controller selected the wrong accelerator");
            if (expected_id == `EVO_ACCEL_FALLBACK) begin
                wait (complete);
                @(posedge clk);
            end else begin
                if (!op_active) fail("operation did not become active");
                wait (accel_start);
                @(posedge clk);
                checker_mismatch = inject_mismatch;
                accel_done = 1'b1;
                @(posedge clk);
                checker_mismatch = 1'b0;
                accel_done = 1'b0;
                wait (complete);
                @(posedge clk);
            end
            @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("waves/tb_adaptive_controller.vcd");
        $dumpvars(0, tb_adaptive_controller);
        request_valid = 1'b0; accel_done = 1'b0; accel_error = 1'b0; checker_mismatch = 1'b0;
        opcode = `EVO_OPCODE_NONE; availability = 4'b1111;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        @(negedge clk);
        if (selected_accel != `EVO_ACCEL_NONE || op_active || complete || use_fallback) fail("reset state was not clean");

        request_and_complete(`EVO_OPCODE_CRC32, `EVO_ACCEL_CRC32, 1'b0);
        request_and_complete(`EVO_OPCODE_POPCNT, `EVO_ACCEL_POPCNT, 1'b1);
        if (!disabled_accels[1]) fail("controller did not quarantine failed popcount accelerator");
        request_and_complete(`EVO_OPCODE_POPCNT, `EVO_ACCEL_FALLBACK, 1'b0);

        availability = 4'b1011;
        request_and_complete(`EVO_OPCODE_FIR, `EVO_ACCEL_FALLBACK, 1'b0);

        $display("PASS tb_adaptive_controller");
        $finish;
    end
endmodule
