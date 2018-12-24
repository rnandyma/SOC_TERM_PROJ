module fp_mul(operand1, operand2, result);
input[31:0] operand1;
input[31:0] operand2;
output [31:0]result;
wire [47:0] mantissa_product;
wire [47:0] mantissa_product_a;
wire [23:0] mantissa1;
wire [23:0] mantissa2;
wire sign_result;
wire [7:0] exp_result;
wire [22:0]mantissa_result;
wire flag;
//combinational logic
assign mantissa1={1'b1, operand1[22:0]};
assign mantissa2={1'b1, operand2[22:0]};
assign mantissa_product_a = mantissa1*mantissa2;
assign flag =(mantissa_product_a[47:46]>=2'b10)?1:0;
assign mantissa_product = (flag==1)?mantissa_product_a>>1:mantissa_product_a;
assign sign_result = operand1[31]^operand2[31];
assign mantissa_result = (mantissa_product[47:46]==2'b01)?mantissa_product[45:23]:mantissa_product[46:24];
assign exp_result = (flag==0)?operand1[30:23]+operand2[30:23]-8'd127:operand1[30:23]+operand2[30:23]-8'd127+1'b1;
assign result=(operand1==0 || operand2==0)?0:{sign_result,exp_result,mantissa_result};
endmodule
