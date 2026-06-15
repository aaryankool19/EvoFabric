`include "evofabric_defs.svh"

module tb_popcount_accel;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic start, valid, done, busy, error;
    logic [3:0] opcode, accelerator_id;
    logic [31:0] input_a, output_0, output_1, output_2, output_3, cycle_counter;

    always #5 clk = ~clk;

    popcount_accel dut (
        .clk(clk), .rst_n(rst_n), .start(start), .valid(valid), .opcode(opcode),
        .input_a(input_a), .input_b(32'd0), .input_c(32'd0), .input_d(32'd0),
        .done(done), .busy(busy), .output_0(output_0), .output_1(output_1),
        .output_2(output_2), .output_3(output_3), .error(error),
        .cycle_counter(cycle_counter), .accelerator_id(accelerator_id)
    );

    initial begin
        $dumpfile("build/tb_popcount_accel.vcd");
        $dumpvars(0, tb_popcount_accel);
        start = 1'b0; valid = 1'b0; opcode = `EVO_OPCODE_POPCNT; input_a = 32'hF0F0_0001;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk); valid = 1'b1; start = 1'b1;
        @(posedge clk); start = 1'b0;
        wait (done);
        if (output_0 != 32'd9 || error) $fatal(1, "popcount failed");
        $finish;
    end
endmodule
