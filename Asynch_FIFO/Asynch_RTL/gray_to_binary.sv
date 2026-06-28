module gray_to_binary #(parameter ADDR_WIDTH = 9)(
    input logic [ADDR_WIDTH:0] i_din,
    output logic [ADDR_WIDTH:0] o_dout
);

always_comb
begin
for (int i = 0; i <= ADDR_WIDTH; i = i + 1)
begin
    o_dout[i] = ^(i_din >> i);
end
end
endmodule
