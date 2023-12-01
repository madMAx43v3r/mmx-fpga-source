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

(* use_dsp = "no" *)

module mem_hash #(parameter N = 32, M = 16, ID_WIDTH = 32, NUM_ITER = 256) (
	input clk,
	input rst_n,
	input in_valid,
	input in_ready,
	input [4:0] in_addr,
	input [ID_WIDTH-1:0] in_index,
	input [N*32-1:0] mem_in,
	output reg [N*32-1:0] out_hash,
	output reg [ID_WIDTH-1:0] out_index,
	output reg out_ready,
	output reg out_valid
);

localparam LANE_WIDTH = $clog2(M);
localparam ITER_WIDTH = $clog2(NUM_ITER);
localparam NUM_CYCLE = 13;

reg [M-1:0] have_init;
reg [ID_WIDTH-1:0] lane_index[M-1:0];
reg [ITER_WIDTH-1:0] iter[M-1:0];

reg init_flag;
reg [N*32-1:0] init_state;
reg [LANE_WIDTH-1:0] next;
reg [LANE_WIDTH-1:0] init_lane;

reg [NUM_CYCLE-1:0] flag;
reg [LANE_WIDTH-1:0] lane[NUM_CYCLE:0];
reg [N*32-1:0] state_buf[NUM_CYCLE-1:0];
reg [ITER_WIDTH-1:0] iter_buf[NUM_CYCLE-1:0];

(* ram_style = "distributed" *)
reg [N*32-1:0] state[M-1:0];
(* ram_style = "block" *)
reg [N*32-1:0] mem[N*M-1:0];

reg [4:0] shift_0[N-1:0];
reg [4:0] shift_10[N-1:0];

reg [N*32-1:0] sum_1;
reg [N*8-1:0]  sum_2;
reg [N*2-1:0]  sum_3;
reg [N*1-1:0]  sum[12:4];

reg [31:0] div_5[3:0];
reg [31:0] div_6;
reg [31:0] div_7;
reg [9:0] dir[12:8];

wire [4:0] bits_11;
wire [4:0] offset_8;
wire [4:0] offset_12;

reg [N*32-1:0] mem_tmp[12:9];
reg [N*32-1:0] mem_buf[12:11];
reg [N*32-1:0] state_new;

reg mem_write_flag;
reg [N*32-1:0] mem_write_data;
reg [LANE_WIDTH+9:0] mem_write_addr;

assign bits_11 = dir[11];
assign offset_8 = (dir[8] >> 5);
assign offset_12 = (dir[12] >> 5);

function [31:0] rotl_32 (input [31:0] v, input [4:0] bits);
	begin
		rotl_32 = (v << bits) | (v >> (32 - bits));
	end
endfunction

integer i;

always @(posedge clk)
begin
	out_ready <= !flag[11];
	
	mem_write_flag <= 0;
	
	if(in_ready && out_valid)
	begin
		out_valid <= 0;
	end
	
	for(i = 1; i <= NUM_CYCLE; i = i + 1)
	begin
		if(i < NUM_CYCLE) begin
			iter_buf[i] <= iter_buf[i-1];
			state_buf[i] <= state_buf[i-1];
		end
		lane[i] <= lane[i-1];
	end
	
	if(rst_n)
	begin
		lane[0] <= (lane[0] + 1) % M;
		flag <= (flag << 1) | have_init[lane[0]];
	end
	
	iter_buf[0] <= iter[lane[0]];
	state_buf[0] <= state[lane[0]];
	
	for(i = 0; i < 32; i = i + 1)
	begin
		shift_0[i] <= (iter[lane[0]] + i) % 32;
		sum_1[i*N+:N] <= rotl_32(state_buf[0][i*N+:N], shift_0[i]);
	end
	for(i = 0; i < 8; i = i + 1)
	begin
		sum_2[i*N+:N] <= sum_1[(i * 4 + 0)*N+:N] + sum_1[(i * 4 + 1)*N+:N] + sum_1[(i * 4 + 2)*N+:N] + sum_1[(i * 4 + 3)*N+:N];
	end
	for(i = 0; i < 2; i = i + 1)
	begin
		sum_3[i*N+:N] <= sum_2[(i * 4 + 0)*N+:N] + sum_2[(i * 4 + 1)*N+:N] + sum_2[(i * 4 + 2)*N+:N] + sum_2[(i * 4 + 3)*N+:N];
	end
	
	sum[4] <= sum_3[0+:N] + sum_3[N+:N];
	sum[5] <= sum[4];
	sum[6] <= sum[5];
	sum[7] <= sum[6];
	sum[8] <= sum[7];
	sum[9] <= sum[8];
	sum[10] <= sum[9];
	sum[11] <= sum[10];
	sum[12] <= sum[11];
	
