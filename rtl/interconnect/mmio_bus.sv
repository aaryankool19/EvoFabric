module mmio_bus (
    input  logic        bus_valid,
    input  logic        bus_write,
    input  logic [31:0] bus_addr,
    input  logic [31:0] bus_wdata,
    input  logic [31:0] accel_rdata,
    input  logic [31:0] perf_rdata,
    output logic        accel_write,
    output logic        accel_read,
    output logic        perf_read,
    output logic [31:0] local_addr,
    output logic [31:0] local_wdata,
    output logic [31:0] bus_rdata,
    output logic        bus_ready
);
    localparam [15:0] ACCEL_BASE = 16'h0000;
    localparam [15:0] PERF_BASE  = 16'h0100;

    always @* begin
        local_addr = {16'd0, bus_addr[15:0]};
        local_wdata = bus_wdata;
        accel_write = 1'b0;
        accel_read = 1'b0;
        perf_read = 1'b0;
        bus_rdata = 32'd0;
        bus_ready = bus_valid;

        if (bus_valid && bus_addr[15:8] == ACCEL_BASE[15:8]) begin
            accel_write = bus_write;
            accel_read = !bus_write;
            bus_rdata = accel_rdata;
        end else if (bus_valid && bus_addr[15:8] == PERF_BASE[15:8]) begin
            perf_read = !bus_write;
            bus_rdata = perf_rdata;
        end
    end
endmodule
