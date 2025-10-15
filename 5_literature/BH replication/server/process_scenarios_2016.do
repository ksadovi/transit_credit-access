//cd "$main/server" // to uncomment if not running on the server
local copy = `1'
cap mkdir logs
log using logs/log`copy'.smcl, replace
local scstart = (`copy'-1)*20 // for paralleling this on the server
local scend = `copy'*20 - 1

/* Data inputs:
	input/line_stations
	input/reshuffle_*
	input/distances
	input/triplets
	input/citycentroids
*/

local exercise nlink // the type of permutations
local year 2016

forvalues sc = `scstart'/`scend' {
	noi di "** Scenario `sc' Year `year'"
	** First non-transfer travel time along railroads
	use input/line_stations, clear // lists stations in the correct order for each line
	merge m:1 lineid using input/reshuffle_`exercise', keep(3) nogen keepusing(year_operate`sc' speed) // scenarios which indicate when each line counterfactually opens
	keep if year_operate`sc'<=`year' | `year'==2019
	sort lineid linestationid
	keep lineid linestationid cityid speed
	rename cityid cityid2
	by lineid: gen cityid1 = cityid2[_n-1]
	merge m:1 cityid1 cityid2 using input/distances, keep(1 3) nogen
	sort lineid linestationid
	by lineid: gen linekm2 = sum(dist)
	drop dist cityid1 linestationid

	tempfile line2
	save `line2', replace

	drop speed // will get it from `line2', should be constant along the line
	rename (cityid2 linekm2) (cityid1 linekm1)
	joinby lineid using `line2' // form all pairs of cities which are directly connected by railroad
	drop if cityid1==cityid2
	gen rrtime = 60* abs(linekm2-linekm1) * 1.3 / speed // 60 converts to min, 1.3 for HSR running below nominal speed
	collapse (min) rrtime, by(cityid1 cityid2) fast // if line goes C->A->B->A->D, it may require a change C->A + A->D but changes are free now
	
	tempfile rrdirect_`exercise'`sc'_`year'
	save "`rrdirect_`exercise'`sc'_`year''"

	** Now the full matrix, only direct routes (by railroad or not)
	use input/distances, clear
	gen time = 60 * 1.2 * dist/120 // travel time without railroads
	keep cityid1 cityid2 time

	merge 1:1 cityid1 cityid2 using "`rrdirect_`exercise'`sc'_`year''", assert(1 3) nogen keepusing(rrtime)
	replace time = min(time,rrtime) // use railroad if it's faster
	drop rrtime
	tempfile time_`exercise'`sc'_`year'
	save "`time_`exercise'`sc'_`year''" // 0th iteration
	erase "`rrdirect_`exercise'`sc'_`year''"

	** And iterate until have triangular inequality
	local it = 1
	local nupdate = 1
	qui while (`it'<=20 & `nupdate'>0) {
		noi di "Iteration `it'"
		use input/triplets, clear
		rename (cityidA cityidC) (cityid1 cityid2)
		merge m:1 cityid1 cityid2 using "`time_`exercise'`sc'_`year''", assert(2 3) keep(3) nogen
		rename (cityid1 cityid2 time) (cityidA cityidC timeAC)

		rename (cityidC cityidB) (cityid1 cityid2)
		merge m:1 cityid1 cityid2 using "`time_`exercise'`sc'_`year''", assert(2 3) keep(3) nogen
		rename (cityid1 cityid2 time) (cityidC cityidB timeCB)

		gen timeindirect = timeAC + timeCB + 0 // 0 min to change
		drop cityidC timeAC timeCB
		rename (cityidA cityidB) (cityid1 cityid2)
		collapse (min) timeindirect, by(cityid1 cityid2) fast

		tempfile sym
		save `sym', replace
		rename (cityid1 cityid2) (cityid2 cityid1)
		append using `sym'

		merge 1:1 cityid1 cityid2 using "`time_`exercise'`sc'_`year''", nogen
		count if timeindirect<time-0.001 // -0.001 to avoid false positives because of rounding
		local nupdate = r(N)
		noi replace time = min(time, timeindirect)
		drop timeindirect
		save "`time_`exercise'`sc'_`year''", replace
		local ++it
	}

	** Now compute MA
	use "`time_`exercise'`sc'_`year''", clear
	rename cityid2 cityid
	merge m:1 cityid using input/citycentroids, assert(3) nogen keepusing(population2000)
	gen weight =  exp(-0.02*time)
	gen ma_`exercise'`sc' = population2000*weight
	//gen ma_loo_`exercise'`sc' = population2000*weight if cityid != cityid1 // leave-own-city-out version
	collapse (sum) ma*_`exercise'`sc', by(cityid1) fast
	rename cityid1 cityid
	replace ma_`exercise'`sc' = log(ma_`exercise'`sc')
	//replace ma_loo_`exercise'`sc' = log(ma_loo_`exercise'`sc')
	gen year = `year'
	save output/scenario_`exercise'`sc'_`year', replace		
}
log close _all
