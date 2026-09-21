module tb_fpr_adder;
 logic clk=0,rst_n=0,valid=0;
 logic [63:0] int_mu_l,int_mu_r;
 logic signed [5:0] z_l,z_r;
 wire done;wire [63:0] fpr_rlt_l,fpr_rlt_r;
 Fpr_adder dut(.*);
 task tick;begin #5;clk=1;#1;clk=0;#4;end endtask
 integer z,c,n;real center;
 initial begin
  tick();rst_n=1;
  for(c=0;c<3;c=c+1)for(z=-18;z<=19;z=z+1)begin
   center=(c==0)?-7.0:((c==1)?0.0:23.0);
   valid=0;tick();int_mu_l=$realtobits(center);int_mu_r=$realtobits(-center);
   z_l=6'(z);z_r=6'(1-z);valid=1;n=0;
   while(!done&&n<10)begin tick();n=n+1;end
   if(!done)$fatal(1,"adder timeout");
   if(fpr_rlt_l!==$realtobits(center+z))$fatal(1,"left signed output %d",z);
   if(fpr_rlt_r!==$realtobits(-center+1-z))$fatal(1,"right signed output %d",z);
   valid=0;tick();
  end
  $display("PASS Fpr_adder: 114 signed candidate/center pairs (test-only FP model)");$finish;
 end
endmodule
