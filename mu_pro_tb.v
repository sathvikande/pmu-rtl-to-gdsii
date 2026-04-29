`timescale 1ns/1ps

module pmu_pro_tb();
    // Signal Declarations
    reg clk;
    reg rst_n;
    reg wkup_irq;
    reg tmout_evt;
    reg [1:0] load_lvl;

    wire sys_clk_en;
    wire [1:0] volt_sel;
    wire [3:0] curr_state;

    // --- Waveform Dumping (SHM) ---
    initial begin
        $shm_open("waves.shm"); // Opens the database
        $shm_probe("AS");       // Probes all signals in the current scope and below
    end

    // Instantiate the Optimized PMU
    pmu_pro_optimized uut (
        .clk(clk),
        .rst_n(rst_n),
        .wkup_irq(wkup_irq),
        .load_lvl(load_lvl),
        .tmout_evt(tmout_evt),
        .sys_clk_en(sys_clk_en),
        .volt_sel(volt_sel),
        .curr_state(curr_state)
    );

    // Clock Generation: 100MHz (10ns period)
    always #5 clk = ~clk;

    // Monitor for Terminal Output
    initial begin
        $display("\n--- Starting PMU Simulation (SHM Enabled) ---");
        $monitor("Time: %0t | State: %b | Load: %b | Clk_En: %b | Volt: %b", 
                 $time, curr_state, load_lvl, sys_clk_en, volt_sel);
    end

    // Stimulus Process
    initial begin
        // Initialize
        clk = 0;
        rst_n = 0;
        wkup_irq = 0;
        tmout_evt = 0;
        load_lvl = 2'b00;

        // Reset
        #15 rst_n = 1;
        
        // 1. Wakeup: SLEEP -> IDLE
        #20 wkup_irq = 1;
        #10 wkup_irq = 0;

        // 2. Load: IDLE -> ACTIVE
        #20 load_lvl = 2'b10;

        // 3. Peak: ACTIVE -> BOOST
        #30 load_lvl = 2'b11;

        // 4. Cool down: BOOST -> ACTIVE -> IDLE
        #30 load_lvl = 2'b00;

        // 5. Shutdown: IDLE -> SLEEP
        #30 tmout_evt = 1;
        #10 tmout_evt = 0;

        #50 $display("--- Simulation Finished ---");
        $finish;
    end

endmodule
