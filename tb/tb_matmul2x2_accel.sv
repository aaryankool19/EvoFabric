`include "evofabric_defs.svh"

module tb_matmul2x2_accel;
    logic clk = 1'b0, rst_n = 1'b0, start, valid, done, busy, error;
    logic [3:0] opcode, accelerator_id;
    logic [31:0] input_a, input_b, input_c, input_d;
    logic [31:0] output_0, output_1, output_2, output_3, cycle_counter;
    always #5 clk = ~clk;

    task automatic fail(input string message);
        begin
            $display("FAIL tb_matmul2x2_accel: %s", message);
            $fatal(1);
        end
    endtask

    matmul2x2_accel dut (
        .clk(clk), .rst_n(rst_n), .start(start), .valid(valid), .opcode(opcode),
        .input_a(input_a), .input_b(input_b), .input_c(input_c), .input_d(input_d),
        .done(done), .busy(busy), .output_0(output_0), .output_1(output_1),
        .output_2(output_2), .output_3(output_3), .error(error),
        .cycle_counter(cycle_counter), .accelerator_id(accelerator_id)
    );

    task automatic run_vector(
        input signed [15:0] a00, input signed [15:0] a01,
        input signed [15:0] a10, input signed [15:0] a11,
        input signed [15:0] b00, input signed [15:0] b01,
        input signed [15:0] b10, input signed [15:0] b11
    );
        logic signed [31:0] e0, e1, e2, e3;
        begin
            input_a = {a01, a00};
            input_b = {a11, a10};
            input_c = {b01, b00};
            input_d = {b11, b10};
            e0 = a00 * b00 + a01 * b10;
            e1 = a00 * b01 + a01 * b11;
            e2 = a10 * b00 + a11 * b10;
            e3 = a10 * b01 + a11 * b11;
            opcode = `EVO_OPCODE_MATMUL;
            valid = 1'b1;
            @(posedge clk); start = 1'b1;
            @(negedge clk);
            if (!busy) fail("busy did not assert after start");
            @(posedge clk); start = 1'b0;
            wait (done);
            @(negedge clk);
            if (output_0 !== e0 || output_1 !== e1 || output_2 !== e2 || output_3 !== e3) fail("wrong matrix result");
            if (error) fail("error asserted for a valid MATMUL opcode");
            if (cycle_counter !== 32'd3) fail("unexpected cycle counter");
            @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("waves/tb_matmul2x2_accel.vcd");
        $dumpvars(0, tb_matmul2x2_accel);
        start = 1'b0; valid = 1'b0; opcode = `EVO_OPCODE_MATMUL;
        input_a = 32'd0; input_b = 32'd0; input_c = 32'd0; input_d = 32'd0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        @(negedge clk);
        if (done || busy || error || output_0 !== 32'd0) fail("reset state was not clean");
        if (accelerator_id !== `EVO_ACCEL_MATMUL) fail("wrong accelerator ID");

        run_vector(16'sd1, 16'sd2, 16'sd3, 16'sd4, 16'sd5, 16'sd6, 16'sd7, 16'sd8);
        run_vector(-16'sd1, 16'sd2, 16'sd3, -16'sd4, 16'sd2, -16'sd1, 16'sd5, 16'sd6);

        input_a = {16'd2, 16'd1}; input_b = {16'd4, 16'd3};
        input_c = {16'd6, 16'd5}; input_d = {16'd8, 16'd7};
        opcode = `EVO_OPCODE_POPCNT;
        valid = 1'b1;
        @(posedge clk); start = 1'b1;
        @(posedge clk); start = 1'b0;
        wait (done);
        @(negedge clk);
        if (!error) fail("wrong opcode did not assert error");

        $display("PASS tb_matmul2x2_accel");
        $finish;
    end
endmodule
