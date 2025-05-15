module for_loop (
    input  logic clk,
    input  logic rst_n,
    input  logic valid,
    //input values
    input  logic [62:0] z_63, // Because the z_63 is initialized as round(2^63 * x) in algorithm, so it is identical to just take the upper 63 bits of a 72 bits x. 
    input  logic [62:0] ccs_63,  //Same as above
    //output
    output logic [62:0] y_63,  //return y with 63-bit
    output logic done,
    //Share a SUB64 with samplerz
    output logic [63:0] sub_data_in_a,
    output logic [63:0] sub_data_in_b,
    input logic [62:0] sub_data_out,
    output logic sub_data_valid
);
//Coeffienct table
    localparam logic [63:0] C [0:12] = '{
        64'h0000_0004_7411_83A3, 64'h00000036548CFC06,
        64'h0000024FDCBF140A, 64'h000171D939DE045,
        64'h0000D00CF58F6F84,  64'h000680681CF796E3,
        64'h002D82D8305B0FEA, 64'h011111110E066FD0,
        64'h0555555555070F00, 64'h155555555581FF00,
        64'h400000000002B400,
        64'h7FFFFFFFFFFF4800, 64'h8000000000000000
    };

    logic [4:0] cnt;
    logic [62:0] products_z_y;
    logic [63:0] C_pre;
    logic [62:0] mul_data_in_a;
    logic [62:0] mul_data_in_b;
    logic [62:0] mul_data_out_ab;
    logic        mul_data_valid;

//cnt logics 0~25
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 'd0;
        end else if(valid) begin 
            cnt <= (cnt <= 'd27) ? cnt + 'd1 : cnt;
        end else begin
            cnt <= 'd0;
        end
    end

//Done logics
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        done <= 'b0;
    end else if (valid && (cnt == 'd26)) begin
        done <= 'b1;
    end else begin
        done <= 'b0;
    end
end


//MUL63 mul select logics
always_comb begin
    if (valid && cnt < 'd25) begin
        mul_data_valid = cnt[0];
        mul_data_in_a = z_63;
        mul_data_in_b = y_63;
    end else if (valid && cnt == 'd26) begin
        mul_data_valid = 1'b1;
        mul_data_in_a = ccs_63;
        mul_data_in_b = y_63;
    end else begin
        mul_data_valid = 1'b0;
        mul_data_in_a = 'b0;
        mul_data_in_b = 'b0;
    end
end     
//products_z_y logics
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        products_z_y <= 'b0;
    end else if (mul_data_valid && cnt <= 'd25) begin
        products_z_y <= mul_data_out_ab;
    end else begin
        products_z_y <= products_z_y;
    end
end
//////////////////////////////////////////////////////////////////////
//y_63 logics
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        y_63 <= 'b0;
    end else if (cnt == 'b0)begin 
        y_63 <= C[0][62:0];
    end else if (valid & sub_data_valid & cnt <= 'd25) begin
        y_63 <= sub_data_out;
    end else if (valid & mul_data_valid & cnt == 'd26) begin
        y_63 <= mul_data_out_ab;
    end else begin
        y_63 <= y_63;
    end
end

//SUB module datapath
always_comb begin
    if (valid && cnt <= 'd25) begin
        sub_data_valid = (~cnt[0]) & (cnt > 'd0);
        sub_data_in_a = C_pre;
        sub_data_in_b = {1'b0,products_z_y};//Make it 64 bits
    end else begin
        sub_data_valid = 1'b0;
        sub_data_in_a = 'b0;
        sub_data_in_b = 'b0;
    end
end 

//C_pre logics
always_comb begin
    C_pre = C[0];
    case (cnt)
         'd2: C_pre = C[1];
         'd3: C_pre = C[1];
         'd4: C_pre = C[2];
         'd5: C_pre = C[2];
         'd6: C_pre = C[3];
         'd7: C_pre = C[3];
         'd8: C_pre = C[4];
         'd9: C_pre = C[4];
         'd10: C_pre = C[5];
         'd11: C_pre = C[5];
         'd12: C_pre = C[6];
         'd13: C_pre = C[6];
         'd14: C_pre = C[7];
         'd15: C_pre = C[7];
         'd16: C_pre = C[8];
         'd17: C_pre = C[8];
         'd18: C_pre = C[9];
         'd19: C_pre = C[9];
         'd20: C_pre = C[10];
         'd21: C_pre = C[10];
         'd22: C_pre = C[11];
         'd23: C_pre = C[11];
         'd24: C_pre = C[12];
         'd25: C_pre = C[12];
         default: C_pre = 'x;
    endcase
end

//Instantiate the arithmetic models

MUL63 uMUL63 (
    .data_in_a(mul_data_in_a),
    .data_in_b(mul_data_in_b),
    .data_valid(mul_data_valid),
    .data_out_ab(mul_data_out_ab)
);

endmodule