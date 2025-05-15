module cmp (
    input clk,
    input rst_n,
    input logic valid,
    output logic done,
    //Make sure that the rdm is always ready when requested.
    output logic rdm_req,
    input logic [7:0] rdm8,
    //interface to for_loop
    input logic [5:0] s_6,
    input logic [62:0] y_63,
    output logic rlt,
    //connect to SUB64
    output logic [63:0] sub_data_in_a,
    output logic [63:0] sub_data_in_b,
    output logic sub_data_valid,
    input logic [63:0] sub_data_out
);
    logic [63:0] y_64;
    logic [3:0] cnt;
    logic [63:0] tmp;
    logic w_positive, w_negtive, w_equal;
    //datapath
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sub_data_valid <= 'b0;
        end else if (valid && (cnt == 'b1)) begin
            sub_data_valid <= 'b1;
        end else begin
            sub_data_valid <= 'b0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_64 <= 'b0;
        end else if (valid && (cnt == 'd0)) begin
            y_64 <= {y_63,1'b0};
        end else begin
            y_64 <= y_64;
        end
    end
    assign sub_data_in_a = y_64;//2*y_63
    assign sub_data_in_b = 64'h0000_0000_0000_0001; //1
//Done(pulse)
    always_ff @(posedge clk or negedge rst_n) begin//done
        if (!rst_n) begin
            done <= 'b0;
        end else if (valid && (cnt =='d10 || (cnt < 'd10 && cnt > 'd2 && ~w_equal))) begin//Either unequal in loop or reach the limit of the loop
            done <= 'b1;
        end else begin
            done <= 'b0;
        end
    end
//cnt
    always_ff @(posedge clk or negedge rst_n) begin//cnt
        if (!rst_n) begin
            cnt <= 'b0;
        end else if (valid) begin
            cnt <= ((cnt <= 'd2) || (w_equal && cnt <= 'd11))? cnt + 'd1 : cnt;
        end else begin
            cnt <= 'd0;
        end
    end
//Calculatioin of tmp
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    tmp <= 'b0;
  end else if (cnt == 'd2) begin
    tmp <= sub_data_out >> s_6;
  end
end
//cmp logics
always_comb begin
    w_equal = 1'b0;
    w_negtive = 1'bx;
    w_positive = 1'bx;
    case (cnt) 
        'd3: begin w_equal = rdm8 == tmp[8*7+:8]; w_positive = rdm8 > tmp[8*7+:8]; w_negtive = rdm8 < tmp[8*7+:8]; end
        'd4: begin w_equal = rdm8 == tmp[8*6+:8]; w_positive = rdm8 > tmp[8*6+:8]; w_negtive = rdm8 < tmp[8*6+:8]; end
        'd5: begin w_equal = rdm8 == tmp[8*5+:8]; w_positive = rdm8 > tmp[8*5+:8]; w_negtive = rdm8 < tmp[8*5+:8]; end
        'd6: begin w_equal = rdm8 == tmp[8*4+:8]; w_positive = rdm8 > tmp[8*4+:8]; w_negtive = rdm8 < tmp[8*4+:8]; end
        'd7: begin w_equal = rdm8 == tmp[8*3+:8]; w_positive = rdm8 > tmp[8*3+:8]; w_negtive = rdm8 < tmp[8*3+:8]; end
        'd8: begin w_equal = rdm8 == tmp[8*2+:8]; w_positive = rdm8 > tmp[8*2+:8]; w_negtive = rdm8 < tmp[8*2+:8]; end
        'd9: begin w_equal = rdm8 == tmp[8*1+:8]; w_positive = rdm8 > tmp[8*1+:8]; w_negtive = rdm8 < tmp[8*1+:8]; end
        'd10:begin w_equal = rdm8 == tmp[8*0+:8]; w_positive = rdm8 > tmp[8*0+:8]; w_negtive = rdm8 < tmp[8*0+:8]; end
    endcase
end
//rlt
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rlt <= 'b0;
    end else if (valid & (cnt > 'd2 & cnt < 'd11)) begin
        rlt <= w_negtive;
    end else begin
        rlt <= rlt;
    end
end
//rdm_req logics
assign rdm_req = valid & ~done & ((cnt == 'd2) || (cnt > 'd2 & cnt < 'd10 & w_equal));

endmodule