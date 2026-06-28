# Asynchronous FIFO
With the foundation I gained from my synchronous FIFO, I built a parameterizable asynchronous FIFO that safely transfers data between two independent clock domains. My design utilizes gray-coded pointers and dual-flip-flop synchronizers to allow crossing of the write and read clock boundary. Full/almost-full and empty/almost-empty flags are also built in so that data is never written to a full FIFO or read from an empty FIFO. 

## Overview: How it works 
- Write/read pointers increment in their own domains on each accepted w_enable / r_enable.
- Each binary pointer is converted to Gray code before leaving its domain.
- The Gray pointer is passed through a two-flop synchronizer into the opposite domain (g_wptr_synch, g_rptr_synch).
- Each native pointer is compared to the incoming synchronized pointer to generate full/almost-full/empty/almost-empty flags
- The synchronizer-based pointer crossing of the asynchronous FIFO makes all flags conservative estimates, ensuring data remains intact in all cases 

## Why use an Asynchronous FIFO
Asynchronous FIFOs significantly enhance the capabilities of synchronous FIFOs, as they can facilitate communication between differently clocked interfaces. However, this aspect creates complications, especially in detecting full/empty flags. Calculating how full or empty our FIFO is requires knowing how many times we've written and read at any given time. But how can we reliably obtain these values if they're constantly changing at different frequencies?

## Transferring Pointers Across the Clock Boundary
Our writes and reads exist in separate clock domains. Therefore, we need to use a **D-flip-flop synchronizer** with two or more D-flip-flops so that our write-pointer value can sync to our read-clock in a stable state and vice versa. To further prevent metastability and ensure our pointer signals arrive reliably, we have to feed our pointers in **gray code** to the synchronizers. This means only one bit will need to change and stabilize at a time, which is significantly safer than having multiple bits changing and stabilizing at different times. These methods will allow us to safely transfer our write and read pointers across the clock boundary and calculate our flags.

## Verification 
The testbench for the asynchronous FIFO uses an active monitor and scoreboard to always record data going in to the FIFO and compare it against data leaving the FIFO. This system operates on the positive edge of the write and read clocks to emulate the DUT, while all other testbench stimulus operate on negative clock edges. The testbench fills the FIFO, writes to a full FIFO, drains the FIFO, and reads from an empty FIFO at different starting points to verify edge cases and wrap-around functionality. Flags are checked at specific checkpoints where they are expected to trigger. Then, the FIFO reads and writes simultaneously and with randomized write/read enable signals to simulate real-life use. 

## Waveform 
Below are the waveforms obtained through GTKWave. The first image shows the waveform of the stimulus filling the FIFO the minimum amounts needed to trigger the almost full flag, then the full flag, then finally writes to a full FIFO. There are momentary pauses between each of these steps for error checks in the testbench.
<img width="796" height="221" alt="Screenshot 2026-06-27 220647" src="https://github.com/user-attachments/assets/83634074-5f97-44ab-ba48-5ea1b7215bb2" />

**Notice the delays.** When write enable (w_enable) goes high, there's a substantial delay before the synchronized write pointer (g_wptr_synch) activates, and an even longer delay before the empty flag drops. This highlights the built-in latency of the asynchronous FIFO and the source of our conservative estimates. The d-flip-flops in our synchronizer means the write pointer requires two read-clock cycles to become synchronized. Only after it has propagated through the synchronizer to the read domain can our empty flag be calculated and finally drop on the third positive read-clock edge. Note that empty is calculated combinationally after two read-clock cycles, but we update the empty flag synchronously on the third cycle to ensure all bits are stable and update reliably on the clock edge. This exact process explains why our empty/almost-empty flags drop late and our full/almost-full flags trigger early. The read domain always thinks the FIFO is more full than it is, while the write domain always thinks the FIFO is less empty than it is.

This second image shows the waveform of the stimulus emptying the FIFO the minimum amounts needed to trigger the almost empty flag, then the empty flag, then reads from an empty FIFO. Once again, there are momentary pauses between each. You will notice a similar latency as the previous waveform.
<img width="794" height="219" alt="Screenshot 2026-06-27 220936" src="https://github.com/user-attachments/assets/eab6bc5b-1b68-4d39-8d36-e9591ea596be" />







