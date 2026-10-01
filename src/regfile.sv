module regfile #(parameter DATAWIDTH = 32) (
	output wire [DATAWIDTH-1:0] readData1, readData2, readData3, readData4,
	input wire [DATAWIDTH-1:0] writeData1, writeData2,
	input wire [3:0] readReg1, readReg2, readReg3, readReg4, writeReg1, writeReg2,
	input wire clk, resetn, write
	);
 	 
	reg [DATAWIDTH-1:0] regs [0:15];
	integer i;

	always @(posedge clk or negedge resetn) begin //asynchronous RESET
		 if(!resetn)begin                    //active low RESET
			for(i=0; i<16; i=i+1)begin  //clear all registers when RESET
				regs[i] <= 0;
			end
		end
		else begin
			
			if(write)begin
				regs[writeReg1] <= writeData1;  //write writeData1 to register writeReg1
				regs[writeReg2] <= writeData2; // write writeData2 to register writeReg2
			end
		end
	end

	//prioritize writeData
		assign readData1 = (write && writeReg1 == readReg1) ? writeData1 :
			           (write && writeReg2 == readReg1) ? writeData2 :
 			            regs[readReg1];

		assign readData2 = (write && writeReg1 == readReg2) ? writeData1 :
			    	   (write && writeReg2 == readReg2) ? writeData2 :
 			    	    regs[readReg2];

		assign readData3 = (write && writeReg1 == readReg3) ? writeData1 :
			    	   (write && writeReg2 == readReg3) ? writeData2 :
 			    	    regs[readReg3];

		assign readData4 = (write && writeReg1 == readReg4) ? writeData1 :
			    	   (write && writeReg2 == readReg4) ? writeData2 :
 			    	    regs[readReg4];

endmodule
