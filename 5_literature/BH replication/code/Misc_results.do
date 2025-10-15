log using "$results/Misc_results.log", replace

use "$data/lines", clear
** Built and unbuilt lines differ by the number of links
gen open = date_operate<=mdy(12,31,2016)
tabstat nlinks if lineid!=1, by(open) s(mean N) // exclude the pilot line
reg nlinks open if lineid!=1, r

** Average employment growth and average MA growth
use "$data/analysis_data", clear
sum emp_growth dma0 if !mi(emp_growth)

log close
