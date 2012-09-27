module fpu_mul_tb;
   
reg CLK = 0;
reg RESET = 1;
reg EN = 1;

shortreal A, B;
//reg [31:0] A, B;
wire [31:0] Z;
logic [31:0] Zgood;

always
   begin
   #500.0ps;
   CLK = ~CLK;
   end

initial
   begin
   RESET = 1;
   #2000;
   RESET = 0;
   
   A = -5.6;
   B = -0.0125;
   
   //A = 2.0;
   //B = 2.0;
   
   Zgood = A + B;
      
   end

fpu_mul uut(.*); /*  input         CLK,
                     input         RESET,
                     input         EN,
                     input  [31:0] A,
                     input  [31:0] B,
                     output [31:0] Z ); */   
   
   
endmodule
