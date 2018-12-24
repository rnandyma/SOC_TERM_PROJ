///////////////// This is a simple component ///////////////////////////////
///////////////// that contains 8  memory-mapped 32 bit registers ////////////
////////////////// A 3-bit address is used to access the registers /////////////

module avalon_sdot_addr8bit (clk,
                      reset,
                      address,
                      writedata,
                      write,
                      read,
                      chipselect,
                      readdata, //cpu
		    waitrequest
                     	);

///////// AVALON-MM Interface signals
//
//as of now acc has 2 avalon slave interface. one for connecting to the cpu
//and other for connecting to the cpu. this can be reduced to one slave intf
//if dma only reads back the data.

input clk;   // this is the clock coming in from the avalon bus
input reset ; // reset from the avalon bus
input [7:0] address ;  // 3-bit address coming from the avalon system bus (need only 3 bits to address 8 memory-mapped registers)
input [31:0] writedata ; // 32 bit write data line
input  write ;	//write request
input read ;	//read request
input chipselect;	//becomes 1 when this component is accessed by an Avalon transactions
output reg [31:0] readdata ;
output reg waitrequest;
integer i = 0, j=0, reset_flag=0, loop1_flag=0, loop2_flag=0, loop3_flag=0;
reg load_done;


//we need array of regs each size of 32 bits for storing burst transfer values//
//reg[31:0]X_val[0:95];
//reg[31:0]Y_val[0:95];
reg [31:0]array[255:0];
reg [31:0] dataa;
reg[31:0] datab;
reg[31:0] product;
reg[31:0] sum;
wire[31:0] product_wire;
wire[31:0] sum_wire;
integer loop_index; // variable for all the loops

fp_mul mul_unit(dataa,datab,product_wire); // multiplier unit
fp_adder_new add_unit(sum,product,sum_wire); // adder unit

always@(posedge clk )
begin
	if(reset == 1)
	begin
		for( loop_index = 0; loop_index < 256; loop_index = loop_index + 1 ) begin 
			array [ loop_index ] <= 1 ;  
		end
	dataa<=0;
	datab<=0;
	product<=0;
	sum<=0;
	i=0;
        j=0;
	reset_flag=reset_flag+1;
	end
	else if (write & chipselect) 
	begin
	array[address]<=writedata;
	loop1_flag=loop1_flag+1;
	j =j+1;
	end
	else if(array[255] == 32'd1)
	begin
	loop2_flag=loop2_flag+1;
		if(i<96)
		begin
		dataa<=array[i];
		datab<=array[i+96];
		sum<=sum_wire;
		product<=product_wire;
		waitrequest <= 1'b1;
		i=i+1;
		end
		else
		begin
		waitrequest <= 1'b0;
		array[255] <= 32'd0;
		array[254] <= sum_wire;
		end
	end
	else if(read & chipselect & waitrequest == 0 && array[255] == 32'd0)
	begin
	readdata <= array[address];
	dataa<=0;
	datab<=0;
	product<=0;
	sum<=0;
	i=0;
	loop3_flag=loop3_flag+1;
	end
end	
endmodule
 
