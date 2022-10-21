import numpy as np


def is_in_circle(xy):
    return xy[0]**2+xy[1]**2 < 1

def random_points(nbr_iter, seed=42):
    np.random.seed(seed)
    return np.random.rand(nbr_iter,2)

def pi(nbr_iter, seed=42):
    v=map(is_in_circle, random_points(nbr_iter,seed))
    return 4.0*np.sum(list(v)) / nbr_iter
