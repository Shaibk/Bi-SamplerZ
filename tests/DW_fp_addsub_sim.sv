// Test-only behavioral model. Not a DesignWare replacement or synthesis input.
// The directed tests use exact small integral binary64 values only.
module DW_fp_addsub #(parameter sig_width=52,exp_width=11,ieee_compliance=1)(
 input [63:0] a,b, input [2:0] rnd,input op, output [63:0] z,output [7:0] status
);
 assign z = $realtobits(op ? $bitstoreal(a)-$bitstoreal(b) : $bitstoreal(a)+$bitstoreal(b));
 assign status=0;
endmodule
