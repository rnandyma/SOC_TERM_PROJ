///////////////// This is a simple component ///////////////////////////////
///////////////// that contains 8  memory-mapped 32 bit registers ////////////
////////////////// A 3-bit address is used to access the registers /////////////

module avalon_sdot_ax (clk,
                      reset,
                      address1,
                      writedata1,
                      write1,
                      read1,
                      chipselect1,
                      readdata1, //cpu
		    waitrequest1
                     	);

///////// AVALON-MM Interface signals
//
//as of now acc has 2 avalon slave interface. one for connecting to the cpu
//and other for connecting to the cpu. this can be reduced to one slave intf
//if dma only reads back the data.

input clk;   // this is the clock coming in from the avalon bus
input reset ; // reset from the avalon bus
input [23:0] address1 ;  // 3-bit address coming from the avalon system bus (need only 3 bits to address 8 memory-mapped registers)
input [31:0] writedata1 ; // 32 bit write data line
input  write1 ;	//write request
input read1 ;	//read request
input chipselect1;	//becomes 1 when this component is accessed by an Avalon transactions
output reg [31:0] readdata1 ;
output reg waitrequest1;
/*input [23:0] address2 ;  // 3-bit address coming from the avalon system bus (need only 3 bits to address 8 memory-mapped registers)

input  write2 ;	//write request
input read2 ;	//read request
input chipselect2;	//becomes 1 when this component is accessed by an Avalon transactions
output reg [31:0] readdata2 ;
output reg waitrequest2;*/
integer i = 0;
reg load_done;


//we need array of regs each size of 32 bits for storing burst transfer values//
reg[31:0]X_val[0:95];
reg[31:0]Y_val[0:95];
reg[4:0] count;
reg[4:0] count_next;
reg [31:0] dataa;
reg[31:0] datab;
reg[31:0] product;
reg[31:0] sum;
wire[31:0] product_wire;
wire[31:0] sum_wire;
reg [4:0] check_count;

//change the state of the controller which is stored in the count
/*always@(posedge clk)
begin
	if(reset == 0)
	count<=5'd0;
	else
	count<=count_next;
end*/

fp_mul mul_unit(dataa,datab,product_wire);
fp_adder_new add_unit(sum,product,sum_wire);

always@(posedge clk )
begin
	if(reset == 1)
	begin
	count_next<=5'd0;
	count<=count_next;
	end
	else begin
	count<=count_next;
	case(count)
	5'b00000 :begin
		  load_done<=0;
		  for(i=0;i<96;i=i+1)
		  begin
		  	X_val[i]<=32'd0;
			Y_val[i]<=32'd0;
		  end
		  readdata1<=32'd0;
		 // readdata2<=32'd0;
		  waitrequest1<=0;
		 // waitrequest2<=0;
		  dataa<=0;
		  datab<=0;
		  product<=0;
		  sum<=0;
		  i=0;
		  count_next<=count+1;
		 end
	5'b00001:begin // get X values from DMA into X_val[]. Takes 96 cycles.
		if(write1 == 1) begin
		 X_val[i]<=writedata1;
			 if(i==95)
			 begin
			 	load_done<=1;
				i=0;
			//	waitrequest2<=1;
				count_next<=count+1; //96 values copied, now move to next state.
			 end
		else
			begin
				load_done<=0;
				i=i+1;
			//	waitrequest1<=1;
				count<=count_next;

			end
		end
		end
	5'b00010:begin // get Y values from DMA into Y_val[]. Takes 96 cycles.
		if(write1 == 1) begin
		 Y_val[i]<=writedata1;
		 if(i==32'd95)
			begin
			 	load_done<=1;
				i=0;
				count_next<=count+1; //96 values copied, now move to next state, multiplication
			end
			else
			begin
				load_done<=0;
				i=i+1;
				//waitrequest2<=1;
				count<=count_next;
			end
		end
		end
	5'b00011: begin // Multiplication state: multiply X_val[i] * Y_val[i]
			dataa<=X_val[i];
			datab<=Y_val[i];
			sum<=sum_wire;
			count_next <= count_next+1; // one product done, go to add state.			
			count <= count+1; // assign count directly count+1 else one cycle delay.
			waitrequest1<=1;
		  end
	5'b00100:begin // Addition state: assign sum_wire to sum reg.
			if(i!=32'd95) // until 96 MACs are done, keep moving between multiplication and addition states.
			begin
		        product <= product_wire;
			count_next <= count_next-1;
			count <= count-1;
			i = i+1;
			end
			else 
			begin
			count_next <= count+1; // go to final state
			end
		end
	5'b00101:begin // Assign final sum value
		//TODO: uncommment if condition after testing in questasim. if(read2 == 1 && chipselect2) begin
			sum<=sum_wire; //'h410a3d58
			waitrequest1<=0;	// inform cpu that readdata1 is valid
			count_next <= count;
			if(waitrequest1 == 0) begin
			readdata1 <= sum_wire; 
			end
			end
		// end
	endcase
	end
// keep one extra reg to keep data for checking if it is done or not then let
// the cpu read it.	
end
endmodule
 
