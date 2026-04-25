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

@st.cache_data
def csv_for_download(df):
    return df.to_csv().encode("utf-8")

def tsv_for_download(df):
    return df.to_csv(sep="\t", index=False).encode("utf-8")


#%%
conn.close()

st.header(f'{festivalname}')

st.subheader('File for programme beer list:')

df

prgcsv = csv_for_download(df)
prgtsv = tsv_for_download(df)

col1, col2 = st.columns(2)

with col1:
    st.download_button(
        key="prgcsv",
        label="Download CSV",
        data=prgcsv,
        file_name="programme_beer_list.csv",
        mime="text/csv",
        icon=":material/download:",
    )

with col2:
    st.download_button(
        key="prgtsv",
        label="Download TSV",
        data=prgtsv,
        file_name="programme_beer_list.tsv",
        mime="text/tab-separated-values",
        icon=":material/download:",
    )

