module nn(output reg signed[31:0] final_output,
	  output reg [2:0] ovf_fsm_stage, zero_fsm_stage,
	  output reg total_ovf, total_zero,
	  input signed[31:0] input_1, input_2,
	  input clk, resetn, enable
	  );

        //define 7 states to binary codes
	parameter deactivated_state = 3'b000;
	parameter loading_weights_biases = 3'b001;
	parameter data_preprocessing_layer = 3'b010;
	parameter input_layer = 3'b011;
	parameter output_layer = 3'b100;
	parameter data_postprocessing_layer = 3'b101;
	parameter idle_state = 3'b110;

	parameter alu_add = 4'b0100;
	parameter alu_mul = 4'b0110;
	parameter alu_asr = 4'b0010;
	parameter alu_asl = 4'b0011;

	reg [2:0] current_state, next_state;
	reg signed[31:0] inter_1, inter_2, inter_3, inter_4, inter_5;

	reg rf_write;
	reg [3:0] rf_wr_address1, rf_wr_address2;
	reg [31:0] rf_wr_data1, rf_wr_data2;
	reg [3:0] rf_rr1, rf_rr2, rf_rr3, rf_rr4;
	wire [31:0] rf_rd1, rf_rd2, rf_rd3, rf_rd4;

	regfile reg_f(
		  .readData1(rf_rd1),
		  .readData2(rf_rd2),
		  .readData3(rf_rd3),
		  .readData4(rf_rd4),
		  .writeData1(rf_wr_data1),
		  .writeData2(rf_wr_data2),
		  .readReg1(rf_rr1),
		  .readReg2(rf_rr2),
		  .readReg3(rf_rr3),
		  .readReg4(rf_rr4),
		  .writeReg1(rf_wr_address1),
		  .writeReg2(rf_wr_address2),
		  .clk(clk),
		  .resetn(resetn),
		  .write(rf_write)
	);

	reg [7:0] rom_address1, rom_address2;
	wire[31:0] rom_out1, rom_out2;
	reg[4:0] rom_counter;

	WEIGHT_BIAS_MEMORY rom(
			.clk(clk),
			.addr1(rom_address1),
			.addr2(rom_address2),
			.dout1(rom_out1),
			.dout2(rom_out2)
	);

	reg signed[31:0] alu1_op1, alu1_op2, alu2_op1, alu2_op2;
   	reg [3:0]  alu1_opcode, alu2_opcode;
	wire signed[31:0] alu1_res, alu2_res;
	wire alu1_ovf, alu2_ovf, alu1_zero, alu2_zero;

	alu alu_1(
		.zero(alu1_zero),
		.ovf(alu1_ovf),
		.result(alu1_res),
		.op1(alu1_op1),
		.op2(alu1_op2),
		.alu_op(alu1_opcode)
	);

	alu alu_2(
		.zero(alu2_zero),
		.ovf(alu2_ovf),
		.result(alu2_res),
		.op1(alu2_op1),
		.op2(alu2_op2),
		.alu_op(alu2_opcode)
	);

	reg signed[31:0] mac1_op1, mac1_op2, mac1_op3, mac2_op1, mac2_op2, mac2_op3;
	wire signed[31:0] mac1_res, mac2_res;
	wire mac1_ovf_mul, mac1_ovf_add, mac1_zero_mul, mac1_zero_add;
	wire mac2_ovf_mul, mac2_ovf_add, mac2_zero_mul, mac2_zero_add;

	mac_unit mac_1(
		  .total_result(mac1_res),
		  .zero_mul(mac1_zero_mul),
		  .zero_add(mac1_zero_add),
		  .ovf_mul(mac1_ovf_mul),
		  .ovf_add(mac1_ovf_add),
		  .op1(mac1_op1),
		  .op2(mac1_op2),
		  .op3(mac1_op3)
	);

	mac_unit mac_2(
		  .total_result(mac2_res),
		  .zero_mul(mac2_zero_mul),
		  .zero_add(mac2_zero_add),
		  .ovf_mul(mac2_ovf_mul),
		  .ovf_add(mac2_ovf_add),
		  .op1(mac2_op1),
		  .op2(mac2_op2),
		  .op3(mac2_op3)
	);

	always @(posedge clk or negedge resetn) //asynchronous RESET
	  begin : STATE_MEMORY
		if(!resetn)begin                   //active low RESET
			current_state <= deactivated_state; //if RESET is activated go to deactivated_state
			rom_counter <= 0; //clear counter
			//clear registers from previous tests
			inter_1 <= 0;
			inter_2 <= 0;
			inter_3 <= 0;
			inter_4 <= 0;
			inter_5 <= 0;
			final_output <=0;
			/*clear ovf, zero and default values to 
			  stages to prepare for the next test*/
			total_ovf <= 0;           
        		total_zero <= 0;          
        		ovf_fsm_stage <= 3'b111;  
        		zero_fsm_stage <= 3'b111;
		end
		else begin
			current_state <= next_state;
			/* load 10 parameters, since we can only write 2 values to the register file per 
			   cycle we need 5 + 1 (delay from ROM) clock cycles to complete the loading stage */
			if(current_state == loading_weights_biases)begin
				if(rom_counter < 6)
					rom_counter <= rom_counter + 1;
			end 
			else
				rom_counter <= 0;

			case(current_state)
				data_preprocessing_layer : begin
					if(!total_ovf)begin
					// store alu_1 and alu_2 results in intermediate registers
						inter_1 <= alu1_res;
						inter_2 <= alu2_res;
					end
					
					if(alu1_ovf | alu2_ovf)begin
						total_ovf <= 1;
						ovf_fsm_stage <= data_preprocessing_layer;
						final_output <= 32'hFFFF_FFFF; // -1					
					end else
						total_ovf <= 0;
					
					if(alu1_zero | alu2_zero)begin
						total_zero <= 1;
						zero_fsm_stage <= data_preprocessing_layer;
					end else
						total_zero <= 0;
				end

				input_layer : begin
					if(!total_ovf)begin
					// store mac_1 and mac_2 results in intermediate registers
						inter_3 <= mac1_res;
						inter_4 <= mac2_res;
					end
					
					if(mac1_ovf_mul | mac1_ovf_add | mac2_ovf_mul |mac2_ovf_add)begin
						total_ovf <= 1;
						ovf_fsm_stage <= input_layer;
						final_output <= 32'hFFFF_FFFF; 
					end else 
						total_ovf <= 0;
					
					if(mac1_zero_mul | mac1_zero_add | mac2_zero_mul | mac2_zero_add)begin
						total_zero <= 1;
						zero_fsm_stage <= input_layer;
					end else 
						total_zero <= 0;
				end

				output_layer : begin
					if(!total_ovf)begin
					// store mac_2 result in intermediate register
						inter_5 <= mac2_res;
					end
	
					if(mac1_ovf_mul | mac1_ovf_add | mac2_ovf_mul |mac2_ovf_add)begin
						total_ovf <= 1;
						ovf_fsm_stage <= output_layer;
						final_output <= 32'hFFFF_FFFF; 
					end else
						total_ovf <= 0;
					
					if(mac1_zero_mul | mac1_zero_add | mac2_zero_mul | mac2_zero_add)begin
						total_zero <= 1;
						zero_fsm_stage <= output_layer;
					end else
						total_zero <= 0;
				end

				data_postprocessing_layer : begin
					if(alu1_ovf)begin
						total_ovf <= 1;
						ovf_fsm_stage <= data_postprocessing_layer;
						final_output <= 32'hFFFF_FFFF;
					end else begin
						total_ovf <= 0;
						final_output <= alu1_res;
					end

					if(alu1_zero)begin
						total_zero <= 1;
						zero_fsm_stage <= data_postprocessing_layer;
					end else
						total_zero <= 0;
						
				end

				idle_state : begin
				/*clear ovf, zero and default values to 
				  stages to prepare for the next test*/
					total_ovf <= 0;
					total_zero <= 0;
					ovf_fsm_stage <= 3'b111; 
					zero_fsm_stage <= 3'b111;
				end
			endcase
		end
	end

	always @(*)
	  begin : NEXT_STATE_LOGIC
		case(current_state)
		  	deactivated_state         : next_state = enable ? loading_weights_biases : deactivated_state;

		  	loading_weights_biases : begin
				if(rom_counter >= 6)
					next_state = data_preprocessing_layer;
				else
					next_state = loading_weights_biases;
		  	end 

		  	data_preprocessing_layer  : next_state = total_ovf ? idle_state : input_layer;

		  	input_layer               : next_state = total_ovf ? idle_state : output_layer;

		  	output_layer              : next_state = total_ovf ? idle_state : data_postprocessing_layer;

		  	data_postprocessing_layer : next_state = idle_state;

		  	idle_state                : next_state = enable ? data_preprocessing_layer : idle_state;

		  	default                   : next_state = deactivated_state;
		endcase
	  end

	always @(*)
	  begin : OUTPUT_LOGIC
		//default values to avoid latches
		rf_write = 0;
		rf_wr_address1 = 0;
		rf_wr_address2 = 0;
		rf_wr_data1 = 0;
		rf_wr_data2 = 0;

		rf_rr1 = 0;
		rf_rr2 = 0;
		rf_rr3 = 0;
		rf_rr4 = 0;

            	rom_address1 = 0;
		rom_address2 = 0;

 		alu1_op1 = 0;
		alu1_op2 = 0;
		alu1_opcode = 0;
		alu2_op1 = 0;
		alu2_op2 = 0;
		alu2_opcode = 0;

		mac1_op1 = 0;
		mac1_op2 = 0;
		mac1_op3 = 0;
		mac2_op1 = 0;
		mac2_op2 = 0;
		mac2_op3 = 0;

		case(current_state)
			loading_weights_biases : begin
				//request next data
				rom_address1 = ((rom_counter +1) << 3);
				rom_address2 = ((rom_counter +1) << 3) + 4;

				if(rom_counter > 0)begin
					rf_write = 1;
					//write requested data to register file
					rf_wr_address1 = ((rom_counter - 1) << 1) + 2;
					rf_wr_address2 = ((rom_counter - 1) << 1) + 3;
					rf_wr_data1 = rom_out1;
					rf_wr_data2 = rom_out2;
				end
			end
			data_preprocessing_layer : begin
				rf_rr1 = 4'd2;  //shift_bias_1
				rf_rr2 = 4'd3;  //shift_bias_2

				alu1_op1 = $signed(input_1);
				alu1_op2 = $signed(rf_rd1);
				alu1_opcode = alu_asr;

				alu2_op1 = $signed(input_2);
				alu2_op2 = $signed(rf_rd2);
				alu2_opcode = alu_asr;
			end
			input_layer : begin
				rf_rr1 = 4'd4; //weight_1
				rf_rr2 = 4'd5; //bias_1
				rf_rr3 = 4'd6; //weight_2
				rf_rr4 = 4'd7; //bias_2

				mac1_op1 = $signed(inter_1);
				mac1_op2 = $signed(rf_rd1);
				mac1_op3 = $signed(rf_rd2);

				mac2_op1 = $signed(inter_2);
				mac2_op2 = $signed(rf_rd3);
				mac2_op3 = $signed(rf_rd4);
			end
			output_layer : begin
				rf_rr1 = 4'd8; //weight_3
				rf_rr2 = 4'd9; //weight_4
				rf_rr3 = 4'd10; //bias_3

				mac1_op1 = $signed(inter_4);
				mac1_op2 = $signed(rf_rd2);
				mac1_op3 = $signed(rf_rd3);

				mac2_op1 = $signed(inter_3);
				mac2_op2 = $signed(rf_rd1);
				mac2_op3 = $signed(mac1_res);
			end
			data_postprocessing_layer : begin
				rf_rr1 = 4'd11;  //shift_bias_3

				alu1_op1 = $signed(inter_5);
				alu1_op2 = $signed(rf_rd1);
				alu1_opcode = alu_asl;
			end
		endcase
	  end
endmodule