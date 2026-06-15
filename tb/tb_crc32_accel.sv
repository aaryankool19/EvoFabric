`include "evofabric_defs.svh"

module tb_crc32_accel;
    logic clk = 1'b0, rst_n = 1'b0, start, valid, done, busy, error;
    logic [3:0] opcode, accelerator_id;
    logic [31:0] input_a, output_0, output_1, output_2, output_3, cycle_counter;
    always #5 clk = ~clk;

    crc32_accel dut (
        .clk(clk), .rst_n(rst_n), .start(start), .valid(valid), .opcode(opcode),
        .input_a(input_a), .input_b(32'd0), .input_c(32'd0), .input_d(32'd0),
        .done(done), .busy(busy), .output_0(output_0), .output_1(output_1),
        .output_2(output_2), .output_3(output_3), .error(error),
        .cycle_counter(cycle_counter), .accelerator_id(accelerator_id)
    );

    function automatic [31:0] crc32_word(input logic [31:0] value);
        integer i;
        logic [31:0] crc;
        begin
            crc = 32'hFFFF_FFFF ^ value;
            for (i = 0; i < 32; i = i + 1) crc = crc[0] ? ((crc >> 1) ^ 32'hEDB8_8320) : (crc >> 1);
            crc32_word = ~crc;
        end
    endfunction

    initial begin
        $dumpfile("build/tb_crc32_accel.vcd");
        $dumpvars(0, tb_crc32_accel);
        start = 1'b0; valid = 1'b0; opcode = `EVO_OPCODE_CRC32; input_a = 32'h1234_5678;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk); valid = 1'b1; start = 1'b1;
        @(posedge clk); start = 1'b0;
        wait (done);
        if (output_0 != crc32_word(input_a) || error) $fatal(1, "crc32 failed");
        $finish;
    end
endmodule
