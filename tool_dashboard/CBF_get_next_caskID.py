#%%
import mysql.connector
import pandas as pd
import streamlit as st
import yaml
from pathlib import Path
from bfdb_yaml import current_festival
from datetime import datetime

#%%
conn = st.connection('cbf', type='sql')

#%%
st.title("Cask ID Lookup")

st.write("This tool retrieves the highest cask ID in use for a festival")

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
st.write("Use the menu in the left sidebar to choose another festival")
st.write("Time of last database query: " + datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

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
