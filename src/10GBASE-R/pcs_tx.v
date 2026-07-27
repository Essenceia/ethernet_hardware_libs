/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
*/ 
module pcs_tx#(
	parameter DATA_W = 32,
	localparam SERDES_W = 32,
	localparam HEAD_W = 2,
	localparam BLOCK_W = DATA_W+HEAD_W,
	localparam KEEP_W = DATA_W/8,
	localparam XGMII_DATA_W = 32,
	localparam XGMII_KEEP_W = XGMII_DATA_W/8,
)(
	input              pcs_clk, /* pcs common clk */
	input              tx_par_clk, /* serdes parallel clk */
	input              nreset,

	// MAC
	input                    ctrl_v_i,
	input                    idle_v_i,
	input                    start_v_i,
	input                    term_v_i,
	input                    err_v_i,
	input [XGMII_DATA_W-1:0] data_i, // tx data
	input [XGMII_KEEP_W-1:0] keep_i,

	/* SerDes */
	output [SERDES_W-1:0]    serdes_data_o
);
// encoder
logic                    scram_v;
logic        unused_enc_head_v;
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
logic  gb_accept;
/*verilator lint_on UNUSEDSIGNAL */

/* input to gearbox */
logic         gb_nreset;
logic [LANE_N*HEAD_W-1:0] gb_head;
logic [LANE_N*DATA_W-1:0] gb_data;
	

// encode
pcs_enc_lite #(.DATA_W(DATA_W))
m_pcs_enc(
	.ctrl_v_i(ctrl_v_i),
	.idle_v_i(idle_v_i),
	.start_v_i(start_v_i),
	.term_v_i(term_v_i),
	.err_v_i(err_v_i),
	.data_i(data_i), // tx data
	.keep_i(keep_i),
	.head_v_o(unused_enc_head_v),
	.data_o(data_enc)	
);

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
assign scram_v = gb_accept;
assign ready_o = gb_accept;

/* gearbox */
gearbox_tx #(
	.DATA_W(DATA_W),
	.HEAD_W(HEAD_W)
)m_gearbox_tx(
	.clk(tx_par_clk),
	.nreset(gb_nreset),
	.head_i(gb_head),
	.data_i(gb_data),
	.accept_v_o(gb_accept),  
	.data_o(serdes_data_o)
);

endmodule
