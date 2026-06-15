`include "evofabric_defs.svh"

module tb_popcount_accel;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic start, valid, done, busy, error;
    logic [3:0] opcode, accelerator_id;
    logic [31:0] input_a, output_0, output_1, output_2, output_3, cycle_counter;

    always #5 clk = ~clk;

    task automatic fail(input string message);
        begin
            $display("FAIL tb_popcount_accel: %s", message);
            $fatal(1);
        end
    endtask

    task automatic run_vector(input [31:0] value, input [31:0] expected_count);
        begin
            input_a = value;
            opcode = `EVO_OPCODE_POPCNT;
            valid = 1'b1;
            @(posedge clk); start = 1'b1;
            @(negedge clk);
            if (!busy) fail("busy did not assert after start");
            @(posedge clk); start = 1'b0;
            wait (done);
            @(negedge clk);
            if (output_0 !== expected_count) fail("wrong popcount result");
            if (output_1 !== 32'd0 || output_2 !== 32'd0 || output_3 !== 32'd0) fail("unused outputs were not zero");
            if (error) fail("error asserted for a valid popcount opcode");
            if (cycle_counter !== 32'd1) fail("unexpected cycle counter");
            @(posedge clk);
        end
    endtask

    popcount_accel dut (
        .clk(clk), .rst_n(rst_n), .start(start), .valid(valid), .opcode(opcode),
        .input_a(input_a), .input_b(32'd0), .input_c(32'd0), .input_d(32'd0),
        .done(done), .busy(busy), .output_0(output_0), .output_1(output_1),
        .output_2(output_2), .output_3(output_3), .error(error),
        .cycle_counter(cycle_counter), .accelerator_id(accelerator_id)
    );

    initial begin
        $dumpfile("waves/tb_popcount_accel.vcd");
        $dumpvars(0, tb_popcount_accel);
        start = 1'b0; valid = 1'b0; opcode = `EVO_OPCODE_POPCNT; input_a = 32'd0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        @(negedge clk);
        if (done || busy || error || output_0 !== 32'd0) fail("reset state was not clean");
        if (accelerator_id !== `EVO_ACCEL_POPCNT) fail("wrong accelerator ID");

        run_vector(32'h0000_0000, 32'd0);
        run_vector(32'hFFFF_FFFF, 32'd32);
        run_vector(32'hF0F0_0001, 32'd9);

        input_a = 32'h0000_0001;
        opcode = `EVO_OPCODE_CRC32;
        valid = 1'b1;
        @(posedge clk); start = 1'b1;
        @(posedge clk); start = 1'b0;
        wait (done);
        @(negedge clk);
        if (!error) fail("wrong opcode did not assert error");

        $display("PASS tb_popcount_accel");
        $finish;
    end
endmodule
