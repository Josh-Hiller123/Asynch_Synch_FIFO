module asynch_fifo_rpointer #(parameter ADDR_WIDTH = 9, parameter ALMOST_EMPTY = 16)(
input logic i_rclk,
input logic r_enable,
input logic i_rrst,
input logic [ADDR_WIDTH:0] g_wptr_synch, 

output logic [ADDR_WIDTH:0] g_rptr, 
output logic [ADDR_WIDTH:0] b_rptr, 
output logic o_empty, 
output logic o_almostempty,
output logic r_enable_gated
);

logic [ADDR_WIDTH:0] g_rptr_next;
logic [ADDR_WIDTH:0] b_rptr_next;
logic [ADDR_WIDTH:0] b_wptr_synch;
logic w_empty; 
logic w_almostempty;
logic [ADDR_WIDTH:0] w_fill_level;  

always_ff @(posedge i_rclk or negedge i_rrst)
begin
    if(!i_rrst)
    begin
        b_rptr <= 0; 
        g_rptr <= 0; 
        o_empty <= 1; 
        o_almostempty <= 1;
    end
    else 
    begin
        b_rptr <= b_rptr_next;
        g_rptr <= g_rptr_next;
        o_empty <= w_empty; 
        o_almostempty <= w_almostempty; 
    end
end

assign r_enable_gated = r_enable && !o_empty;
assign b_rptr_next = b_rptr + r_enable_gated; 
assign g_rptr_next = (b_rptr_next >> 1) ^ b_rptr_next; 

assign w_empty = (g_rptr_next == g_wptr_synch); 
assign w_fill_level = b_wptr_synch - b_rptr_next;
assign w_almostempty = (w_fill_level <= ALMOST_EMPTY);

gray_to_binary #(.ADDR_WIDTH(ADDR_WIDTH)) g_rptr_conversion (
.i_din(g_wptr_synch), 
.o_dout(b_wptr_synch)
);

endmodule
