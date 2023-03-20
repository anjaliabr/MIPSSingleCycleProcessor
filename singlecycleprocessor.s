// Single Cycle MIPS Processor 
module mips( 
input logic clk, reset, 
input logic [31:0] instr, 
output logic [31:0] instr, 
output logic memwrite, 
output logic [31:0] aluout, writedata, 
output logic [31:0] readdate 
); 
logic memtoreg, alusrc, regdst, regwrite, jump, pcsrc, zero; 
logic [2:0] alucontrol; 
 
controller c(instr[31:26], instr[5:0], zero, memtoreg, memwrite, pcsrc, alusrc, regdst, regwrite, jump, alucontrol); 
datapath dp(clk, reset, memtoreg, pcsrc, alusrc, regdst, regwrite, jump, alucontrol, zero, pc, instr, aluout, writedata, readdata); 
endmodule 
 
// Controller unit 
module controller( 
input logic [5:0] op, funct, 
input logic zero, 
output logic memtoreg, memwrite, 
output logic pcsrc, alusrc, 
output logic regdst, regwrite, 
output logic jump, 
output logic [2:0] alucontrol 
); 
logic [1:0] aluop; 
logic branch; 
maindec md(op, memtoreg, memwrite, branch, alusrc, regdst, 
regwrite, jump, aluop); 
aludec ad(funct, aluop, alucontrol); 
 
assign pcsrc = branch & zero; 
endmodule 
 
// Main Decoder 
module maindec( 
input logic [5:0] op, 
output logic memtoreg, memwrite, 
output logic branch, alusrc, 
output logic regdst, regwrite, 
output logic jump, 
output logic [1:0] aluop 
); 
logic [8:0] controls; 
 
assign {regwrite, regdst, alusrc, branch, memwrite, memtoreg, jump, aluop} = controls; 
 
always_comb 
case(op) 
6’b000000: controls <= 9’b110000010; //RTYPE 
6’b100011: controls <= 9’b101001000; //LW 
6’b101011: controls <= 9’b001010000; //SW 
6’b000100: controls <= 9’b000100001; //BEQ 
6’b001000: controls <= 9’b101000000; //ADDI 
6’b000010: controls <= 9’b000000010; //J 
default: controls <= 9’bxxxxxxxxx; //illegal op 
endcase 
endmodule 
 
// ALU Decoder 
module aludec( 
input logic [5:0] funct, 
input logic [1:0] aluop, 
output logic [2:0] alucontrol 
); 
always_comb 
case(aluop) 
2’b00: alucontrol <= 3’b010; //ADD (for lw/sw/addi) 
2’b01: alucontrol <= 3’b110; //SUB (for beq) 
default: case(funct) //R-type instructions 
6’b100000: alucontrol <= 3’b010; //ADD 
6’b100010: alucontrol <= 3’b110; //SUB 
6’b100100: alucontrol <= 3’b000; //AND 
6’b100101: alucontrol <= 3’b001; //OR 
6’b101010: alucontrol <= 3’b111; //SLT 
default: alucontrol <= 3’bxxx; //??? 
endcase 
endcase 
endmodule 
 
// Datapath Unit 
module datapath( 
input logic clk, reset, 
input logic memtoreg, pcsrc, 
input logic alusrc, regdst, 
input logic regwrite, jump, 
input logic [2:0] alucontrol, 
input logic [31:0] instr, readdata, 
output logic zero, 
output logic [31:0] pc, 
output logic [31:0] aluout, writedata, 
}; 
logic [4:0] writereg; 
logic [31:0] pcnext, pcnextbr, pcplus4, pcbranch; 
logic [31:0] signimm, signimmsh; 
logic [31:0] srca, srcb; 
logic [31:0] result; 
 
// next PC logic 
flopr #(32) pcreg(clk, reset, pcnext, pc); 
adder pcadd1(pc, 32’b100, pcplus4); 
sl2 immsh(sigimm, signimmsh) ; 
adder pcadd2(pcplus4, signimmsh, pcbranch); 
mux2 #(32) pcbrmux(pcplus4, pcbranch, pcsrc, pcnextbr); 
mux2 #(32) pcmux(pcnextbr, {pcplus4[31:28], instr[25:0], 
2’b00}, jump, pcnext); 
 
//register file logic 
regfile rf(clk, regwrite, instr[25:21], instr[20:16], 
writereg, result, srca, writedata); 
mux2 #(5) wrmux(instr[20:16], instr[15:11], regdst, 
writereg); 
mux2 #(32) resmux(aluout, readdata, memtoreg, result); 
signext se(instr[15:0], signimm); 
 
