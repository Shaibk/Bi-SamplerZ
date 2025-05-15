module flt272int (
    input  clk                      ,
    input  valid,
    input  logic [63:0] fpr_mu_l,
    input  logic [63:0] fpr_mu_r,
    input  logic [63:0] fpr_isigma,
    
    output logic [71:0] r_l,
    output logic [71:0] r_r,
    output logic [71:0] isigma,   //72bits precision
    output logic [63:0] int_mu_l   ,//IEEE 754 
    output logic [63:0] int_mu_r   //IEEE 754
);
//Intermediate
    logic [51:0] mu_l_frn, mu_r_frn, isigma_frn;//fractioinal part of fp
    logic [10:0]  mu_l_exp, mu_r_exp, isigma_exp;//exponent part of fp
    logic [71:0] isigma_cmp;
    logic [1:0] cnt;
    logic [51:0] mu_l_tmp, mu_r_tmp;
    logic [51:0] mul_tmp, mur_tmp;
//fractional part
    assign mu_l_frn   = fpr_mu_l[51:0];
    assign mu_r_frn   = fpr_mu_r[51:0];
    assign isigma_frn = fpr_isigma[51:0];
//exponent part
    assign mu_l_exp = fpr_mu_l[62:52]-11'd1023;//original exp of mu, they are positive.
    assign mu_r_exp = fpr_mu_r[62:52]-11'd1023;
    assign isigma_exp  = 11'd1022 - fpr_isigma[62:52];//absolute value of exp, because they are negative.
    
//cnt generation 0~2
    always_ff @(posedge clk) begin
        if(!valid)         cnt <= 2'b0;
        else if(cnt != 2'b10)  cnt <= cnt + 2'b1;
        else               cnt <= cnt;
    end
//72bits r generation
    always_ff @(posedge clk) begin 
        if(valid &&(cnt == 0)) begin
             mu_l_tmp <= mu_l_frn << mu_l_exp;
             mu_r_tmp <= mu_r_frn << mu_r_exp;  //get the fraction part
        end else if (cnt == 1) begin
            r_l <= {mu_l_tmp,20'b0};
            r_r <= {mu_r_tmp,20'b0};
        end else begin
            mu_l_tmp <= mu_l_tmp;
            mu_r_tmp <= mu_r_tmp;
        end
    end
//72bits isgima generation
assign isigma_cmp = {1'b1,isigma_frn,19'b0};//Add the ignore '1' with 2^72
    always_ff @(posedge clk) begin
        if(valid) begin
            isigma <= isigma_cmp >> isigma_exp;
        end else begin
            isigma <= isigma;
        end
    end
//int_mu_l, int_mu_r generation
assign int_mu_l = {1'b0,fpr_mu_l[62:52],mul_tmp};
assign int_mu_r = {1'b0,fpr_mu_r[62:52],mur_tmp};
    
    always_ff @(posedge clk) begin
        if(valid && (cnt == 0)) begin
            mul_tmp <= mu_l_frn >> (52-mu_l_exp);
            mur_tmp <= mu_r_frn >> (52-mu_r_exp);
        end else if (cnt == 1) begin
            mul_tmp <= mul_tmp << (52-mu_l_exp);
            mur_tmp <= mur_tmp << (52-mu_r_exp);
        end else begin
            mul_tmp <= mul_tmp;
            mur_tmp <= mur_tmp;
        end
    end

endmodule
