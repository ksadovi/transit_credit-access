# Adds variable names in English to the catalog of raw files

import pandas as pd

# we set all directories in this file called set_directories.py
exec(open("set_directories.py").read())

# manual translation of chinese_words_to_translate.csv happened!

# read the file index provided
file_index = pd.read_csv(misc_input_folder + "file_index.csv")
file_index.columns = ['year','level','filename','varnames']

# load translated file
translated_words = pd.read_csv(misc_input_folder + "chinese_words_translated.csv")[['chinese_word','english_translation']]

# sort by length of the chinese words in descending order
# so that when we replace, we don't end up replacing part of a longer string with the
# translation of a shorter string
translated_words['length'] = translated_words.chinese_word.str.len()
translated_words.sort_values('length', ascending=False, inplace=True)

# put the units and varnames into separate dictionaries
units = translated_words[translated_words.english_translation.str.startswith('_')]
varnames = translated_words[~translated_words.english_translation.str.startswith('_')]
units_dict = units.set_index('chinese_word').T.to_dict('list')
varnames_dict = varnames.set_index('chinese_word').T.to_dict('list')


# a function that translates the chinese varnames to english varnames
# replace varnames before the units, because the characters used in the units
# appear in the variable names also and we don't want them to be replaced partially
# by unit translations first
def translate(row):
	str_to_translate = row['varnames']
	for chn, eng in varnames_dict.items():
	  	str_to_translate = str_to_translate.replace(chn, eng[0])
	for chn, eng in units_dict.items():
	  	str_to_translate = str_to_translate.replace(chn, eng[0])
	str_to_translate = str_to_translate.replace('(','')
	str_to_translate = str_to_translate.replace(')','')
	row['varnames_eng'] = str_to_translate
	return row

# translate and save
translated_file_index = file_index.apply(lambda x: translate(x), axis = 1)
translated_file_index.to_csv(misc_output_folder + "file_index_translated.csv", index = False)
