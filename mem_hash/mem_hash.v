`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2023 02:08:56 PM
// Design Name: 
// Module Name: mem_hash
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

module mem_hash #(parameter N = 32, NUM_ITER = 256) (
	input clk,
	input rst_n,
	input in_valid,
	input in_ready,
	input [4:0] in_addr,
	input [N*32-1:0] mem_in,
	output [N*32-1:0] hash_out,
	output reg out_ready,
	output reg done
);

reg have_init;
reg [11:0] iter;
reg [N*32-1:0] state;
(* ram_style = "distributed" *)
reg [N*32-1:0] mem[N-1:0];

reg state_valid;
reg [N*32-1:0] sum_0;
reg [N*16-1:0] sum_1;
reg [N*8-1:0] sum_2;
reg [N*4-1:0] sum_3;
reg [N*2-1:0] sum_4;
reg [N*1-1:0] sum_5;
reg [5:0] sum_valid;

reg [9:0] dir;
reg dir_valid;

wire [4:0] bits;
wire [4:0] offset;
wire [4:0] mem_addr;

reg [N*32-1:0] mem_tmp;
reg [N*32-1:0] mem_tmp_1;
reg [N*32-1:0] mem_tmp_2;
reg [2:0] mem_tmp_valid;

assign bits = dir;
assign offset = (dir >> 5);
assign mem_addr = (have_init ? offset : in_addr);
assign hash_out = state;

function [31:0] rotl_32 (input [31:0] v, input [4:0] bits);
	begin
		rotl_32 = (v << bits) | (v >> (32 - bits));
	end
endfunction

integer i;

always @(posedge clk)
begin
	for(i = 0; i < 32; i = i + 1)
	begin
		sum_0[i*N+:N] <= rotl_32(state[i*N+:N], (iter + i) % 32);
	end
	for(i = 0; i < 16; i = i + 1)
	begin
		sum_1[i*N+:N] <= sum_0[i*N+:N] + sum_0[(16 + i)*N+:N];
	end
	for(i = 0; i < 8; i = i + 1)
	begin
		sum_2[i*N+:N] <= sum_1[i*N+:N] + sum_1[(8 + i)*N+:N];
	end
	for(i = 0; i < 4; i = i + 1)
	begin
		sum_3[i*N+:N] <= sum_2[i*N+:N] + sum_2[(4 + i)*N+:N];
	end
	for(i = 0; i < 2; i = i + 1)
	begin
		sum_4[i*N+:N] <= sum_3[i*N+:N] + sum_3[(2 + i)*N+:N];
	end
	
	sum_5 <= sum_4[0+:N] + sum_4[N+:N];
	
	if(state_valid) begin
		sum_valid <= 1;
		state_valid <= 0;
	end else begin
		sum_valid <= (sum_valid << 1);
	end
	
//	dir <= sum_5 % 1193;
	dir <= sum_5 - ((sum_5 * 3600140) >> 32);
	dir_valid <= sum_valid[5];
	
	for(i = 0; i < 32; i = i + 1)
	begin
		mem_tmp_1[i*N+:N] <= mem_tmp[((iter + i) % 32)*N+:N];
		
		mem_tmp_2[i*N+:N] <= rotl_32(mem_tmp_1[i*N+:N], bits);
	end
	
	if(mem_tmp_valid[2])
	begin
		for(i = 0; i < 32; i = i + 1)
		begin
			state[i*N+:N] <= state[i*N+:N] + (mem_tmp_2[i*N+:N] ^ sum_5);
		end
		if(iter == NUM_ITER - 1) begin
			done <= 1;
		end else begin
			state_valid <= 1;
			iter <= iter + 1;
		end
	end
	
	if(in_ready && done)
	begin
		done <= 0;
		out_ready <= 1;
		have_init <= 0;
	end
	
	if(!rst_n)
	begin
		done <= 0;
		out_ready <= 1;
		have_init <= 0;
	end
	else if(!have_init)
	begin
		if(in_valid && out_ready)
		begin
			if(in_addr == 31)
			begin
				iter <= 0;
				state_valid <= 1;
				sum_valid <= 0;
				dir_valid <= 0;
				mem_tmp_valid <= 0;
				state <= mem_in;
				have_init <= 1;
				out_ready <= 0;
			end
			mem[mem_addr] <= mem_in;
		end
	end
	else begin
		if(dir_valid)
		begin
			mem_tmp <= mem[mem_addr];
			mem_tmp_valid <= 1;
		end else begin
			mem_tmp_valid <= (mem_tmp_valid << 1);
		end
		if(state_valid && iter > 0)
		begin
			mem[mem_addr] <= mem_tmp ^ state;
		end
	end
end





endmodule
