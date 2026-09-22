// =====================================================================
// Testbench for vending_machine_fsm
// Simulate with Icarus Verilog:
//   iverilog -o vm_sim vending_machine_fsm.v vending_machine_tb.v
//   vvp vm_sim
//   gtkwave vending_machine.vcd     (to view waveforms)
// =====================================================================
`timescale 1ns/1ns

module vending_machine_tb;

    reg clk, rst;
    reg nickel, dime;
    wire dispense, change5;
    wire [1:0] state_out;

    vending_machine_fsm dut (
        .clk(clk),
        .rst(rst),
        .nickel(nickel),
        .dime(dime),
        .dispense(dispense),
        .change5(change5),
        .state_out(state_out)
    );

    always #5 clk = ~clk; // 10ns period clock

    // Insert one coin pulse, exactly one clock cycle wide
    task insert_nickel;
        begin
            @(negedge clk); nickel = 1;
            @(negedge clk); nickel = 0;
        end
    endtask

    task insert_dime;
        begin
            @(negedge clk); dime = 1;
            @(negedge clk); dime = 0;
        end
    endtask

    initial begin
        $dumpfile("vending_machine.vcd");
        $dumpvars(0, vending_machine_tb);

        clk = 0; rst = 1; nickel = 0; dime = 0;
        @(negedge clk); rst = 0;

        $display("time\tstate\tdispense\tchange5");
        $monitor("%4t\t%0d\t%b\t\t%b", $time, state_out, dispense, change5);

        // ---- Test case 1: nickel + dime = 15c exact, no change ----
        $display("\n-- Test 1: nickel then dime (5+10=15, expect dispense=1, change5=0) --");
        insert_nickel;
        insert_dime;
        @(negedge clk); // let DISPENSE state register/settle

        // ---- Test case 2: dime + nickel = 15c exact, no change ----
        $display("\n-- Test 2: dime then nickel (10+5=15, expect dispense=1, change5=0) --");
        insert_dime;
        insert_nickel;
        @(negedge clk);

        // ---- Test case 3: dime + dime = 20c, overpay, expect 5c change ----
        $display("\n-- Test 3: dime then dime (10+10=20, expect dispense=1, change5=1) --");
        insert_dime;
        insert_dime;
        @(negedge clk);

        // ---- Test case 4: nickel + nickel + nickel = 15c exact ----
        $display("\n-- Test 4: nickel x3 (5+5+5=15, expect dispense=1, change5=0) --");
        insert_nickel;
        insert_nickel;
        insert_nickel;
        @(negedge clk);

        // ---- Test case 5: reset mid-transaction ----
        $display("\n-- Test 5: insert a nickel, then reset mid-way, expect state back to IDLE --");
        insert_nickel;
        @(negedge clk); rst = 1;
        @(negedge clk); rst = 0;

        #20;
        $display("\nSimulation complete.");
        $finish;
    end

endmodule
