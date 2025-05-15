/*
No need to add rdm_req signal here, it is updated synchronously with basesampler.
*/
module bef_loop #(
parameter iLN2 = 73'h171547652b820000000,//2^72
parameter LN2  = 72'hb17217f7d1d0000000
)
( 
   input clk,
    input rst_n,
    input logic valid,
//1 bit rdm b
    input logic [7:0] rdm8,
    //output logic rdm_req,
//Input from basesampler and per_samp modules
    input logic [4:0] z0,
    input logic [71:0] r_72,
    input logic [71:0] sqr2_isigma,
//To connect the for_loop module.
    output logic [62:0] z_63,
//To connect the aft_loop module.
    output logic [5:0] s_6,
//To connect the MUL81
    input logic [80:0] MUL_data_out,
    output logic      MUL_data_valid,
    output logic [80:0] MUL_data_in_a,
    output logic [80:0] MUL_data_in_b,
    output logic done
);
//To connect the SUB81
logic [80:0] SUB_data_out;
logic       SUB_data_valid;
logic [80:0] SUB_data_in_a;
logic [80:0] SUB_data_in_b;
//Intermeida signals
logic [2:0] cnt;
logic [80:0] z_r;
logic [80:0] sqr_z_r;
logic [7:0] s_tmp;//9 bits needed
logic [80:0] MUL_tmp;//Store the (z-r)^2 * sqr2isigma / s * ln2.
logic [80:0] MUL_tmp2,MUL_tmp3;// Need to store the value in advance.
logic [80:0] x_81;
logic [71:0] r_Ber;//Distinguish this r and r(r_72) in main routine carefully.

wire b = rdm8[0]; 
//cnt logics
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt <= 'd0;
    end else if (valid) begin
        cnt <= (cnt < 'd7)? cnt + 'd1 : cnt;
    end else begin
        cnt <= 'd0;
    end
end

//Done logics
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        done <= 'b0;
    end else if (valid && (cnt == 'd6)) begin
        done <= 'b1;
    end else begin
        done <= 'b0;
    end
end

//assign rdm_req = valid && (cnt == 'd1); // Request for random data only at the start of the loop

//SUB81 mul select logics
always_comb begin
    case (cnt) 
        'd1: begin SUB_data_valid = '1;
                  SUB_data_in_a = (b == 'd0)? {4'b0,z0,r_72} : {4'b0,z0,72'b0} + '1; 
                  SUB_data_in_b = (b == 'd0)? 'd0             : {9'b0,r_72};
        end
        'd4: begin SUB_data_valid = 'd1; SUB_data_in_a = MUL_tmp; SUB_data_in_b = MUL_tmp2; end
        'd7: begin SUB_data_valid = 'd1; SUB_data_in_a = x_81 ; SUB_data_in_b = MUL_tmp3; end
        default : begin SUB_data_valid = 'd0; SUB_data_in_a = 'd0; SUB_data_in_b = 'd0; end
        endcase
end
always_ff @(posedge clk) begin if (cnt == 'd1) z_r <= SUB_data_out; end
always_ff @(posedge clk) begin if (cnt == 'd4) x_81 <= SUB_data_out; end
always_ff @(posedge clk) begin if (cnt == 'd7) r_Ber <= SUB_data_out[71:0]; end
///////////////////////////////////////////////////

//MUL64 mul select logics
always_comb begin
    case (cnt)
    'd2: begin MUL_data_valid = 'd1; MUL_data_in_a = z_r; MUL_data_in_b = z_r; end
    'd3: begin MUL_data_valid = 'd1; MUL_data_in_a = sqr_z_r; MUL_data_in_b = sqr2_isigma; end
    'd5: begin MUL_data_valid = 'd1; MUL_data_in_a = x_81; MUL_data_in_b = {8'b0,iLN2}; end
    'd6: begin MUL_data_valid = 'd1; MUL_data_in_a = {1'b0,s_tmp,72'b0}; MUL_data_in_b = {9'b0,LN2}; end
    default: begin MUL_data_valid = 'd0; MUL_data_in_a = 'd0; MUL_data_in_b = 'd0;end
    endcase
end
always_ff @(posedge clk) begin if (cnt == 'd2) sqr_z_r <= MUL_data_out;end
always_ff @(posedge clk) begin if (cnt == 'd3) MUL_tmp <= MUL_data_out;end
always_ff @(posedge clk) begin if (cnt == 'd5) s_tmp = MUL_data_out[79:72];end
always_ff @(posedge clk) begin if (cnt == 'd6) MUL_tmp3 = MUL_data_out;end
////////////////////////////////////////////////

//MUL_tmp2 logics: A set of pre_calculated values
always_comb begin
    case (z0)
    'd0:  MUL_tmp2 = 81'h000000000000000000000000000;
    'd1:  MUL_tmp2 = 81'h0000000004d3e2f060ef0000000;
    'd2:  MUL_tmp2 = 81'h00000000134f8bc183bc0000000;
    'd3:  MUL_tmp2 = 81'h000000002b72fa7368670000000;
    'd4:  MUL_tmp2 = 81'h000000004d3e2f060ef00000000;
    'd5:  MUL_tmp2 = 81'h0000000078b1297977570000000;
    'd6:  MUL_tmp2 = 81'h00000000adcbe9cda19c0000000;
    'd7:  MUL_tmp2 = 81'h00000000ec8e70028dbf0000000;
    'd8:  MUL_tmp2 = 81'h0000000134f8bc183bc00000000;
    'd9:  MUL_tmp2 = 81'h00000001870ace0eab9f0000000;
    'd10: MUL_tmp2 = 81'h00000001e2c4a5e5dd5c0000000;
    'd11: MUL_tmp2 = 81'h000000024826439dd0f70000000;
    'd12: MUL_tmp2 = 81'h00000002b72fa73686700000000;
    'd13: MUL_tmp2 = 81'h000000032fe0d0affdc70000000;
    'd14: MUL_tmp2 = 81'h00000003b239c00a36fc0000000;
    'd15: MUL_tmp2 = 81'h000000043e3a7545320f0000000;
    'd16: MUL_tmp2 = 81'h00000004d3e2f060ef000000000;
    'd17: MUL_tmp2 = 81'h000000057333315d6dcf0000000;
    'd18: MUL_tmp2 = 81'h000000061c2b383aae7c0000000;
    default: MUL_tmp2 = 81'h000000000000000000000000000;
    endcase
end


//Generate s_6 logics
always_ff @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin 
        s_6 <= 'd0;
    end else if (cnt == 'd6) begin
        s_6 <= (s_tmp < 'd63)? s_tmp[5:0] : 'd63;
    end
end
//Generate z_63 logics
assign z_63   = r_Ber[71:9];
//Instantiate the SUB81 module
SUB81 uSUB81 (
    .data_in_a(SUB_data_in_a),
    .data_in_b(SUB_data_in_b),
    .data_out(SUB_data_out),
    .data_valid(SUB_data_valid)
);



endmodule