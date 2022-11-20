from copy import deepcopy
import pandas as pd
from pathlib import Path
import json


def cross_join(left, right):
    new_rows = [] if right else left
    for left_row in left:
        for right_row in right:
            temp_row = deepcopy(left_row)
            for key, value in right_row.items():
                temp_row[key] = value
            new_rows.append(deepcopy(temp_row))
    return new_rows


def flatten_list(data):
    for elem in data:
        if isinstance(elem, list):
            yield from flatten_list(elem)
        else:
            yield elem


def json_to_dataframe(data_in):
    def flatten_json(data, prev_heading=''):
        if isinstance(data, dict):
            rows = [{}]
            for key, value in data.items():
                rows = cross_join(rows, flatten_json(value, key))
        elif isinstance(data, list):
            rows = []
            for item in data:
                [rows.append(elem) for elem in flatten_list(flatten_json(item, prev_heading))]
        elif data is not None:
            rows = [{prev_heading: data}]
        else:
            rows = [{}]
        return rows

    return pd.DataFrame(flatten_json(data_in))


def convert_to_csv(filespath, outputfile):
    if filespath is None: 
        print('No input file specified')
        exit(1)
    if outputfile is None: 
        print('No output file specified')
        exit(1)

    jsonpath = Path(filespath)
    with jsonpath.open('r', encoding='utf-8') as dat_f:
        dat = json.loads(dat_f.read())

    print('\rPreprocessing ', filespath)
    dataframe = json_to_dataframe(dat)
    dataframe.to_csv(outputfile, index=False)

    print('{} generated success!'.format(outputfile))



