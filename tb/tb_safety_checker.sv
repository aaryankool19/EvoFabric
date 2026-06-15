`include "evofabric_defs.svh"

module tb_safety_checker;
    logic mismatch, fallback_forced;
    logic [31:0] checked_output_0, checked_output_1, checked_output_2, checked_output_3;

    accel_safety_checker dut (
        .valid(1'b1), .opcode(`EVO_OPCODE_POPCNT), .input_a(32'hFFFF_0000),
        .input_b(32'd0), .input_c(32'd0), .input_d(32'd0),
        .accel_output_0(32'd15), .accel_output_1(32'd0), .accel_output_2(32'd0), .accel_output_3(32'd0),
        .mismatch(mismatch), .fallback_forced(fallback_forced),
        .checked_output_0(checked_output_0), .checked_output_1(checked_output_1),
        .checked_output_2(checked_output_2), .checked_output_3(checked_output_3)
    );

    initial begin
        $dumpfile("build/tb_safety_checker.vcd");
        $dumpvars(0, tb_safety_checker);
        #1;
        if (!mismatch || !fallback_forced || checked_output_0 != 32'd16) $fatal(1, "safety checker failed");
        $finish;
    end
endmodule
