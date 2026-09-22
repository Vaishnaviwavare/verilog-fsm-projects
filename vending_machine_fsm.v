// =====================================================================
// Vending Machine Controller - FSM
// Item price = 15 cents. Accepts nickel (5c) and dime (10c) coin pulses,
// one coin per clock cycle. Dispenses the item once inserted total >= 15,
// and returns 5c change if the total is 20 (overpaid by a dime after a
// dime, i.e. 10+10).
//
// Classic FSM example (4 states): IDLE -> FIVE -> TEN -> DISPENSE -> IDLE
// =====================================================================

module vending_machine_fsm (
    input  wire clk,
    input  wire rst,       // active-high synchronous reset
    input  wire nickel,    // pulse: 5 cent coin inserted
    input  wire dime,      // pulse: 10 cent coin inserted
    output reg  dispense,  // 1 for one cycle: item released
    output reg  change5,   // 1 for one cycle: return 5 cents change
    output wire [1:0] state_out // exposed for testbench/debug
);

    // ---------------- State encoding ----------------
    localparam IDLE     = 2'b00; // 0 cents inserted so far
    localparam FIVE     = 2'b01; // 5 cents inserted so far
    localparam TEN      = 2'b10; // 10 cents inserted so far
    localparam DISPENSE = 2'b11; // >= 15 cents reached -> release item

    reg [1:0] state, next_state;
    reg       change_pending; // set when the 15c threshold was crossed via 10+10 (=20, owe 5c back)

    assign state_out = state;

    // ---------------- State register ----------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ---------------- Next-state logic ----------------
    always @(*) begin
        next_state = state; // default: hold state (no coin inserted)
        case (state)
            IDLE: begin
                if (nickel)      next_state = FIVE;
                else if (dime)   next_state = TEN;
            end
            FIVE: begin
                if (nickel)      next_state = TEN;       // 5+5 = 10
                else if (dime)   next_state = DISPENSE;  // 5+10 = 15, exact
            end
            TEN: begin
                if (nickel)      next_state = DISPENSE;  // 10+5 = 15, exact
                else if (dime)   next_state = DISPENSE;  // 10+10 = 20, owe 5c
            end
            DISPENSE: begin
                next_state = IDLE; // dispense for one cycle, then reset the count
            end
            default: next_state = IDLE;
        endcase
    end

    // ---------------- Change-owed tracking ----------------
    // Only the TEN -> DISPENSE transition via a dime overshoots the 15c
    // price (10 + 10 = 20), so that is the only path that owes change.
    always @(posedge clk or posedge rst) begin
        if (rst)
            change_pending <= 1'b0;
        else if (state == TEN && dime)
            change_pending <= 1'b1;
        else if (state == DISPENSE)
            change_pending <= 1'b0;
    end

    // ---------------- Output logic (Moore) ----------------
    always @(*) begin
        dispense = (state == DISPENSE);
        change5  = (state == DISPENSE) && change_pending;
    end

endmodule
