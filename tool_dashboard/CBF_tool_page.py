#%%
import mysql.connector
import pandas as pd
import streamlit as st
import yaml
from pathlib import Path
from bfdb_yaml import current_festival
from datetime import datetime, timedelta

# Begin login and inactivity management ------------------------------------------------------
# Configurable inactivity timeout (in minutes); set via .streamlit/secrets.toml [app] section.
timeout_mins = st.secrets.get("app", {}).get("inactivity_timeout_minutes", 60)

st.set_page_config(page_title="BeerfestDB Tools", page_icon="favicon.ico")
st.title("BeerfestDB Tools")

if not st.user.is_logged_in:
    if st.button("Log in with BeerfestDB account"):
        st.login()
    st.stop()

# Update last_activity on every full (user-triggered) rerun.
# The periodic fragment below only re-executes the fragment function,
# leaving this line untouched, so last_activity correctly reflects
# the most recent user interaction.
st.session_state.last_activity = datetime.now()

@st.fragment(run_every=60)  # Check every 60 seconds
def _inactivity_check():
    timeout = timedelta(minutes=timeout_mins)
    if datetime.now() - st.session_state.last_activity > timeout:
        st.logout()

_inactivity_check()

st.markdown(f"Welcome {st.user.name}!")

if st.button("Log out"):
    st.logout()
# End login and inactivity management --------------------------------------------------------

conn = st.connection('cbf', type='sql')

if 'festival' not in st.session_state:
    st.session_state.festival = f'{current_festival}'

fsql = '''select name from festival where year > 2023;'''
fdf = conn.query(fsql)
festlist = fdf['name'].to_list()

festnames = [str(name) for name in (festlist)]

def set_festival():
    st.session_state['festival']

festival_selection = st.sidebar.selectbox(
"Choose a festival",
(festnames),
key="festival",
on_change=set_festival
)

festivalname = st.session_state['festival']

##########

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
