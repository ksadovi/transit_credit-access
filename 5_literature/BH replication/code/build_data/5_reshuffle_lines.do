** Produce 1,999 permutations of lines within groups with the same number of links
set seed 1
use "$data/lines", clear
sort lineid
gen year_operate0 = year_opening
gen int group = nlinks
replace group = 99 if year_operate0==2003 // don't permute the pilot line that opened in 2003

forvalues sc = 1/1999 {
	permutevar year_operate0, cluster(group)
	rename year_operate0_shuffled year_operate`sc'
}

save "$data/reshuffle_nlink", replace
