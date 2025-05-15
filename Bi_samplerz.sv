`include "falconsoar_pkg.sv"

module Bi_samplerz 
  import falconsoar_pkg::*;
(
    input clk,
    input reset,//Initial signal
    //Task 
    exec_operator_if.slave task_itf,//start port gives a pulse, must come after at least 90 cycles when reset.
    //read 
    mem_inst_if.master_rd  mem_rd,
    //write 
    mem_inst_if.master_wr  mem_wr

);
    localparam bit [3:0] SAMPLERZ_512   = 4'd1;  // Normal sampling operation in Falcon-512
    localparam bit [3:0] SAMPLERZ_1024  = 4'd2;  // Normal sampling operation in Falcon-1024
//Control signals
  //Shaking signals
    //pre_samp state
    logic pre_samp_valid;
    logic pre_samp_done;

    //basesampler
    logic basesampler_valid;
    logic basesampler_done;

    //Dependent Modules
    logic bef_loop_valid_l;
    logic bef_loop_done_l;

    //bef_loop state
    logic bef_loop_valid_r;
    logic bef_loop_done_r;

    logic for_loop_valid_l;
    logic for_loop_done_l;

    //for_loop state
    logic for_loop_valid_r;
    logic for_loop_done_r; 

    //CMP state
    logic cmp_valid_l;
    logic cmp_done_l;

    logic cmp_valid_r;
    logic cmp_done_r;
    
    //Final addition
    logic final_adder_valid;
    logic final_adder_done;
  //State mechine control signals
    logic assist_l;// The r datapath help the l side
    logic assist_r;// The l datapath help the r side

    //Final Status(l/r side finish the job)
    logic status_l;
    logic status_r;

//Data path
    //pre_samp
    logic [62:0] ccs_63;
    logic [71:0] r_l;
    logic [71:0] r_r;
    logic [71:0] sqr2_isigma;
    logic [63:0] int_mu_l;
    logic [63:0] int_mu_r;
    //bef_loop_l
    logic [4:0] z0_l,z0_l_reg;
    logic [62:0] z_63_l_reg;//buffer
    logic [5:0] s_6_l_reg;
    //bef_loop_r
    logic [4:0] z0_r,z0_r_reg;
    logic [62:0] z_63_r_reg;//buffer
    logic [5:0] s_6_r_reg;
    //for_loop_l
    logic [62:0] y_63_l;
    logic [62:0] z_63_l;
    logic [5:0] s_6_l;
    //for_loop_r
    logic [62:0] y_63_r;
    logic [62:0] z_63_r;
    logic [5:0] s_6_r;
    //CMP results
    logic cmp_rlt_r;
    logic cmp_rlt_l;
//Shared SUB64
    //SUB64_l
    logic [63:0] sub_data_in_a_l;
    logic [63:0] sub_data_in_b_l;
    logic [63:0] sub_data_out_l;
    logic sub_data_valid_l;
    //SUB64_r
    logic [63:0] sub_data_in_a_r;
    logic [63:0] sub_data_in_b_r;
    logic [63:0] sub_data_out_r;
    logic sub_data_valid_r;

    //SUB64 interface to for_loop_l
    logic [62:0] for_sub_data_out_l;
    logic [63:0] for_sub_data_in_a_l;
    logic [63:0] for_sub_data_in_b_l;
    logic for_sub_data_valid_l;

    //SUB64 interface to for_loop_r
    logic [62:0] for_sub_data_out_r;
    logic [63:0] for_sub_data_in_a_r;
    logic [63:0] for_sub_data_in_b_r;
    logic for_sub_data_valid_r;

    //SUB64 interface to CMP_l
    logic [63:0] cmp_sub_data_in_a_l;
    logic [63:0] cmp_sub_data_in_b_l;
    logic [63:0] cmp_sub_data_out_l;
    logic cmp_sub_data_valid_l;
    //SUB64 interface to CMP_r
    logic [63:0] cmp_sub_data_in_a_r;
    logic [63:0] cmp_sub_data_in_b_r;
    logic [63:0] cmp_sub_data_out_r;
    logic cmp_sub_data_valid_r;

  //SUB64 datapath connection(Shared module between cmp and for loop)
    //l
  always_comb begin
    // Default assignments to avoid latch inference
    for_sub_data_out_l   = '0;
    cmp_sub_data_out_l   = '0;
    sub_data_in_a_l      = '0;
    sub_data_in_b_l      = '0;
    sub_data_valid_l     = '0;

    if (for_loop_valid_l) begin
        for_sub_data_out_l = sub_data_out_l[62:0];
        sub_data_in_a_l    = for_sub_data_in_a_l;
        sub_data_in_b_l    = for_sub_data_in_b_l;
        sub_data_valid_l   = for_sub_data_valid_l;
    end else begin
        cmp_sub_data_out_l = sub_data_out_l;
        sub_data_in_a_l    = cmp_sub_data_in_a_l;
        sub_data_in_b_l    = cmp_sub_data_in_b_l;
        sub_data_valid_l   = cmp_sub_data_valid_l;
    end
end

    //r
  always_comb begin
    // Default assignments to avoid latch inference
    for_sub_data_out_r   = '0;
    cmp_sub_data_out_r   = '0;
    sub_data_in_a_r      = '0;
    sub_data_in_b_r      = '0;
    sub_data_valid_r     = '0;

    if (for_loop_valid_r) begin  
        for_sub_data_out_r = sub_data_out_r[62:0];
        sub_data_in_a_r    = for_sub_data_in_a_r;
        sub_data_in_b_r    = for_sub_data_in_b_r;
        sub_data_valid_r   = for_sub_data_valid_r;
    end else begin
        cmp_sub_data_out_r = sub_data_out_r;
        sub_data_in_a_r    = cmp_sub_data_in_a_r;
        sub_data_in_b_r    = cmp_sub_data_in_b_r;
        sub_data_valid_r   = cmp_sub_data_valid_r;
    end
end

//Shared MUL81
    //MUL81_l
    logic [80:0] MUL_data_in_a_l;
    logic [80:0] MUL_data_in_b_l;
    logic [80:0] MUL_data_out_l;
    logic MUL_data_valid_l;

    //MUL81_r
    logic [80:0] MUL_data_in_a_r;
    logic [80:0] MUL_data_in_b_r;
    logic [80:0] MUL_data_out_r;
    logic MUL_data_valid_r;

    //MUL81_l interface to pre_samp
    logic [80:0] pre_MUL_data_in_a_l;
    logic [80:0] pre_MUL_data_in_b_l;
    logic [80:0] pre_data_out_l;
    logic pre_MUL_data_valid_l;

    //MUL81_r interface to pre_samp
    logic [80:0] pre_MUL_data_in_a_r;
    logic [80:0] pre_MUL_data_in_b_r;
    logic [80:0] pre_data_out_r;
    logic pre_MUL_data_valid_r;

    //MUL81_l interface to bef_loop_l
    logic [80:0] bef_MUL_data_in_a_l;
    logic [80:0] bef_MUL_data_in_b_l;
    logic [80:0] bef_MUL_data_out_l;
    logic bef_MUL_data_valid_l;

    //MUL81_r interface to bef_loop_r
    logic [80:0] bef_MUL_data_in_a_r;
    logic [80:0] bef_MUL_data_in_b_r;
    logic [80:0] bef_MUL_data_out_r;
    logic bef_MUL_data_valid_r;

  //MUL81 datapath connection(Shared module between cmp and for loop)
    //MUL81_l(Shared between pre_samp and bef_loop_l)
  always_comb begin
  if (bef_loop_valid_l) begin
    bef_MUL_data_out_l = MUL_data_out_l;
    pre_data_out_l     = '0;
  end else begin
    bef_MUL_data_out_l = '0;
    pre_data_out_l     = MUL_data_out_l;
  end
  MUL_data_in_a_l     = bef_loop_valid_l ? bef_MUL_data_in_a_l : pre_MUL_data_in_a_l;
  MUL_data_in_b_l     = bef_loop_valid_l ? bef_MUL_data_in_b_l : pre_MUL_data_in_b_l;
  MUL_data_valid_l    = bef_loop_valid_l ? bef_MUL_data_valid_l : pre_MUL_data_valid_l;
end
 
    //MUL80_r(Shared between pre_samp and bef_loop_r)
  always_comb begin
    // Default assignments to avoid latches
    bef_MUL_data_out_r  = '0;
    pre_data_out_r      = '0;
    MUL_data_in_a_r     = '0;
    MUL_data_in_b_r     = '0;
    MUL_data_valid_r    = '0;

    if (bef_loop_valid_r) begin
        bef_MUL_data_out_r = MUL_data_out_r;
        MUL_data_in_a_r    = bef_MUL_data_in_a_r;
        MUL_data_in_b_r    = bef_MUL_data_in_b_r;  
        MUL_data_valid_r   = bef_MUL_data_valid_r;
    end else begin
        pre_data_out_r     = MUL_data_out_r;
        MUL_data_in_a_r    = pre_MUL_data_in_a_r;
        MUL_data_in_b_r    = pre_MUL_data_in_b_r;
        MUL_data_valid_r   = pre_MUL_data_valid_r;
    end
end

//RDM NUMBER LOGICS

  //refill_l
  logic refill_control_done_l;
  logic refill_rdm10_req_l;
  logic refill_rdm1_req_l;
  logic [79:0] refill_rdm10_l;
  logic [7:0] refill_rdm1_l;
  //refill_r
  logic refill_control_done_r;
  logic refill_rdm10_req_r;
  logic refill_rdm1_req_r;
  logic [79:0] refill_rdm10_r;
  logic [7:0] refill_rdm1_r;
  //chacha20
  logic restart_chacha20;  
  logic fetch_en, fetch_en_l, fetch_en_r;
  logic chacha20_done;
  logic [1023:0] prng_data;
  
  logic base_rdm_req;
  logic cmp_rdm_req_l;
  logic cmp_rdm_req_r;

  logic [143:0] base_rdm144;
  logic [7:0] cmp_rdm8_l, cmp_rdm8_r;
  logic [7:0] bef_rdm8_l, bef_rdm8_r;
  //rdm number request logic
  assign refill_rdm10_req_l = base_rdm_req;
  assign refill_rdm10_req_r = base_rdm_req;
  assign refill_rdm1_req_l = cmp_rdm_req_l;
  assign refill_rdm1_req_r = cmp_rdm_req_r;
  assign fetch_en = fetch_en_l || fetch_en_r;
  //rdm number connection logic

  always_ff @(posedge clk) if (base_rdm_req) base_rdm144 = {refill_rdm10_l[63:8],refill_rdm10_r[63:8]};
  always_ff @(posedge clk) if (base_rdm_req) bef_rdm8_l = refill_rdm10_l[7:0];
  always_ff @(posedge clk) if (base_rdm_req) bef_rdm8_r = refill_rdm10_r[7:0];
  always_ff @(posedge clk) if (cmp_rdm_req_l) cmp_rdm8_l = refill_rdm1_l;
  always_ff @(posedge clk) if (cmp_rdm_req_r) cmp_rdm8_r = refill_rdm1_r;

//Control logics
  //R/W logic
    logic [63:0] smp_l;
    logic [63:0] smp_r;
    wire                       mem_rd_chacha20_en   ; //
    wire [MEM_ADDR_BITS - 1:0] mem_rd_chacha20_addr ; //
    wire [   BANK_WIDTH - 1:0] mem_rd_chacha20_data ;
    wire        r_en_pre_samp   ;
    wire [MEM_ADDR_BITS - 1:0] r_addr_pre_samp ; 
    logic rdm_init;
    wire [3:0]  task_type  = task_itf.input_task[14:11];  //
    wire start = ((task_type == SAMPLERZ_512)   |
                  (task_type == SAMPLERZ_1024)  ) & task_itf.start;//Need to be a pulse
//task decoding
    wire        restart    = task_itf.input_task[15   ];  //
    wire [MEM_ADDR_BITS - 1:0] dst_addr   = task_itf.input_task[TASK_REDUCE_BW - 2*MEM_ADDR_BITS - 1:TASK_REDUCE_BW - 3*MEM_ADDR_BITS];  // This is for write dstination addr
    wire [MEM_ADDR_BITS - 1:0] src1_addr  = task_itf.input_task[TASK_REDUCE_BW - 1*MEM_ADDR_BITS - 1:TASK_REDUCE_BW - 2*MEM_ADDR_BITS];  // This is for sigma
    wire [MEM_ADDR_BITS - 1:0] src0_addr  = task_itf.input_task[TASK_REDUCE_BW - 0*MEM_ADDR_BITS - 1:TASK_REDUCE_BW - 1*MEM_ADDR_BITS];  // This is for mu and random
    assign task_itf.op_done = final_adder_done;

    wire [MEM_ADDR_BITS - 1:0] isigma_addr = src1_addr;
    wire [MEM_ADDR_BITS - 1:0] mu_addr     = src0_addr;
    wire [MEM_ADDR_BITS - 1:0] random_addr = 13'd130;
    
    always_ff @(posedge clk) begin 
        if(~reset)                   rdm_init <= 'd0 ;
        else if(start & restart)    rdm_init <= 'd1 ; 
        else if(refill_control_done_l & refill_control_done_r) rdm_init <= 'd0 ; 
    end

    assign mem_rd.en   = (rdm_init || ~reset)  ?  mem_rd_chacha20_en  :r_en_pre_samp;
    assign mem_rd.addr = (rdm_init || ~reset)  ?  mem_rd_chacha20_addr:r_addr_pre_samp;
    assign mem_rd_chacha20_data = mem_rd.data; 

    assign mem_wr.en   = final_adder_done;
    assign mem_wr.addr = dst_addr ;
    assign mem_wr.data = {128'h0,smp_l,smp_r};
  // FSM
  typedef enum logic [7:0] {
    INIT    = 'b00000001, // To generate two z0 and activate the chacha20 to fill the rdm buffer when reset.
    IDLE    = 'b00000010,//idle state
    PRE     = 'b00000100,
    NLOOP   = 'b00001000,
    SWITCHL = 'b00010000,//help the l side. R side switch to l value.(r side working)
    SWITCHR = 'b00100000,//help the r side. L side switch to r value.(l side working)
    ALOOP   = 'b01000000,
    F_ADD   = 'b10000000,//final addition
    NREG    = 'b00000000
  } state_t;

  state_t state, next_state, pre_state;
  // State transition: flip-flop to hold the current state
  always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
      state <= IDLE;
      pre_state <= IDLE;
    end
    else begin
      state <= next_state;
      pre_state <= state;
    end
  end
  // Next state logic
  always_comb begin
    case (state)
      INIT : next_state = basesampler_done ? PRE : INIT; 
      IDLE : next_state = (restart & start)? INIT : (start ? PRE : IDLE);
      PRE  : next_state = (bef_loop_done_l && bef_loop_done_r) ? NREG : PRE;
      NREG : next_state = (assist_l || assist_r)? ALOOP : NLOOP;
      NLOOP: begin 
        if (!(cmp_done_l && cmp_done_r)) begin
          next_state = NLOOP;
        end else if (cmp_rlt_l && cmp_rlt_r) begin
          next_state = F_ADD;
        end else if ((!cmp_rlt_l) && (!cmp_rlt_r)) begin
          next_state = NREG;
        end else begin
          next_state = (assist_l)? SWITCHL : SWITCHR;
        end
      end
      SWITCHL: next_state = (bef_loop_done_r)? NREG : SWITCHL;
      SWITCHR: next_state = (bef_loop_done_l)? NREG : SWITCHR;
      ALOOP : begin
        if (!(cmp_done_l && cmp_done_r)) begin
          next_state = ALOOP;
        end else if (cmp_rlt_l || cmp_rlt_r) begin
          next_state = F_ADD;
        end else begin
          next_state = NREG;
        end
      end
      F_ADD : next_state = (final_adder_done)? IDLE : F_ADD;
      default: next_state = IDLE;
    endcase
  end

  //Task control logics in each state
  always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
      assist_l <= 'b0;
      assist_r <= 'b0;
      status_l <= 'b0;
      status_r <= 'b0;
    end else begin
      case (state)
        INIT : begin
          assist_l <= 'b0;
          assist_r <= 'b0;
          status_l <= 'b0;
          status_r <= 'b0;
        end
        IDLE : begin
          assist_l <= 'b0;
          assist_r <= 'b0;
          status_l <= 'b0;
          status_r <= 'b0;
        end
        PRE : begin
          assist_l <= 'b0;
          assist_r <= 'b0;
          status_l <= 'b0;
          status_r <= 'b0;

        end
        NREG : begin
          assist_l <= assist_l;
          assist_r <= assist_r;
          status_l <= 'b0;
          status_r <= 'b0;
          s_6_l <= s_6_l_reg;//read the input
          s_6_r <= s_6_r_reg;
          z_63_l <= z_63_l_reg;
          z_63_r <= z_63_r_reg;
          z0_l_reg <= z0_l;
          z0_r_reg <= z0_r;

        end
        NLOOP : begin
          assist_l <= 'b0;
          assist_r <= 'b0;
          status_l <= 'b0;
          status_r <= 'b0;

        end
        SWITCHL : begin
          assist_l <= 'b1;
          assist_r <= 'b0;
          status_l <= 'b0;
          status_r <= 'b1;
        end
        SWITCHR : begin
          assist_l <= 'b0;
          assist_r <= 'b1;
          status_l <= 'b1;
          status_r <= 'b0;          
        end
        ALOOP : begin
          assist_l <= assist_l;
          assist_r <= assist_r;
          status_l <= status_l;
          status_r <= status_r;
        end
        F_ADD : begin
          assist_l <= 'b0;
          assist_r <= 'b0;
          status_l <= 'b1;
          status_r <= 'b1;
        end
        default: begin
          assist_l <= 'b0;
          assist_r <= 'b0;
          status_l <= 'b0;
          status_r <= 'b0;
      end
      endcase
    end
  end


//pre_samp_valid logic
always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
        pre_samp_valid <= 'b0;
    end else if ((state == PRE && pre_state == IDLE) || (state == PRE && pre_state == INIT)) begin
        pre_samp_valid <= 'b1;
    end else if (pre_samp_done) begin
        pre_samp_valid <= 'b0;
    end else begin
        pre_samp_valid <= pre_samp_valid;
    end
end

//basesampler_valid logic
always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
        basesampler_valid <= 'b0;
    end else if ((state == NLOOP && pre_state == NREG) || (state == ALOOP && pre_state == NREG) 
    || (state == INIT && refill_control_done_l && refill_control_done_r)) begin      //Adding INIT state, removing PRE state
        basesampler_valid <= 'b1;
    end else if (basesampler_done) begin
        basesampler_valid <= 'b0;
    end else begin
        basesampler_valid <= basesampler_valid;
    end
end

//for_loop_valid logic
always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
        for_loop_valid_l <= 'b0;
    end else if ((state == NLOOP && pre_state == NREG) || (state == ALOOP && pre_state == NREG)) begin
        for_loop_valid_l <= 'b1;
    end else if (for_loop_done_l) begin
        for_loop_valid_l <= 'b0;
    end else begin
        for_loop_valid_l <= for_loop_valid_l;
    end
end

always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
        for_loop_valid_r <= 'b0;
    end else if ((state == NLOOP && pre_state == NREG) || (state == ALOOP && pre_state == NREG)) begin
        for_loop_valid_r <= 'b1;
    end else if (for_loop_done_r) begin
        for_loop_valid_r <= 'b0;
    end else begin
        for_loop_valid_r <= for_loop_valid_r;
    end
end

//Final_adder logic
 assign final_adder_valid = status_l && status_r;

//bef_loop_valid_l logic
always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
        bef_loop_valid_l <= 'b0;
    end else if ((pre_samp_done && !assist_l) || (state == SWITCHR && pre_state == NLOOP) || ((state == NLOOP || state ==ALOOP) & basesampler_done)) begin//No sampler_done again
        bef_loop_valid_l <= 'b1;
    end else if (bef_loop_done_l) begin
        bef_loop_valid_l <= 'b0;
    end else begin
        bef_loop_valid_l <= bef_loop_valid_l;
    end
end

//bef_loop_valid_r logic
always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
        bef_loop_valid_r <= 'b0;
    end else if ((pre_samp_done && !assist_r) || (state == SWITCHL && pre_state == NLOOP) || ((state == NLOOP || state ==ALOOP) & basesampler_done)) begin//No sampler_done again
        bef_loop_valid_r <= 'b1;
    end else if (bef_loop_done_r) begin
        bef_loop_valid_r <= 'b0;
    end else begin
        bef_loop_valid_r <= bef_loop_valid_r;
    end
end

//cmp_valid_l logic 
always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
        cmp_valid_l <= 'b0;
    end else if (for_loop_done_l) begin
        cmp_valid_l <= 'b1;
    end else if (cmp_done_l) begin
        cmp_valid_l <= 'b0;
    end else begin
        cmp_valid_l <= cmp_valid_l;
    end
end

//cmp_valid_r logic
always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
        cmp_valid_r <= 'b0;
    end else if (for_loop_done_r) begin
        cmp_valid_r <= 'b1;
    end else if (cmp_done_r) begin
        cmp_valid_r <= 'b0;
    end else begin
        cmp_valid_r <= cmp_valid_r;
    end
end




pre_samp pre_samp_inst (
    .clk(clk),
    .rst_n(reset),
    .valid(pre_samp_valid),
    .task_type(task_type),
    .r_en           (   r_en_pre_samp       ), //o
    .r_addr         (   r_addr_pre_samp     ), //o [  9:0]
    .r_data         (   mem_rd.data         ), //i [511:0]
    .mu_addr        (   mu_addr             ), //i [  9:0]
    .isigma_addr    (   isigma_addr         ), 
    .ccs_63(ccs_63),
    .r_l(r_l),
    .r_r(r_r),
    .sqr2_isigma(sqr2_isigma),
    .int_mu_l(int_mu_l),
    .int_mu_r(int_mu_r),
    .MUL_data_out_l(pre_data_out_l),
    .MUL_data_valid_l(pre_MUL_data_valid_l),
    .MUL_data_in_a_l(pre_MUL_data_in_a_l),
    .MUL_data_in_b_l(pre_MUL_data_in_b_l),
    .MUL_data_out_r(pre_data_out_r),
    .MUL_data_valid_r(pre_MUL_data_valid_r),
    .MUL_data_in_a_r(pre_MUL_data_in_a_r),
    .MUL_data_in_b_r(pre_MUL_data_in_b_r),
    .done(pre_samp_done)
  );


bef_loop bef_loop_l (
    .clk(clk),
    .rst_n(reset),
    .valid(bef_loop_valid_l),
    .rdm8(bef_rdm8_l),
    .z0(z0_l),
    .r_72((assist_r == 'b0)? r_l : r_r),
    .sqr2_isigma(sqr2_isigma),
    .z_63(z_63_l_reg),
    .s_6(s_6_l_reg),
    .MUL_data_out(bef_MUL_data_out_l),
    .MUL_data_valid(bef_MUL_data_valid_l),
    .MUL_data_in_a(bef_MUL_data_in_a_l),
    .MUL_data_in_b(bef_MUL_data_in_b_l),
    .done(bef_loop_done_l)
  );

bef_loop bef_loop_r (
    .clk(clk),
    .rst_n(reset),
    .valid(bef_loop_valid_r),
    .rdm8(bef_rdm8_r),
    .z0(z0_r),
    .r_72((assist_l == 'b0)? r_r : r_l),
    .sqr2_isigma(sqr2_isigma),
    .z_63(z_63_r_reg),
    .s_6(s_6_r_reg),
    .MUL_data_out(bef_MUL_data_out_r),
    .MUL_data_valid(bef_MUL_data_valid_r),
    .MUL_data_in_a(bef_MUL_data_in_a_r),
    .MUL_data_in_b(bef_MUL_data_in_b_r),
    .done(bef_loop_done_r)
  );

for_loop for_loop_l (
    .clk    (clk),
    .rst_n  (reset),
    .valid  (for_loop_valid_l),
    .z_63   (z_63_l),
    .ccs_63 (ccs_63),
    .y_63   (y_63_l),
    .done   (for_loop_done_l),
    .sub_data_in_a(for_sub_data_in_a_l),
    .sub_data_in_b(for_sub_data_in_b_l),
    .sub_data_valid(for_sub_data_valid_l),
    .sub_data_out(for_sub_data_out_l)
  );
  
for_loop for_loop_r (
    .clk    (clk),
    .rst_n  (reset),
    .valid  (for_loop_valid_r),
    .z_63   (z_63_r),
    .ccs_63 (ccs_63),
    .y_63   (y_63_r),
    .done   (for_loop_done_r),
    .sub_data_in_a(for_sub_data_in_a_r),
    .sub_data_in_b(for_sub_data_in_b_r),
    .sub_data_valid(for_sub_data_valid_r),
    .sub_data_out(for_sub_data_out_r)
  );

basesampler basesampler_inst (
    .clk     (clk),
    .rst_n   (reset),
    .valid   (basesampler_valid),
    .rdm144  (base_rdm144),
    .rdm_req (base_rdm_req),
    .z0_l    (z0_l),
    .z0_r    (z0_r),
    .done    (basesampler_done)
  );

SUB64 SUB64_l (
    .data_in_a(sub_data_in_a_l),
    .data_in_b(sub_data_in_b_l),
    .data_valid(sub_data_valid_l),
    .data_out(sub_data_out_l)
);

SUB64 SUB64_r (
    .data_in_a(sub_data_in_a_r),
    .data_in_b(sub_data_in_b_r),
    .data_valid(sub_data_valid_r),
    .data_out(sub_data_out_r)
);
cmp cmp_l (
    .clk(clk),
    .rst_n(reset),
    .valid(cmp_valid_l),
    .done(cmp_done_l),
    .rdm8(cmp_rdm8_l),
    .rdm_req(cmp_rdm_req_l),
    .s_6(s_6_l),
    .y_63(y_63_l),
    .rlt(cmp_rlt_l),
    .sub_data_in_a(cmp_sub_data_in_a_l),
    .sub_data_in_b(cmp_sub_data_in_b_l),
    .sub_data_valid(cmp_sub_data_valid_l),
    .sub_data_out(cmp_sub_data_out_l)
  );
  
cmp cmp_r (
    .clk(clk),
    .rst_n(reset),
    .valid(cmp_valid_r),
    .done(cmp_done_r),
    .rdm8(cmp_rdm8_r),
    .rdm_req(cmp_rdm_req_r),
    .s_6(s_6_r),
    .y_63(y_63_r),
    .rlt(cmp_rlt_r),
    .sub_data_in_a(cmp_sub_data_in_a_r),
    .sub_data_in_b(cmp_sub_data_in_b_r),
    .sub_data_valid(cmp_sub_data_valid_r),
    .sub_data_out(cmp_sub_data_out_r)
  );
MUL81 MUL81_l ( 
    .MUL_data_in_a(MUL_data_in_a_l),
    .MUL_data_in_b(MUL_data_in_b_l),
    .MUL_data_out(MUL_data_out_l),
    .MUL_data_valid(MUL_data_valid_l)
  );
MUL81 MUL81_r ( 
    .MUL_data_in_a(MUL_data_in_a_r),
    .MUL_data_in_b(MUL_data_in_b_r),
    .MUL_data_out(MUL_data_out_r),
    .MUL_data_valid(MUL_data_valid_r)
  );
Fpr_adder fpr_adder_inst (
    .clk(clk),
    .rst_n(reset),
    .valid(final_adder_valid),
    .int_mu_l(int_mu_l),
    .int_mu_r(int_mu_r),
    .z0_l(z0_l_reg),
    .z0_r(z0_r_reg),
    .fpr_rlt_l(smp_l),
    .fpr_rlt_r(smp_r),
    .done(final_adder_done)
  );

refill_control refill_control_l (
  
    .clk(clk),
    .rst_n(reset),
    .start(chacha20_done), 
    .fetch_en(fetch_en_l), 
    .read_1byte(refill_rdm1_req_l), 
    .read_10byte(refill_rdm10_req_l), 
    .dout_10   (refill_rdm10_l),
    .dout_1    (refill_rdm1_l),
    .done(refill_control_done_l), 
    .r_data(prng_data[511:0])
);

refill_control refill_control_r (
  
    .clk(clk),
    .rst_n(reset),
    .start(chacha20_done), 
    .fetch_en(fetch_en_r), 
    .read_1byte(refill_rdm1_req_r), 
    .read_10byte(refill_rdm10_req_r), 
    .dout_10   (refill_rdm10_r),
    .dout_1    (refill_rdm1_r),
    .done(refill_control_done_r), 
    .r_data(prng_data[1023:512])
);

//Use same seeds or different seeds?
chacha20 chacha20_inst (
    .clk                 (clk                  ),  // Clock input
    .rst_n               (reset                ),  // Active low reset
    .start               ( start               ),  // Start signal
    .restart             (restart              ),  // Restart signal (new seed)
    .sign_init           (state == INIT        ),  // Sample initialization flag
    .fetch_en            (fetch_en             ),  // Fetch enable
    .done                (chacha20_done          ),  // Done signal output
    .src_addr            (random_addr          ),  // Source address for PRNG seed
    .mem_rd_chacha20_en  (mem_rd_chacha20_en   ),  // Read enable to memory
    .mem_rd_chacha20_addr(mem_rd_chacha20_addr ),  // Read address for memory
    .mem_rd_chacha20_data(mem_rd_chacha20_data ),  // Read data from memory
    .data_o              (prng_data            )   // Output 512 bits random data
);


endmodule
