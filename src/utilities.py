from functools import lru_cache
from parsons.databases.redshift import Redshift
from pywell import get_secret

# caching the config avoids fetching secrets each time
@lru_cache(maxsize=1)
def get_redshift() -> Redshift:
    redshift_creds = get_secret("redshift-admin")
    return Redshift(
        username=redshift_creds["username"],
        password=redshift_creds["password"],
        host=redshift_creds["host"],
        db=redshift_creds["dbName"],
        port=redshift_creds["port"],
        s3_temp_bucket=redshift_creds["temp_s3_bucket"],
        aws_access_key_id=redshift_creds["temp_s3_bucket_iam_access_key"],
        aws_secret_access_key=redshift_creds["temp_s3_bucket_iam_secret"],
        use_env_token=False,
    )


  
def redshift_query_from_file(sql_filename):
    if not sql_filename.endswith(".sql"):
        sql_filename += ".sql"

    with open(f"redshift_queries/{sql_filename}", "r") as sql_file:
        return get_redshift().query(sql_file.read())
