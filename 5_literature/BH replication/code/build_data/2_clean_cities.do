* Clean citycentroids data (from gis output)

// List of provincial capitals
import excel "${raw}/gis/ProvCapitals.xls", clear first case(lower)
tempfile provcap
save `provcap'

// Geo coordinates of prefecture capitals
import excel "${raw}/gis/PrefCapitals.xls", clear first case(lower)
destring adm2_pcode, replace

merge m:1 name name_eng using `provcap', keepusing(name name_eng) assert(1 3)
gen byte prov_capital = _m==3
drop _m

egen dups = count(1), by(adm2_pcode) // There is a dozen of cities for which there are >1 coordinates---drop them, use centroid for simplicity
drop if dups>1 & prov_capital==0 & name_eng!=adm2_eng // drop dups, except when provincial capital or name=prefecture name 
isid adm2_pcode
keep adm2_pcode latitude longitude prov_capital
tempfile prefcap
save `prefcap'

// Main city centroids file
import excel "${raw}/gis/CityCentroids.xls", clear first case(lower)
rename (longitude latitude) (lon_centroid lat_centroid)
assert substr(adm2_pcode,1,2)=="CN"
replace adm2_pcode = substr(adm2_pcode,3,.)
destring adm2_pcode, replace
isid adm2_pcode

** Add exact geographic coordinates from PrefCapitals (but use centroids if exact ones are not available)
merge 1:1 adm2_pcode using `prefcap', assert(1 3) gen(mPrefCap)
gen flag_centroid = mPrefCap==1 // 1 if the coordinate is approximate
replace latitude = lat_centroid if mi(latitude)
replace longitude = lon_centroid if mi(longitude)
replace prov_capital = 0 if mi(prov_capital)
assert !mi(latitude) & !mi(longitude)
drop lat_centroid lon_centroid mPrefCap
drop adm0* fid

** Stripping suffixes from CityCentroids

rename adm1_zh province_cn
rename adm2_zh city_cn
rename objectid cityid

