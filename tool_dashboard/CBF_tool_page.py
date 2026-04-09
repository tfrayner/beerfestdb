#%%
import streamlit as st

st.title("BeerfestDB Tools")

pages = {
    "Data Tables": [
        st.Page("CBF_beer_price_calculator.py", title="Price Load File"),
        st.Page("CBF_gf_vegan_beer.py", title="Vegan & G-free"),
    ],
    "Extras": [
        st.Page("CBF_get_next_caskID.py", title="Next Cask ID"),
    ],
}

pg = st.navigation(pages)
pg.run()

