* Master file for Borusyak and Hull "Non-Random Exposure to Exogenous Shocks"
* Last Modified: July 1, 2023 (KB)
 
/*============================================================================
						Part 1: set directories, install packages
 ============================================================================*/
clear all
cap file close _all
set more off
set maxvar 20000
*---------------------------------------------------------------------
if (c(username)=="hull") global main "/Users/hull/Dropbox (Personal)/Generalized Bartik/BH replication"
if (c(username)=="borusyak") global main "~/Dropbox/Ideas/Generalized Bartik/BH replication"
if (c(username)=="uctpkbo") global main "C:/Users/uctpkbo/Dropbox/Ideas/Generalized Bartik/BH replication"
*---------------------------------------------------------------------
global main = "$main"
global data = "$main/data"
global do = "$main/code"
global results = "$main/results"
global raw = "$main/raw"
global outgis = "$main/gis"
global server = "$main/server"

cd "$do/build_data"
cap mkdir "$data"
cap mkdir "$results"
*---------------------------------------------------------------------
ssc install geodist
ssc install cleanchars
net install dm88_1.pkg, from("http://www.stata-journal.com/software/sj5-4") // installs renvars from dm88_1.pkg, can do via "search renvars"

/*============================================================================
						Part 2: prepare railway database
 ============================================================================*/
// Clean population data
do 1_clean_population.do						// Imports population data

// Cleaning railway data
do 2_clean_cities.do							// Cleans the database of prefecture-level cities
do 3_clean_lines.do								// Cleans the database of lines and stations
do 4_ma2007.do 									// Compute MA for the initial year 2007
do 5_reshuffle_lines.do 						// Generate reshuffled lines

cap mkdir "$server"
cap mkdir "$server/input"
cap mkdir "$server/output"
cap mkdir "$server/logs"
copy "$data/line_stations.dta" "$server/input/", replace
copy "$data/reshuffle_nlink.dta" "$server/input/", replace
copy "$data/distances.dta" "$server/input/", replace
copy "$data/triplets.dta" "$server/input/", replace
copy "$data/citycentroids.dta" "$server/input/", replace

stop
/*============================================================================
						Part 3: server processing
						
Transfer $main/server to the research computing cluster and execute run_server_2016_slurm.sh or run_server_2016_torque 
(depending on which system your cluster uses) as a batch job (via qsub or sbatch), which calls 100 parallel copies of process_scenarios_2016, each processing 20 line permutations. 
Once all jobs are done transfer the contents of the /output folder back into $main/server/output (and optionally the logs FYI). 
This takes around 1hr.

In principle you can do this part on your computer without a cluster. Each of 2,000 simulations takes ~2min. In this case ignore run_server_2016_*.sh and execute the following code directly in Stata:

	cd "$server"
	forvalues call = 1/100 {
		do process_scenarios_2016.do `call'
	}
	cd "$do/build_data"

============================================================================*/

/*============================================================================
						Part 4: extraction of Chinese City Statistical Yearbooks in python
	
Make sure python is in PATH
Replace python with python3 depending on your installation
Only tested on Windows
Relative directory paths are set in set_directories.py and shouldn't require any changes
============================================================================*/
shell python -m pip install -r requirements.txt // Installs required Python packages
shell python 6_unlock_excel_files.py			// Unlocks the locked raw yearbook Excel files
shell python 7_extract_excel.py					// Reads the yearbooks into simple tables
shell python 8_translate_file_index.py			// Adds variable names in English to the catalog of raw files
shell python 9_clean_yearbook.py				// Creates datasets with yearbooks for all years

/*============================================================================
						Part 5: prepare outcomes and merge everything					
============================================================================*/
// Clean yearbooks
do 10a_construct_variables_clevel				// Reads county-level yearbooks into DTA file
do 10b_construct_variables_prefabove			// Reads prefecture-level yearbooks into DTA file
do 11_clean_cityvar.do							// Combines county- and pref-level data
do 12_outcomes.do								// Prepares a cleaned panel of city outcomes
do 13_outlier_treatment.do 						// Drop outliers for the outcomes

// Merge everything and prepare final datasets for analyses and maps
do 14_combine_ma_2016.do						// Combine server simulations into one file, computed expected & recentered MA
do 15_merge_data.do					  			// Generate the main dataset analysis_data

/*============================================================================
						Part 6: regression analyses & other outputs
 ============================================================================*/
cd "$do"
do Table1.do									// Table 1: Employment effects of market access
do Table2.do									// Table 2: Regressions of MA growth on measures of economic geography
do Maps_data.do 								// Output CSV data files for the maps
cd "$do"
do Misc_results.do								// Produces other numbers directly reported in the draft
