import argparse
import logging
import time
import s3
from pi import pi

LOGGER = logging.getLogger(__name__)

if __name__ == "__main__":
    
    parser = argparse.ArgumentParser()

    parser.add_argument('--nbr_iter', type=int, required=True)
    parser.add_argument('--seed', type=int)
    parser.add_argument('--s3bucket', type=str)
    args = parser.parse_args()

    LOGGER.warning(f'Running job for pi with {args.nbr_iter} nbr_iter and {args.seed} seed')
    
    time_stamp = time.time()
    output = {"time_stamp": time_stamp, "nbr_iter": args.nbr_iter, "seed": args.seed, "pi": pi(args.nbr_iter, args.seed)}

    LOGGER.warning(f'Output is {output}')

    if args.s3bucket:
        key=f'{time_stamp}-{ args.nbr_iter}-{args.seed}'
        s3.upload(args.s3bucket, key, output )