module tb_pair_result_bank;
    logic clk=0, rst_n=0, clear=0, round_start=0, round_active=0;
    logic assist_l=0, assist_r=0, done_l=0, done_r=0, accept_l=0, accept_r=0;
    logic signed [5:0] candidate_l=-7, candidate_r=19;
    wire round_complete, round_accept_l, round_accept_r, valid_l, valid_r;
    wire signed [5:0] result_l,result_r;
    pair_result_bank dut(.*);
    task tick; begin #5;clk=1;#1;clk=0;#4;end endtask
    task begin_pair;
      begin clear=1;round_active=0;assist_l=0;assist_r=0;tick();clear=0;end
    endtask
    task run_round(input bit a,input bit b,input integer delay_side);
      begin
        done_l=0;done_r=0;round_start=1;round_active=0;tick();round_start=0;round_active=1;
        accept_l=a;accept_r=b;
        if(delay_side==0) begin done_l=1;done_r=1;tick();end
        else if(delay_side==1) begin
          done_l=1;tick();done_l=0;accept_l=!a;tick();done_r=1;tick();
        end else begin
          done_r=1;tick();done_r=0;accept_r=!b;tick();done_l=1;tick();
        end
        done_l=0;done_r=0;round_active=0;
      end
    endtask
    integer a,b,d,k;
    initial begin
      tick();rst_n=1;
      for(d=0;d<3;d=d+1)for(a=0;a<2;a=a+1)for(b=0;b<2;b=b+1)begin
        begin_pair();candidate_l=-7;candidate_r=19;run_round(a,b,d);
        if(valid_l!==1'(a)||valid_r!==1'(b))$fatal(1,"normal valid flags");
        if(a&&result_l!==-6'sd7)$fatal(1,"normal left result");
        if(b&&result_r!==6'sd19)$fatal(1,"normal right result");
      end
      for(k=0;k<2;k=k+1)for(d=0;d<3;d=d+1)for(a=0;a<2;a=a+1)for(b=0;b<2;b=b+1)begin
        begin_pair();candidate_l=-7;candidate_r=19;run_round(k==0,k==1,0);
        assist_r=(k==0);assist_l=(k==1);candidate_l=-18;candidate_r=3;run_round(a,b,d);
        if(k==0)begin
          if(!valid_l||result_l!==-6'sd7)$fatal(1,"stored left overwritten");
          if(valid_r!==1'(a||b))$fatal(1,"helper right valid");
          if((a||b)&&result_r!==(a ? -6'sd18 : 6'sd3))$fatal(1,"helper priority");
        end else begin
          if(!valid_r||result_r!==6'sd19)$fatal(1,"stored right overwritten");
          if(valid_l!==1'(a||b))$fatal(1,"helper left valid");
          if((a||b)&&result_l!==(a ? -6'sd18 : 6'sd3))$fatal(1,"helper priority");
        end
        if(!(a||b))begin run_round(0,1,d);if(!valid_l||!valid_r)$fatal(1,"retry completion");end
      end
      $display("PASS pair_result_bank: 12 normal and 24 helper cases, staggered done, frozen results, retry, fixed priority");$finish;
    end
endmodule
