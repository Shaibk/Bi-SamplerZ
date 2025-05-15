module MUL63 (
    input logic [62:0] data_in_a,
    input logic [62:0] data_in_b,
    input logic        data_valid,
    output logic [62:0] data_out_ab
);

    logic [125:0] data_out_ex;
    always_comb begin
        if (data_valid) begin
            data_out_ex = data_in_a * data_in_b;
            data_out_ab = data_out_ex[125:63];
        end else
            data_out_ab = 'b0;
    end
endmodule