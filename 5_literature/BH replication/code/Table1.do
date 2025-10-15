use "${data}/analysis_data", clear
global conley_options "panelvar(cityid) lon(longitude) lat(latitude) timevar(year) dist(500) lag(9999) bartlett"

*** Table 1: Employment effects of MA 
eststo clear
** Panel A: no controls
* Panel A col 1
eststo : ols_spatial_HAC emp_growth dma0 c , $conley_options
	estadd local col = "A1"

* Panel A col 2
ri_ci emp_growth dma0 ma_nlink_rc, range(-1 2) zsim(ma_nlink_rc_*)
	local ri_left = r(ci_left)
	local ri_right = r(ci_right)

eststo : iv_spatial_hac emp_growth dma0 ma_nlink_rc, controls(c) options($conley_options)
	estadd scalar ri_left = `ri_left'
	estadd scalar ri_right = `ri_right'
	estadd local col = "A2"

* Panel A col 3
ri_ci emp_growth ma_nlink_rc, range(-1 2) zsim(ma_nlink_rc_*) controls(dma_nlink_pscore)
	local ri_left = r(ci_left)
	local ri_right = r(ci_right)
eststo : ols_spatial_HAC emp_growth ma_nlink_rc dma_nlink_pscore c , $conley_options
	estadd scalar ri_left = `ri_left'
	estadd scalar ri_right = `ri_right'
	estadd local col = "A3"

** Panel B: geocontrols
* Panel B col 1
eststo : ols_spatial_HAC emp_growth dma0 distance_B lat lon c , $conley_options
	estadd local col = "B1"

* Panel B col 2
ri_ci emp_growth dma0 ma_nlink_rc, range(-1 2) zsim(ma_nlink_rc_*) controls(distance_B lat lon)
	local ri_left = r(ci_left)
	local ri_right = r(ci_right)

eststo : iv_spatial_hac emp_growth dma0 ma_nlink_rc, c(distance_B lat lon c) options($conley_options)
	estadd scalar ri_left = `ri_left'
	estadd scalar ri_right = `ri_right'
	estadd local col = "B2"

* Panel B col 3
ri_ci emp_growth ma_nlink_rc, range(-1 2) zsim(ma_nlink_rc_*) controls(dma_nlink_pscore distance_B lat lon)
	local ri_left = r(ci_left)
	local ri_right = r(ci_right)
eststo : ols_spatial_HAC emp_growth ma_nlink_rc dma_nlink_pscore distance_B lat lon c , $conley_options
	estadd scalar ri_left = `ri_left'
	estadd scalar ri_right = `ri_right'
	estadd local col = "B3"

esttab using "$results/Table1.csv", b(%9.3f) se(%9.3f) nostar r2 ///
	replace obslast drop(c) scalar(col ri_left ri_right)  ///
	rename(ma_nlink_rc dma0) order(dma0 dma_nlink_pscore)
