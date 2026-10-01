module alu(output reg zero, ovf,
	   output reg signed[31:0] result,
	   input signed [31:0] op1, op2,
	   input [3:0] alu_op
	   );

        //define 12 ALU operations to binary codes
	parameter [3:0] ALUOP_LSR = 4'b0000;    //Logic Shift Right
	parameter [3:0] ALUOP_LSL = 4'b0001;   //Logic Shift Left
	parameter [3:0] ALUOP_ASR = 4'b0010;  //Arithmetic Shift Right
	parameter [3:0] ALUOP_ASL = 4'b0011; //Arithmetic Shift Left

	parameter [3:0] ALUOP_ADD = 4'b0100;    //Addition
	parameter [3:0] ALUOP_SUB = 4'b0101;   //Substraction
	parameter [3:0] ALUOP_MULT = 4'b0110; //Multiplication

	parameter [3:0] ALUOP_LAND = 4'b1000;     //Logic AND
	parameter [3:0] ALUOP_LOR = 4'b1001;     //Logic OR
	parameter [3:0] ALUOP_LNOR = 4'b1010;   //Logic NOR
	parameter [3:0] ALUOP_LNAND = 4'b1011; //Logic NAND
	parameter [3:0] ALUOP_LXOR = 4'b1100; //Logic XOR

	reg signed [63:0] mult_full;

	always @(*) begin
	//set default values to avoid latches
		ovf = 0;
		result = 0;
		mult_full = 0;

		case(alu_op)

			ALUOP_LSR : result = op1 >> op2;
			ALUOP_LSL : result = op1 << op2;		
			ALUOP_ASR : result = op1 >>> op2;
			ALUOP_ASL : result = op1 <<< op2;

			ALUOP_ADD : begin
				result = op1 + op2;
				ovf = (op1[31] == op2[31]) && (result[31] != op1[31]); //check for overflow
			end
			ALUOP_SUB : begin
				result = op1 - op2;
				ovf = (op1[31] != op2[31]) && (result[31] != op1[31]); //check for overflow
			end
			ALUOP_MULT : begin
				mult_full = op1 * op2;
        			result = mult_full[31:0];
        			ovf = (mult_full[63:32] != {32{mult_full[31]}}); //check for overflow
			end

			ALUOP_LAND  : result = op1 & op2;
			ALUOP_LOR   : result = op1 | op2;
			ALUOP_LNOR  : result = ~(op1 | op2); 
			ALUOP_LNAND : result = ~(op1 & op2);
			ALUOP_LXOR  : result = op1 ^op2;

			default : result = 32'b0;
		endcase
		
		//set zero to 1 if the result is 0
		zero = (result == 0);
	end
endmodule