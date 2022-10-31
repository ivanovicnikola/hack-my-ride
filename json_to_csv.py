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
                rows = cross_join(rows, flatten_json(value, prev_heading + '.' + key))
        elif isinstance(data, list):
            rows = []
            for item in data:
                [rows.append(elem) for elem in flatten_list(flatten_json(item, prev_heading))]
        elif isinstance(data, list):
            rows = []
            if len(data) != 0:
                for i in range(len(data)):
                    [rows.append(elem) for elem in flatten_list(flatten_json(data[i], prev_heading))]
            else:
                data.append(None)
                [rows.append(elem) for elem in flatten_list(flatten_json(data[0], prev_heading))]
        else:
            rows = [{prev_heading[1:]: data}]
        return rows

    return pd.DataFrame(flatten_json(data_in))


jsonpath = Path(r'C:\Users\Bogdana\Desktop\ULB\Data_Mining\vehiclePosition01.json')

with jsonpath.open('r', encoding='utf-8') as dat_f:
    dat = json.loads(dat_f.read())

dataframe = json_to_dataframe(dat)

dataframe.rename(columns={
        "data.time": "time",
        "data.Responses.lines.lineId": "lineId",
        "data.Responses.lines.vehiclePositions.directionId": "directionId",
        "data.Responses.lines.vehiclePositions.distanceFromPoint": "distanceFromPoint",
        "data.Responses.lines.vehiclePositions.pointId": "pointId"
}, inplace=True)

dataframe.to_csv(r'C:\Users\Bogdana\Desktop\ULB\Data_Mining\file.csv', index=False)





