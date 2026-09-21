module tb_flt2int72;
 logic clk=0,valid=0;logic [63:0] fpr_mu_l,fpr_mu_r,fpr_isigma;
 wire [71:0]r_l,r_r,isigma;wire [63:0]int_mu_l,int_mu_r;
 flt272int dut(.*);
 task tick;begin #5;clk=1;#1;clk=0;#4;end endtask
 task check(input real x,input real y,input real a,input real b,input logic[71:0]fa,input logic[71:0]fb);
 begin
  valid=0;tick();fpr_mu_l=$realtobits(x);fpr_mu_r=$realtobits(y);fpr_isigma=$realtobits(0.75);
  valid=1;tick();tick();tick();valid=0;tick();
  if(int_mu_l!==$realtobits(a)||int_mu_r!==$realtobits(b)||r_l!==fa||r_r!==fb)$fatal(1,"center decomposition %f %f",x,y);
  if(isigma!==72'hc00000000000000000)$fatal(1,"inverse sigma");
 end endtask
 initial begin
  tick();
  check(0.0,-0.0,0.0,0.0,0,0);
  check(0.25,-0.25,0.0,-1.0,72'h400000000000000000,72'hc00000000000000000);
  check(1.5,-1.5,1.0,-2.0,72'h800000000000000000,72'h800000000000000000);
  check(7.875,-7.875,7.0,-8.0,72'he00000000000000000,72'h200000000000000000);
  check(19.0,-19.0,19.0,-19.0,0,0);
  check(4503599627370496.0,-4503599627370496.0,4503599627370496.0,-4503599627370496.0,0,0);
  check(2.0**(-80),-(2.0**(-80)),0.0,-1.0,0,72'hffffffffffffffffff);
  $display("PASS center decomposition: signed, subunit, integral, large, and sub-grid inputs");$finish;
 end
endmodule