//	dir <= sum % 1193;
	div_5[0] <= ({32'b0, sum[4]} * 22'b0000000000001100001100) >> 32;
	div_5[1] <= ({32'b0, sum[4]} * 22'b0000000010110000000000) >> 32;
	div_5[2] <= ({32'b0, sum[4]} * 22'b0000101100000000000000) >> 32;
	div_5[3] <= ({32'b0, sum[4]} * 22'b1101000000000000000000) >> 32;
	
	div_6    <= div_5[0] + div_5[1] + div_5[2] + div_5[3];
	div_7    <= div_6 * 3600140;
	
	dir[8]  <= sum[7] - div_7;
	dir[9] <= dir[8];
	dir[10] <= dir[9];
	dir[11] <= dir[10];
	dir[12] <= dir[11];
	
	if(flag[8])
	begin
		mem_tmp[9] <= mem[lane[9] * N + offset_8];
	end
	mem_tmp[10] <= mem_tmp[9];
	mem_buf[11] <= mem_tmp[10];
	mem_buf[12] <= mem_buf[11];
	
	for(i = 0; i < 32; i = i + 1)
	begin
		shift_10[i] <= (iter_buf[9] + i) % N;
		
		mem_tmp[11][i*N+:N] <= mem_tmp[10][shift_10[i]*N+:N];
		
		mem_tmp[12][i*N+:N] <= rotl_32(mem_tmp[11][i*N+:N], bits_11);
	end
	
	if(flag[12])
	begin
		for(i = 0; i < 32; i = i + 1)
		begin
			state_new[i*N+:N] = state_buf[12][i*N+:N] + (mem_tmp[12][i*N+:N] ^ sum[12]);
		end
		state[lane[13]] <= state_new;
		
		mem_write_flag <= 1;
		mem_write_addr <= lane[13] * N + offset_12;
		mem_write_data <= state_new ^ mem_buf[12];
		
		if(iter_buf[12] == NUM_ITER - 1)
		begin
			out_hash <= state_new;
			out_index <= lane_index[lane[13]];
			out_valid <= 1;
			have_init[lane[13]] <= 0;
		end
		else begin
			iter[lane[13]] <= iter_buf[12] + 1;
		end
	end
	else if(init_flag && init_lane == lane[13])
	begin
		init_flag <= 0;
		iter[lane[13]] <= 0;
		state[lane[13]] <= init_state;
		have_init[lane[13]] <= 1;
	end
	
	if(rst_n && mem_write_flag)
	begin
		mem[mem_write_addr] <= mem_write_data;
	end
	
	if(!rst_n)
	begin
		next <= 0;
		flag <= 0;
		lane[0] <= 0;
		init_flag <= 0;
		out_valid <= 0;
		out_ready <= 1;
		have_init <= 0;
	end
	else if(in_valid && out_ready)
	begin
		if(in_addr == 31)
		begin
			init_flag <= 1;
			init_lane <= next;
			init_state <= mem_in;
			lane_index[next] <= in_index;
			next <= (next + 1) % M;
		end
		mem_write_flag <= 1;
		mem_write_addr <= next * N + in_addr;
		mem_write_data <= mem_in;
	end
end





endmodule
