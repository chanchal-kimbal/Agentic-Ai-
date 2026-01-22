from psycopg2 import OperationalError
import psycopg2
from fetch_meter_from_db import get_meter_data_with_last_comm_json
from user_creds import generate_access_token


def is_validate(projectid,client_id,username,password):

    is_projectId_validate=get_meter_data_with_last_comm_json(projectid)
    is_creds=generate_access_token(client_id,username,password)

    if is_projectId_validate and is_creds :
        return True
    else :
        return False
    


def validate_db_credentials(host, port, database, user, password):
    try:
        conn = psycopg2.connect(
            host=host,
            port=port,
            database=database,
            user=user,
            password=password,
            connect_timeout=5
        )
        conn.close()
        return True
    except OperationalError:
        return False





