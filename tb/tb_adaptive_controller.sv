`include "evofabric_defs.svh"

module tb_adaptive_controller;
    logic clk = 1'b0, rst_n = 1'b0, request_valid, accel_done, accel_error, checker_mismatch;
    logic accel_start, op_active, complete, use_fallback;
    logic [3:0] selected_accel;
    logic [4:1] disabled_accels;
    always #5 clk = ~clk;

    adaptive_controller dut (
        .clk(clk), .rst_n(rst_n), .request_valid(request_valid), .opcode(`EVO_OPCODE_POPCNT),
        .availability(4'b1111), .accel_done(accel_done), .accel_error(accel_error),
        .checker_mismatch(checker_mismatch), .accel_start(accel_start), .op_active(op_active),
        .complete(complete), .use_fallback(use_fallback), .selected_accel(selected_accel),
        .disabled_accels(disabled_accels)
    );

    initial begin
        $dumpfile("build/tb_adaptive_controller.vcd");
        $dumpvars(0, tb_adaptive_controller);
        request_valid = 1'b0; accel_done = 1'b0; accel_error = 1'b0; checker_mismatch = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk); request_valid = 1'b1;
        @(posedge clk); request_valid = 1'b0;
        wait (accel_start);
        if (selected_accel != `EVO_ACCEL_POPCNT) $fatal(1, "controller did not select popcount");
        @(posedge clk); checker_mismatch = 1'b1; accel_done = 1'b1;
        @(posedge clk); checker_mismatch = 1'b0; accel_done = 1'b0;
        if (!complete && !disabled_accels[1]) $fatal(1, "controller did not quarantine failed accel");
        @(posedge clk); request_valid = 1'b1;
        @(posedge clk); request_valid = 1'b0;
        @(posedge clk);
        if (!use_fallback) $fatal(1, "controller did not choose fallback after quarantine");
        $finish;
    end
endmodule
