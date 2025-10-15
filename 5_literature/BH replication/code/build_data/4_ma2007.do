** Compute MA for the initial year 2007

local year 2007

** First non-transfer travel time along railroads
use "${data}/line_stations", clear
merge m:1 lineid using "${data}/lines", keep(3) nogen keepusing(year_opening speed)
keep if year_opening<=`year' | `year'==2019
sort lineid linestationid
keep lineid linestationid cityid speed
rename cityid cityid2
by lineid: gen cityid1 = cityid2[_n-1]
merge m:1 cityid1 cityid2 using "${data}/distances", keep(1 3) nogen
sort lineid linestationid
by lineid: gen linekm2 = sum(dist)
drop dist cityid1 linestationid

tempfile line2
save `line2', replace

drop speed // will get it from `line2', should be constant along the line
rename (cityid2 linekm2) (cityid1 linekm1)
joinby lineid using `line2'
drop if cityid1==cityid2
gen rrtime = 60* abs(linekm2-linekm1) * 1.3 / speed // 60 converts to min, 1.3 for HSR running below nominal speed
collapse (min) rrtime, by(cityid1 cityid2) fast // if line goes C->A->B->A->D, it may require a change C->A + A->D but changes are free now

tempfile rrdirect
save "`rrdirect'"

** Now the full matrix, only direct routes
use "${data}/distances", clear
gen time = 60 * 1.2 * dist/120
keep cityid1 cityid2 time

merge 1:1 cityid1 cityid2 using "`rrdirect'", assert(1 3) nogen keepusing(rrtime)
replace time = min(time,rrtime)
drop rrtime
tempfile time
save "`time'" // 0th iteration
erase "`rrdirect'"

** And iterate to get triangular inequality
local it = 1
local nupdate = 1
qui while (`it'<=20 & `nupdate'>0) {
	noi di "Iteration `it'"
	use "${data}/triplets", clear
	rename (cityidA cityidC) (cityid1 cityid2)
	merge m:1 cityid1 cityid2 using "`time'", assert(2 3) keep(3) nogen
	rename (cityid1 cityid2 time) (cityidA cityidC timeAC)

	rename (cityidC cityidB) (cityid1 cityid2)
	merge m:1 cityid1 cityid2 using "`time'", assert(2 3) keep(3) nogen
	rename (cityid1 cityid2 time) (cityidC cityidB timeCB)

	gen timeindirect = timeAC + timeCB + 0 // 0 min to change
	drop cityidC timeAC timeCB
	rename (cityidA cityidB) (cityid1 cityid2)
	collapse (min) timeindirect, by(cityid1 cityid2) fast

	tempfile sym
	save `sym', replace
	rename (cityid1 cityid2) (cityid2 cityid1)
	append using `sym'

	merge 1:1 cityid1 cityid2 using "`time'", nogen
	count if timeindirect<time-0.001 // -0.001 to avoid false positives because of rounding
	local nupdate = r(N)
	noi replace time = min(time, timeindirect)
	drop timeindirect
	save "`time'", replace
	local ++it
}

** Now compute MA
use "`time'", clear
rename cityid2 cityid
merge m:1 cityid using "${data}/citycentroids", assert(3) nogen keepusing(population2000)
gen weight =  exp(-0.02*time)
gen ma`year' = population2000*weight
collapse (sum) ma*`year', by(cityid1) fast
rename cityid1 cityid
replace ma`year' = log(ma`year')
gen year = `year'
save "${data}/ma`year'", replace		
