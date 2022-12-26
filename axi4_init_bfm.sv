// Copyright (C) 2022, Muzaffer Kal
// This module implements an AXI4 initiator BFM

module   axi4_init_bfm #(master_name,
                         data_bus_width,
                         address_bus_width,
                         id_bus_width,
                         max_outstanding_transactions,
                         exclusive_access_supported)
   
input   ACLK,
input   ARESETn,
// Write Address Channel
output  [id_bus_width-1:0] AWID,
output  [address_bus_width-1:0] AWADDR,
output  [AWLEN,
output  AWSIZE,
output  AWBURST,
output  AWLOCK,
output  AWCACHE,
output  AWPROT,
output  AWVALID,
input   AWREADY,
// Write Data Channel
input  WID,
input  WDATA,
input  WSTRB,
input  WLAST,
input  WVALID,
input  WREADY,
// Write Response Channel
input  BID,
input  BRESP,
input  BVALID,
input  BREADY,
// Read Address Channel
input  ARID,
input  ARADDR,
input  ARLEN,
input  ARSIZE,
input  ARBURST,
input  ARLOCK,
input  ARCACHE,
input  ARPROT,
input  ARVALID,
input  ARREADY,
// Read Data Channel
input  RID,
input  RDATA,
input  RRESP,
input  RLAST,
input  RVALID,
input  RREADY);

endmodule

