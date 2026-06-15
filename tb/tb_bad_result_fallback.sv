`include "evofabric_defs.svh"

module tb_bad_result_fallback;
    logic clk = 1'b0, rst_n = 1'b0, bus_valid, bus_write, fault_inject, bus_ready, irq_done;
    logic [31:0] bus_addr, bus_wdata, bus_rdata, status_word;
    always #5 clk = ~clk;

    evofabric_top dut (
        .clk(clk), .rst_n(rst_n), .bus_valid(bus_valid), .bus_write(bus_write),
        .bus_addr(bus_addr), .bus_wdata(bus_wdata), .fault_inject(fault_inject),
        .accel_available(4'b1111), .bus_rdata(bus_rdata), .bus_ready(bus_ready), .irq_done(irq_done)
    );

    task automatic write_reg(input [31:0] addr, input [31:0] data);
        begin
            @(posedge clk); bus_valid = 1'b1; bus_write = 1'b1; bus_addr = addr; bus_wdata = data;
            @(posedge clk); bus_valid = 1'b0; bus_write = 1'b0;
        end
    endtask

    task automatic read_reg(input [31:0] addr, output [31:0] data);
        begin
            @(posedge clk); bus_valid = 1'b1; bus_write = 1'b0; bus_addr = addr;
            @(posedge clk); data = bus_rdata; bus_valid = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("build/tb_bad_result_fallback.vcd");
        $dumpvars(0, tb_bad_result_fallback);
        bus_valid = 1'b0; bus_write = 1'b0; bus_addr = 32'd0; bus_wdata = 32'd0; fault_inject = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        fault_inject = 1'b1;
        write_reg(32'h04, 32'hFFFF_0000);
        write_reg(32'h00, {24'd0, `EVO_OPCODE_POPCNT, 3'd0, 1'b1});
        wait (irq_done);
        fault_inject = 1'b0;
        read_reg(32'h14, bus_wdata);
        read_reg(32'h24, status_word);
        if (bus_wdata != 32'd16) $fatal(1, "fallback did not repair bad result");
        if (status_word[16] != 1'b1) $fatal(1, "popcount accelerator was not disabled");

        write_reg(32'h00, {24'd0, `EVO_OPCODE_POPCNT, 3'd0, 1'b1});
        wait (irq_done);
        read_reg(32'h14, bus_wdata);
        if (bus_wdata != 32'd16) $fatal(1, "fallback path did not serve later request");
        $finish;
    end
endmodule
