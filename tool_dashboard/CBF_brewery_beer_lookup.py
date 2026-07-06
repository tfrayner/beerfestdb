#%%
import mysql.connector
import streamlit as st
import pandas as pd
from CBF_logger import make_logger

logger = make_logger(__file__)

#%%
conn = st.connection('cbf', type='sql')

#%%
st.title('CBF brewery and beer lookup')
st.subheader('Or: Have we had that beer before?')

sql = '''select c.name as Brewery, p.name as 'Beer Name', p.nominal_abv as ABV, ps.description as Style, f.name as Festival
from product p, company c, product_style ps, festival f, festival_product fp
where c.name like :brewery
and p.name like :beer
and p.company_id = c.company_id
and p.product_category_id = ps.product_category_id
and p.product_style_id = ps.product_style_id
and f.festival_id = fp.festival_id
and fp.product_id = p.product_id
and f.name not like '%Test%';'''


st.write("Enter a brewery name, beer name, or both. Search is case-insensitive. Use % as wildcard.")

breweryname = st.text_input("Search for a brewery", key="brewery")

beername = st.text_input("Search for a beer", value= "%", key="beer")

logger.debug(f"Executing SQL query with brewery='{breweryname}' and beer='{beername}'")
df = conn.query(sql, params={"brewery": breweryname, "beer": beername})

@st.cache_data
def csv_for_download(df):
    logger.debug("Converting DataFrame to CSV for download")
    return df.to_csv(index=False).encode("utf-8")

def tsv_for_download(df):
    logger.debug("Converting DataFrame to TSV for download")
    return df.to_csv(sep="\t", index=False).encode("utf-8")


#%%
conn.close()

csv = csv_for_download(df)
tsv = tsv_for_download(df)

st.subheader("Beers we've had from", f'{breweryname}')
st.dataframe(df, hide_index=True)

col1, col2 = st.columns(2)

with col1:
    st.download_button(
        key="csv",
        label="Download CSV",
        data=csv,
        file_name="festival_brewery_beers.csv",
        mime="text/csv",
        icon=":material/download:",
    )

with col2:
    st.download_button(
        key="tsv",
        label="Download TSV",
        data=tsv,
        file_name="festival_brewery_beers.tsv",
        mime="text/tab-separated-values",
        icon=":material/download:",
    )




