module fp_adder_new(
        operand1,
        operand2,
        result);
input  [31:0] operand1;
input  [31:0] operand2;
output reg [31:0] result;

wire [26:0] operand1_mantissa, operand2_mantissa;
reg [27:0] result_mantissa;
reg [7:0]result_exponent;
reg save;
reg result_sign;
wire [7:0] operand1_exponent, operand2_exponent;
wire operand1_sign,operand2_sign;
reg [7:0] diff_exponent;
wire flag0, flag1, flag2;
wire [7:0]flagdiff;
wire flag_exp_a;
wire [26:0] shifted_operand1,shifted_operand2;

assign operand1_mantissa = {1'b1,operand1[22 : 0], 3'd0};
assign operand2_mantissa = {1'b1,operand2[22 : 0], 3'd0};
assign operand1_exponent = operand1[30 : 23];
assign operand2_exponent = operand2[30 : 23];
assign operand1_sign = operand1[31];
assign operand2_sign = operand2[31];
assign flag0=(operand1==0 && operand2==0)?1:0;
assign flag1=(operand1==0)?1:0;
assign flag2=(operand2==0)?1:0;
assign flagdiff=(operand1_exponent>operand2_exponent)?(operand1_exponent-operand2_exponent):(operand2_exponent-operand1_exponent);
assign flag_exp_a=(operand1_exponent>operand2_exponent)?1:0;
assign shifted_operand1=(flag_exp_a==0)?(operand1_mantissa>>flagdiff):operand1_mantissa;
assign shifted_operand2=(flag_exp_a==1)?(operand2_mantissa>>flagdiff):operand2_mantissa;

always @(*)
begin
save=1'b0;
if(flag0==1)begin
result[31]=0;
result[30:23]=8'd0;
result[22:0]=28'd0;
save=1;
end

else if(flag1==1)begin
result[31]=operand2_sign;
result[30:23]=operand2_exponent;
result[22:0]=operand2_mantissa[25:3];
save=1;
end
else if(flag2==1)begin
result[31]=operand1_sign;
result[30:23]=operand1_exponent;
result[22:0]=operand1_mantissa[25:3];
save=1;
end

else if(operand1_sign==operand2_sign) begin
result_sign=operand1_sign;
result_exponent=((flag_exp_a==1)?operand1_exponent:operand2_exponent);
result_mantissa=shifted_operand1+shifted_operand2;

end
else if(shifted_operand1>shifted_operand2) begin
result_sign=operand1_sign;
result_exponent=((flag_exp_a==1)?operand1_exponent:operand2_exponent);
result_mantissa=shifted_operand1-shifted_operand2;

end
else if(shifted_operand2>shifted_operand1) begin
result_sign=operand2_sign;
result_exponent=((flag_exp_a==1)?operand1_exponent:operand2_exponent);
result_mantissa=shifted_operand2-shifted_operand1;

end
//z=(z_m[26])?{z_s,(z_e+1'b1),z_m[26:4]}:{z_s,z_e,z_m[26:4]};
if(save==0)begin
result[31]=result_sign;
if(result_mantissa[27:26]==2'b00 )begin
result[22:0]=result_mantissa[24:2];
result[30:23]=(result_exponent-1);
end
else if(result_mantissa[27:26]==2'b01)begin
result[22:0]=result_mantissa[25:3];
result[30:23]=(result_exponent);
end
else begin
result[30:23]=(result_mantissa[27:26]>=2'b10)?result_exponent+1'b1:result_exponent;
result[22:0]=(result_mantissa[27])? result_mantissa[26:4]: result_mantissa[27:5];
end


end

end
endmodule
