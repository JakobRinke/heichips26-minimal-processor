module add8(
  input wire clk,
  input wire rst_n,
  input wire start,
  input wire [7:0] op1,
  input wire [7:0] op2,
  output reg [7:0] res,
  output reg done
);

always @(posedge clk) begin
  if (done == 1) done <= 0;
  if (rst_n == 0) begin
    done <= 0;
    res <= 0;
  end
  if(start==1) begin
    res <= op1 + op2;
    done <= 1;
  end
end


endmodule
