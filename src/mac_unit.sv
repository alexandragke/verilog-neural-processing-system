module mac_unit(output signed[31:0] total_result,
		output zero_mul, zero_add, ovf_mul, ovf_add,
		input signed[31:0] op1, op2, op3
		);

	wire signed[31:0] mul_result;

//first ALU for multiplication
	alu alu_mult(
		.zero(zero_mul),
	 	.ovf(ovf_mul),
		.result(mul_result),
		.op1(op1),
		.op2(op2),
		.alu_op(4'b0110)
	);

//second ALU for addition
	alu alu_add(
		.zero(zero_add),
	 	.ovf(ovf_add),
		.result(total_result),
		.op1(mul_result),
		.op2(op3),
		.alu_op(4'b0100)
	);
endmodule
