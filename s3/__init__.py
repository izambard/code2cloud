import io
import json

import boto3


def upload(bucket_url: str, key: str, resource: object):
    s3 = boto3.client('s3')
    buffer = io.StringIO()
    json.dump(resource, buffer)    
    buffer.seek(0)
    buffer=io.BytesIO(buffer.read().encode('utf8'))
    s3.upload_fileobj(buffer, bucket_url, key)