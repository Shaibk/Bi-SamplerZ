// Retain logical results while physical lanes are reused for assistance.
module pair_result_bank (
    input logic clk, rst_n, clear, round_start, round_active,
    input logic assist_l, assist_r, done_l, done_r, accept_l, accept_r,
    input logic signed [5:0] candidate_l, candidate_r,
    output logic round_complete, round_accept_l, round_accept_r,
    output logic valid_l, valid_r,
    output logic signed [5:0] result_l, result_r
);
    logic seen_l, seen_r, saved_accept_l, saved_accept_r;
    assign round_complete = (seen_l || done_l) && (seen_r || done_r);
    assign round_accept_l = seen_l ? saved_accept_l : accept_l;
    assign round_accept_r = seen_r ? saved_accept_r : accept_r;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seen_l <= 0; seen_r <= 0; saved_accept_l <= 0; saved_accept_r <= 0;
        end else if (clear || round_start) begin
            seen_l <= 0; seen_r <= 0; saved_accept_l <= 0; saved_accept_r <= 0;
        end else if (round_active) begin
            if (done_l) begin seen_l <= 1; saved_accept_l <= accept_l; end
            if (done_r) begin seen_r <= 1; saved_accept_r <= accept_r; end
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_l <= 0; valid_r <= 0; result_l <= 0; result_r <= 0;
        end else if (clear) begin
            valid_l <= 0; valid_r <= 0; result_l <= 0; result_r <= 0;
        end else if (round_active && round_complete) begin
            if (assist_l) begin
                if (!valid_l && (round_accept_l || round_accept_r)) begin
                    result_l <= round_accept_l ? candidate_l : candidate_r;
                    valid_l <= 1;
                end
            end else if (assist_r) begin
                if (!valid_r && (round_accept_l || round_accept_r)) begin
                    result_r <= round_accept_l ? candidate_l : candidate_r;
                    valid_r <= 1;
                end
            end else begin
                if (!valid_l && round_accept_l) begin result_l <= candidate_l; valid_l <= 1; end
                if (!valid_r && round_accept_r) begin result_r <= candidate_r; valid_r <= 1; end
            end
        end
    end
endmodule
