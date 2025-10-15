*Clean lines and stations data

* Reads lists of lines and stations
import excel "${raw}/stations.xlsx", clear first case(lower) sheet(Lines)
tempfile lines
save `lines'

import excel "${raw}/stations.xlsx", clear first case(lower) sheet(LineStations)

*Assign id to line stations
gen linestationid=_n

merge m:1 lineid using `lines', assert(3) nogen
sort linestationid

keep linestationid lineid superlineid linename year_planned year_approved station_name_cn city_cn province_cn date_build date_operate line_operating line_type minspeed_design maxspeed_design mileage plan_type planid
assert !mi(station_name_cn)

* Get rid of the "station" suffix "站"
foreach suffix in "站"{
	local l=length("`suffix'")
	replace station_name_cn = substr(station_name_cn, 1, length(station_name_cn) - `l') if substr(station_name_cn, -`l', `l') =="`suffix'"
}

*Restrict to mainland China (drop Hainan, Hong Kong, Taiwan, Macau)
foreach province in "海南" "香港" "台湾" "澳门"{
	drop if province_cn=="`province'"	
}

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

gen speed = maxspeed_design
replace speed = minspeed_design if mi(speed)
drop maxspeed_design minspeed_design

gen line_type_en="4V4H" if line_type=="四横四纵"
replace line_type_en="8V8H" if line_type=="八横八纵"
replace line_type_en="intercity" if line_type=="城际客运系统"
replace line_type_en="strait" if line_type=="海峡西岸铁路"
replace line_type_en="upgraded" if line_type=="提速改造"
replace line_type_en="midwest" if line_type=="完善路网布局和西部开发性新线"

* make sure lineid uniquely identifies line name
sort linename lineid
assert (lineid!=lineid[_n-1]) | (linename==linename[_n-1])

sort linestationid
order linestationid lineid superlineid linename station_name_cn city_cn province_cn date_build date_operate line_operating line_type* speed mileage 

drop if province_cn=="海南" | province_cn=="香港" | province_cn=="澳门" | province_cn=="台湾"  // Restrict to mainland China
merge m:1 city_cn province_cn using "$data/citycentroids", assert(2 3) keep(3) nogen keepusing(cityid city_en province_en)

sort lineid linestationid
save "${data}/stations_clean", replace

/*===========================================================================
			Build Database of Raillines, Stations, and Connections 
===========================================================================*/
** Lines
use "${data}/stations_clean", clear

keep lineid superlineid linename line_operating date_build date_operate line_type_en speed year_planned year_approved plan_type planid
gen upgraded = (line_type_en == "upgraded")
drop if line_type_en == "upgraded" // Only keep new lines, drop line upgrades
duplicates drop
isid lineid

assert !mi(date_operate) if line_operating==1
gen year_opening = cond(line_operating==1, year(date_operate), 2019) // 2019 = planned but not opened
gen year_build = year(date_build)
gen construction_days = date_operate - date_build
gen construction_years = year(date_operate) - year(date_build)
save "${data}/lines", replace

** Stations (unique per city/line)
use "${data}/stations_clean", clear // 182 lines initially

drop if line_type_en == "upgraded" // now 168 lines
keep linestationid lineid city_cn city_en province_cn province_en cityid 
drop if province_cn=="海南" | province_cn=="香港" | province_cn=="澳门"  | province_cn=="台湾" 

drop if lineid==lineid[_n+1] & cityid==cityid[_n+1] // drop multiple consequent stations in the same city
bys lineid : drop if _N==1 // completely local HSR are not relevant; now 150 lines

sort lineid linestationid
save "${data}/line_stations", replace


** Build connections: pairs of adjacent stations
use "${data}/line_stations", clear
keep lineid cityid
rename cityid cityid1
by lineid: gen cityid2 = cityid1[_n+1]
drop if mi(cityid2)
gen connectionid = _n
save "${data}/line_connections", replace

* Test that there are no crazy connections (between places super far away) 
* Also remove lines with no connections from line.dta and add total computed distance of the line to the lines file. 
* It's based on centroid distances for now and does not match the reported length of line in Lin (2017, Table A4)
use "${data}/line_connections", clear
merge m:1 cityid1 cityid2 using "${data}/distances", assert(2 3) keep(3) nogen
sum dist, d // median around 90, max=539

collapse (sum) computed_length=dist (count) nlinks=connectionid, by(lineid)
merge 1:1 lineid using "${data}/lines", nogen keep(3)
order computed_length nlinks, last
save "${data}/lines", replace

* Add first & last stop on each line to the lines file
use "${data}/line_stations", clear
merge m:1 cityid using "${data}/citycentroids", assert(2 3) keep(3) nogen
gen cityprov = city_en + ", " + province_en 
bys lineid : gen firststop = cityprov[1]
by lineid : gen laststop = cityprov[_N]

duplicates drop lineid, force
keep lineid firststop laststop 

merge 1:1 lineid using "${data}/lines", nogen
order firststop laststop, last
save "${data}/lines", replace

/* Classify "branch" lines which don't have any provincial capital on them
use "${data}/line_stations", clear
merge m:1 cityid using "${data}/citycentroids", keep(1 3) keepusing(prov_capital) //8 little districts are not in city_database_wide, I guess they never have outcome data
replace prov_capital=0 if mi(prov_capital)
collapse (sum) connect_capitals=prov_capital, by(lineid)
merge 1:1 lineid using "$data/lines", assert(3) nogen
order connect_capitals, last
gen byte branch = (connect_capitals==0)
save "${data}/lines", replace */

** For each city, check whether it's been connected ever, and when; add this to the citycentroids file
use "${data}/line_stations", clear
merge m:1 lineid using "${data}/lines", assert(2 3) keep(3) nogen keepusing(line_operating date_operate upgraded)
collapse (count) nlines=line_operating (min) date_firstconnected=date_operate, by(cityid) 
tempfile planned
save `planned'

use "${data}/citycentroids", clear
merge 1:1 cityid using `planned', assert(1 3) gen(mplanned)

gen planned = mplanned==3
replace nlines = 0 if !planned
drop mplanned
gen year_firstconnected = year(date_firstconnected)
order year_firstconnected, after (date_firstconnected)

label variable nlines "number of planned HSR lines passing through"
label variable date_firstconnected "date of first planned HSR opening"
label variable year_firstconnected "year of first planned HSR opening"
label variable planned "dummy of having at least one line planned"
save, replace

