module data_memory #(
    parameter WORDS = 256
) (
    input  logic        clk,
    input  logic        write_en,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata
);
    logic [31:0] mem [0:WORDS-1];

    integer i;
    initial begin
        for (i = 0; i < WORDS; i = i + 1) mem[i] = 32'd0;
    end

    always_ff @(posedge clk) begin
        if (write_en) mem[addr[31:2] % WORDS] <= wdata;
        rdata <= mem[addr[31:2] % WORDS];
    end
endmodule
