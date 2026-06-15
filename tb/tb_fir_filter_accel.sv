`include "evofabric_defs.svh"

module tb_fir_filter_accel;
    logic clk = 1'b0, rst_n = 1'b0, start, valid, done, busy, error;
    logic [3:0] opcode, accelerator_id;
    logic [31:0] input_a, input_b, input_c, input_d;
    logic [31:0] output_0, output_1, output_2, output_3, cycle_counter;
    always #5 clk = ~clk;

    task automatic fail(input string message);
        begin
            $display("FAIL tb_fir_filter_accel: %s", message);
            $fatal(1);
        end
    endtask

    fir_filter_accel dut (
        .clk(clk), .rst_n(rst_n), .start(start), .valid(valid), .opcode(opcode),
        .input_a(input_a), .input_b(input_b), .input_c(input_c), .input_d(input_d),
        .done(done), .busy(busy), .output_0(output_0), .output_1(output_1),
        .output_2(output_2), .output_3(output_3), .error(error),
        .cycle_counter(cycle_counter), .accelerator_id(accelerator_id)
    );

    task automatic run_vector(input signed [31:0] a, input signed [31:0] b, input signed [31:0] c, input signed [31:0] d);
        logic signed [31:0] expected;
        begin
            input_a = a;
            input_b = b;
            input_c = c;
            input_d = d;
            expected = a + (b <<< 1) + (c * 32'sd3) + (d <<< 2);
            opcode = `EVO_OPCODE_FIR;
            valid = 1'b1;
            @(posedge clk); start = 1'b1;
            @(negedge clk);
            if (!busy) fail("busy did not assert after start");
            @(posedge clk); start = 1'b0;
            wait (done);
            @(negedge clk);
            if (output_0 !== expected) fail("wrong FIR result");
            if (output_1 !== 32'd0 || output_2 !== 32'd0 || output_3 !== 32'd0) fail("unused outputs were not zero");
            if (error) fail("error asserted for a valid FIR opcode");
            if (cycle_counter !== 32'd3) fail("unexpected cycle counter");
            @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("waves/tb_fir_filter_accel.vcd");
        $dumpvars(0, tb_fir_filter_accel);
        start = 1'b0; valid = 1'b0; opcode = `EVO_OPCODE_FIR;
        input_a = 32'd0; input_b = 32'd0; input_c = 32'd0; input_d = 32'd0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        @(negedge clk);
        if (done || busy || error || output_0 !== 32'd0) fail("reset state was not clean");
        if (accelerator_id !== `EVO_ACCEL_FIR) fail("wrong accelerator ID");

        run_vector(32'sd1, 32'sd2, 32'sd3, 32'sd4);
        run_vector(-32'sd2, 32'sd4, -32'sd6, 32'sd8);

        input_a = 32'd1; input_b = 32'd2; input_c = 32'd3; input_d = 32'd4;
        opcode = `EVO_OPCODE_POPCNT;
        valid = 1'b1;
        @(posedge clk); start = 1'b1;
        @(posedge clk); start = 1'b0;
        wait (done);
        @(negedge clk);
        if (!error) fail("wrong opcode did not assert error");

        $display("PASS tb_fir_filter_accel");
        $finish;
    end
endmodule
