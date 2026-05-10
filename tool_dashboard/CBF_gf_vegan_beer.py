#%%
import mysql.connector
import streamlit as st
import pandas as pd

#%%
conn = st.connection('cbf', type='sql')

#%%
st.title('CBF vegan and gluten-free beers')

festivalname = st.session_state['festival']

#%%
vsql = '''select c.name as Brewery, c.name as Beer, p.nominal_abv as ABV, ps.description as Style, p.description as 'Tasting Notes'
from product p, festival f, festival_product fp, company c, product_style ps
where f.name = :festivalname
and p.company_id = c.company_id
and f.festival_id = fp.festival_id
and fp.product_id = p.product_id
and p.product_category_id = ps.product_category_id
and p.product_style_id = ps.product_style_id
and p.is_vegan = '1';'''

#%%
vdf = conn.query(vsql, params={"festivalname": festivalname})

#%%
gsql = '''select c.name as Brewery, p.name as Beer, p.nominal_abv as ABV, ps.description as Style, p.description as 'Tasting Notes'
from product p, product_allergen_type at, product_allergen a, festival f, festival_product fp, company c, product_style ps
where at.description = 'gluten'
and f.name = :festivalname
and a.product_allergen_type_id = at.product_allergen_type_id
and a.product_id = p.product_id
and p.company_id = c.company_id
and f.festival_id = fp.festival_id
and fp.product_id = p.product_id
and p.product_category_id = ps.product_category_id
and p.product_style_id = ps.product_style_id
and a.present = '0';'''

#%%
gfdf = conn.query(gsql, params={"festivalname": festivalname})

#%%
vgsql = '''select c.name as Brewery, p.name as Beer, p.nominal_abv as ABV, ps.description as Style, p.description as 'Tasting Notes'
from product p, product_allergen_type at, product_allergen a, festival f, festival_product fp, company c, product_style ps
where at.description = 'gluten'
and f.name = :festivalname
and a.product_allergen_type_id = at.product_allergen_type_id
and a.product_id = p.product_id
and p.company_id = c.company_id
and f.festival_id = fp.festival_id
and fp.product_id = p.product_id
and p.product_category_id = ps.product_category_id
and p.product_style_id = ps.product_style_id
and a.present = '0'
and p.is_vegan = '1';'''


#%%
vgfdf = conn.query(vgsql, params={"festivalname": festivalname})

@st.cache_data
def csv_for_download(df):
    return df.to_csv().encode("utf-8")

def tsv_for_download(df):
    return df.to_csv(sep="\t", index=False).encode("utf-8")


#%%
conn.close()

vcsv = csv_for_download(vdf)
vtsv = tsv_for_download(vdf)
gfcsv = csv_for_download(gfdf)
gftsv = tsv_for_download(gfdf)
vgfcsv = csv_for_download(vgfdf)
vgftsv = tsv_for_download(vgfdf)

#%%
st.header(f'{festivalname}')
st.write("Use the menu in the left sidebar to choose another festival")


st.subheader("Vegan beers")
st.dataframe(vdf, hide_index=True)

col1, col2 = st.columns(2)

with col1:
    st.download_button(
        key="vcsv",
        label="Download CSV",
        data=vcsv,
        file_name="vegan_beer_list.csv",
        mime="text/csv",
        icon=":material/download:",
    )

with col2:
    st.download_button(
        key="vtsv",
        label="Download TSV",
        data=vtsv,
        file_name="vegan_beer_list.tsv",
        mime="text/tab-separated-values",
        icon=":material/download:",
    )


st.subheader("Gluten-free beers")
st.dataframe(gfdf, hide_index=True)

col1, col2 = st.columns(2)

with col1:
    st.download_button(
        key="gfcsv",
        label="Download CSV",
        data=gfcsv,
        file_name="gluten-free_beer_list.csv",
        mime="text/csv",
        icon=":material/download:",
    )

with col2:
    st.download_button(
        key="gftsv",
        label="Download TSV",
        data=gftsv,
        file_name="gluten-free_beer_list.tsv",
        mime="text/tab-separated-values",
        icon=":material/download:",
    )


st.subheader("Beers that are both vegan and gluten-free")
st.dataframe(vgfdf, hide_index=True)

col1, col2 = st.columns(2)

with col1:
    st.download_button(
        key="vgfcsv",
        label="Download CSV",
        data=vgfcsv,
        file_name="_beer_list.csv",
        mime="text/csv",
        icon=":material/download:",
    )

with col2:
    st.download_button(
        key="vgftsv",
        label="Download TSV",
        data=vgftsv,
        file_name="vegan-GF_beer_list.tsv",
        mime="text/tab-separated-values",
        icon=":material/download:",
    )

#%%
