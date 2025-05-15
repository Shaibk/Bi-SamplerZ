module Fpr_adder (
    input  clk ,
    input logic valid,
    input logic rst_n,
    input  logic [63:0] int_mu_l,    //In IEEE 754
    input  logic [63:0] int_mu_r,
    input  logic [4:0] z0_l,         //5 bits binary integer.
    input  logic [4:0] z0_r,
    output logic done,
    output logic [63:0] fpr_rlt_l   ,//In IEEE 754 
    output logic [63:0] fpr_rlt_r   
);
    logic [2:0] cnt;
    logic [63:0] fpr_z0_l, fpr_z0_r;
    logic [63:0] ieee_val_l, ieee_val_r;
    logic [63:0] a_fp64, b_fp64, z_fp64;

always_comb begin
  case (z0_l)
    5'd0 : ieee_val_l = 64'h0000000000000000;
    5'd1 : ieee_val_l = 64'h3ff0000000000000;
    5'd2 : ieee_val_l = 64'h4000000000000000;
    5'd3 : ieee_val_l = 64'h4008000000000000;
    5'd4 : ieee_val_l = 64'h4010000000000000;
    5'd5 : ieee_val_l = 64'h4014000000000000;
    5'd6 : ieee_val_l = 64'h4018000000000000;
    5'd7 : ieee_val_l = 64'h401c000000000000;
    5'd8 : ieee_val_l = 64'h4020000000000000;
    5'd9 : ieee_val_l = 64'h4022000000000000;
    5'd10: ieee_val_l = 64'h4024000000000000;
    5'd11: ieee_val_l = 64'h4026000000000000;
    5'd12: ieee_val_l = 64'h4028000000000000;
    5'd13: ieee_val_l = 64'h402a000000000000;
    5'd14: ieee_val_l = 64'h402c000000000000;
    5'd15: ieee_val_l = 64'h402e000000000000;
    5'd16: ieee_val_l = 64'h4030000000000000;
    5'd17: ieee_val_l = 64'h4031000000000000;
    5'd18: ieee_val_l = 64'h4032000000000000;
    default: ieee_val_l = 64'h0;
  endcase

  case (z0_r)
    5'd0 : ieee_val_r = 64'h0000000000000000;
    5'd1 : ieee_val_r = 64'h3ff0000000000000;
    5'd2 : ieee_val_r = 64'h4000000000000000;
    5'd3 : ieee_val_r = 64'h4008000000000000;
    5'd4 : ieee_val_r = 64'h4010000000000000;
    5'd5 : ieee_val_r = 64'h4014000000000000;
    5'd6 : ieee_val_r = 64'h4018000000000000;
    5'd7 : ieee_val_r = 64'h401c000000000000;
    5'd8 : ieee_val_r = 64'h4020000000000000;
    5'd9 : ieee_val_r = 64'h4022000000000000;
    5'd10: ieee_val_r = 64'h4024000000000000;
    5'd11: ieee_val_r = 64'h4026000000000000;
    5'd12: ieee_val_r = 64'h4028000000000000;
    5'd13: ieee_val_r = 64'h402a000000000000;
    5'd14: ieee_val_r = 64'h402c000000000000;
    5'd15: ieee_val_r = 64'h402e000000000000;
    5'd16: ieee_val_r = 64'h4030000000000000;
    5'd17: ieee_val_r = 64'h4031000000000000;
    5'd18: ieee_val_r = 64'h4032000000000000;
    default: ieee_val_r = 64'h0;
  endcase
end

  
  //cnt logics
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt <= 'b0;
    end else if (valid) begin
      cnt <= (cnt < 'b100)? cnt + 'b01 : cnt;
    end else begin
      cnt <= 'b00;
    end
  end

  // Output assignment using LUT at the first cycle of the valid signal.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fpr_z0_l <= 'b0;
      fpr_z0_r <= 'b0;
    end else if (cnt == 2'b00 && valid) begin
      fpr_z0_l <= ieee_val_l;
      fpr_z0_r <= ieee_val_r;
    end else begin
      fpr_z0_l <= fpr_z0_l;
      fpr_z0_r <= fpr_z0_r;
    end
  end

  //Additon logics
always_comb begin
  a_fp64      = '0;
  b_fp64      = '0;
  case (cnt) 
    2'b10 : begin
      a_fp64    = fpr_z0_l;
      b_fp64    = int_mu_l;
    end
    2'b11 : begin
      a_fp64    = fpr_z0_r;
      b_fp64    = int_mu_r;
    end
  endcase
end
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fpr_rlt_l <= 'b0;
    end else if (cnt == 2'b10) begin
        fpr_rlt_l <= z_fp64;
    end else begin
        fpr_rlt_l <= fpr_rlt_l;
    end
end
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fpr_rlt_r <= 'b0;
    end else if (cnt == 2'b11) begin
        fpr_rlt_r <= z_fp64;
    end else begin
        fpr_rlt_r <= fpr_rlt_r;
    end
end


  //Done logics
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      done <= 'b0;
    end else if (cnt == 2'b11) begin
      done <= 'b1;
    end else begin
      done <= 'b0;
    end
  end


//Instansiate the fp adder
DW_fp_addsub u_fp_add_64 (
  .a(a_fp64),
  .b(b_fp64),
  .rnd(3'b000),
  .op(1'b0),
  .z(z_fp64),
  .status()
);




endmodule