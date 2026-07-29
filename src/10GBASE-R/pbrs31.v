
/* 
PBRS31 for link training 
G(x) = 1 + x^{28} + x^{31} 
*/
module pbrs31(
	input wire clk, 

	input wire        enable_i,	
	input wire        rst_seed_i, 
	input wire [31:0] seed_i,

	output wire [31:0] pbrs_o
);
wire [31:0] lfsr_next; 
reg  [31:0] lfsr_q; 
reg  [31:0]	buff = 0;

always @(*) begin
	for(integer i=31; i>=0; i--) begin
		lfst_next[i] = lfsr_q[i] ^ buff[27] ^ buff[30];
		buff = { buff[30:0], lfsr_q[i] };
	end
end

always @(posedge clk) begin
	if (enable_i) begin
		if (rst_seed_i) lfsr_q <= seed_i;
		else lfsr_q <= lfsr_next;
	end
end

assign pbrs_o = lfsr_q; 

endmodule
