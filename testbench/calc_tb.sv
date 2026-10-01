`timescale 1ns/1ps
 
module testbench();
	reg clk, btnc, btnac, btnl, btnr, btnd;
	reg [15:0] sw;
	wire [15:0] led;

	calc dut(
		.led(led),
		.clk(clk),
		.btnc(btnc),
		.btnac(btnac),
		.btnl(btnl),
		.btnr(btnr),
		.btnd(btnd),
		.sw(sw)
	);

	reg btnl_val [0:7];
	reg btnr_val [0:7];
	reg btnd_val [0:7];

	reg [15:0] switches [0:7];
	reg [15:0] exp_val [0:7];
	
	initial begin
		//set values for testing
		btnl_val[0] = 0; btnr_val[0] = 1; btnd_val[0] = 0;
		btnl_val[1] = 1; btnr_val[1] = 1; btnd_val[1] = 1;
		btnl_val[2] = 0; btnr_val[2] = 0; btnd_val[2] = 0;
		btnl_val[3] = 1; btnr_val[3] = 0; btnd_val[3] = 1;
		btnl_val[4] = 1; btnr_val[4] = 0; btnd_val[4] = 0;
		btnl_val[5] = 0; btnr_val[5] = 0; btnd_val[5] = 1;
		btnl_val[6] = 1; btnr_val[6] = 1; btnd_val[6] = 0;
		btnl_val[7] = 0; btnr_val[7] = 1; btnd_val[7] = 1;

        	//initialize switches and expected values
		switches[0] = 16'h285A; exp_val[0] = 16'h285A; 
		switches[1] = 16'h04C8; exp_val[1] = 16'h2C92;
		switches[2] = 16'h0005; exp_val[2] = 16'h0164;
		switches[3] = 16'hA085; exp_val[3] = 16'h5E1A;
		switches[4] = 16'h07FE; exp_val[4] = 16'h13CC;
		switches[5] = 16'h0004; exp_val[5] = 16'h3CC0;
		switches[6] = 16'hFA65; exp_val[6] = 16'hC7BF;
		switches[7] = 16'hB2E4; exp_val[7] = 16'h14DB;
	end

	initial begin
    		clk = 1'b0;
	end

	always begin
		#10 clk = ~clk;  // period 20ns, 50% duty cycle
	end
	
	integer i;

	initial begin
		btnc = 0; 
		btnac = 0; 
		btnl = 0; 
		btnr = 0; 
		btnd = 0; 
		sw = 0;

		//test RESET (btnac)
		btnac = 1; #20 btnac = 0;
		#20;

		if (led == 0)
        		$display("RESET Test: PASSED, led = %h", led);
    		else
        		$display("RESET Test: FAILED, led = %h", led);

		//test for every case
		for(i=0; i<8; i = i + 1)begin
			btnl = btnl_val[i];
			btnr = btnr_val[i];
			btnd = btnd_val[i];
			sw = switches[i];

			//btnc=1 to load new value to accumulator
			btnc = 1; 
			#30;
			btnc = 0;

			#10;

			if(led == exp_val[i])
				 $display("Test %0d : RIGHT", i);
			else
				 $display("Test %0d :WRONG", i);
		end
		$stop;
	end

endmodule