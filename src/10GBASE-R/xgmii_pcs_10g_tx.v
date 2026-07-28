/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 * 
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License. 
 * 
 * This code is provided "as is" without any express or implied warranties. */

/* XGMII 10G PCS */

module xgmii_pcs_10g_tx #(
	parameter XGMII_DATA_W = 64,
	localparam XGMII_CTRL_W = (XGMII_DATA_W)/8
)(
	input clk, 
	input nreset,

 	input [XGMII_DATA_W-1:0] xgmii_txd_i,
	input [XGMII_CTRL_W-1:0] xgmii_txc_i,

	output                    ready_o,
	output [XGMII_DATA_W-1:0] data_o
);
localparam XGMII_KEEP_W = XGMII_CTRL_W;

// xgmii interface to custom lite pcs interface
logic ctrl_v;
logic idle_v;
logic term_v;
logic err_v;
logic start_v;
logic [XGMII_KEEP_W-1:0] keep; // data keep

xgmii_pcs_10g_enc_intf #( .XGMII_DATA_W(XGMII_DATA_W))
m_xgmii_intf(
	.clk(clk),
	.nreset(nreset),
	.xgmii_txd_i(xgmii_txd_i),
	.xgmii_txc_i(xgmii_txc_i),
	.ctrl_v_o(ctrl_v),
	.idle_v_o(idle_v),
	.start_v_o(start_v),
	.term_v_o(term_v),
	.err_v_o(err_v),
	.keep_o(keep)
);

pcs_tx #(.IS_10G(1), .XGMII_DATA_W(XGMII_DATA_W))
m_pcs_tx(
	.pcs_clk(clk),
	.tx_par_clk(clk),
	.nreset(nreset),

	.ctrl_v_i(ctrl_v),
	.idle_v_i(idle_v),
	.start_v_i(start_v),
	.term_v_i(term_v),
	.err_v_i(err_v),
	.data_i(xgmii_txd_i),
	.keep_i(keep),
	.ready_o(ready_o),
	.serdes_data_o(data_o)
);
endmodule
