#%%
import mysql.connector
import streamlit as st
import pandas as pd
from CBF_logger import make_logger

logger = make_logger(__file__)

#%%
conn = st.connection('cbf', type='sql')

#%%
st.title('CBF beer allergen lookup')

festivalname = st.session_state['festival']

alsql = '''select description as allergen from product_allergen_type;'''
logger.debug("Executing SQL query to fetch allergen types")
aldf = conn.query(alsql)
allergenlist = aldf['allergen'].to_list()

allergens = [str(allergen) for allergen in (allergenlist)]

def choose_allergen():
    st.session_state['allergen']

st.subheader(f'{festivalname}')
st.write("Use the menu in the left sidebar to choose another festival")

allergen_selection = st.selectbox(
"Choose an allergen",
(allergenlist),
key="allergen",
on_change=choose_allergen
)

allergen = st.session_state['allergen']

#%%
asql = '''select c.name as Brewery, p.name as Beer, p.nominal_abv as ABV, ps.description as Style, p.description as 'Tasting Notes'
from product p, product_allergen_type at, product_allergen a, festival f, festival_product fp, company c, product_style ps, product_category pc
where at.description = :allergen
and f.name = :festivalname
and pc.product_category_id = '1'
and a.product_allergen_type_id = at.product_allergen_type_id
and a.product_id = p.product_id
and p.company_id = c.company_id
and f.festival_id = fp.festival_id
and fp.product_id = p.product_id
and p.product_category_id = ps.product_category_id
and pc.product_category_id = ps.product_category_id
and p.product_style_id = ps.product_style_id
and a.present = '1';'''

#%%
logger.debug("Executing SQL query to fetch beers containing the selected allergen")
adf = conn.query(asql, params={"festivalname": festivalname, "allergen": allergen})


#%%
conn.close()

def csv_for_download(df):
    logger.debug("Converting DataFrame to CSV for download")
    return df.to_csv().encode("utf-8")

def tsv_for_download(df):
    logger.debug("Converting DataFrame to TSV for download")
    return df.to_csv(sep="\t", index=False).encode("utf-8")

acsv = csv_for_download(adf)
atsv = tsv_for_download(adf)

#%%
st.header("Allergen finder")


#%%
conn.close()

def csv_for_download(df):
    logger.debug("Converting DataFrame to CSV for download")
    return df.to_csv().encode("utf-8")

def tsv_for_download(df):
    logger.debug("Converting DataFrame to TSV for download")
    return df.to_csv(sep="\t", index=False).encode("utf-8")

acsv = csv_for_download(adf)
atsv = tsv_for_download(adf)

#%%
st.write("Table of beers containing the allergen selected above")
st.dataframe(adf, hide_index=True)

col1, col2 = st.columns(2)

with col1:
    st.download_button(
        key="acsv",
        label="Download CSV",
        data=acsv,
        file_name="allergen_beer_list.csv",
        mime="text/csv",
        icon=":material/download:",
    )

with col2:
    st.download_button(
        key="atsv",
        label="Download TSV",
        data=atsv,
        file_name="allergen_beer_list.tsv",
        mime="text/tab-separated-values",
        icon=":material/download:",
    )


#%%


