* Output CSV files for the maps

cd "$main/data"

* Line maps for all years (actual + one simulation) --- used in Figures 1.A, 1.B, 2.B, A1
use line_connections, clear
merge m:1 lineid using lines, assert(2 3) keep(3) nogen keepusing(year_opening speed line_type_en firststop laststop computed_length)
merge m:1 lineid using reshuffle_nlink, assert(2 3) keep(3) nogen keepusing(year_operate1)
rename year_operate1 year_operate_sim

rename cityid1 cityid
merge m:1 cityid using citycentroids, keep(1 3) nogen keepusing(latitude longitude city_en)
rename (cityid latitude longitude city_en) (cityid1 latitude1 longitude1 city_en1)
rename cityid2 cityid
merge m:1 cityid using citycentroids, keep(1 3) nogen keepusing(latitude longitude city_en)
rename (cityid latitude longitude city_en1) (cityid2 latitude2 longitude2 city_en2)
sort connectionid
order connectionid, first
export delimited "$outgis/lines_by_year.csv", replace

* Realized, expected and recentered MA growth in 2016 (actual + one simulation) --- used in Figures 1.A, 2.A, 2.B, A1
use ma2016_combined, clear
merge 1:1 cityid using ma_scenarios_2016, keepusing(ma_nlink1) assert(3) nogen
gen dma_nlink1 = ma_nlink1-ma2007
foreach v of varlist dma* {
	replace `v' = 0 if inrange(`v',-10^-6,0)
}
rename (ma_nlink1 dma_nlink1) (ma_sim dma_sim)
gen objectid = _n
export delimited "$outgis/ma2016.csv", replace

