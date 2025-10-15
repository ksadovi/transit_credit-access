// Author: Kirill Borusyak, 15nov2020. Based on shufflevar
// Same syntax but generates a random permutation, while shufflevar never leaves any observation in the same place

capture program drop permutevar
program define permutevar
	version 10
	syntax varlist(min=1) [ , Joint DROPold cluster(varname)]
	tempvar oldsortorder withinorder
	gen `oldsortorder'=_n
	if "`cluster'"!="" {
		local bystatement "by `cluster': "
		sort `cluster' `oldsortorder'
	}
	else {
		local bystatement ""
	}
	`bystatement' gen `withinorder'=_n
	
	if "`joint'"=="joint" {
		tempvar newsortorder
		gen `newsortorder'=uniform()
		sort `cluster' `newsortorder'
		foreach var in `varlist' {
			capture drop `var'_shuffled
			qui `bystatement' gen `var'_shuffled=`var'[`withinorder']
			if "`dropold'"=="dropold" {
				drop `var'
			}
		}
		sort `oldsortorder'
		drop `newsortorder' `withinorder' `oldsortorder'
	}
	else {
		foreach var in `varlist' {
			tempvar newsortorder
			gen `newsortorder'=uniform()
			sort `cluster' `newsortorder'
			capture drop `var'_shuffled
			qui `bystatement' gen `var'_shuffled=`var'[`withinorder']
			drop `newsortorder'
			if "`dropold'"=="dropold" {
				drop `var'
			}
		}
		sort `oldsortorder'
		drop `oldsortorder'
	}
end

