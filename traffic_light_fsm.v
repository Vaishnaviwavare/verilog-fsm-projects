// =====================================================================
// Traffic Light Controller - FSM (Moore Machine)
// Intersection: North-South (NS) road vs East-West (EW) road
// Sequence: NS_GREEN -> NS_YELLOW -> EW_GREEN -> EW_YELLOW -> repeat
// =====================================================================
// Light encoding (3 bits): {Red, Yellow, Green}  -> only one bit high
//   RED    = 3'b100
//   YELLOW = 3'b010
//   GREEN  = 3'b001
//
// CLK_FREQ parameter = number of clk cycles that make up "1 second".
// Set it small (e.g. 4) in the testbench for fast simulation, and to
// your real board's clock frequency (e.g. 50_000_000 for a 50 MHz
// clock) for actual FPGA/ASIC implementation.
// =====================================================================

module traffic_light_fsm #(
    parameter CLK_FREQ       = 4,   // clk cycles per simulated "second"
    parameter NS_GREEN_TIME  = 8,   // seconds
    parameter EW_GREEN_TIME  = 6,   // seconds
    parameter YELLOW_TIME    = 3    // seconds
)(
    input  wire       clk,
    input  wire       rst,          // active-high synchronous reset
    output reg  [2:0] ns_light,      // {R,Y,G} for North-South road
    output reg  [2:0] ew_light,      // {R,Y,G} for East-West road
    output wire [1:0] state_out      // exposed for the testbench/debug
);

    // ---------------- State encoding ----------------
    localparam NS_GREEN  = 2'b00;
    localparam NS_YELLOW = 2'b01;
    localparam EW_GREEN  = 2'b10;
    localparam EW_YELLOW = 2'b11;

    // ---------------- Light encoding -----------------
    localparam RED    = 3'b100;
    localparam YELLOW = 3'b010;
    localparam GREEN  = 3'b001;

    reg [1:0]  state, next_state;
    reg [4:0]  timer;         // seconds remaining in current state
    reg [31:0] clk_counter;   // divides clk down to a 1-second tick
    reg        tick;

    assign state_out = state;

    // ---------------- 1-second tick generator ----------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_counter <= 0;
            tick        <= 1'b0;
        end else if (clk_counter == CLK_FREQ - 1) begin
            clk_counter <= 0;
            tick        <= 1'b1;
        end else begin
            clk_counter <= clk_counter + 1;
            tick        <= 1'b0;
        end
    end

    // ---------------- State + timer register ----------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= NS_GREEN;
            timer <= NS_GREEN_TIME - 1;
        end else if (tick) begin
            if (timer == 0) begin
                state <= next_state;
                case (next_state)
                    NS_GREEN:  timer <= NS_GREEN_TIME - 1;
                    NS_YELLOW: timer <= YELLOW_TIME - 1;
                    EW_GREEN:  timer <= EW_GREEN_TIME - 1;
                    EW_YELLOW: timer <= YELLOW_TIME - 1;
                    default:   timer <= NS_GREEN_TIME - 1;
                endcase
            end else begin
                timer <= timer - 1;
            end
        end
    end

    // ---------------- Next-state logic (round robin) ----------------
    always @(*) begin
        case (state)
            NS_GREEN:  next_state = NS_YELLOW;
            NS_YELLOW: next_state = EW_GREEN;
            EW_GREEN:  next_state = EW_YELLOW;
            EW_YELLOW: next_state = NS_GREEN;
            default:   next_state = NS_GREEN;
        endcase
    end

    // ---------------- Output logic (Moore: depends only on state) ----------------
    always @(*) begin
        case (state)
            NS_GREEN: begin
                ns_light = GREEN;
                ew_light = RED;
            end
            NS_YELLOW: begin
                ns_light = YELLOW;
                ew_light = RED;
            end
            EW_GREEN: begin
                ns_light = RED;
                ew_light = GREEN;
            end
            EW_YELLOW: begin
                ns_light = RED;
                ew_light = YELLOW;
            end
            default: begin
                ns_light = RED;
                ew_light = RED;
            end
        endcase
    end

endmodule
