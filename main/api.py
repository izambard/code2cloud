import logging
import time

from fastapi import FastAPI

from pi import pi

app = FastAPI()

LOGGER = logging.getLogger(__name__)

@app.get("/")
def get_root():    
    return {"Hello": "World"}


@app.get("/pi/")
def get_item(nbr_iter: int = 10, seed : int = 42):
    LOGGER.warning(f'Received request for pi with {nbr_iter} nbr_iter and {seed} seed')    
    return {"time_stamp": time.time(), "nbr_iter": nbr_iter, "seed": seed, "pi": pi(nbr_iter, seed)}