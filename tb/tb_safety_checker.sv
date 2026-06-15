`include "evofabric_defs.svh"

module tb_safety_checker;
    logic valid;
    logic [3:0] opcode;
    logic [31:0] input_a, input_b, input_c, input_d;
    logic [31:0] accel_output_0, accel_output_1, accel_output_2, accel_output_3;
    logic mismatch, fallback_forced;
    logic [31:0] checked_output_0, checked_output_1, checked_output_2, checked_output_3;

    accel_safety_checker dut (
        .valid(valid), .opcode(opcode), .input_a(input_a),
        .input_b(input_b), .input_c(input_c), .input_d(input_d),
        .accel_output_0(accel_output_0), .accel_output_1(accel_output_1),
        .accel_output_2(accel_output_2), .accel_output_3(accel_output_3),
        .mismatch(mismatch), .fallback_forced(fallback_forced),
        .checked_output_0(checked_output_0), .checked_output_1(checked_output_1),
        .checked_output_2(checked_output_2), .checked_output_3(checked_output_3)
    );

    task automatic fail(input string message);
        begin
            $display("FAIL tb_safety_checker: %s", message);
            $fatal(1);
        end
    endtask

    initial begin
        $dumpfile("waves/tb_safety_checker.vcd");
        $dumpvars(0, tb_safety_checker);
        valid = 1'b0;
        opcode = `EVO_OPCODE_POPCNT;
        input_a = 32'hFFFF_0000; input_b = 32'd0; input_c = 32'd0; input_d = 32'd0;
        accel_output_0 = 32'd15; accel_output_1 = 32'd0; accel_output_2 = 32'd0; accel_output_3 = 32'd0;
        #1;
        if (mismatch || fallback_forced) fail("invalid checker transaction flagged a mismatch");

        valid = 1'b1;
        #1;
        if (!mismatch || !fallback_forced || checked_output_0 != 32'd16) fail("popcount mismatch was not repaired");

        accel_output_0 = 32'd16;
        #1;
        if (mismatch || fallback_forced || checked_output_0 != 32'd16) fail("matching popcount result was rejected");

        opcode = `EVO_OPCODE_FIR;
        input_a = 32'd1; input_b = 32'd2; input_c = 32'd3; input_d = 32'd4;
        accel_output_0 = 32'd30;
        #1;
        if (mismatch || checked_output_0 != 32'd30) fail("matching FIR result was rejected");

        opcode = `EVO_OPCODE_MATMUL;
        input_a = {16'd2, 16'd1}; input_b = {16'd4, 16'd3};
        input_c = {16'd6, 16'd5}; input_d = {16'd8, 16'd7};
        accel_output_0 = 32'd19; accel_output_1 = 32'd22; accel_output_2 = 32'd43; accel_output_3 = 32'd51;
        #1;
        if (!mismatch || checked_output_3 != 32'd50) fail("matrix mismatch was not detected and repaired");

        $display("PASS tb_safety_checker");
        $finish;
    end
endmodule
