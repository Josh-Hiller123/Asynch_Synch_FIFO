module asynch_fifo_wpointer #(parameter ADDR_WIDTH = 9, parameter ALMOST_FULL = 16)(
input logic i_wclk,
input logic w_enable,
input logic i_wrst, 
input logic [ADDR_WIDTH:0] g_rptr_synch, 

output logic [ADDR_WIDTH:0] g_wptr,
output logic [ADDR_WIDTH:0] b_wptr,
output logic o_full, 
output logic o_almostfull,
output logic w_enable_gated
);
 
logic [ADDR_WIDTH:0] b_wptr_next;
logic [ADDR_WIDTH:0] g_wptr_next;
logic [ADDR_WIDTH:0] b_rptr_synch; 
logic w_full; 
logic w_almostfull;
logic [ADDR_WIDTH:0] w_fill_level;

always_ff @(posedge i_wclk or negedge i_wrst)
begin
if (!i_wrst)
begin
    b_wptr <= 0;
    g_wptr <= 0;
    o_full <= 0;
    o_almostfull <= 0;
end
else 
begin
    b_wptr <= b_wptr_next;
    g_wptr <= g_wptr_next; 
    o_full <= w_full;
    o_almostfull <= w_almostfull;
end
end

assign w_enable_gated = w_enable && !o_full;
assign b_wptr_next = b_wptr + w_enable_gated; 
assign g_wptr_next = (b_wptr_next >> 1) ^ b_wptr_next; 

assign w_full = (g_wptr_next == {~g_rptr_synch[ADDR_WIDTH:ADDR_WIDTH-1], g_rptr_synch[ADDR_WIDTH-2:0]}); // 11000... vs 00000...
assign w_fill_level = b_wptr_next - b_rptr_synch;
assign w_almostfull = (w_fill_level >= (1 << ADDR_WIDTH) - ALMOST_FULL);

gray_to_binary #(.ADDR_WIDTH(ADDR_WIDTH)) g_rptr_conversion(
.i_din(g_rptr_synch), 
.o_dout(b_rptr_synch)
);
endmodule
