/*9+72=81
*/
module MUL81 (
    input logic [80:0] MUL_data_in_a,
    input logic [80:0] MUL_data_in_b,
    input logic        MUL_data_valid,
    output logic [80:0] MUL_data_out
);
    logic [161:0] MUL_data_out_ex;
always_comb begin
    if (MUL_data_valid) begin
        MUL_data_out_ex = MUL_data_in_a * MUL_data_in_b;
        MUL_data_out = MUL_data_out_ex[152:72];
    end else begin
        MUL_data_out = 'b0;
    end
end
endmodule