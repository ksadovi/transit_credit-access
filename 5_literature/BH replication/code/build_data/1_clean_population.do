*** Import population sizes
import excel "${raw}/Population.xlsx", clear case(lower) firstrow sheet("Data")

replace status = lower(status)
replace name = lower(name)
replace name = subinstr(name," shì","",.) // need to make names match, so remove accents etc.
replace name = subinstr(name," shĕng","",.)
replace name = subinstr(name,"Ā","a",.)
replace name = subinstr(name,"È","e",.)
replace name = subinstr(name,"Ē","e",.)
replace name = subinstr(name,"ā","a",.)
replace name = subinstr(name,"á","a",.)
replace name = subinstr(name,"à","a",.)
replace name = subinstr(name,"ă","a",.)
replace name = subinstr(name,"è","e",.)
replace name = subinstr(name,"é","e",.)
replace name = subinstr(name,"ĕ","e",.)
replace name = subinstr(name,"ē","e",.)
replace name = subinstr(name,"ī","i",.)
replace name = subinstr(name,"ì","i",.)
replace name = subinstr(name,"í","i",.)
replace name = subinstr(name,"ĭ","i",.)
replace name = subinstr(name,"ō","o",.)
replace name = subinstr(name,"ó","o",.)
replace name = subinstr(name,"ò","o",.)
replace name = subinstr(name,"ŏ","o",.)
replace name = subinstr(name,"ū","u",.)
replace name = subinstr(name,"ú","u",.)
replace name = subinstr(name,"ù","u",.)
replace name = subinstr(name,"ŭ","u",.)
replace name = subinstr(name,"Ü","u",.)
replace name = subinstr(name,"ü","u",.)
replace name = subinstr(name,"ĝ","g",.)
replace name = subinstr(name,"ê","e",.)


replace status = lower(status)
drop if status=="sovereign state"
// identify rows which are for provinces not cities
gen isprovince = inlist(status,"province","municipal province") | regexm(status,"autonomous region") 
gen province_en = name if isprovince // get provinces in English & Chinese
gen province_chn = native if isprovince
replace province_en = province_en[_n-1] if mi(province_en)
replace province_chn = province_chn[_n-1] if mi(province_chn)
drop if isprovince
drop isprovince
rename (name native) (city_en city_chn)
replace province_en = "guangxi" if regexm(province_en,"guangxi ") // fix typos
replace province_en = "ningxia" if regexm(province_en,"ningxia ")
replace province_en = "shaanxi" if regexm(province_en,"shaanxi")
replace province_en = "xinjiang" if regexm(province_en,"xinjiang ")
replace province_en = "tibet" if regexm(province_en,"tibet")
replace province_en = "inner mongolia" if regexm(province_en,"inner mongolia")
drop if province_en=="hainan"

preserve
	import excel "${raw}/Population.xlsx", clear case(lower) firstrow sheet("Manual") // A list of spelling corrections manually prepared by KB 
	rename (city province) (city_en province_en)
	* some corrections that are no longer needed
	drop if city_en == "rikaze [shigatse, xigazê]" 
	drop if city_en == "diqing zangzu zizhizhou [dêqên]"
	drop if city_en == "ganzi zangzu zizhizhou [garzê]"
	tempfile manual
	save `manual'
	
	import excel "$raw/Population.xlsx", clear case(lower) firstrow sheet("HubeiCorrection") // Hubei has cities which are not quite cities, they were originally not reported in the source table so KB added them
	rename (city province) (city_en province_en)
	tempfile hubei
	save `hubei'
restore

merge 1:1 city_en province_en using `manual', gen(mmanual) // correct different spelling
replace city_en = newname if mmanual==3
drop mmanual newname
drop status 

drop if regexm(city_en, "xiantao, tianmen, qianjiang & shennongjia") // will replace with individual ones in the next line
append using `hubei'

* Only keep the first part of the city names, remove the suffix identifying the minority groups in that region 
split city_en, parse(" ") limit(1) gen(name_first_part)
replace city_en = name_first_part if name != "inner mongolia"
drop name_first_part

* Add some exceptions to match with citycentroids file
replace city_en = "urumqi" if city_chn == "乌鲁木齐市"
replace city_en = "tacheng" if city_chn == "塔城地区"
replace city_en = "rikaze" if city_chn == "日喀则市"
replace city_en = "luliang" if city_chn == "吕梁市"
drop if mi(city_chn)

save "$data/population", replace
