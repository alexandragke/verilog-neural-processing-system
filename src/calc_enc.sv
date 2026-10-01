module calc_enc(alu_op0, alu_op1, alu_op2, alu_op3, btnl, btnr, btnd);
	output wire alu_op0, alu_op1, alu_op2, alu_op3;
	input wire btnl, btnr, btnd;

	wire m0, m1, m2, m3, m4, m5, m6, m7, m8;
	wire y0, y1, y2, y3, y4, y5;
	wire A0, A1, A2, A3;

        //generate alu_op0
	not(m0, btnl);
	and(m1, btnl, btnr);
	not(m2, btnd);
	and(y0, m0, btnd);
	and(y1, m1, m2);
	or(A0, y0, y1);
	assign alu_op0 = A0;

	//generate alu_op1
	not(m3, btnr);
	not(m4, btnd);
	or(y2, m3, m4);
	and(A1, btnl, y2);
	assign alu_op1 = A1;

	//generate alu_op2
	not(m5, btnl);
	xor(m6, btnr, btnd);
	and(y3, m5, btnr);
	not(y4, m6);
	and(y5, btnl, y4);
	or(A2, y3, y5);
	assign alu_op2 = A2;

	//generate alu_op3
	and(m7, btnl, btnr);
	and(m8, btnl, btnd);
	or(A3, m7, m8);
	assign alu_op3 = A3;

endmodule