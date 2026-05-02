#%%
import mysql.connector
import streamlit as st
import pandas as pd
import math

#%%
conn = st.connection('cbf', type='sql')

#%%
st.title("Beer price calculator"	)

st.write("Known limitation: The beerfestdb does not support more than one price per product. If a beer is available in both cask and keg, choose one price to load, and manually edit the cask end sign .tex file to create the other.")

#%%
if 'festival' not in st.session_state:
    st.session_state.festival = "Cambridge Winter Festival 2025"

if 'orderbatch' not in st.session_state:
    st.session_state.orderbatch = "Main Beer Order"

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

obsql = '''select  ob.description as batch, ob.order_date from order_batch ob, festival f
where ob.festival_id = f.festival_id
and f.name = :festivalname
'''

obdf = conn.query(obsql, params={"festivalname": festivalname})
order_batch_list = obdf['batch'].to_list()

order_batches = [str(batch) for batch in (order_batch_list)]

orderbatch = st.selectbox(
"Choose an order batch",
(order_batches),
key="orderbatch"
)

default_abv_coefficient = 70
default_abv_constant = 230
## in pence
default_l_coefficient = 1.64
## to do: convert to taking input values

abv_coefficient =  st.number_input(
    "Enter ABV price coefficient (in pence)", value=70, placeholder="Type a number..."
)

st.write("Default value:", default_abv_coefficient)

abv_constant =  st.number_input(
    "Enter ABV constant (in pence)", value=230, placeholder="Type a number..."
)

st.write("Default value:", default_abv_constant)

l_coefficient =  st.number_input(
    "Enter price sale coefficient per litre", value=1.64, placeholder="Type a number (multiply firkin-based value by 41) ..."
)

st.write("Default value:", default_l_coefficient)

#%%
osql = '''
select distinct c.name as brewery_name, p.name as product_name, p.nominal_abv as product_abv, cs.description as cask_size, cm.price as cask_price, cs.container_volume as c_vol, m.litre_multiplier as lm
from product p, festival f, company c, cask_management cm, container_size cs, container_measure m, order_batch ob, product_order po
where 
f.name = :festivalname
and ob.description = :orderbatch
and p.company_id = c.company_id
and p.product_category_id = 1
and cm.container_size_id = cs.container_size_id
and cs.container_measure_id = m.container_measure_id
and f.festival_id = ob.festival_id
and ob.order_batch_id = po.order_batch_id
and po.product_order_id = cm.product_order_id
and po.product_id = p.product_id;
'''

#%%
dfo = conn.query(osql, params={"festivalname": festivalname, "orderbatch": orderbatch})

#%%
dfo['cask_price'] = dfo['cask_price'].fillna(value=0).astype(int)
dfo['lpc'] = dfo.apply(lambda row: row['c_vol'] * row['lm'], axis=1)

dfo['abv_price'] = dfo['product_abv'].apply(lambda x: x * abv_coefficient + abv_constant)
dfo['l_price'] = dfo.apply(lambda row: row['cask_price'] / row['lpc'], axis=1)
dfo['cost_price'] = dfo['l_price'].apply(lambda x: x * l_coefficient)
dfo['price_to_round'] = dfo.apply(lambda row: row['abv_price'] if row['abv_price'] > row['cost_price']  else row['cost_price'], axis=1)

#%%
dfo['norm_price'] = dfo['price_to_round'].apply(lambda x: x / 20)
dfo['rounded_price'] = dfo['norm_price'].apply(lambda x: math.ceil(x) * 20)
dfo['product_sale_price'] = dfo['rounded_price'].apply(lambda x: x / 100)
dfo['festival_name'] = festivalname

#%%
dfload = dfo[['festival_name', 'brewery_name', 'product_name', 'cask_size', 'product_sale_price']]
##  includes cask size/format, to show where cask & keg differ
### BUT this isn't supported by the db schema at present anyway!

@st.cache_data
def csv_for_download(df):
    return df.to_csv().encode("utf-8")

def tsv_for_download(df):
    return df.to_csv(sep="\t", index=False).encode("utf-8")

#%%
conn.close()

#%%
st.header(f'{festivalname} Beer Prices')

st.write("Download table as file to use as input for load_data.pl")
st.write("Price is based on ABV or cask cost, whichever is greater.")
st.write("*Note: If a cask price is missing, its value is set at zero (0), and the ABV-based price will be displayed.*")

st.subheader(f'{orderbatch} - Sale Price Load File')
st.dataframe(dfload, hide_index=True, column_order=('festival_name', 'brewery_name', 'product_name', 'product_sale_price'))


pcsv = csv_for_download(dfload)
ptsv = tsv_for_download(dfload)

col1, col2 = st.columns(2)

with col1:
    st.download_button(
        key="pcsv",
        label="Download CSV",
        data=pcsv,
        file_name="beer_price_data.csv",
        mime="text/csv",
        icon=":material/download:",
    )

with col2:
    st.download_button(
        key="ptsv",
        label="Download TSV",
        data=ptsv,
        file_name="beer_price_data.tsv",
        mime="text/tab-separated-values",
        icon=":material/download:",
    )

#%%
