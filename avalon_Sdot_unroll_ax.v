module avalon_sdot_ax (clk,
                      reset,
                      address1,
                      writedata1,
                      write1,
                      read1,
                      chipselect1,
                      readdata1, //dma
		    waitrequest1,
                      address2,
                      writedata2,
                      write2,
                      read2,
                      chipselect2,
                      readdata2, //cpu
		    waitrequest2
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
input [23:0] address2 ;  // 3-bit address coming from the avalon system bus (need only 3 bits to address 8 memory-mapped registers)
input [31:0] writedata2 ; // 32 bit write data line
input  write2 ;	//write request
input read2 ;	//read request
input chipselect2;	//becomes 1 when this component is accessed by an Avalon transactions
output reg [31:0] readdata2 ;
output reg waitrequest2;
////reg var////
reg [31:0]sum;
reg [31:0]x[0:95];
reg [31:0]w[0:95];
reg [6:0]load_x_done;
reg [6:0]load_w_done;
reg [2:0]count;
reg [2:0] count_next;
wire [31:0]product_wire[0:95];
wire [31:0]sum_wire_first[0:47];
wire [31:0]sum_wire_second[0:23];
wire [31:0]sum_wire_third[0:11];
wire [31:0]sum_wire_fourth[0:5];
wire [31:0]sum_wire_fifth[0:2];
wire [31:0]sum_wire_sixth[0:1];


integer p = 0;

//generating  multipy blocks///
genvar i;
generate
for(i=0;i<96;i=i+1) begin: mul_blocks
fp_mul mul_unit(x[i],w[i],product_wire[i]);
end
endgenerate
//first layer add
genvar adder_1st_layer;
generate
for(adder_1st_layer=0;adder_1st_layer<48;adder_1st_layer=adder_1st_layer+2)begin:add_1st_layer
fp_adder_new add_unit(product_wire[adder_1st_layer],product_wire[adder_1st_layer+1],sum_wire_first[adder_1st_layer/2]);
end
endgenerate
//second layer add
genvar adder_2nd_layer;
generate
for(adder_2nd_layer=0;adder_2nd_layer<24;adder_2nd_layer=adder_2nd_layer+2)begin:add_2nd_layer
fp_adder_new add_unit(sum_wire_first[adder_2nd_layer],sum_wire_first[adder_2nd_layer+1],sum_wire_second[addaer_2nd_layer/2]);
end
endgenerate
//third layer add
genvar adder_3rd_layer;
generate
for(adder_3rd_layer=0;adder_3rd_layer<12;adder_3rd_layer=adder_3rd_layer+2)begin:add_3rd_layer
fp_adder_new add_unit(sum_wire_second[adder_3rd_layer],sum_wire_second[adder_3rd_layer+1],sum_wire_third[adder_3rd_layer/2]);
end
endgenerate
//fourth layer add
genvar adder_4th_layer;
generate
for(adder_4th_layer=0;adder_4th_layer<6;adder_4th_layer=adder_4th_layer+2)begin:add_4th_layer
fp_adder_new add_unit(sum_wire_third[adder_4th_layer],sum_wire_third[adder_4th_layer+1],sum_wire_fourth[adder_4th_layer/2]);
end
endgenerate
//fifth layer add
genvar adder_5th_layer;
generate
for(adder_5th_layer=0;adder_5th_layer<3;adder_5th_layer=adder_5th_layer+2)begin:add_5th_layer
fp_adder_new add_unit(sum_wire_fourth[adder_5th_layer],sum_wire_fourth[adder_5th_layer+1],sum_wire_fifth[adder_5th_layer/2]);
end
endgenerate
//sixth layer add
genvar adder_6th_layer;
generate
fp_adder_new add_unit(sum_wire_fifth[0],sum_wire_fifth[1],sum_wire_sixth[0]);
fp_adder_new add_unit_1(sum_wire_fifth[2],sum_wire_sixth[0],sum_wire_sixth[1]);
endgenerate


always@(posedge clk)
begin
	if(reset ==1)
	count=3'b0;
	else 
	count = count_next;
	case(count)
	3'b000 :begin
		  //load_done<=0;
		  for(p=0;p<96;p=p+1)
		  begin
		  	x[p]<=32'd0;
			w[p]<=32'd0;
		  end
		  readdata1<=32'd0;
		  readdata2<=32'd0;
		  waitrequest1<=0;
		  waitrequest2<=0;
		  load_x_done<=0;
		  load_w_done<=0;
		  count_next <= 3'b001;
		  end
	3'b001 : begin
		 if(chipselect1 == 1 && write1 == 1 && address1[7]==1)begin
		x[load_x_done]=readdata1;
		load_x_done = load_x_done+1;
		end
		else if(chipselect1 == 1 && write1 == 1 && address1[7] == 0)begin
		w[load_w_done]=readdata1;
		load_w_done = load_w_done +1;
		end
		 if(load_x_done == 7'd96 && load_w_done == 7'd96)
		 count_next = 3'b010;
		 else 
		 count_next = 3'b001; 
		 
		 end
	3'b010: begin
		sum<=sum_wire_sixth[1];
		if(chipselect2 == 1&& read2 == 1)
		readdata2<=sum;
		end
endcase

end


endmodule

// for pipleining this algorithm we need to think that when x[i],y[i] is
// available we should start x[i]*y[i] and not wait for x[i+1] and y[i+i] and
// also when we are doing sum[i+1] = sum[i]+product[i] we can calculate
// product[i+1]




