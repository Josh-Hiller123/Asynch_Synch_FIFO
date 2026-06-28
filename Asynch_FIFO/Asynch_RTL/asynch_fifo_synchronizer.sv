module asynch_fifo_synchronizer #(parameter ADDR_WIDTH = 9)(
input logic [ADDR_WIDTH:0] i_din, 
input logic i_clk, 
input logic i_nrst,  
output logic [ADDR_WIDTH:0] o_dout 
);
logic [ADDR_WIDTH:0] r_q1;

always_ff @(posedge i_clk or negedge i_nrst)
begin
if (!i_nrst)
begin 
    r_q1 <= 0; 
    o_dout <= 0;
end
else 
begin
    r_q1 <= i_din;
    o_dout <= r_q1; 
end
end
endmodule
