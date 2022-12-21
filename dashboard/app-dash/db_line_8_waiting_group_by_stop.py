from dash import Dash, html, dcc, Input, Output
import pandas as pd
import plotly.express as px
import numpy as np
import dash_bootstrap_components as dbc

px.set_mapbox_access_token("pk.eyJ1IjoibWlyd2lzZWsiLCJhIjoiY2xieG1xNmN2MDhoNjN1cm13OTFvNnE5ZiJ9.FbjwkhyEBMW6xAd7r1zRUA")

external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css', dbc.themes.BOOTSTRAP, 'style.css']

app = Dash(__name__, external_stylesheets=external_stylesheets)

data = pd.read_csv('regularity_8_waiting_group_by_stop.csv')
time_groups = list(data['Period'].unique())
category = ['SWT', 'AWT', 'EWT']

selected_values = {'timegroup': time_groups[0], 'category' : category[0]}

def get_df_by_stop_name(df, stop_name):
    stop = df[df['stop_name'] == stop_name]
    
    lt = {}
    for p in time_groups:
        for c in category:
            if c not in lt.keys():   lt[c] = list()
            lt[c].append(float(stop[stop['Period'] == p][c]))


    ab = []
    for c in category:
        item = lt[c]
        ab += list(zip(time_groups, item, [c] * len(item) ))

    return pd.DataFrame(ab, columns=['Period', 'WaitingTime', 'Category'])


colors = ['#ee9b00', '#ca6702', '#ae2012', '#ee9b00', '#ca6702', '#ae2012', '#ee9b00', '#ca6702', '#ae2012', '#ee9b00', '#ca6702', '#ae2012']

stops_ordered = pd.read_csv('line8_stops_ordered.csv')
# stops_ordered = stops_ordered['stop_name']
stops = list(stops_ordered['stop_name'])
df = get_df_by_stop_name(data, 'BUYL')

def get_figure(df):
    return px.bar(df, x="Period", y="WaitingTime", color='Category', barmode="group",
            width=650, height=500,
            labels={ 
                "Period": "Time Groups",  "WaitingTime": "Waiting Time (Seconds)"
            })

def get_map(df, selection):
    filter_data = df[df['Period'] == selection['timegroup']]
    return px.scatter_mapbox(filter_data, lat="lat", lon="lng", color="stop_name", size=selection['category'], height=650,
                  color_continuous_scale=px.colors.cyclical.IceFire, size_max=15, zoom=12)

# Slider logic
slider_max = len(stops)

def get_rotated_label():
    labels = {}
    for i, s in enumerate(stops):
        labels[i+1] = {'label': s, 'style': {"transform": "rotate(-40deg)", 'font-size': '0.6em'}}
    return labels

row = html.Div(
    [
        dbc.Row(
            [
                dbc.Col(html.Div(
                    dcc.Slider(
                        1,
                        slider_max,
                        step=1,
                        id='crossfilter-stop--slider',
                        value=1,
                        marks=get_rotated_label()
                        # , "transform": "rotate(45deg)"
                    ),
                    style={'width': '98%', 'padding': '20px 0px 0px 0px'}
                ), md=12),
            ]
        ),
        dbc.Row([
            dbc.Col(
                html.Div(id='output-stop-slider', style={'margin-top': 20, 'margin-left': 20, 'font-size': '1.6em'}),
                md=5
            ),
            dbc.Col(
                html.Div([
                    html.Label('Time Periods'),
                    # dcc.RadioItems(id='time-period-input', options=time_groups, value=time_groups[0]),
                    dbc.RadioItems(
                        id="time-period-input",
                        className="btn-group",
                        inputClassName="btn-check",
                        labelClassName="btn btn-outline-primary",
                        labelCheckedClassName="active",
                        options=[
                            {"label": time_groups[0], "value": 1},
                            {"label": time_groups[1], "value": 2},
                            {"label": time_groups[2], "value": 3},
                            {"label": time_groups[3], "value": 4},
                        ],
                        value=1,
                    ),
                    html.Label('Measure', style={'margin-left': '10px'}),
                    dbc.RadioItems(
                        id="category-input",
                        className="btn-group",
                        inputClassName="btn-check",
                        labelClassName="btn btn-outline-primary",
                        labelCheckedClassName="active",
                        options=[
                            {"label": category[0], "value": 1},
                            {"label": category[1], "value": 2},
                            {"label": category[2], "value": 3},
                        ],
                        value=1,
                    ),
                ], style = {"margin-top": "20px", 'font-size': '1.2em'}),
                width={"size": 6, "order": "last", 'offset': 1},
            ),
        ]),
        dbc.Row([
            dbc.Col(
                html.Div([
                    html.Div([
                        dcc.Graph(
                            figure=get_figure(df),
                            id='graph-with-slider'
                        )
                    ], style={'width': '30%',
                     'display': 'inline-block', 'padding': '0 20'})
                ]),
                md=5
            ),
            dbc.Col(
                html.Div([
                    html.Div([
                        dcc.Graph(
                            figure=get_map(data, selected_values),
                            id='stops-map'
                        )
                    ], 
                    # style={'width': '60%', 'display': 'inline-block', 'padding': '0 0'}
                    )
                ]),
                md=7
            ),
        ])
    ]
)

app.layout = row

@app.callback(
    Output('output-stop-slider', 'children'),
    [Input('crossfilter-stop--slider', 'value')])
def signal_stop_name_change(value):
    return 'Selected Stop: {}'.format(stops[value-1])

# Map update
@app.callback(
    Output('stops-map', 'figure'),
    [Input('time-period-input', 'value'),
     Input('category-input', 'value')])
def update_category(timegroup, cate):
    selected_values['category'] = category[cate-1]
    selected_values['timegroup'] = time_groups[timegroup-1]

    fig = get_map(data, selected_values)
    fig.update_layout(transition_duration=500)
    return fig


@app.callback(
    # Output('output-stop-slider', 'children'),
    Output('graph-with-slider', 'figure'),
    [Input('crossfilter-stop--slider', 'value')])
def update_slider_figure(selected_stop):
    global data
    
    df = get_df_by_stop_name(data, stops[selected_stop-1])
    fig = get_figure(df)
    fig.update_layout(transition_duration=500)
    return fig

if __name__ == '__main__':
    app.run_server(debug=True)
