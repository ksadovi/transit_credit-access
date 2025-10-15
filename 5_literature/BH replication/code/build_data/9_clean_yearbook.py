# Creates datasets with yearbooks for all years

from pathlib import Path
import pandas as pd
import os
import re
import glob
import functools
import math
import sys
import warnings
import ast
warnings.filterwarnings("ignore")

raw_yearbook_folder = "../../raw/yearbooks/"
unlocked_yearbook_folder = "../../data/unlocked/yearbooks/"
extracted_yearbook_folder = "../../data/temp_outputs/extract_excel_output/"
cleaned_yearbook_folder = "../../data/temp_outputs/clean_yearbook_output/"
misc_input_folder = "../../raw/input/"
temp_output_folder = "../../data/temp_outputs/"
build_database_output_folder = "../../data/temp_outputs/build_database_output/"
misc_output_folder = "../../data/temp_outputs/input_edit/"

# we set all directories in this file called set_directories.py
exec(open("set_directories.py").read())


# a function to display a progress bar
def progressBar(value, endvalue, bar_length=20):
    percent = float(value) / endvalue
    arrow = '-' * int(round(percent * bar_length) - 1) + '>'
    spaces = ' ' * (bar_length - len(arrow))
    sys.stdout.write("\rPercent: [{0}] {1}%".format(arrow + spaces, int(round(percent * 100))))
    sys.stdout.flush()


progressBar(1, 10)

# verify if the input exists
if not os.path.exists(extracted_yearbook_folder):
    print("Input folder does not exist!")
    sys.exit()

# create the output folder if it doesn't exist
Path(cleaned_yearbook_folder).mkdir(parents=True, exist_ok=True)
Path(output_folder).mkdir(parents=True, exist_ok=True)
Path(build_database_output_folder).mkdir(parents=True, exist_ok=True)
progressBar(2, 10)

# filter the variables we need from all the csv files extracted from yearbooks

# city_set: variable to collect all city names so that they can be assigned
# an index later this index is going to be used to merge variables from
# different files we need to do this because different files have different set
# of cities so we need to collect them all before assigning the index
city_set = set()


# a function to remove random characters and keep only Chinese character
def getChinese(context):
    filtrate = re.compile(u'[^\u4E00-\u9FA5]')  # non-Chinese unicode range
    context = filtrate.sub(r'', context)  # remove all non-Chinese characters
    return context


file_index_translated = pd.read_csv(misc_output_folder + "file_index_translated.csv", index_col = False)
file_index_translated['full_filename'] = file_index_translated.apply(lambda x: str(x.year) + "-" + x.level + "-" + x.filename, axis = 1)

file_name_list = file_index_translated.full_filename.values
# file_varname_list = file_index_translated.varnames_eng.values
# use a loop to read each file
for filename in file_name_list:
    # get the correct filename
    filename_csv = filename.replace(".xls", ".csv")
    # read file
    try:
        df = pd.read_csv(extracted_yearbook_folder + filename_csv, encoding='utf-8', index_col = False)
    except FileNotFoundError:
        continue

    # drop an extra index column starting with "Unnamed:" if it exists
    df = df.loc[:, ~df.columns.str.startswith("Unnamed")]
    # swap the chinese column names with english translations
    new_varnames = file_index_translated[file_index_translated.full_filename == filename].varnames_eng.values[0]
    df.columns = ['city_cn'] + ast.literal_eval(new_varnames)
    # remove rows with no data (usually some table section headers)
    df = df.dropna(subset = df.columns[1:], how = 'all')
    # remove rows with no city name
    df = df.dropna(subset = ['city_cn'], how = 'any')
    # remove whitespace from the city names, remove the "city" suffix,
    # remove "province" suffix, remove non-chinese characters
    df.city_cn = df.city_cn.str.strip()
    df.city_cn = df.city_cn.str.strip('市')
    df.city_cn = df.city_cn.str.strip('省')
    df.city_cn = df.city_cn.apply(getChinese)
    # add cities in the file to the set of all cities
    city_set = city_set.union(set(df.city_cn.values))
    # standardize units (multiply 10000 for those recorded in 10000s,
    # multiply 1000 for those recorded in 1000s)
    for col in df.columns:
        if "_10k" in col:
            df[col] = df[col] * 10000
        if "_1k" in col:
            df[col] = df[col] * 1000

    # remove units from the variable names
    df.columns = [i.replace("_10k", "") for i in df.columns]
    df.columns = [i.replace("_1k", "") for i in df.columns]
    if len(df.columns) > 1:
        df = df.set_index('city_cn')
        # get year and level of the file and add to variable names
        file_year = str(math.floor(file_index_translated[file_index_translated.full_filename == filename].year.values[0]))
        df.columns = [i + file_year for i in df.columns]
        df = df.reset_index()
        df.round(2).to_csv(cleaned_yearbook_folder + filename_csv, index = False)

progressBar(4, 10)
# add a numerical index for the cities for faster merging (in steps)

# step 1: create a lookup table for the cities and indices
city_list = list(city_set)
city_num = list(range(0, len(city_list)))
city_dict = {k: v for k, v in zip(city_list, city_num)}
progressBar(5, 10)

# step 2: add index to every file
for filename in glob.glob(cleaned_yearbook_folder + '*-*.csv'):
    df = pd.read_csv(filename, index_col = False)
    df['city_index'] = df['city_cn'].map(city_dict)
    df.to_csv(filename, index = False)

for level in ['clevel', 'prefabove']:
    # step 3: merge all variables from all files on city index
    df_list = []
    i = 0
    for filename in glob.glob(cleaned_yearbook_folder + '*-' + level + '-*.csv'):
        data_new = pd.read_csv(filename, index_col= False).drop_duplicates(subset = 'city_index', keep = 'last')
        data_new = data_new.drop(columns = 'city_cn')
        df_list.append(data_new)
    data_full = functools.reduce(lambda left, right:
                                 pd.merge(left, right, on=['city_index'],
                                          how = 'outer'), df_list)
    # convert city index back to city name
    city_dict_reverse = {k: v for k, v in zip(city_num, city_list)}
    data_full['city_cn'] = data_full['city_index'].map(city_dict_reverse)
    # sort columns by name
    data_full = data_full.reindex(sorted(data_full.columns), axis=1)
    data_full = data_full[[not s for s in data_full.city_cn.str.contains('合计')]]
    progressBar(6, 10)
    # load city name errors lookup table from file
    city_name_errors = pd.read_excel(misc_input_folder + 'city_name_errors.xlsx')
    # correct errors in city names
    for i in range(len(city_name_errors)):
        row = city_name_errors.iloc[i]
        error = row.city_error
        correction = row.city_correct
        data_error = data_full[data_full.city_cn == error]
        data_correct = data_full[data_full.city_cn == correction]
        if len(data_error) > 0 and len(data_correct) > 0:
            temp = data_correct.fillna(data_error.iloc[0], axis=0)
            data_full = data_full[data_full.city_cn != error]
            data_full = data_full[data_full.city_cn != correction]
            data_full = pd.concat([data_full, temp], axis = 0)

    # exclude some "cities" that are actually rows for totals
    city_name_exclude = city_name_errors.exclude.values.flatten()
    data_full = data_full[~data_full.city_cn.isin(city_name_exclude)]
    if level == "prefabove":
        data_full.loc[(data_full.city_cn == "北京"), "TotWageWorkers_cny_duc2006"] = 149345630000
    data_full.to_csv(temp_output_folder + "all_variables_" + level + "_wide.csv", index = False)


    progressBar(10, 10)
