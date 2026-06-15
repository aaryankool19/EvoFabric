`include "evofabric_defs.svh"

module adaptive_controller (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       request_valid,
    input  logic [3:0] opcode,
    input  logic [4:1] availability,
    input  logic       accel_done,
    input  logic       accel_error,
    input  logic       checker_mismatch,
    output logic       accel_start,
    output logic       op_active,
    output logic       complete,
    output logic       use_fallback,
    output logic [3:0] selected_accel,
    output logic [4:1] disabled_accels
);
    typedef enum logic [1:0] {
        ST_IDLE,
        ST_START,
        ST_WAIT,
        ST_FALLBACK
    } state_t;

    state_t state;
    logic [3:0] chosen_accel;

    function automatic [3:0] choose_accel(input logic [3:0] op, input logic [4:1] avail, input logic [4:1] disabled);
        begin
            choose_accel = `EVO_ACCEL_FALLBACK;
            if (op == `EVO_OPCODE_POPCNT && avail[1] && !disabled[1]) choose_accel = `EVO_ACCEL_POPCNT;
            if (op == `EVO_OPCODE_CRC32  && avail[2] && !disabled[2]) choose_accel = `EVO_ACCEL_CRC32;
            if (op == `EVO_OPCODE_FIR    && avail[3] && !disabled[3]) choose_accel = `EVO_ACCEL_FIR;
            if (op == `EVO_OPCODE_MATMUL && avail[4] && !disabled[4]) choose_accel = `EVO_ACCEL_MATMUL;
        end
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            selected_accel <= `EVO_ACCEL_NONE;
            disabled_accels <= 4'b0000;
            accel_start <= 1'b0;
            op_active <= 1'b0;
            complete <= 1'b0;
            use_fallback <= 1'b0;
        end else begin
            accel_start <= 1'b0;
            complete <= 1'b0;

            case (state)
                ST_IDLE: begin
                    op_active <= 1'b0;
                    use_fallback <= 1'b0;
                    if (request_valid) begin
                        chosen_accel = choose_accel(opcode, availability, disabled_accels);
                        selected_accel <= chosen_accel;
                        op_active <= 1'b1;
                        if (chosen_accel == `EVO_ACCEL_FALLBACK) begin
                            use_fallback <= 1'b1;
                            state <= ST_FALLBACK;
                        end else begin
                            state <= ST_START;
                        end
                    end
                end
                ST_START: begin
                    accel_start <= 1'b1;
                    state <= ST_WAIT;
                end
                ST_WAIT: begin
                    if (accel_done) begin
                        if (accel_error || checker_mismatch) begin
                            disabled_accels[selected_accel] <= 1'b1;
                            use_fallback <= 1'b1;
                        end
                        complete <= 1'b1;
                        op_active <= 1'b0;
                        state <= ST_IDLE;
                    end
                end
                ST_FALLBACK: begin
                    complete <= 1'b1;
                    op_active <= 1'b0;
                    state <= ST_IDLE;
                end
                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
