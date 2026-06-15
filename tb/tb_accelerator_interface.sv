`include "evofabric_defs.svh"

module tb_accelerator_interface;
    logic clk = 1'b0, rst_n = 1'b0, start, valid, done, busy, error;
    logic [3:0] accelerator_id;
    logic [31:0] output_0, output_1, output_2, output_3, cycle_counter;
    always #5 clk = ~clk;

    task automatic fail(input string message);
        begin
            $display("FAIL tb_accelerator_interface: %s", message);
            $fatal(1);
        end
    endtask

    popcount_accel dut (
        .clk(clk), .rst_n(rst_n), .start(start), .valid(valid), .opcode(`EVO_OPCODE_POPCNT),
        .input_a(32'hFFFF_0000), .input_b(32'd0), .input_c(32'd0), .input_d(32'd0),
        .done(done), .busy(busy), .output_0(output_0), .output_1(output_1),
        .output_2(output_2), .output_3(output_3), .error(error),
        .cycle_counter(cycle_counter), .accelerator_id(accelerator_id)
    );

    initial begin
        $dumpfile("waves/tb_accelerator_interface.vcd");
        $dumpvars(0, tb_accelerator_interface);
        start = 1'b0; valid = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        @(posedge clk); start = 1'b1;
        @(posedge clk); start = 1'b0;
        repeat (2) @(posedge clk);
        if (busy || done) fail("accelerator ran when valid was low");

        @(posedge clk); valid = 1'b1; start = 1'b1;
        @(negedge clk);
        if (!busy) fail("busy did not assert during common handshake");
        @(posedge clk); start = 1'b0;
        wait (done);
        @(negedge clk);
        if (accelerator_id != `EVO_ACCEL_POPCNT) fail("wrong accelerator ID");
        if (output_0 != 32'd16) fail("wrong common interface result");
        if (error) fail("error asserted during common interface test");
        if (cycle_counter != 32'd1) fail("wrong common interface cycle count");

        $display("PASS tb_accelerator_interface");
        $finish;
    end
endmodule
