`timescale 1ns/1ps
module pmu_pro_optimized (
    input  wire       clk,        // System Clock
    input  wire       rst_n,      // Active Low Reset
    input  wire       wkup_irq,   // Wakeup Interrupt
    input  wire [1:0] load_lvl,   // 00:None, 01:Low, 10:Med, 11:High
    input  wire       tmout_evt,  // Idle timeout event
    output reg        sys_clk_en, // Clock Gate Enable (0 = Clock Stopped)
    output reg  [1:0] volt_sel,   // Voltage Scaling: 00:0.7V, 01:0.9V, 11:1.1V
    output reg  [3:0] curr_state  // One-Hot State Output
);

    // One-Hot State Encoding for maximum efficiency
    localparam ST_SLEEP  = 4'b0001;
    localparam ST_IDLE   = 4'b0010;
    localparam ST_ACTIVE = 4'b0100;
    localparam ST_BOOST  = 4'b1000;

    reg [3:0] state_reg, next_state;

    // 1. Sequential State Transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state_reg <= ST_SLEEP;
        else
            state_reg <= next_state;
    end

    // 2. Optimized Next-State Logic (Minimized Logic Gates)
    always @(*) begin
        next_state = state_reg; // Default: Hold current state
        case (state_reg)
            ST_SLEEP:  if (wkup_irq)  next_state = ST_IDLE;
            
            ST_IDLE:   if (tmout_evt)  next_state = ST_SLEEP;
                       else if (load_lvl > 0) next_state = ST_ACTIVE;
            
            ST_ACTIVE: if (load_lvl == 2'b11) next_state = ST_BOOST;
                       else if (load_lvl == 2'b00) next_state = ST_IDLE;
            
            ST_BOOST:  if (load_lvl < 2'b11)  next_state = ST_ACTIVE;

            default:   next_state = ST_SLEEP;
        endcase
    end

    // 3. Registered & Optimized Output Logic
    // Eliminates combinational glitches that cause power spikes
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sys_clk_en <= 1'b0;
            volt_sel   <= 2'b00;
            curr_state <= ST_SLEEP;
        end else begin
            curr_state <= next_state; // Output current state
            case (next_state)
                ST_SLEEP: begin
                    sys_clk_en <= 1'b0; // Shut down clock tree
                    volt_sel   <= 2'b00; // Minimum leakage voltage
                end
                ST_IDLE: begin
                    sys_clk_en <= 1'b1; 
                    volt_sel   <= 2'b01; // Nominal voltage
                end
                ST_ACTIVE: begin
                    sys_clk_en <= 1'b1;
                    volt_sel   <= 2'b01;
                end
                ST_BOOST: begin
                    sys_clk_en <= 1'b1;
                    volt_sel   <= 2'b11; // Overdrive voltage
                end
            endcase
        end
    end
endmodule
