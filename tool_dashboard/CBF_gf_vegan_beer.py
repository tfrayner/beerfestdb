#%%
import mysql.connector
import streamlit as st
import pandas as pd

#%%
conn = st.connection('cbf', type='sql')

#%%
st.title('CBF vegan and gluten-free beers')

#%%
if 'festival' not in st.session_state:
    st.session_state.festival = "Cambridge Winter Festival 2025"

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

#%%
conn.close()

#%%
st.header(f'{festivalname}')

st.subheader("Vegan beers")
st.dataframe(vdf, hide_index=True)

st.subheader("Gluten-free beers")
st.dataframe(gfdf, hide_index=True)

st.subheader("Beers that are both vegan and gluten-free")
st.dataframe(vgfdf, hide_index=True)

#%%