// ALU LOGIC 
mux2 #(32) srcbmux(writedata, signimm, alusrc, srcb); 
alu alu(srca, srcb, alucontrol, aluout, zero); 
endmodule 
 
// Register File 
module regfile( 
input logic clk, 
input logic we3, 
input logic [4:0] ra1, ra2, wa3, 
input logic [31:0] wd3, 
output logic [31:0] rd1, rd2 
); 
logic [31:0] rf[31:0]; 
 
// three ported register file 
// read two ports combined 
// write third port on rising edge of clk 
// register 0 hardwired to 0 
 
always_ff@(posedge clk) 
if (we3) rf[wa3] <= wd3; 
 
assign rd1 = (ra1 != 0) ? rf[ra1] : 0; 
assign rd2 = (ra2 != 0) ? rf[ra2] : 0; 
endmodule 
 
// Adder 
module adder( 
input logic [31:0] a, b, 
output logic [31:0] y 
); 
assign y = a + b; 
endmodule 
 
// Left Shift logical unit 
module s12( 
input logic [31:0] a, 
output logic [31:0] y 
); 
// shift left by 2 
assign y = {a[29 :0], 2’b00) ; 
endmodule 
 
// Sign Extend Logic Unit 
module signext( 
input logic [15:0] a, 
output logic [31:0] y 
); 
assign y = {{16{a[15]}},a}; 
endmodule  
 
// Resettable Flip-Flop 
module flopr #(parameter WIDTH = 8) ( 
input logic clk, reset, 
input logic [WIDTH-1:0] d, 
output logic [WIDTH-1:0] q 
); 
always_ff@(posedge clk, posedge reset) 
if (reset) q <= 0; 
else q <= d; 
endmodule 
 
// 2:1 Multiplexer 
module mux2 #(parameter WIDTH = 8) ( 
input logic [WIDTH-1:0] d0, d1, 
input logic s, 
output logic [WIDTH-1:0] y 
); 
assign y = s ? d1 : d0; 
endmodule 
 
// ALU 
module alu( 
input logic [31:0] A, B, 
input logic [2:0] F, 
output logic [31:0] Y, 
output logic zero 
); 
reg [31:0] sum; 
reg [31:0] B0; 
 
assign B0 = F[2] ? ~B : B; 
assign sum = A + B0 + F[2]; 
 
// ALU operations 
always@(*) 
case(F[1:0]) 
2’b00: Y = A & B0; // logical AND 
2’b01: Y = A | B0; // logical OR 
2’b10: Y = sum; // ADD or SUB 
2’b11: Y = sum[31]; // SLT 
default: Y = 0; 
endcase 
 
assign zero = (Y == 32’b00); //checks whether Y is 0 
endmodule 
 
// Module call for the four seven-segment displays 
module display( 
input logic [31:0] a, 
output logic [6:0] HEX0, HEX1, HEX2, HEX3 
); 
seven_seg S0(a[3:0], HEX0); 
seven_seg S1(a[7:4], HEX1); 
seven_seg S2(a[11:8], HEX2); 
seven_seg S3(a[15:12], HEX3); 
endmodule 
 
// Seven-segment display 
module seven_seg( 
input [3:0] a, 
output reg [6:0] HEX0 // Seven Segment Digits 
); 
always 
case(a[3:0]) 
4’h0: HEX0 <= 7’b100_0000; //’0’ display 
4’h1: HEX0 <= 7’b111_1001; //’1’ display 
4’h2: HEX0 <= 7’b010_0100; //’2’ display 
4’h3: HEX0 <= 7’b011_0000; //’3’ display 
4’h4: HEX0 <= 7’b001_1001; //’4’ display 
4’h5: HEX0 <= 7’b001_0010; //’5’ display 
4’h6: HEX0 <= 7’b000_0010; //’6’ display 
4’h7: HEX0 <= 7’b111_1000; //’7’ display 
4’h8: HEX0 <= 7’b000_0000; //’8’ display 
4’h9: HEX0 <= 7’b001_1000; //’9’ display 
4’hA: HEX0 <= 7’b000_1000; //’A’ display 
4’hB: HEX0 <= 7’b000_0011; //’B’ display 
4’hC: HEX0 <= 7’b100_0110; //’C’ display 
4’hD: HEX0 <= 7’b100_0000; //’D’ display 
4’hE: HEX0 <= 7’b000_0110; //’E’ display 
4’hF: HEX0 <= 7’b000_1110; //’F’ display 
default: HEX0 <= 7’b111_1111; 
endcase 
endmodule 
 
