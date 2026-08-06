module add8(
	input reg clk,
	input reg rst_n,
	input reg start,
	input wire [7:0] op1,
	input wire [7:0] op2,
	output reg [7:0] res,
	output reg done);

	assign res=op1+op2;

	begin always @posedge(clk)
		done = 0;
		if (rst_n == 0) begin
			done = 0;
		end
		if(start==1) begin
			done = 1;
		end
	end	


endmodule
