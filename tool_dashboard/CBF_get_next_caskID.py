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
st.title("Cask ID Lookup")

st.write("This tool retrieves the highest cask ID in use for a festival")


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
sql = '''select max(cm.cellar_reference) as cask_ID
from cask_management cm, festival f
where f.festival_id=cm.festival_id 
and f.name = :festivalname;'''

#%%
df = conn.query(sql, params={"festivalname": festivalname})


#%%
conn.close()

st.header(f'{festivalname}')

## fish the actual number out and assign to caskmax

idcol = df['cask_ID'].to_list()
caskmax = idcol[0]

st.subheader('Max cask ID in use:')
st.write(caskmax)

st.subheader("Next cask ID available:")

if isinstance(caskmax, int):
    st.write(caskmax + 1)
else:
    st.write("Not applicable")
