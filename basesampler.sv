module basesampler (
    input clk,
    input rst_n,
    input logic valid,
    input logic [143:0] rdm144,
    output logic rdm_req, //Request for random data
    output logic [4:0] z0_l,
    output logic [4:0] z0_r,
    output logic done//Valid for one cycle
);

localparam logic [71:0] RCDT [0:17] = '{72'd3024686241123004913666,72'd1564742784480091954050,72'd636254429462080897535,72'd199560484645026482916,72'd47667343854657281903,
72'd859590200636044063,72'd116329795344668388,72'd117656387352093658,72'd8867391802663976,72'd496969357462633,72'd20680885154299,72'd638331848991,72'd14602316184,72'd247426747,72'd3104126,72'd28824,72'd198,72'd1};

logic cmp[18:0];
logic sel [18:0];
logic [71:0] rdm72;
tri [4:0] z;
logic [2:0] cnt;

assign rdm72 = (cnt == 2) ? rdm144[143:72] : ((cnt == 3) ? rdm144[71:0] : 72'b0);
//cnt generation 0~3
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 'b0;
        end else if (valid && (cnt != 'b100+1)) begin
            cnt <= cnt + 'b1;
        end else if (!valid) begin
            cnt <= 'b0;
        end else begin
            cnt <= cnt;
        end
    end

//Done logics
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        done <= 'b0;
    end else if (valid && (cnt == 'b10+1)) begin
        done <= 'b1;
    end else begin
        done <= 'b0;
    end
end

//Generate comparison result 
always_comb begin
    for (int i = 0; i < 18; i++) begin
        cmp[i] = (rdm72 < RCDT[i]);
    end
    cmp[18] = 'b0; //Last element is always 1
end

//Generate 'NAND' logic
always_comb begin 
    sel[0] = ~cmp[0];
    for (int j = 0; j < 18; j++)begin
        sel[j+1] = cmp[j] & (~cmp[j+1]);
    end
end
//Generate tri-state net
genvar k;
generate 
    for (k = 0; k < (18 +1); k++) begin : tri_driver
        assign z = sel[k]? k : 'bz;
    end
endgenerate
//Generate z0 siganl
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        z0_l <= 5'b0;
        z0_r <= 5'b0;        
    end else if (valid) begin
        case (cnt)
        'd2 : begin z0_l <= z; z0_r <= z0_r; end
        'd3 : begin z0_l <= z0_l; z0_r <= z; end
        default : begin z0_l <= z0_l; z0_r <= z0_r; end
        endcase
    end else begin
        z0_l <= z0_l;
        z0_r <= z0_r;
    end
end
//rdm_req logic
assign rdm_req = valid && !done && (cnt == 'b1);
endmodule