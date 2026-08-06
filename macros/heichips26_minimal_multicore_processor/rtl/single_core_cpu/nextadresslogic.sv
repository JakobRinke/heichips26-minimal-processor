// Next Adress Logic tracking location in program flow
module nextadresslogic(
	input wire clk
	input wire rst_n,
	input wire [7:0] imm,
	input wire select_jump,
	input wire done_writing,
	output reg [7:0] current_pc,
	output reg done_pc);

	// Demux related
	wire [7:0] jump_by;
	assign jump_by = select_jump ? imm : 8'b00000001;
	
	// PC related
	wire done_add;
	wire [7:0] next_pc;

	// Adder related
	// remember: done signal of adder is deasserted within adder module
	add8 adder(.clk(clk),
		.rst_n(rst_n),
        	.start(done_writing),
        	.op1(jump_by),
        	.op2(current_pc),
        	.res(next_pc),
        	.done(done_add));
	

	always @(posedge clk) begin
		if (done_pc == 1) done_pc <= 0;
		if(rst_n == 0) begin
			current_pc <= 8'b0;
      			done_pc <= 0;
		end
		if(done_add  == 1) begin
			current_pc <= next_pc;
			done_pc <= 1;
		end
		
	end

endmodule
