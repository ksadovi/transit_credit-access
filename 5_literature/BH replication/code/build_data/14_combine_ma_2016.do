// Combine server simulations into one file, computed expected & recentered MA

set more off
local max_sc=1999

use "$server/output/scenario_nlink0_2016", clear
rename ma_nlink0 ma0
merge 1:1 cityid using "${data}/ma2007", nogen assert(3) 
qui forval sc=1/`max_sc' {
	merge 1:1 cityid using "$server/output/scenario_nlink`sc'_2016", nogen assert(3)
}

egen ma_nlink_pscore = rowmean(ma_nlink*)
order cityid year ma0 ma2007 ma_nlink_pscore, first
save "${data}/ma_scenarios_2016", replace 

keep cityid year ma0 ma2007 ma_nlink_pscore
gen dma0 = ma0-ma2007
gen dma_nlink_pscore = ma_nlink_pscore-ma2007
gen ma_nlink_rc = ma0-ma_nlink_pscore

label var ma0 "Actual logMA, 2016"
label var ma2007 "Initial logMA, 2007"
label var ma_nlink_pscore "Expected logMA, 2016"
label var dma0 "Actual MA growth, 2007-2016"
label var dma_nlink_pscore "Expected MA growth, 2007-2016"
label var ma_nlink_rc "Recentered MA, 2016"
save "${data}/ma2016_combined", replace 
