// Copyright (C) 2015
// Author kal@dspia.com (Muzaffer Kal)
// This module implements an AXI3 slave BFM

module axi3_slave_bfm 
  #(slave_name = "slave",
    data_bus_width = 32,
    address_bus_width = 32,
    id_bus_width = 3, 
    slave_base_address = 0,
    slave_memory_size = 0,
    max_outstanding_transactions = 4,
    memory_model_mode = 0,
    exclusive_access_supported = 0,
    axi_rsp_width = 2,
    axi_len_width = 4,
    axi_qos_width = 4,
    axi_lock_width = 2,
    axi_size_width = 3,
    axi_prot_width = 3,
    axi_brst_width = 3,
    axi_burst_len = 16,
    max_burst_bytes_width = 8,
    max_wr_outstanding_transactions = 8,
    axi_brst_type_width = 3,
    axi_cache_width = 4
  )
  (
    input                                   ACLK,
    input                                   ARESETn,
    output logic                            ARREADY,
    output logic                            AWREADY,
    output logic                            BVALID,
    output logic                            RLAST,
    output logic                            RVALID,
    output logic                            WREADY,
    output logic  [axi_rsp_width-1:0]       BRESP,
    output logic  [axi_rsp_width-1:0]       RRESP,
    output logic  [data_bus_width-1:0]      RDATA,
    output logic  [id_bus_width-1:0]        BID,
    output logic  [id_bus_width-1:0]        RID,
    input                                   ARVALID,
    input                                   AWVALID,
    input                                   BREADY,
    input                                   RREADY,
    input                                   WLAST,
    input                                   WVALID,
    input         [axi_brst_type_width-1:0] ARBURST,
    input         [axi_lock_width-1:0]      ARLOCK,
    input         [axi_size_width-1:0]      ARSIZE,
    input         [axi_brst_type_width-1:0] AWBURST,
    input         [axi_lock_width-1:0]      AWLOCK,
    input         [axi_size_width-1:0]      AWSIZE,
    input         [axi_prot_width-1:0]      ARPROT,
    input         [axi_prot_width-1:0]      AWPROT,
    input         [address_bus_width-1:0]   ARADDR,
    input         [address_bus_width-1:0]   AWADDR,
    input         [data_bus_width-1:0]      WDATA,
    input         [axi_cache_width-1:0]     ARCACHE,
    input         [axi_cache_width-1:0]     ARLEN,
    input         [axi_qos_width-1:0]       ARQOS,
    input         [axi_cache_width-1:0]     AWCACHE,
    input         [axi_len_width-1:0]       AWLEN,
    input         [axi_qos_width-1:0]       AWQOS,
    input         [(data_bus_width/8)-1:0]  WSTRB,
    input         [id_bus_width-1:0]        ARID,
    input         [id_bus_width-1:0]        AWID,
    input         [id_bus_width-1:0]        WID
  );
  integer STOP_ON_ERROR;
  integer RESPONSE_TIMEOUT;

  assign ARREADY = 0;
  assign AWREADY = 0;
  assign BVALID = 0;
  assign RLAST = 0;
  assign RVALID = 0;
  assign WREADY = 0;
  assign BRESP = 0;
  assign RRESP = 0;
  assign RDATA = 0;
  assign BID = 0;
  assign RID = 0;

  task set_stop_on_error;
    input LEVEL;
    begin
      STOP_ON_ERROR = LEVEL;
    end
  endtask
  task automatic set_channel_level_info;
    input LEVEL;
    $display("SLV: set_channel_level_info: %d", LEVEL);
  endtask
  task automatic set_function_level_info;
    input LEVEL;
    $display("SLV: set_function_level_info: %d", LEVEL);
  endtask
  task automatic set_disable_reset_value_checks;
    input LEVEL;
    $display("SLV: set_disable_reset_value_checks: %d", LEVEL);
  endtask
  task automatic RECEIVE_WRITE_ADDRESS;
    input LEVEL;
    input id_invalid;
    input [address_bus_width-1:0] awaddr;
    input [axi_len_width-1:0] awlen;
    input [axi_size_width-1:0] awsize;
    input [axi_brst_width-1:0] awbrst;
    input [axi_lock_width-1:0] awlock;
    input [axi_cache_width-1:0] awcache;
    input [axi_prot_width-1:0] awprot;
    input [id_bus_width-1:0] awid;
    $display("SLV: RECEIVE_WRITE_ADDRESS: %d", LEVEL);
  endtask
  task automatic RECEIVE_READ_ADDRESS;
    input LEVEL;
    input id_invalid;
    input [address_bus_width-1:0] araddr;
    input [axi_len_width-1:0] arlen;
    input [axi_size_width-1:0] arsize;
    input [axi_brst_width-1:0] arbrst;
    input [axi_lock_width-1:0] arlock;
    input [axi_cache_width-1:0] arcache;
    input [axi_prot_width-1:0] arprot;
    input [id_bus_width-1:0] arid;
    $display("SLV: RECEIVE_READ_ADDRESS %d", LEVEL);
  endtask
  task automatic RECEIVE_WRITE_BURST_NO_CHECKS;
    input [id_bus_width-1:0] wid;
    //output [(data_bus_width*axi_burst_len)-1:0] burst_data [0:max_wr_outstanding_transactions-1];
    output [(max_wr_outstanding_transactions*data_bus_width*axi_burst_len)-1:0] burst_data;
    //output [max_burst_bytes_width:0] burst_valid_bytes [0:max_wr_outstanding_transactions-1];
    output [max_wr_outstanding_transactions*max_burst_bytes_width:0] burst_valid_bytes;
    $display("SLV: RECEIVE_WRITE_BURST_NO_CHECKS: %d", wid);
  endtask
  task automatic SEND_WRITE_RESPONSE;
    input [id_bus_width-1:0] wid;
    output [axi_rsp_width-1:0] bresp;
    $display("SLV: SEND_WRITE_RESPONSE: %d", wid);
  endtask
  task automatic SEND_READ_BURST_RESP_CTRL;
    input [id_bus_width-1:0] arid;
    input [address_bus_width-1:0] araddr;
    input [axi_len_width-1:0] arlen;
    input [axi_size_width-1:0] arsize;
    input [axi_brst_width-1:0] arbrst;
    input [axi_brst_width-1:0] data;
    input [axi_brst_width-1:0] resp;
    $display("SLV: SEND_READ_BURST_RESP_CTRL: %d", arid);
  endtask
endmodule
