#%%
import streamlit as st

st.title("BeerfestDB Tools")
st.set_page_config(page_icon="favicon.ico")

if not st.user.is_logged_in:
    if st.button("Log in with BeerfestDB account"):
        st.login()
    st.stop()
else:
    st.markdown(f"Welcome {st.user.name}!")

if st.button("Log out"):
    st.logout()

pages = {
    "Data Tables": [
        st.Page("CBF_beer_price_calculator.py", title="Price Load File"),
        st.Page("CBF_gf_vegan_beer.py", title="Vegan & G-free"),
        st.Page("CBF_beer_allergen_lookup.py", title="Beer Allergens"),
        st.Page("CBF_get_programme_notes.py", title="Programme Beer List"),
    ],
    "Extras": [
        st.Page("CBF_get_next_caskID.py", title="Next Cask ID"),
    ],
}

pg = st.navigation(pages)
pg.run()

