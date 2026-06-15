`include "evofabric_defs.svh"

module tb_matmul2x2_accel;
    logic clk = 1'b0, rst_n = 1'b0, start, valid, done, busy, error;
    logic [3:0] opcode, accelerator_id;
    logic [31:0] output_0, output_1, output_2, output_3, cycle_counter;
    always #5 clk = ~clk;

    matmul2x2_accel dut (
        .clk(clk), .rst_n(rst_n), .start(start), .valid(valid), .opcode(opcode),
        .input_a({16'd2, 16'd1}), .input_b({16'd4, 16'd3}),
        .input_c({16'd6, 16'd5}), .input_d({16'd8, 16'd7}),
        .done(done), .busy(busy), .output_0(output_0), .output_1(output_1),
        .output_2(output_2), .output_3(output_3), .error(error),
        .cycle_counter(cycle_counter), .accelerator_id(accelerator_id)
    );

    initial begin
        $dumpfile("build/tb_matmul2x2_accel.vcd");
        $dumpvars(0, tb_matmul2x2_accel);
        start = 1'b0; valid = 1'b0; opcode = `EVO_OPCODE_MATMUL;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk); valid = 1'b1; start = 1'b1;
        @(posedge clk); start = 1'b0;
        wait (done);
        if (output_0 != 32'd19 || output_1 != 32'd22 || output_2 != 32'd43 || output_3 != 32'd50 || error) $fatal(1, "matmul failed");
        $finish;
    end
endmodule
