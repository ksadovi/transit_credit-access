use "${data}/analysis_data", clear
keep if !mi(dlog_avgnworkers_ppl_wc)

// demean all geocontrols [for pvalues this is done by the inddemean option]
foreach v of varlist dma_nlink_pscore distance_B lat lon {
	qui sum `v'
	replace `v' = `v'-r(mean)
}

global conley_options "panelvar(cityid) lon(longitude) lat(latitude) timevar(year) dist(500) lag(9999) bartlett"

* col 1: unadjusted
eststo clear
eststo : ols_spatial_HAC dma0 c distance_B lat lon, $conley_options
	test distance_B lat lon 
	estadd scalar F = r(F)
	estadd scalar Fp = r(p)
	estadd local col = "1"
	
* col 2: recentered, no mu
ri_spectest ma_nlink_rc distance_B lat lon, sim(ma_nlink_rc_*)
	local jointp = r(jointp)
eststo : ols_spatial_HAC ma_nlink_rc c distance_B lat lon, $conley_options 
	estadd scalar RI_pvalue = `jointp'
	estadd local col = "2"
	
* col 3: recentered, just mu
ri_spectest ma_nlink_rc dma_nlink_pscore, sim(ma_nlink_rc_*)
	local jointp = r(jointp)
eststo : ols_spatial_HAC ma_nlink_rc c dma_nlink_pscore, $conley_options 
	estadd scalar RI_pvalue = `jointp'
	estadd local col = "3"

* col 4 recentered, geo variables and mu
ri_spectest ma_nlink_rc distance_B lat lon dma_nlink_pscore, sim(ma_nlink_rc_*)
	local jointp = r(jointp)
eststo : ols_spatial_HAC ma_nlink_rc c distance_B lat lon dma_nlink_pscore, $conley_options 
	estadd scalar RI_pvalue = `jointp'
	estadd local col = "4"
	
esttab using "$results/Table2.csv", b(%9.3f) se(%9.3f) nostar r2 ///
	replace obslast order(distance_B lat lon dma_nlink_pscore c) scalars(RI_pvalue col)
