# Unlocks the locked raw yearbook Excel files

from pathlib import Path
from tqdm import tqdm

import msoffcrypto

exec(open("set_directories.py").read())


def main():
    indir  = Path(raw_yearbook_folder)
    outdir = Path(unlocked_yearbook_folder)
    unlock_excel_recursive(indir, outdir)


def unlock_excel_recursive(indir, outdir):
    files = Path(indir).glob("**/*xls*")
    pbar = tqdm(sorted(list(files)))
    for infile in pbar:
        pbar.set_description(str(infile))
        outfile = (outdir / infile.relative_to(indir)).resolve()
        outfile.parent.mkdir(parents=True, exist_ok=True)
        with open(infile.resolve(), 'rb') as inf:
            excel = msoffcrypto.OfficeFile(inf)
            excel.load_key(password='VelvetSweatshop')
            excel.decrypt(open(outfile, 'wb'))


if __name__ == "__main__":
    main()
