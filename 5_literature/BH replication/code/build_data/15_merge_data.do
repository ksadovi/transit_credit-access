// Generate the main dataset analysis_data

// Get time-invariant city variables (for 310 cities that ever appear in the outcomes data)
use "$data/citycentroids", clear //keepusing(population2000 planned year_firstconnected latitude longitude prov_capital distance_B

merge 1:1 cityid using "$data/ma2016_combined", assert(3) nogen 
merge 1:1 cityid using "${data}/ma_scenarios_2016", assert(3) nogen

// Get time-invariant source of outcomes
preserve
	use "$data/city_database_long", clear
	keep cityid source 
	duplicates drop
	isid cityid
	tempfile outcomes
	save `outcomes'
restore
merge 1:1 cityid using `outcomes', keep(3) nogen // keep 310 cities where outcomes are ever populated
merge 1:1 cityid using "$data/outcomes_2007_2016", keep(3) nogen // keep 283 cities with employment outcomes, out of them 275 passing the outlier filter

// Additional variables 
gen emp_growth=dlog_avgnworkers_ppl_wc	// main outcome variable
gen lat = latitude/100
gen lon = longitude/100
gen c = 1 // constant
forvalues sc = 1/1999 {
	gen ma_nlink_rc_`sc' = ma_nlink`sc' - ma_nlink_pscore
	drop ma_nlink`sc'
}

label var emp_growth "Employment growth"
label var lat "Latitude/100"
label var lon "Longitude/100"
label var c "Constant"

order cityid city_en city_cn emp_growth dma0 dma_nlink_pscore ma_nlink_rc, first 
compress
save "$data/analysis_data", replace
