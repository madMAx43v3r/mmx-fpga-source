`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/02/2023 12:01:18 AM
// Design Name: 
// Module Name: chacha_block
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

module chacha_block #(parameter N = 32) (
	input clk,
	input clk_en,
	input  [(N*16)-1:0] in,
	output [(N*16)-1:0] out
);

wire [N-1:0] x [15:0];
wire [N-1:0] t [15:0];
wire [N-1:0] y [15:0];

genvar i;

for(i = 0; i < 16; i = i + 1)
begin
	assign x[i] = in[i*N+:N];
	assign out[i*N+:N] = y[i];
end

chacha_qr4 QR0 (clk, clk_en, x[0], x[4], x[8], x[12], t[0], t[4], t[8], t[12]);
chacha_qr4 QR1 (clk, clk_en, x[1], x[5], x[9], x[13], t[1], t[5], t[9], t[13]);
chacha_qr4 QR2 (clk, clk_en, x[2], x[6], x[10], x[14], t[2], t[6], t[10], t[14]);
chacha_qr4 QR3 (clk, clk_en, x[3], x[7], x[11], x[15], t[3], t[7], t[11], t[15]);

chacha_qr4 QR4 (clk, clk_en, t[0], t[5], t[10], t[15], y[0], y[5], y[10], y[15]);
chacha_qr4 QR5 (clk, clk_en, t[1], t[6], t[11], t[12], y[1], y[6], y[11], y[12]);
chacha_qr4 QR6 (clk, clk_en, t[2], t[7], t[8], t[13], y[2], y[7], y[8], y[13]);
chacha_qr4 QR7 (clk, clk_en, t[3], t[4], t[9], t[14], y[3], y[4], y[9], y[14]);

endmodule
