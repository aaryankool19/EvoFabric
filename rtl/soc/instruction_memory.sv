module instruction_memory #(
    parameter WORDS = 256
) (
    input  logic [31:0] addr,
    output logic [31:0] rdata
);
    logic [31:0] mem [0:WORDS-1];

    integer i;
    initial begin
        for (i = 0; i < WORDS; i = i + 1) mem[i] = 32'h0000_0013;
    end

    assign rdata = mem[addr[31:2] % WORDS];
endmodule
