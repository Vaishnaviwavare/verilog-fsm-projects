// =====================================================================
// Testbench for traffic_light_fsm
// Simulate with Icarus Verilog:
//   iverilog -o tlc_sim traffic_light_fsm.v traffic_light_tb.v
//   vvp tlc_sim
//   gtkwave traffic_light.vcd     (to view waveforms)
// =====================================================================
`timescale 1ns/1ns

module traffic_light_tb;

    reg clk;
    reg rst;
    wire [2:0] ns_light;
    wire [2:0] ew_light;
    wire [1:0] state_out;

    // Small CLK_FREQ and short timings so the whole cycle finishes fast in sim
    traffic_light_fsm #(
        .CLK_FREQ(4),
        .NS_GREEN_TIME(5),
        .EW_GREEN_TIME(4),
        .YELLOW_TIME(2)
    ) dut (
        .clk(clk),
        .rst(rst),
        .ns_light(ns_light),
        .ew_light(ew_light),
        .state_out(state_out)
    );

    // 10ns period clock (100 MHz) — arbitrary for simulation purposes
    always #5 clk = ~clk;

    // Human-readable light decode, stored in plain regs so $monitor can
    // display them directly (some simulators reject function calls inside
    // $monitor arguments).
    reg [48:1] ns_name, ew_name;

    always @(*) begin
        case (ns_light)
            3'b100:  ns_name = "RED";
            3'b010:  ns_name = "YELLOW";
            3'b001:  ns_name = "GREEN";
            default: ns_name = "UNKNOWN";
        endcase
        case (ew_light)
            3'b100:  ew_name = "RED";
            3'b010:  ew_name = "YELLOW";
            3'b001:  ew_name = "GREEN";
            default: ew_name = "UNKNOWN";
        endcase
    end

    initial begin
        $dumpfile("traffic_light.vcd");
        $dumpvars(0, traffic_light_tb);

        clk = 0;
        rst = 1;
        #12;                 // hold reset for a couple of clock edges
        rst = 0;

        $display("time\tstate\tNS_light\tEW_light");
        $monitor("%4t\t%0d\t%s\t\t%s", $time, state_out, ns_name, ew_name);

        // Run long enough to observe several full NS/EW cycles
        #800;

        $display("Simulation complete.");
        $finish;
    end

endmodule
