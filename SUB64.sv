//We are sure that the result is positive
module SUB64 (
    input logic [63:0] data_in_a,
    input logic [63:0] data_in_b,
    input logic        data_valid,
    output logic [63:0] data_out
);

    always_comb begin
        if (data_valid) begin
            data_out = data_in_a - data_in_b;
        end else begin
            data_out = 'b0;
        end
    end
endmodule