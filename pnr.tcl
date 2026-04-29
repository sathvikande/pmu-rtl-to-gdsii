###########################################################################
# PMU_PRO_OPTIMIZED: MMMC-COMPLIANT PNR FLOW (v13.1)
# FULL AUTOMATED SCRIPT WITH SIGN-OFF REPORTING
###########################################################################

# --- 0. WORKSPACE CLEANUP ---
exec rm -rf reports db pmu_complete.enc pmu_complete.enc.dat pmu_clk.ctstch constraints.sdc
exec mkdir -p reports/cts_reports reports/timing reports/power reports/physical db netlists

# --- 1. DESIGN SETTINGS ---
set init_verilog "netlists/pmu_scl180_netlist.v"
set init_top_cell "pmu_pro_optimized"
set scl_lef_dir "/mnt/hgfs/scl_bridge/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/6M1L/lef"
set init_lef_file "$scl_lef_dir/scl18fs120_tech.lef $scl_lef_dir/scl18fs120_std.lef"
set init_pwr_net "VDD"
set init_gnd_net "VSS"
set init_lib_file "/mnt/hgfs/scl_bridge/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/6M1L/liberty/lib_flow_ss/tsl18fs120_scl_ss.lib"

# --- 2. MMMC SETUP ---
set sdc_file [open "constraints.sdc" w]
puts $sdc_file "current_design pmu_pro_optimized"
puts $sdc_file "create_clock -name clk -period 10 \[get_ports clk\]" 
close $sdc_file

create_library_set -name default_lib -timing $init_lib_file
create_rc_corner -name default_rc
create_delay_corner -name default_delay_corner \
    -library_set default_lib \
    -rc_corner default_rc \
    -opcond_library tsl18fs120_scl_ss \
    -opcond tsl18fs120_scl_ss

create_constraint_mode -name default_constraint -sdc_files {constraints.sdc}
create_analysis_view -name default_view -delay_corner default_delay_corner -constraint_mode default_constraint

# --- 3. INITIALIZATION ---
init_design -setup {default_view} -hold {default_view}

# --- 4. GLOBAL NET CONNECTIONS ---
globalNetConnect VDD -type pgpin -pin VDD -inst *
globalNetConnect VSS -type pgpin -pin VSS -inst *
globalNetConnect VDD -type net -net VDD
globalNetConnect VSS -type net -net VSS

# --- 5. FLOORPLAN & POWER PLANNING ---
floorPlan -r 1.0 0.7 10.08 10.08 10.08 10.08

addRing -nets {VSS VDD} -width 2 -spacing 1 \
        -layer {top M6 bottom M6 left M5 right M5} -offset 0.5

addStripe -nets {VSS VDD} -layer M2 -width 1.0 -spacing 0.5 \
          -direction vertical -set_to_set_distance 15 \
          -start_from left -xleft_offset 10 -extend_to design_boundary

sroute -connect { blockPin padPin corePin floatingStripe } \
       -allowLayerChange 1 \
       -allowJogging 1 \
       -nets { VDD VSS }

# --- 6. PLACEMENT & CTS ---
setPlaceMode -fp false
placeDesign -prePlaceOpt

set cts_file [open "pmu_clk.ctstch" w]
puts $cts_file "AutoCTSRootPin clk"
puts $cts_file "MaxDelay       1.0ns"
puts $cts_file "MinDelay       0.0ns"
puts $cts_file "MaxSkew        200ps"
puts $cts_file "Buffer         bufbd7 bufbd4 bufbd2"
puts $cts_file "End"
close $cts_file

specifyClockTree -file pmu_clk.ctstch
ckSynthesis -report reports/cts_reports/pmu_cts.ctsrpt
refinePlace -preserveRouting

# --- 7. FILLER & ROUTING ---
addFiller -cell {feedth9 feedth3 feedth} -prefix FILL
routeDesign -globalDetail

# --- 8. POST-ROUTING EXTRACTION & ANALYSIS ---
setAnalysisMode -checkType setup -skew true -clockPropagation autoDetectClockTree
extractRC

# --- 9. GENERATE ALL POST-PNR REPORTS ---

# A. Timing Reports (Setup & Hold)
setAnalysisMode -checkType setup
report_timing > reports/timing/post_route_setup.rpt
report_constraint -all_violators > reports/timing/setup_violators.rpt

setAnalysisMode -checkType hold
report_timing > reports/timing/post_route_hold.rpt
report_constraint -all_violators > reports/timing/hold_violators.rpt

# B. Clock Tree Reports
report_clock_tree -summary > reports/cts_reports/clk_summary.rpt
report_skew -clock clk > reports/cts_reports/clk_skew.rpt

# C. Power Analysis (Static)
report_power -outfile reports/power/static_power_report.rpt

# D. Physical & Verification Reports
report_area > reports/physical/area.rpt
report_density > reports/physical/density.rpt
verifyGeometry -report reports/physical/geometry.rpt
verifyConnectivity -type all -report reports/physical/connectivity.rpt

# E. Summary Report
summaryReport -outdir reports/summary_report

# --- 10. SAVE FINAL OUTPUTS ---
saveNetlist netlists/pmu_final_signoff.v
saveDesign db/pmu_complete.enc

puts "############################################################"
puts "   PNR FLOW COMPLETE - ALL REPORTS SAVED IN ./reports/      "
puts "############################################################"