*Remove city suffix			  
foreach  city_suffix in  "林区[3]" "[4]" "市" "藏族自治州" "哈尼族彝族自治州" "哈尼族自治州" "彝族自治州" "土家族苗族自治州" "蒙古族自治州" "蒙古自治州" "哈尼族彝族自治州" "苗族侗族自治州" "哈萨克自治州[5]" "藏族羌族自治州" "傣族景颇族自治州" "壮族苗族自治州" "朝鲜族自治州" "回族自治州" "布依族苗族自治州" "白族自治州" "傣族自治州" "哈尼族" "傈僳族自治州" "黎族苗族自治县[2]" "黎族自治县[2]" "县[2]" "黎族苗族自治县[2]" "市〔1〕" "市[1]" "自治州" "[3]" "县[1]" "地区"{
	gen str_length=length(city_cn)
	local l=length("`city_suffix'")
	count if substr(city_cn,-`l',.)=="`city_suffix'"
	replace city_cn=substr(city_cn,1,str_length-`l') if substr(city_cn,-`l',.)=="`city_suffix'"
	drop str_length
}

*Remove province suffix 
foreach province_suffix in "省" "维吾尔族自治区" "壮族自治区" "回族自治区" "特别行政区" "维吾尔自治区" "自治区" "市"{
	gen str_length=length(province_cn)
	local l=length("`province_suffix'")
	count if substr(province_cn,0-`l',.)=="`province_suffix'"
	replace province_cn=substr(province_cn,1,str_length-`l') if substr(province_cn,0-`l',.)=="`province_suffix'"
	drop str_length
}
/*
correct an error in citycentroids.csv
*/
replace city_cn="株洲" if city_cn=="株州"

split adm1_en, l(1)
split adm2_en, l(1)
drop adm1_en adm2_en
rename adm1_en1 province_en
rename adm2_en1 city_en

replace province_en="Inner Mongolia" if province_en=="Inner"

order cityid city_en province_en, first

/* Export to CSV for maps
preserve
	drop *_cn
	replace city_en = "Nanning" if city_en=="NanNing" // fix a typo
	export delimited "${raw}/gis/all_cities.csv", replace 
	
	keep if prov_capital==1
	gen byte show = inlist(city_en,"Beijing","Tianjin","Hohhot","Harbin","Shanghai","Wuhan","Lhasa") | inlist(city_en,"Ürümqi","Xi'an","Chongqing","Guangzhou")
	export delimited "${raw}/gis/provcapital_cities.csv", replace 
restore */

*Restrict to mainland China
drop if province_cn=="海南" | province_cn=="香港" | province_cn=="澳门" | province_cn=="台湾" 

keep admin_type cityid province_cn province_en city_cn city_en shape_area latitude longitude adm2_pcode prov_capital
order admin_type cityid province_cn city_cn province_en city_en shape_area latitude longitude adm2_pcode prov_capital
quietly{
	replace admin_type = "Prefecture-level city" if city_en=="Nagqu" // nagqu was converted from prefecture to pref-level city in 2017  
	keep if inlist(admin_type,"Prefecture-level city","Municipality","Prefecture","Autonomous prefecture","Sub-prefecture-level city", ///
		"Sub-province-level prefecture", "League","Forestry district") 
	
	isid cityid
	isid city_cn province_cn
	compress
	
	replace city_en = lower(city_en)
	replace province_en = lower(province_en)
	
	replace city_en = subinstr(city_en,"Ā","a",.)
	replace city_en = subinstr(city_en,"È","e",.)
	replace city_en = subinstr(city_en,"Ē","e",.)
	replace city_en = subinstr(city_en,"ā","a",.)
	replace city_en = subinstr(city_en,"á","a",.)
	replace city_en = subinstr(city_en,"à","a",.)
	replace city_en = subinstr(city_en,"ă","a",.)
	replace city_en = subinstr(city_en,"è","e",.)
	replace city_en = subinstr(city_en,"é","e",.)
	replace city_en = subinstr(city_en,"ĕ","e",.)
	replace city_en = subinstr(city_en,"ē","e",.)
	replace city_en = subinstr(city_en,"ī","i",.)
	replace city_en = subinstr(city_en,"ì","i",.)
	replace city_en = subinstr(city_en,"í","i",.)
	replace city_en = subinstr(city_en,"ĭ","i",.)
	replace city_en = subinstr(city_en,"ō","o",.)
	replace city_en = subinstr(city_en,"ó","o",.)
	replace city_en = subinstr(city_en,"ò","o",.)
	replace city_en = subinstr(city_en,"ŏ","o",.)
	replace city_en = subinstr(city_en,"ū","u",.)
	replace city_en = subinstr(city_en,"ú","u",.)
	replace city_en = subinstr(city_en,"ù","u",.)
	replace city_en = subinstr(city_en,"ŭ","u",.)
	replace city_en = subinstr(city_en,"Ü","u",.)
	replace city_en = subinstr(city_en,"ü","u",.)
	replace city_en = subinstr(city_en,"ĝ","g",.)
	replace city_en = subinstr(city_en,"ê","e",.)
	
	* make some exceptions to standardize the city names to be the same
	* as in the Population.xlsx file for matching later
	replace city_en = "diqing" if city_en == "deqen"
	replace city_en = "ganzi" if city_en == "garze"
	replace city_en = "shannan" if city_en == "lhoka"
	replace city_en = "tacheng" if city_en == "tarbagatay"
	replace city_en = "rikaze" if city_en == "xigaze"
}
*outsheet using "${data}/citycentroids.csv", replace

* Add population
merge 1:1 city_en province_en using "$data/population", assert(3)
drop city_chn province_chn _merge
compress

* Compute distance to Beijing in 1,000km (cityid==243)
qui summ latitude if cityid==243
local B_lat=r(mean) 
qui summ longitude if cityid==243
local B_lon=r(mean) 
geodist latitude longitude `B_lat' `B_lon', generate(distance_B) sphere
replace distance_B = distance_B/1000 

/* Labels */
label variable cityid "unique city identifier from citycentroids.csv"
label variable city_cn "city Chinese name"
label variable city_en "city English name"
label variable province_cn "province Chinse name"
label variable province_en "province English name"
label variable admin_type "administrative type of region"
label variable shape_area "area (sq.km)"
label variable latitude "centroid latitude (degrees)"
label variable longitude "centroid longitude (degrees)"
label variable adm2_pcode "administrative code of region (from gis)"
label variable prov_capital "dummy of province capitals"
label variable population2000 "population in 2000"
label variable population2010 "population in 2010"
label variable distance_B "distance to Beijing (km)"

save "${data}/citycentroids", replace

/*===========================================================================
				Build distances
===========================================================================*/
	
use cityid latitude longitude shape_area using "${data}/citycentroids", clear
tempfile cc
save `cc'

drop shape_area
rename (cityid latitude longitude) (cityid1 latitude1 longitude1) 
cross using `cc'
rename (cityid latitude longitude shape_area) (cityid2 latitude2 longitude2 shape_area2) 
geodist latitude1 longitude1 latitude2 longitude2, gen(dist) sphere
gen dist_within = cond(cityid1==cityid2, 128*sqrt(shape_area/3.14)/(45*3.14), dist)
	// sqrt term is the radius of a circle, then get the avg distance assuming capital is in the center
	// this version makes sure it's never 0

drop lat* lon*
sort cityid1 cityid2
save "${data}/distances", replace

/*===========================================================================
			Generate a simple database of provinces
===========================================================================*/
use "${data}/citycentroids", clear
keep province_en province_cn 
duplicates drop
save "${data}/provinces", replace

set more off

/*===========================================================================
			Generate a dataset of all city triplets for MA computation
===========================================================================*/
use cityid using "$data/citycentroids", clear
sort cityid
save "$data/cityidlist", replace

use "$data/cityidlist", clear
rename cityid cityidA
cross using "$data/cityidlist"
rename cityid cityidB
keep if cityidA<cityidB
cross using "$data/cityidlist"
rename cityid cityidC // route is A->C->B
save "$data/triplets", replace
