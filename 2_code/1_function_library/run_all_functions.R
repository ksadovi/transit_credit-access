all_files = list.files("2_code/1_function_library/")
all_files = all_files[all_files != "run_all_functions.R"]

for(i in all_files){
  source(paste0("2_code/1_function_library/", i))
}

try(rm(all_files, i)) %>% suppressWarnings()
