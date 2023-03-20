// This is module to display the results on the Altera DE0 device 
module outputDisp( 
  input logic clk, 
  input logic reset, 
  output logic [6:0] HEX0, HEX1, HEX2, HEX3 
); 
  logic [31:0] writedata, dataadr; 
  logic memwrite; 
  logic [31:0] data; 

  //instantiate device 
  top dut(clk, reset, writedata, dataadr, memwrite); 

  // display the output on the seven-segment display 
  display D1(data, HEX0, HEX1, HEX2, HEX3); 

  // results 
  always@(posedge clk) 
  begin 
    data <= dataadr; 
  end 
endmodule 
