`include "evofabric_defs.svh"

module tb_fir_filter_accel;
    logic clk = 1'b0, rst_n = 1'b0, start, valid, done, busy, error;
    logic [3:0] opcode, accelerator_id;
    logic [31:0] output_0, output_1, output_2, output_3, cycle_counter;
    always #5 clk = ~clk;

    fir_filter_accel dut (
        .clk(clk), .rst_n(rst_n), .start(start), .valid(valid), .opcode(opcode),
        .input_a(32'd1), .input_b(32'd2), .input_c(32'd3), .input_d(32'd4),
        .done(done), .busy(busy), .output_0(output_0), .output_1(output_1),
        .output_2(output_2), .output_3(output_3), .error(error),
        .cycle_counter(cycle_counter), .accelerator_id(accelerator_id)
    );

    initial begin
        $dumpfile("build/tb_fir_filter_accel.vcd");
        $dumpvars(0, tb_fir_filter_accel);
        start = 1'b0; valid = 1'b0; opcode = `EVO_OPCODE_FIR;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk); valid = 1'b1; start = 1'b1;
        @(posedge clk); start = 1'b0;
        wait (done);
        if (output_0 != 32'd30 || error) $fatal(1, "fir failed");
        $finish;
    end
endmodule
