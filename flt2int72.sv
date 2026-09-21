// Binary64 center decomposition for finite inputs. The fractional result is
// rounded down to the prototype's 72-bit grid; this is not a conformance proof.
module flt272int (
    input logic clk, valid,
    input logic [63:0] fpr_mu_l, fpr_mu_r, fpr_isigma,
    output logic [71:0] r_l,r_r,isigma,
    output logic [63:0] int_mu_l,int_mu_r
);
    logic [1:0] cnt;
    logic [135:0] pending_l,pending_r;
    function automatic logic [135:0] decompose(input logic [63:0] x);
        logic [52:0] mantissa;
        logic [71:0] scaled;
        logic [63:0] integer_bits,magnitude_bits,mask;
        logic discarded,nonintegral;
        integer exponent_value,shift;
        begin
            exponent_value = (x[62:52]==0) ? -1022 : int'(x[62:52])-1023;
            mantissa = {x[62:52]!=0,x[51:0]};
            scaled=0;discarded=0;nonintegral=0;
            integer_bits=x;magnitude_bits={1'b0,x[62:0]};mask=0;
            if(exponent_value<52) begin
                shift=20+exponent_value;
                if(shift>=0) scaled=72'(mantissa)<<shift;
                else if(-shift>=53) begin scaled=0;discarded=(mantissa!=0);end
                else begin
                    scaled=72'(mantissa>>(-shift));
                    discarded=((mantissa & ((53'd1<<(-shift))-1))!=0);
                end
                if(exponent_value<0) begin
                    nonintegral=(mantissa!=0);
                    integer_bits=(x[63]&&nonintegral)?64'hbff0000000000000:64'b0;
                end else begin
                    mask=(64'd1<<(52-exponent_value))-1;
                    nonintegral=((magnitude_bits&mask)!=0);
                    magnitude_bits=magnitude_bits&~mask;
                    if(x[63]&&nonintegral) magnitude_bits=magnitude_bits+(64'd1<<(52-exponent_value));
                    integer_bits={x[63],magnitude_bits[62:0]};
                end
                if(x[63]&&nonintegral) scaled=~scaled+(discarded?72'd0:72'd1);
            end
            if(x[62:0]==0) integer_bits=64'b0;
            decompose={integer_bits,scaled};
        end
    endfunction
    function automatic logic [71:0] inverse_to_fixed(input logic [63:0] x);
        logic [135:0] parts;
        begin parts=decompose(x);inverse_to_fixed=parts[71:0];end
    endfunction
    always_ff @(posedge clk) begin
        if(!valid)cnt<=0;else if(cnt!=2)cnt<=cnt+1;
        if(valid&&cnt==0)begin pending_l<=decompose(fpr_mu_l);pending_r<=decompose(fpr_mu_r);end
        if(valid&&cnt==1)begin
            {int_mu_l,r_l}<=pending_l;{int_mu_r,r_r}<=pending_r;
        end
        // Falcon's inverse standard deviation is in (0,1).
        if(valid)isigma<=inverse_to_fixed(fpr_isigma);
    end
endmodule
