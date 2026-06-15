`include "evofabric_defs.svh"

module tb_top_workload_switching;
    logic clk = 1'b0, rst_n = 1'b0, bus_valid, bus_write, fault_inject, bus_ready, irq_done;
    logic [31:0] bus_addr, bus_wdata, bus_rdata;
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
        $dumpfile("build/tb_top_workload_switching.vcd");
        $dumpvars(0, tb_top_workload_switching);
        bus_valid = 1'b0; bus_write = 1'b0; bus_addr = 32'd0; bus_wdata = 32'd0; fault_inject = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        write_reg(32'h04, 32'hFFFF_0000);
        write_reg(32'h00, {24'd0, `EVO_OPCODE_POPCNT, 3'd0, 1'b1});
        wait (irq_done);
        read_reg(32'h14, bus_wdata);
        if (bus_wdata != 32'd16) $fatal(1, "top popcount workload failed");

        write_reg(32'h04, 32'd1);
        write_reg(32'h08, 32'd2);
        write_reg(32'h0C, 32'd3);
        write_reg(32'h10, 32'd4);
        write_reg(32'h00, {24'd0, `EVO_OPCODE_FIR, 3'd0, 1'b1});
        wait (irq_done);
        read_reg(32'h14, bus_wdata);
        if (bus_wdata != 32'd30) $fatal(1, "top fir workload failed");
        $finish;
    end
endmodule
