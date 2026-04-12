#%%
import mysql.connector
import pandas as pd
import streamlit as st

#%%
conn = st.connection('cbf', type='sql')

#%%
if 'festival' not in st.session_state:
    st.session_state.festival = "Cambridge Winter Festival 2025"

#%%
st.title("Festival Programme Beer List")

st.write("This tool retrieves the programme notes file for a festival.")

st.write("*Note: This is V1, and retrieves the entire \"programme notes view\" table from beerfestdb. It's usually run for the current festival after data are loaded for **beer**, but before the load for any other product categories. Once additional product categories are loaded, everything will appear in the output (e.g. see any of the past festivals). Filtering may happen in V2...*")

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

#%%
sql = '''select * from programme_notes_view 
where festival = :festivalname;'''

#%%
df = conn.query(sql, params={"festivalname": festivalname})
#%%


#%%
conn.close()

st.header(f'{festivalname}')

st.subheader('File for programme beer list:')

df

