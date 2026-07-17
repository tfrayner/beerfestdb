#%%

from pathlib import Path
import logging

def make_logger(script_name = __file__):
    script_path = Path(script_name)
    logging.basicConfig(
        level=logging.DEBUG,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    return logging.getLogger(script_path.parts[-1])
