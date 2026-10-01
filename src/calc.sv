module calc(output  [15:0] led,
	    input clk, btnc, btnac, btnl, btnr, btnd,
	    input [15:0] sw
	    );

	reg signed [15:0] accumulator;
	wire signed [31:0] accumulator_ex;
	assign accumulator_ex = {{16{accumulator[15]}}, accumulator}; //sign extension

	wire [31:0] sw_ex;
	assign sw_ex = {{16{sw[15]}}, sw}; //sign extension

	wire [31:0] alu_result;
	wire [3:0] alu_op;

	alu u_alu(
		.zero(),
		.ovf(),
		.result(alu_result),
		.op1(accumulator_ex),
		.op2(sw_ex),
		.alu_op(alu_op)
	);

	calc_enc u_enc(
		.alu_op0(alu_op[0]),
		.alu_op1(alu_op[1]),
		.alu_op2(alu_op[2]),
		.alu_op3(alu_op[3]),
		.btnl(btnl),
		.btnr(btnr),
		.btnd(btnd)
	);
	
	always @(posedge clk) begin  //synchronous btnac and btnc
		if(btnac)
			accumulator <= 16'b0;
		else if(btnc)
			accumulator <= alu_result[15:0]; //take lower 16 bits of alu_result and store in accumulator
	end
	assign led = accumulator; //set led to accumulator value
endmodule