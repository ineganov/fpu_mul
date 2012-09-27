module fpu_mul( input         CLK,
                input         RESET,
                input         EN,
                input  [31:0] A,
                input  [31:0] B,
                output [31:0] Z );

//---------------Input stage-----------------//

wire        a_sign, b_sign;
wire  [7:0] a_expt, b_expt;
wire [22:0] a_sig_part, b_sig_part;

wire [31:0] abin = A; //simulation-only
wire [31:0] bbin = B; //simulation-only

ffd #(32) areg(CLK, RESET, EN, A, {a_sign, a_expt, a_sig_part});
ffd #(32) breg(CLK, RESET, EN, B, {b_sign, b_expt, b_sig_part});

wire [23:0] a_sigd  = {1'b1, a_sig_part};               
wire [23:0] b_sigd  = {1'b1, b_sig_part};               

wire zero = ({a_expt, a_sig_part} == '0) | 
            ({b_expt, b_sig_part} == '0) ;

//---------------ALU stage--------------------//

wire        new_sign  = a_sign ^ b_sign;
wire  [9:0] new_expt  = a_expt + b_expt - 7'd127;
wire [47:0] new_sigd  = a_sigd * b_sigd;

wire        zero_alu;
wire        sign_alu;
wire  [9:0] expt_alu;
wire [47:0] sigd_alu;

ffd #(60) cmp_reg(CLK, RESET, 1'b1, { zero,       // 1/ zero flag
                                      new_sign,   // 1/ new sign
                                      new_expt,   //10/ new expt
                                      new_sigd }, //48/ new significand
                                    { zero_alu,
                                      sign_alu,
                                      expt_alu,
                                      sigd_alu });


//--------------Rounding stage---------------//
wire zero_rnd = zero_alu;
wire sign_rnd = sign_alu;

wire  [9:0] expt_rnd = expt_alu;
wire [24:0] sigd_rnd;
round_mul the_roundm(sigd_alu, sigd_rnd );

//-------------Normalize stage---------------//
wire zero_nrm = zero_rnd;
wire sign_nrm = sign_rnd;

//simple addition-only normalize:
wire  [9:0] expt_nrm = sigd_rnd[24] ? ( expt_rnd + 1'b1 ) : expt_rnd;
wire [23:0] sigd_nrm = sigd_rnd[24] ? sigd_rnd[24:1] : sigd_rnd[23:0]; 

//----------------Regout stage---------------//
wire [30:0] ret_val;         //result module
wire ret_sign = sign_rnd;   //result sign

// sig_zero or expt_nrm[9] => 0 (expt < 0; or significand == 0)
wire ret_zero = expt_nrm[9] | zero_rnd;

// expt_nrm[9:8] == 2'b01 => inf (expt > +127)
wire ret_inf = (expt_nrm[9:8] == 2'b01);

assign ret_val = ret_zero ? 31'd0          :
                  ret_inf ? {8'hFF, 23'h0} :
                            {expt_nrm[7:0], sigd_nrm[22:0]};

ffd #(32) zreg(CLK, RESET, 1'b1, {ret_sign, ret_val}, Z);

endmodule

//===========================================//
module round_mul( input  [47:0] S_IN,
                  output [24:0] S_OUT );

wire [22:0] rndbits = S_IN[22:0];

logic [24:0] new_sig;

always_comb
  if(rndbits[22])
    begin
    if(rndbits[21:0] == '0)                      //in a halfway case
      begin
      if(S_IN[23]) new_sig = S_IN[47:23] + 1'b1;  //round to
      else         new_sig = S_IN[47:23]; //nearest even
      end
    else new_sig = S_IN[47:23] + 1'b1;            //round up
    end
  else new_sig = S_IN[47:23];             //round down
              
assign S_OUT = new_sig;
endmodule
//===========================================//
