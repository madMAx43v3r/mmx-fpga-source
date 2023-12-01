`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/02/2023 12:08:27 AM
// Design Name: 
// Module Name: sync_fifo
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

module sync_fifo #(parameter WIDTH = 8, SIZE = 5, MARGIN = 0, BUFFER = 1, EOF = 0) (
	input clk, rst_n,
	input w_en, r_en,
	input eof_in,
	input [WIDTH-1:0] data_in,
	output reg [WIDTH-1:0] data_out,
	output reg [SIZE:0] count,
	output reg valid,
	output reg full,
	output reg empty,
	output reg eof
);

localparam DEPTH = (1 << SIZE);

(* ram_style = "distributed" *)
reg [WIDTH-1:0] fifo [DEPTH-1:0];

reg [SIZE-1:0] w_ptr, r_ptr;
reg eof_flag;

wire [SIZE:0] count_next;

assign full_max = count[SIZE];

assign r_exec = r_en && !empty;
assign w_exec = w_en && !eof && !full_max;

assign count_next = (count + w_exec) - r_exec;

always @(posedge clk)
begin
	if(!rst_n)
	begin
		eof <= 0;
		full <= (MARGIN >= DEPTH);
		empty <= 1;
		valid <= 0;
		w_ptr <= 0;
		r_ptr <= 0;
		count <= 0;
		data_out <= 0;
		eof_flag <= 0;
	end
	else begin
		valid <= r_exec;
		
		empty <= (count_next == 0);
		
		full <= (count_next >= DEPTH - MARGIN);
		
		count <= count_next;
		
		if(w_exec)
		begin
			fifo[w_ptr] <= data_in;
			w_ptr <= w_ptr + 1;
		end
		
		if(r_exec)
		begin
			data_out <= fifo[r_ptr];
			r_ptr <= r_ptr + 1;
		end
		else if(!BUFFER)
		begin
			data_out <= 0;
		end
		
		if(EOF)
		begin
			eof <= eof || (eof_flag && empty && !w_en);
			eof_flag <= (eof_flag || eof_in);
		end
	end
	
	if(w_en && full_max)
	begin
		$display("ERROR: sync_fifo overflow: width=%0d max_size=%0d margin=%0d", WIDTH, DEPTH, MARGIN);
		$stop;
	end
	
	if(w_en && eof)
	begin
		$display("ERROR: sync_fifo fail: write after EOF");
		$stop;
	end
end

endmodule
