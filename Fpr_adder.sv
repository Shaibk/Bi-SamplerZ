module Fpr_adder (
    input  clk ,
    input logic valid,
    input logic rst_n,
    input  logic [63:0] int_mu_l,    //In IEEE 754
    input  logic [63:0] int_mu_r,
    input  logic signed [5:0] z_l, // Accepted signed proposal, -18..19.
    input  logic signed [5:0] z_r,
    output logic done,
    output logic [63:0] fpr_rlt_l   ,//In IEEE 754 
    output logic [63:0] fpr_rlt_r   
);
    logic [2:0] cnt;
    logic [63:0] fpr_z0_l, fpr_z0_r;
    logic [63:0] ieee_val_l, ieee_val_r;
    logic [63:0] a_fp64, b_fp64, z_fp64;

// Small-domain signed integer to binary64 conversion; exact for -18..19.
function automatic logic [63:0] encode_candidate(input logic signed [5:0] z);
    logic [5:0] magnitude;
    logic [51:0] fraction;
    logic [10:0] exponent_bits;
    integer leading;
    begin
        magnitude = z[5] ? -z : z;
        leading = 0;
        for (integer i=0; i<6; i=i+1) if (magnitude[i]) leading=i;
        fraction = ({46'b0,magnitude} << (52-leading));
        exponent_bits = 11'(1023+leading);
        encode_candidate = (magnitude == 0) ? 64'b0 : {z[5],exponent_bits,fraction};
    end
endfunction
always_comb begin
    ieee_val_l = encode_candidate(z_l);
    ieee_val_r = encode_candidate(z_r);
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
DW_fp_addsub #(52, 11, 1) u_fp_add_64 (
  .a(a_fp64),
  .b(b_fp64),
  .rnd(3'b000),
  .op(1'b0),
  .z(z_fp64),
  .status()
);




endmodule