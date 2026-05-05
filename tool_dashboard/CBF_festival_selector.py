#%%
import mysql.connector
import pandas as pd
import streamlit as st
import yaml
from pathlib import Path
from bfdb_yaml import current_festival

#%%
conn = st.connection('cbf', type='sql')

#%%
if 'festival' not in st.session_state:
    st.session_state.festival = f'{current_festival}'
#    st.session_state.festival = "Cambridge Winter Festival 2025"


#%%
fsql = '''select name from festival where year > 2023;'''
fdf = conn.query(fsql)
festlist = fdf['name'].to_list()

festnames = [str(name) for name in (festlist)]

def set_festival():
    st.session_state['festival']

festival_selection = st.selectbox(
"Choose a festival",
(festnames),
key="festival",
on_change=set_festival
)

festivalname = st.session_state['festival']
