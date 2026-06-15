module rv32i_placeholder (
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] pc,
    output logic        bus_valid,
    output logic        bus_write,
    output logic [31:0] bus_addr,
    output logic [31:0] bus_wdata,
    input  logic [31:0] bus_rdata,
    input  logic        bus_ready
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'd0;
            bus_valid <= 1'b0;
            bus_write <= 1'b0;
            bus_addr <= 32'd0;
            bus_wdata <= 32'd0;
        end else begin
            pc <= pc + 32'd4;
            bus_valid <= 1'b0;
            bus_write <= 1'b0;
            bus_addr <= bus_addr;
            bus_wdata <= bus_rdata ^ {31'd0, bus_ready};
        end
    end
endmodule
