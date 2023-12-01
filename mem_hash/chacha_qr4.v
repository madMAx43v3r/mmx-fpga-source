`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2023 11:42:07 PM
// Design Name: 
// Module Name: chacha_qr4
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module chacha_qr4 #(parameter N = 32) (
	input clk,
	input clk_en,
	input [N-1:0] a, b, c, d,
	output [N-1:0] a_out, b_out, c_out, d_out
);

reg [N-1:0] tmp_a [3:0];
reg [N-1:0] tmp_b [3:0];
reg [N-1:0] tmp_c [3:0];
reg [N-1:0] tmp_d [3:0];

assign a_out = tmp_a[3];
assign b_out = tmp_b[3];
assign c_out = tmp_c[3];
assign d_out = tmp_d[3];

integer i;
reg [N-1:0] tmp_add;
reg [N-1:0] tmp_xor;

always @(posedge clk)
begin
	if(clk_en)
	begin
		i = 0;
		tmp_add = a + b;
		tmp_xor = d ^ tmp_add;
		tmp_a[i] <= tmp_add;
		tmp_b[i] <= b;
		tmp_c[i] <= c;
		tmp_d[i] <= {tmp_xor[15:0], tmp_xor[31:16]};
		
		i = i + 1;
		tmp_add = tmp_c[i-1] + tmp_d[i-1];
		tmp_xor = tmp_b[i-1] ^ tmp_add;
		tmp_a[i] <= tmp_a[i-1];
		tmp_b[i] <= {tmp_xor[19:0], tmp_xor[31:20]};
		tmp_c[i] <= tmp_add;
		tmp_d[i] <= tmp_d[i-1];
		
		i = i + 1;
		tmp_add = tmp_a[i-1] + tmp_b[i-1];
		tmp_xor = tmp_d[i-1] ^ tmp_add;
		tmp_a[i] <= tmp_add;
		tmp_b[i] <= tmp_b[i-1];
		tmp_c[i] <= tmp_c[i-1];
		tmp_d[i] <= {tmp_xor[23:0], tmp_xor[31:24]};
		
		i = i + 1;
		tmp_add = tmp_c[i-1] + tmp_d[i-1];
		tmp_xor = tmp_b[i-1] ^ tmp_add;
		tmp_a[i] <= tmp_a[i-1];
		tmp_b[i] <= {tmp_xor[24:0], tmp_xor[31:25]};
		tmp_c[i] <= tmp_add;
		tmp_d[i] <= tmp_d[i-1];
	end
end

endmodule
