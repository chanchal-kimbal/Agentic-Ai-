
########## Update Creds with input Client id's ###########

import requests
import json
def generate_access_token(client_id,username,password):

    try:

        url = "https://ehes-qa-cmd.kimbal.io/token"  

        payload = {
            "grant_type": "password",
            "username": f"{username}",
            "password": f"{password}",
            "client_id": f"{client_id}",
            "client_secret": "",
            "refresh_token": ""
        }

        headers = {
            "Content-Type": "application/x-www-form-urlencoded"
        }

        response = requests.post(url, data=payload, headers=headers)


        if response.status_code != 200:
            print("Response Text:", response.text)
            return None

        token_response = response.json()
        access_token = token_response.get("access_token")

        return access_token
    
    except Exception as e:
        return f"Error: {e}"
















  




















