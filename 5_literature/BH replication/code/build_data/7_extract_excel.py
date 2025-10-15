# Reads the yearbooks into simple tables

from pathlib import Path
from tqdm import tqdm

import pandas as pd
import glob
import os

import warnings
warnings.filterwarnings("ignore")

# we set all directories in this file called set_directories.py
exec(open("set_directories.py").read())

# Read an excel file specifying filenames and columns we want to extract
# in the format of (roughly)[year, level, filename, variable columns, var names]
file_list = pd.read_excel(misc_input_folder + 'extract_excel_file_list.xlsx')

# tidy up the file list (converting format and removing empty rows, etc.)
file_list.cont = file_list.cont.fillna('0')
file_list['year']      = file_list['year'].astype(int, errors='ignore')
file_list['index_col'] = file_list['index_col'].astype(int, errors='ignore')
file_list['num_cols']  = file_list['num_cols'].astype(int, errors='ignore')
file_list['num_cols']  = file_list['num_cols'].astype(str, errors='ignore')

# any file that doesn't have extract set to 1 will be excluded
file_list = file_list.dropna(how='any')

# specify input/output location
# create the output folder if it doesn't exist
Path("../../data/temp_outputs").mkdir(parents=True, exist_ok=True)
Path(misc_output_folder).mkdir(parents=True, exist_ok=True)
Path(extracted_yearbook_folder).mkdir(parents=True, exist_ok=True)

# create a file that we'll use to store the file information,
file_index = []
pbar = tqdm(list(file_list.iterrows()))
for i, row in pbar:
    file = f"{row.year}_{row.level}/{row.filename}"
    path = unlocked_yearbook_folder + file
    pbar.set_description(file)

    # some tables have two sets of data side by side, in which case
    # I save them into two csv files and combine later in (*)
    if int(row.cont) == 1:
        suffix = '_p2'
    else:
        suffix = ''

    # Output file name
    save_filename = Path(f"{row.year}-{row.level}-{row.filename}").stem + suffix + '.csv'
    save_filepath = extracted_yearbook_folder + save_filename

    # open the excel file and concatenate the sheets
    data = pd.concat(pd.read_excel(path, sheet_name=None, nrows=1000))
    data = data.dropna(how='all')
    data.columns = list(range(data.shape[1]))

    # get variable names
    index_col = int(float(row.index_col)) - 1
    col_list = [int(float(n)) - 1 for n in row.num_cols.split(',')]
    var_list = [v for v in row.vars.replace('，', ',').split(',')]
    var_year_list = [v + "_" + str(row.year) for v in row.vars.split(',')]
    file_index.append([row.year, row.level, row.filename, var_list[0:]])
    if len(col_list) != len(var_list):
        print(path)

    # convert strings to numbers, note that some numbers in the raw table
    # contains a space which will cause an error, so we need to remove the spaces
    for j in col_list:
        data.iloc[:, j] = pd.to_numeric(
            data
            .iloc[:, j]
            .astype(str)
            .str.replace("．", ".")
            .str.replace(" ", ""),
            errors = 'coerce')

    # discard redundant rows and columns
    col_list.insert(0, index_col)
    data = data[col_list]
    data = data.dropna(how='all')

    # rename columns, set city names as index column, and save
    var_list.insert(0, 'city_cn')
    data.columns = var_list
    data = data.set_index('city_cn')
    data.to_csv(save_filepath)

# (*) Combine the split files
for filename_2 in glob.glob(extracted_yearbook_folder + '*clevel*_p2.csv'):
    filename_1 = filename_2.split('_p2.csv')[0] + '.csv'
    csv_1 = pd.read_csv(filename_1)
    csv_2 = pd.read_csv(filename_2)
    pd.concat([csv_1, csv_2], axis = 0).to_csv(filename_1)
    os.remove(filename_2)

for filename in glob.glob(extracted_yearbook_folder + '*pref*.csv'):
    csv = pd.read_csv(filename)
    pd.concat([csv], axis = 0).to_csv(filename)

file_index_df = pd.DataFrame(file_index)
# file_index_df.to_csv(misc_input_folder + "file_index.csv", index = False)
# extract the words to translate

# read the file index provided

file_index = pd.read_csv(misc_input_folder + "file_index.csv")
file_index.columns = ['year', 'level', 'filename', 'varnames']

# extract all the words from the variable names
# create a csv file chinese_words_to_translate.csv
# which is then manually translated


# find all words
all_words = str()
for i in file_index.varnames.values:
    all_words = all_words + i

for c in ["'", " ", "][", "]", "[", ")", "("]:
    all_words = all_words.replace(c, ",")

all_words = all_words.split(",")

# remove some suffix
unique_words = set()
for w in all_words:
    if w.endswith("全市") and len(w) > 2:
        w_new = w.replace("全市","")
    elif w.endswith("市辖区") and len(w) > 3:
        w_new = w.replace("市辖区","")
    elif w.endswith("市区") and len(w) > 2:
        w_new = w.replace("市区","")
    elif w.endswith("地区") and len(w) > 2:
        w_new = w.replace("地区","")
    else:
        w_new = w
    unique_words.add(w_new)

# remove empty string
unique_words.remove('')

# save Change misc input--> misc output 5/14
unique_words_df = pd.DataFrame(sorted(unique_words))
unique_words_df.columns = ['chinese_word']
unique_words_df.to_csv(misc_output_folder + "chinese_words_to_translate.csv", index = False)
