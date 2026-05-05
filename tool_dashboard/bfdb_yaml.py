import yaml
from pathlib import Path

this_dir = Path(__file__).parent
parent_dir = Path(this_dir).parent

bfdbyaml = parent_dir / 'beerfestdb_web.yml'

with open(f'{bfdbyaml}') as f:
    bfdbconf = yaml.safe_load(f)

current_festival = (bfdbconf["current_festival"])

