module performance_counters (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        clear,
    input  logic        op_start,
    input  logic        op_complete,
    input  logic        op_failed,
    input  logic [3:0]  selected_accel,
    input  logic [31:0] latency_value,
    output logic [31:0] total_cycles,
    output logic [31:0] calls,
    output logic [31:0] failures,
    output logic [3:0]  last_selected_accel,
    output logic [31:0] last_latency,
    output logic [31:0] best_latency
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_cycles <= 32'd0;
            calls <= 32'd0;
            failures <= 32'd0;
            last_selected_accel <= 4'd0;
            last_latency <= 32'd0;
            best_latency <= 32'hFFFF_FFFF;
        end else if (clear) begin
            total_cycles <= 32'd0;
            calls <= 32'd0;
            failures <= 32'd0;
            last_selected_accel <= 4'd0;
            last_latency <= 32'd0;
            best_latency <= 32'hFFFF_FFFF;
        end else begin
            total_cycles <= total_cycles + 32'd1;
            if (op_start) begin
                calls <= calls + 32'd1;
                last_selected_accel <= selected_accel;
            end
            if (op_complete) begin
                last_latency <= latency_value;
                if (latency_value < best_latency) best_latency <= latency_value;
            end
            if (op_failed) failures <= failures + 32'd1;
        end
    end
endmodule
