`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2023 11:00:45 PM
// Design Name: 
// Module Name: gen_mem_array
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

module gen_mem_array #(parameter N = 32, M = 32, ID_WIDTH = 32) (
	input clk,
	input rst_n,
	input in_valid,
	input in_ready,
	input [(16*N)-1:0] key_in,
	input [ID_WIDTH-1:0] in_index,
	output reg [5:0] out_addr,
	output reg [(N*16)-1:0] out_data,
	output [ID_WIDTH-1:0] out_index,
	output reg out_valid,
	output reg out_ready
);

localparam NUM_CYCLE = 16 * 8;
localparam BUFFER_DEPTH = M * N * 2;

reg init_flag;
reg [NUM_CYCLE-1:0] flag;

wire [(N*16)-1:0] hash_init;
reg  [(N*16)-1:0] state_init;

wire clk_en;
wire [(N*16)-1:0] state [4:0];

reg buffer_init;
reg buffer_switch;
reg [ID_WIDTH-1:0] buffer_index[(M*2)-1:0];
reg [(N*16)-1:0] buffer [(BUFFER_DEPTH*2)-1:0];

chacha_block B0 (clk, clk_en, state[0], state[1]);
chacha_block B1 (clk, clk_en, state[1], state[2]);
chacha_block B2 (clk, clk_en, state[2], state[3]);
chacha_block B3 (clk, clk_en, state[3], state[4]);

assign clk_en = (buffer_init || in_valid);	// TODO: block when buffer full

assign out_flag = flag[NUM_CYCLE - 1];
assign index_fifo_read = clk_en && rst_n && out_flag;
assign index_fifo_write = clk_en && rst_n && in_valid && out_ready;

assign state[0] = (init_flag ? state_init : state[4]);

assign hash_init[0*N+:N]  = 32'h428a2f98;
assign hash_init[1*N+:N]  = 32'h71374491;
assign hash_init[2*N+:N]  = 32'hb5c0fbcf;
assign hash_init[3*N+:N]  = 32'he9b5dba5;
assign hash_init[4*N+:N]  = 32'h3956c25b;
assign hash_init[5*N+:N]  = 32'h59f111f1;
assign hash_init[6*N+:N]  = 32'h923f82a4;
assign hash_init[7*N+:N]  = 32'hab1c5ed5;
assign hash_init[8*N+:N]  = 32'hd807aa98;
assign hash_init[9*N+:N]  = 32'h12835b01;
assign hash_init[10*N+:N] = 32'h243185be;
assign hash_init[11*N+:N] = 32'h550c7dc3;
assign hash_init[12*N+:N] = 32'h72be5d74;
assign hash_init[13*N+:N] = 32'h80deb1fe;
assign hash_init[14*N+:N] = 32'h9bdc06a7;
assign hash_init[15*N+:N] = 32'hc19bf174;

always @(posedge clk)
begin
	out_ready <= clk_en && !flag[31] && !flag[63] && !flag[95];
	
	state_init <= hash_init ^ key_in;
	
	if(in_ready)
	begin
		out_valid <= 0;
	end
	
	if(!rst_n)
	begin
		flag <= 0;
		init_flag <= 0;
		out_valid <= 0;
		out_ready <= 1;
	end
	else if(clk_en)
	begin
		init_flag <= in_valid && out_ready;
		
		flag <= (flag << 1) | init_flag;
		
		if(out_flag) begin
			out_data <= state[4];
		end
		out_valid <= out_flag;
	end
end




endmodule
