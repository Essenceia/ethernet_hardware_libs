/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 * 
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License. 
 * 
 * This code is provided "as is" without any express or implied warranties. */

/* PCS on the transmission path 
 * 
 * This module does not support a configurable data width,
 * it expects 256b of data from the mac every cycle.
 *
 * The meaning of "lane" is difference for 40g than 10g.
 * In 10g each block had 2x4 lanes, in 40g the xgmii data
 * is composed of 4 lanes of 1 block width. */
module pcs_tx#(
	parameter IS_10G = 0,
	parameter IS_TB = 1,
	parameter LANE_N = IS_10G ? 1 : 4,
	parameter DATA_W = 64,
	parameter HEAD_W = 2,
	/* verilator lint_off UNUSEDPARAM */
	parameter BLOCK_W = DATA_W+HEAD_W,
	/* verilator lint_on UNUSEDPARAM */
	parameter KEEP_W = DATA_W/8,
	parameter LANE0_CNT_N = IS_10G ? 2 : 1,
	parameter XGMII_DATA_W = LANE_N*DATA_W,
	parameter XGMII_KEEP_W = LANE_N*KEEP_W
)(
	input              pcs_clk, /* pcs common clk */
	input [LANE_N-1:0] tx_par_clk, /* serdes parallel clk */
	input              nreset,

	// MAC
	input [LANE_N-1:0]             ctrl_v_i,
	input [LANE_N-1:0]             idle_v_i,
	input [LANE_N*LANE0_CNT_N-1:0] start_v_i,
	input [LANE_N-1:0]             term_v_i,
	input [LANE_N-1:0]             err_v_i,
	input [XGMII_DATA_W-1:0]       data_i, // tx data
	input [XGMII_KEEP_W-1:0]       keep_i,


	output                        marker_v_o,// alignement marker added this cycle,not used in 10GBASE-R	
	output                        ready_o,// gearbox accept next data	
	
	/* SerDes */
	output [LANE_N*DATA_W-1:0]    serdes_data_o
);
// encoder
logic                    scram_v;
logic [LANE_N-1:0]       unused_enc_head_v;
logic [XGMII_DATA_W-1:0] data_enc; // encoded

// scrambler
logic [XGMII_DATA_W-1:0] data_scram; // scrambled

// sync header is allways valid
logic [LANE_N*HEAD_W-1:0] sync_head;

// gearbox 

/* gearbox full has the same value every gearbox
* regardless of the lane, we can ignore all of them 
* but 1 as long as we are sending all the data blocks
* within the same cycle, this may be changed in future
* versions */
/*verilator lint_off UNUSEDSIGNAL */
logic [LANE_N-1:0] gb_accept;
/*verilator lint_on UNUSEDSIGNAL */

/* input to gearbox */
logic [LANE_N-1:0]        gb_nreset;
logic [LANE_N*HEAD_W-1:0] gb_head;
logic [LANE_N*DATA_W-1:0] gb_data;

genvar l;
generate
for( l = 0; l < LANE_N; l++ ) begin : gen_enc_lane
	// encode
	pcs_enc_lite #(.DATA_W(DATA_W), .IS_10G(IS_10G))
	m_pcs_enc(
		.ctrl_v_i(ctrl_v_i[l]),
		.idle_v_i(idle_v_i[l]),
		.start_v_i(start_v_i[l*LANE0_CNT_N+LANE0_CNT_N-1:l*LANE0_CNT_N]),
		.term_v_i(term_v_i[l]),
		.err_v_i(err_v_i[l]),
		.part_i('0),
		.data_i(data_i[l*DATA_W+DATA_W-1:l*DATA_W]), // tx data
		.keep_i(keep_i[l*KEEP_W+KEEP_W-1:l*KEEP_W]),
		.keep_next_i('X),
		.head_v_o(unused_enc_head_v[l]),
		.sync_head_o(sync_head[l*HEAD_W+HEAD_W-1:l*HEAD_W]), 
		.data_o(data_enc[l*DATA_W+DATA_W-1:l*DATA_W])	
	);
end
endgenerate

// scramble
_64b66b_tx #(.LEN(XGMII_DATA_W))
m_64b66b_tx(
	.clk(pcs_clk),
	.nreset(nreset),
	.valid_i(scram_v),
	.data_i (data_enc  ),
	.scram_o(data_scram)
);

// gearbox data : scrambled data
assign gb_data = data_scram;
assign gb_head = sync_head;
assign gb_nreset = nreset;

// scrambler
assign scram_v = gb_accept[0];

/* PCS is non blocking in 10G mode
* The only case where the PCS becomes blocking is when we
* are adding the alignement marker.
* And, as there is no alignement marker for 10GBASE and this
* signal is not expected to be used in this configuration */
assign marker_v_o = 1'bX;

assign ready_o   = gb_accept[0];


/* gearbox */
gearbox_tx #(
	.DATA_W(DATA_W),
	.HEAD_W(HEAD_W)
)m_gearbox_tx(
	.clk(tx_par_clk[l]),
	.nreset(gb_nreset[l]),
	.head_i(gb_head[l*HEAD_W+HEAD_W-1:l*HEAD_W]),
	.data_i(gb_data[l*DATA_W+DATA_W-1:l*DATA_W]),
	.accept_v_o(gb_accept[l]),  
	.data_o(serdes_data_o[l*DATA_W+DATA_W-1:l*DATA_W])
);

`ifdef FORMAL

`endif
endmodule
