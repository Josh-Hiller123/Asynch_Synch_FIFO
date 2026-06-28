`timescale 1us/1ns

module asynch_fifo_tb #(
parameter DATA_WIDTH = 8, parameter ADDR_WIDTH = 9, 
parameter ALMOST_FULL = 16, parameter ALMOST_EMPTY = 16)(); 

logic [DATA_WIDTH-1:0] din_tb;
logic wclk_tb = 0;
logic rclk_tb = 0;
logic wrst_tb;
logic rrst_tb; 
logic w_enable_tb;
logic r_enable_tb;

logic [DATA_WIDTH-1:0] dout_tb;
logic full_tb; 
logic almostfull_tb;
logic empty_tb; 
logic almostempty_tb;
 
int errors = 0;
logic [DATA_WIDTH-1:0] data_tracker [$]; 
logic read_delay_tb = 0;
logic [DATA_WIDTH-1:0] randw_data_tb = 0;


always #14 wclk_tb = ~wclk_tb; 
always #23 rclk_tb = ~rclk_tb;

asynch_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .ALMOST_FULL(ALMOST_FULL), .ALMOST_EMPTY(ALMOST_EMPTY)) 
asynch_fifo_dut (
.i_din(din_tb),
.i_wclk(wclk_tb), 
.i_rclk(rclk_tb), 
.i_wrst(wrst_tb), 
.i_rrst(rrst_tb), 
.w_enable(w_enable_tb), 
.r_enable(r_enable_tb),
.o_dout(dout_tb), 
.o_full(full_tb), 
.o_almostfull(almostfull_tb),
.o_empty(empty_tb), 
.o_almostempty(almostempty_tb)
); 

always @(posedge wclk_tb)
begin
    if (w_enable_tb && !full_tb)
        data_tracker.push_back(din_tb);
end

always @(posedge rclk_tb)
begin
    read_delay_tb <= r_enable_tb && !empty_tb; 
        if(read_delay_tb)
        begin
        automatic logic [DATA_WIDTH-1:0] expected_dout = data_tracker.pop_front();
        if(expected_dout !== dout_tb)
        begin
            $display("ERROR: Output expected: %0d, recieved %0d", expected_dout, dout_tb);
            errors = errors + 1; 
        end
        end
end

task automatic do_write (input int num_writes);
for (int i = 0; i <= num_writes - 1; i++)
begin
    @(negedge wclk_tb); 
    w_enable_tb = 1'b1; 
    din_tb = i;
    if(full_tb)
    $display("NOTE: wrote to full FIFO at time %t after %0d writes, data not tracked", $time, (i+1));
end
@(negedge wclk_tb)
w_enable_tb = 1'b0; 
endtask

task automatic do_read (input int num_reads);
for(int i = 0; i <= num_reads - 1; i++)
begin
    @(negedge rclk_tb); 
    r_enable_tb = 1'b1;
    if(empty_tb)
    $display("NOTE: read from empty FIFO at time %t after %0d reads, data not tracked", $time, (i+1));
end
@(negedge rclk_tb)
r_enable_tb = 1'b0; 
endtask

task automatic fill_and_drain();
@(negedge wclk_tb);
do_write((1 << ADDR_WIDTH) - ALMOST_FULL); 

@(negedge wclk_tb);
if (!almostfull_tb)
begin
    $display("ERROR: almost full flag not detected at time %t on edge case", $time);
    errors = errors + 1;
end
else
$display("SUCCESS: Almost full flag detected on edge case!");

@(negedge wclk_tb); 
do_write(ALMOST_FULL);

@(negedge wclk_tb);
if (!full_tb)
begin
    $display("ERROR: full flag not detected at time %t", $time);
    errors = errors + 1;
end
else 
$display("SUCCESS: Full flag detected!");

// Might delete
if (!almostfull_tb)
begin
    $display("ERROR: almost full flag not detected at time %t", $time);
    errors = errors + 1;
end

@(negedge wclk_tb);
$display("Writing to full FIFO, expect NOTES..."); 

@(negedge wclk_tb);
do_write(10);

$display("Writing to full FIFO finished"); 

@(negedge wclk_tb);
if (!full_tb)
begin
    $display("ERROR: full flag not detected at time %t after writing to full FIFO", $time);
    errors = errors + 1;
end
else 
$display("SUCCESS: Full flag detected after writing to full FIFO!");

if (!almostfull_tb)
begin
    $display("ERROR: almost full flag not detected at time %t after writing to full FIFO", $time);
    errors = errors + 1;
end
else 
$display("SUCCESS: Almost full flag detected after writing to full FIFO!");

@(negedge rclk_tb); 
do_read((1 << ADDR_WIDTH) - ALMOST_EMPTY); 

@(negedge wclk_tb);
if (!almostempty_tb)
begin
    $display("ERROR: almost empty flag not detected at time %t on edge case", $time);
    errors = errors + 1;
end
else 
$display("SUCCESS: Almost empty flag detected on edge case!");

@(negedge rclk_tb);
do_read(ALMOST_EMPTY);

@(negedge rclk_tb);
if (!empty_tb)
begin
    $display("ERROR: empty flag not detected at time %t with empty FIFO", $time);
    errors = errors + 1;
end
else 
$display("SUCCESS: Empty flag detected!");

if (!almostempty_tb)
begin
    $display("ERROR: almost empty flag not detected at time %t with empty FIFO", $time);
    errors = errors + 1;
end
else
$display("SUCCESS: Almost empty flag detected with empty FIFO!");

if (data_tracker.size() !== 0)
begin 
    $display("ERROR: FIFO not empty at time %t when expected to be", $time);
    errors = errors + 1;
end

@(negedge rclk_tb);
$display("Reading from empty FIFO, expect NOTES..."); 

@(negedge rclk_tb);
do_read(10);

$display("Reading from empty FIFO finished"); 

@(negedge rclk_tb);

if (data_tracker.size() !== 0)
begin 
    $display("ERROR: FIFO not empty at time %t after reading from full FIFO", $time);
    errors = errors + 1;
end

if (!empty_tb)
begin
    $display("ERROR: empty flag not detected at time %t after reading from empty FIFO", $time);
    errors = errors + 1; 
end
else 
$display("SUCCESS: Empty flag detected after reading from empty FIFO!");

if (!almostempty_tb)
begin
    $display("ERROR: almost empty flag not detected at time %t after reading from empty FIFO", $time);
    errors = errors + 1;
end
else 
$display("SUCCESS: Almost full flag detected after reading from empty FIFO!");

endtask

task automatic read_and_write (input int wr_cycles, input int rd_cycles);
    int writes = 0;
    int reads = 0;
    
    fork
        begin : writing
            repeat (wr_cycles) begin
            
            @(negedge wclk_tb);
            w_enable_tb = $urandom_range(0, 1);
            din_tb = randw_data_tb;
            randw_data_tb = randw_data_tb + 1;   // fresh value every wclk
            if ((w_enable_tb == 1) && !full_tb)
            writes = writes + 1;
            end
            
            @(negedge wclk_tb) w_enable_tb = 0;
        end
        begin : reading
            repeat (rd_cycles) begin
            @(negedge rclk_tb);
            r_enable_tb = $urandom_range(0, 1);
            if ((r_enable_tb == 1) && !empty_tb)
            reads = reads + 1;
            end
            
            @(negedge rclk_tb) r_enable_tb = 0;
        end
    join
    
    repeat(5) @(negedge rclk_tb);
    repeat(5) @(negedge wclk_tb);
    
    if(writes - reads !== data_tracker.size())
    begin
        $display("ERROR: Unexpected amount of remaining FIFO entries in randomized environment, expected %0d, recieved %0d", (writes - reads), data_tracker.size());
        errors = errors + 1; 
    end
    else
    $display("SUCCESS: all FIFO entries in randomized environment accounted for");

endtask

initial
begin
$dumpfile("Asynchronous_FIFO.vcd"); 
$dumpvars(0, asynch_fifo_tb);

din_tb = 0; 
wrst_tb = 0; 
rrst_tb = 0; 
w_enable_tb = 0; 
r_enable_tb = 0; 

repeat(5) @(negedge wclk_tb); 
repeat(5) @(negedge rclk_tb); 

@(negedge wclk_tb); 
wrst_tb = 1; 

@(negedge rclk_tb);
rrst_tb = 1;

    fill_and_drain();

    do_write(50); 
    do_read(50); 

    fill_and_drain();
    fill_and_drain();

    read_and_write(400, 400);

$display("Simulation finished, %0d errors detected", errors);

$finish;
end
endmodule