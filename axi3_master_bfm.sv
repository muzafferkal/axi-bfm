// Copyright (C) 2015
// Author kal@dspia.com (Muzaffer Kal)
// This module implements an AXI3 master BFM

module axi3_master_bfm 
  #(master_name = "master",
    data_bus_width = 32,
    address_bus_width = 32,
    id_bus_width = 3,
    max_outstanding_transactions = 4,
    exclusive_access_supported = 0,
    axi_rsp_width = 2,
    axi_len_width = 4,
    axi_qos_width = 4,
    axi_lock_width = 2,
    axi_size_width = 3,
    axi_prot_width = 3,
    axi_cache_width = 4,
    axi_burst_len = 16,
    axi_brst_width = 3,
    axi_mgp_data_width = 32,
    axi_brst_type_width = 3,
    max_burst_bytes_width = 8,
    max_wr_outstanding_transactions = 8
  )
  (
   input                                  ACLK,
   input                                  ARESETn,
   output logic                           ARVALID,
   output logic                           AWVALID,
   output logic                           BREADY,
   output logic                           RREADY,
   output logic                           WLAST,
   output logic                           WVALID,
   output logic [id_bus_width-1:0]        ARID,
   output logic [id_bus_width-1:0]        AWID,
   output logic [id_bus_width-1:0]        WID,
   output logic [axi_brst_type_width-1:0] ARBURST,
   output logic [axi_lock_width-1:0]      ARLOCK,
   output logic [axi_size_width-1:0]      ARSIZE,
   output logic [axi_brst_type_width-1:0] AWBURST,
   output logic [axi_lock_width-1:0]      AWLOCK,
   output logic [axi_size_width-1:0]      AWSIZE,
   output logic [axi_prot_width-1:0]      ARPROT,
   output logic [axi_prot_width-1:0]      AWPROT,
   output logic [address_bus_width-1:0]   ARADDR,
   output logic [address_bus_width-1:0]   AWADDR,
   output logic [data_bus_width-1:0]      WDATA,
   output logic [axi_cache_width-1:0]     ARCACHE,
   output logic [axi_len_width-1:0]       ARLEN,
   output logic [axi_qos_width-1:0]       ARQOS,
   output logic [axi_cache_width-1:0]     AWCACHE,
   output logic [axi_len_width-1:0]       AWLEN,
   output logic [axi_qos_width-1:0]       AWQOS,
   output logic [(data_bus_width/8)-1:0]  WSTRB,
   input                                  ARREADY,
   input                                  AWREADY,
   input                                  BVALID,
   input                                  RLAST,
   input                                  RVALID,
   input                                  WREADY,
   input        [id_bus_width-1:0]        BID,
   input        [id_bus_width-1:0]        RID,
   input        [axi_rsp_width-1:0]       BRESP,
   input        [axi_rsp_width-1:0]       RRESP,
   input        [data_bus_width-1:0]      RDATA
  );

  integer STOP_ON_ERROR;
  integer RESPONSE_TIMEOUT;

  typedef enum {START = 0, W4RDY, DONE} sadst_t;
  sadst_t sast;
  sadst_t sdst;
  sadst_t rdst;

  always_ff @(posedge ACLK) begin
    if (!ARESETn) begin
      sast <= START;
      sdst <= START;
      rdst <= START;
      WLAST <= 0;
      WVALID <= 0;
      WID <= 0;
      WSTRB <= 0;
      WDATA <= 0;
      ARVALID <= 0;
      BREADY <= 0;
      RREADY <= 0;
      AWVALID <= 0;
      ARID <= 0;
      AWID <= 0;
      ARBURST <= 0;
      ARLOCK <= 0;
      ARSIZE <= 0;
      AWBURST <= 0;
      AWLOCK <= 0;
      AWSIZE <= 0;
      ARPROT <= 0;
      AWPROT <= 0;
      ARADDR <= 0;
      AWADDR <= 0;
      ARCACHE <= 0;
      ARLEN <= 0;
      ARQOS <= 0;
      AWCACHE <= 0;
      AWLEN <= 0;
      AWQOS <= 0;
    end
  end

  task send_write_address;
    input [11:0] excl_id;
    input [address_bus_width-1:0] addr;
    input [axi_len_width-1:0] len;
    input [axi_size_width-1:0] size;
    input [axi_brst_width-1:0] brst;
    input [axi_lock_width-1:0] lock;
    input [axi_cache_width-1:0] cache;
    input [axi_prot_width-1:0] prot;
    forever begin
      @(posedge ACLK) begin
        //$display("in send address state %d", sast);
        case(sast)
        START: begin
          AWVALID <= 1;
          AWADDR  <= addr;
          AWLEN   <= len;
          AWSIZE  <= size;
          AWBURST <= brst;
          AWCACHE <= cache;
          AWLOCK  <= lock;
          AWPROT  <= prot;
          AWID    <= excl_id;
          sast    <= W4RDY;
        end
        W4RDY: begin
          if (AWREADY) begin
            AWVALID <= 0;
            sast    <= START;
            break;
          end
        end
        endcase
      end
    end
  endtask

  task automatic send_burst_data;
    input [11:0] excl_id;
    input [axi_len_width-1:0] len;
    input [axi_size_width-1:0] size;
    input [(axi_mgp_data_width*axi_burst_len)-1:0] data;
    input integer datasize;

    integer Burst_Length = len + 1;
    logic [(axi_mgp_data_width*axi_burst_len)-1:0] tmpdata = data;
    $display("in send burst data %X", data[31:0]);
    $display("in send burst data %X", tmpdata[31:0]);

    forever begin
      @(posedge ACLK) begin
        $display("in send burst data state %d", sdst);
        case(sdst)
        START: begin
          WVALID  <= 1;
          WDATA   <= tmpdata[data_bus_width - 1:0];
          WSTRB   <= {{data_bus_width/8}{1'b1}};
          WLAST   <= Burst_Length == 1;
          WID     <= excl_id;;
          Burst_Length = Burst_Length - 1;
          tmpdata = tmpdata >> data_bus_width;
          sdst    <= W4RDY;
        end
        W4RDY: begin
          if (WREADY) begin
            if (Burst_Length) begin
              WDATA   <= tmpdata[data_bus_width - 1:0];
              WSTRB   <= {{data_bus_width/8}{1'b1}};    // TODO(kal) this is probably not right always
              WLAST   <= Burst_Length == 1;
              Burst_Length = Burst_Length - 1;
              tmpdata = tmpdata >> data_bus_width;
            end
            else begin
              WVALID  <= 0;
              WLAST   <= 0;
              BREADY  <= 1;
              sdst    <= START;
              break;
            end
          end
        end
        endcase
      end
    end
  endtask

  task automatic receive_write_response;
    output [axi_rsp_width-1:0] response;
    forever begin
      @(posedge ACLK) begin
        if (BVALID) begin
          BREADY    <= 0;
          response  = BRESP;
          break;
        end
      end
    end
  endtask

  task send_read_address;
    input [11:0] excl_id;
    input [address_bus_width-1:0] addr;
    input [axi_len_width-1:0] len;
    input [axi_size_width-1:0] size;
    input [axi_brst_width-1:0] brst;
    input [axi_lock_width-1:0] lock;
    input [axi_cache_width-1:0] cache;
    input [axi_prot_width-1:0] prot;
    forever begin
      @(posedge ACLK) begin
        //$display("in send address state %d", sast);
        case(sast)
        START: begin
          ARVALID <= 1;
          ARADDR  <= addr;
          ARLEN   <= len;
          ARSIZE  <= size;
          ARBURST <= brst;
          ARCACHE <= cache;
          ARLOCK  <= lock;
          ARPROT  <= prot;
          ARID    <= excl_id;
          RREADY  <= 1;
          sast    <= W4RDY;
        end
        W4RDY: begin
          if (ARREADY) begin
            ARVALID <= 0;
            sast    <= START;
            break;
          end
        end
        endcase
      end
    end
  endtask

  task automatic receive_burst_data;
    input  [11:0] excl_id;
    input  [axi_len_width-1:0] len;
    input  [axi_size_width-1:0] size;
    output [(axi_mgp_data_width*axi_burst_len)-1:0] data;
    output [axi_rsp_width-1:0] response;

    integer Burst_Length = len + 1;
    integer count = 0;

    forever begin
      @(posedge ACLK) begin
        $display("in receive burst data state %d count %d", sdst, count);
        case(rdst)
        START: begin
          if (RVALID) begin
            data[count*axi_mgp_data_width +: axi_mgp_data_width] = RDATA;
            count = count + 1;
          end
          if (RLAST) begin
            RREADY <= 0;
            response = RRESP;
            break;
          end
        end
        endcase
      end
    end
    $display("MST: receive burst data %X", data);
  endtask

  task automatic WRITE_BURST;
    input [11:0] excl_id;
    input [address_bus_width-1:0] addr;
    input [axi_len_width-1:0] len;
    input [axi_size_width-1:0] size;
    input [axi_brst_width-1:0] brst;
    input [axi_lock_width-1:0] lock;
    input [axi_cache_width-1:0] cache;
    input [axi_prot_width-1:0] prot;
    input [(axi_mgp_data_width*axi_burst_len)-1:0] data;
    input integer datasize;
    output [axi_rsp_width-1:0] response;

    $display("MST: WRITE_BURST: %d", excl_id);
    send_write_address(excl_id, addr, len, size, brst, lock, cache, prot);
    send_burst_data(excl_id, len, size, data, datasize);
    receive_write_response(response);
  endtask

  task set_stop_on_error;
    input LEVEL;
    begin
      STOP_ON_ERROR = LEVEL;
      $display("MST: set_stop_on_error: %d", LEVEL);
    end
  endtask
  task automatic set_channel_level_info;
    input LEVEL;
      $display("MST: set_channel_level_info: %d", LEVEL);
  endtask
  task automatic set_function_level_info;
    input LEVEL;
      $display("MST: set_function_level_info: %d", LEVEL);
  endtask
  task automatic set_disable_reset_value_checks;
    input LEVEL;
      $display("MST: set_disable_reset_value_checks: %d", LEVEL);
  endtask
  task automatic READ_BURST;
    input [11:0] excl_id;
    input [address_bus_width-1:0] addr;
    input [axi_len_width-1:0] len;
    input [axi_size_width-1:0] size;
    input [axi_brst_width-1:0] brst;
    input [axi_lock_width-1:0] lock;
    input [axi_cache_width-1:0] cache;
    input [axi_prot_width-1:0] prot;
    output [(axi_mgp_data_width*axi_burst_len)-1:0] data;
    output [axi_rsp_width-1:0] response;
    $display("MST: READ_BURST: %d", excl_id);

    send_read_address(excl_id, addr, len, size, brst, lock, cache, prot);
    receive_burst_data(excl_id, len, size, data, response);
  endtask
  task automatic WRITE_BURST_CONCURRENT;
    input [11:0] excl_id;
    input [address_bus_width-1:0] addr;
    input [axi_len_width-1:0] len;
    input [axi_size_width-1:0] size;
    input [axi_brst_width-1:0] brst;
    input [axi_lock_width-1:0] lock;
    input [axi_cache_width-1:0] cache;
    input [axi_prot_width-1:0] prot;
    input [(axi_mgp_data_width*axi_burst_len)-1:0] data;
    input integer datasize;
    output [axi_rsp_width-1:0] response;
    $display("MST: WRITE_BURST_CONCURRENT: %X", data[31:0]);
    fork 
      send_write_address(excl_id, addr, len, size, brst, lock, cache, prot);
      send_burst_data(excl_id, len, size, data, datasize);
    join
    receive_write_response(response);
  endtask
endmodule
