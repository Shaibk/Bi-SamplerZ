`include "sample_pkg.sv"
`include "falconsoar_pkg.sv"

import sample_pkg::*;
import falconsoar_pkg::*;
module pre_samp   
#(
parameter MIN_SIGMA_1024 = 73'h14c5c19990c80000000,
parameter MIN_SIGMA_512  = 73'h147201bf1f7a0000000//All with 2^72 Extension.
)
(
    input clk,
    input rst_n,
    input valid,
    input logic [3:0] task_type,//0-falcon512;1-falcon1024. Specified because the coeffients differs from task type.
//Receive the values directly.
    output                r_en              ,
    output logic [ MEM_ADDR_BITS - 1:0]  r_addr            ,
    input        [255:0]  r_data            , 
    input        [ MEM_ADDR_BITS - 1:0]  mu_addr           ,
    input        [ MEM_ADDR_BITS - 1:0]  isigma_addr       ,//The addr of 4 consecutive isigma are the same.

    output logic [62:0] ccs_63,
    output logic [71:0] r_l,
    output logic [71:0] r_r,
    output logic [71:0] sqr2_isigma,//Is 72 bits enough for precision? Or 144 bits?
    output logic [63:0] int_mu_l,
    output logic [63:0] int_mu_r,//For the final IEEE 754 addition  
//To share a MUL81 with other module, additional Inputs and outputs are required. ccs_72 and 2*sqr2_isigma.
    input logic [80:0] MUL_data_out_l,
    output       logic MUL_data_valid_l,
    output logic [80:0] MUL_data_in_a_l,
    output logic [80:0] MUL_data_in_b_l,
    input logic [80:0] MUL_data_out_r,
    output       logic MUL_data_valid_r,
    output logic [80:0] MUL_data_in_a_r,
    output logic [80:0] MUL_data_in_b_r,

    output logic done//Valid for 1 cycle
);

    logic [3:0] cnt;
    logic flt272int_valid;
    logic [71:0] isigma;
    logic [71:0] ccs_72;
    logic [63:0] fpr_isigma;
    logic [63:0] fpr_mu_l;
    logic [63:0] fpr_mu_r;
    logic [ 1:0] isigma_index;
//cnt logics
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <='d0;
        end else if (valid) begin
            cnt <= (cnt < 'd6 + SAMPLERZ_READ_DELAY)? cnt + 'd1 : cnt; 
        end else begin
            cnt <= 'd0;
        end
    end

assign r_en = ((cnt == 'd0) & valid) | (cnt == 'd1);

always_comb begin
        r_addr = 'x;
        case(cnt)
        'd0: r_addr = mu_addr;
        'd1: r_addr = isigma_addr;
        endcase
    end

always_ff @(posedge clk, negedge rst_n) begin
        if      (!rst_n)                           isigma_index <= 'd0                ;
        else if (cnt == (SAMPLERZ_READ_DELAY + 1)) isigma_index <= isigma_index + 'd1 ;
    end

always_ff @(posedge clk) if(cnt == (SAMPLERZ_READ_DELAY))       {fpr_mu_r,fpr_mu_l} <= r_data[127:0];
always_ff @(posedge clk) if(cnt == (SAMPLERZ_READ_DELAY + 1))   fpr_isigma          <= r_data[64*isigma_index+:64];

//Done logics
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done <= 'b0;
        end else if (cnt == 'd4 + SAMPLERZ_READ_DELAY) begin
            done <= 'b1;
        end else begin
            done <= 'b0;
        end
    end

// flt272int_valid Logics
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flt272int_valid <= 'd0;
        end else if (valid && (cnt > 'd1 + SAMPLERZ_READ_DELAY && cnt < 'd4 + SAMPLERZ_READ_DELAY)) begin         // From the read done to 2 cycles later.
            flt272int_valid <= 'd1;
        end else begin
                flt272int_valid <= 'd0;
            end
    end


//Multiplier Strobe Logics
    always_comb begin
        case(cnt)
        'd4+SAMPLERZ_READ_DELAY      : begin MUL_data_valid_l = 'd1; MUL_data_in_a_l = {9'b0,isigma}; MUL_data_in_b_l = {9'b0,isigma};; //Save a shifting logic.
                         MUL_data_valid_r = 'd1; MUL_data_in_a_r = {9'b0,isigma}; MUL_data_in_b_r = (task_type == 'd1)? {8'b0,MIN_SIGMA_512} : {8'b0,MIN_SIGMA_1024};end
        default : begin  MUL_data_valid_l = 'd0; MUL_data_in_a_l = 'd0; MUL_data_in_b_l = 'd0; MUL_data_valid_r = 'd0; MUL_data_in_a_r = 'd0; MUL_data_in_b_r = 'd0;end
        endcase
end

always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sqr2_isigma <= 'd0;
            ccs_72 <= 'd0;
        end else if (cnt == 'd4 + SAMPLERZ_READ_DELAY) begin
            sqr2_isigma <= {1'b0,MUL_data_out_l[71:1]};
            ccs_72 <= MUL_data_out_r[71:0];
        end else begin
            sqr2_isigma <= sqr2_isigma;
            ccs_72 <= ccs_72;
        end
end
//ccs_63 logics
assign ccs_63 = ccs_72[71:9];
//Submodule Instantiatioin
    flt272int u_flt272int (
        .clk(clk),
        .valid(flt272int_valid),
        .fpr_mu_l(fpr_mu_l),
        .fpr_mu_r(fpr_mu_r),
        .fpr_isigma(fpr_isigma),
        .isigma(isigma),
        .r_l(r_l),
        .r_r(r_r),
        .int_mu_l(int_mu_l),
        .int_mu_r(int_mu_r)
    );

endmodule