module asynch_fifo #(
parameter DATA_WIDTH = 8, parameter ADDR_WIDTH = 9, 
parameter ALMOST_FULL = 16, parameter ALMOST_EMPTY = 16)(
input logic i_wclk, 
input logic i_rclk, 
input logic i_wrst,
input logic i_rrst,
input logic w_enable, 
input logic r_enable, 
input logic [DATA_WIDTH-1:0] i_din, 

output logic [DATA_WIDTH-1:0] o_dout, 
output logic o_full, 
output logic o_almostfull, 
output logic o_empty, 
output logic o_almostempty
);

logic [ADDR_WIDTH:0] g_rptr_synch; 
logic [ADDR_WIDTH:0] g_wptr;
logic [ADDR_WIDTH:0] b_wptr;
logic w_enable_gated;

logic [ADDR_WIDTH:0] g_wptr_synch;
logic [ADDR_WIDTH:0] g_rptr;
logic [ADDR_WIDTH:0] b_rptr;
logic r_enable_gated;


asynch_fifo_wpointer #(.ADDR_WIDTH(ADDR_WIDTH), .ALMOST_FULL(ALMOST_FULL)) wptr_plugin (
    .i_wclk(i_wclk), 
    .w_enable(w_enable), 
    .i_wrst(i_wrst),
    .g_rptr_synch(g_rptr_synch),
    .g_wptr(g_wptr),
    .b_wptr(b_wptr), 
    .w_enable_gated(w_enable_gated),
    .o_full(o_full), 
    .o_almostfull(o_almostfull)
);

asynch_fifo_synchronizer #(.ADDR_WIDTH(ADDR_WIDTH)) synch_wptr (
    .i_din(g_wptr),
    .i_clk(i_rclk),
    .i_nrst(i_rrst),
    .o_dout(g_wptr_synch)
);

asynch_fifo_rpointer #(.ADDR_WIDTH(ADDR_WIDTH), .ALMOST_EMPTY(ALMOST_EMPTY)) rptr_plugin (
    .i_rclk(i_rclk),
    .r_enable(r_enable),
    .i_rrst(i_rrst), 
    .g_wptr_synch(g_wptr_synch),
    .g_rptr(g_rptr), 
    .b_rptr(b_rptr), 
    .r_enable_gated(r_enable_gated),
    .o_empty(o_empty), 
    .o_almostempty(o_almostempty)
);

asynch_fifo_synchronizer #(.ADDR_WIDTH(ADDR_WIDTH)) synch_rptr (
    .i_din(g_rptr), 
    .i_clk(i_wclk),
    .i_nrst(i_wrst),
    .o_dout(g_rptr_synch)
);

asynch_fifo_memory #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) mem_plugin (
    .i_din(i_din), 
    .i_wclk(i_wclk), 
    .i_rclk(i_rclk), 
    .w_enable_gated(w_enable_gated), 
    .r_enable_gated(r_enable_gated), 
    .b_wptr(b_wptr),
    .b_rptr(b_rptr),
    .o_dout(o_dout)
);
endmodule
