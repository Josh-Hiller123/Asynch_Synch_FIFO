module asynch_fifo_memory #(parameter DATA_WIDTH = 8, parameter ADDR_WIDTH = 9) (
input logic [DATA_WIDTH-1:0] i_din, 
input logic i_wclk, 
input logic i_rclk, 
input logic w_enable_gated, 
input logic r_enable_gated, 
input logic [ADDR_WIDTH:0] b_wptr,
input logic [ADDR_WIDTH:0] b_rptr,
output logic [DATA_WIDTH-1:0] o_dout
);

logic [DATA_WIDTH-1:0] r_memory [(1 << ADDR_WIDTH)-1:0];

always_ff @(posedge i_wclk)
begin
    if(w_enable_gated)
    begin
        r_memory[b_wptr[ADDR_WIDTH-1:0]] <= i_din; 
    end
end 

always_ff @(posedge i_rclk)
begin
    if(r_enable_gated)
    begin
        o_dout <= r_memory[b_rptr[ADDR_WIDTH-1:0]];
    end
end
endmodule
