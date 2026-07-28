# Ethernet RTL common modules

## 10GBASE-R 

Features: 
- test pattern support on both TX and RX: PRBS9 and PRBS31
- loopback testing
- BER check
- XGMII interface 

TBD:
- MDIO

Whishlist: 
- PRBS7 and/or 13  

Not supported: 
- Low power mode
- FEC

Not provided: 
- RC: Reconciliation sublayer

### XGMII 

The PCS shall expose an XGMII interface as defined by 802.3 clause 46, with the exeption it not being a DDR interface.
Data will be send and accepted on clk rising edge.  
