/*
IV with spatial SE (based on ols_spatial_HAC)
Author: Kirill Borusyak, Dec 28, 2020
*/
cap program drop iv_spatial_hac 
program define iv_spatial_hac , eclass 
syntax varlist(min=3 max=3) [if] [in] [aw iw fw pw], Controls(varlist) OPTions(string) // varlist = y x z
qui {
	
	marksample touse
	markout `touse' `varlist' `controls'
	
	tokenize `varlist'
	local y `1'
	local x `2'
	local z `3'
	
	ivreg `y' (`x'=`z') `controls' [`weight'`exp'] if `touse'
	tempvar resid fs
	local iv_coef = _b[`x']
	gen `resid' = `y'-_b[`x']*`x' if `touse'
	reg `x' `z' `controls' [`weight'`exp'] if `touse'
	predict `fs', xb
	
	ols_spatial_HAC `resid' `fs' `controls' [`weight'`exp'] if `touse', `options'
	matrix b = e(b)
	matrix b[1,1] = `iv_coef'
	matrix colnames b = `x' `controls'
	matrix V = e(V)
	matrix colnames V = `x' `controls'
	matrix rownames V = `x' `controls'
	count if `touse'
	local N = r(N)
	ereturn post b V, esample(`touse') depname(`y') obs(`N')  
}
ereturn display
end
