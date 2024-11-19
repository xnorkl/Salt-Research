import logging
import os
import requests
import azure.functions as func

def call_salt_api(endpoint, data):
    salt_api_url = os.environ['SALT_API_URL']
    username = os.environ['SALT_API_USER']
    password = os.environ['SALT_API_PASSWORD']
    
    # Login to get token
    login_data = {
        'username': username,
        'password': password,
        'eauth': 'pam'
    }
    
    session = requests.Session()
    session.verify = False  # Only if using self-signed certs
    
    # Get auth token
    login_response = session.post(f'{salt_api_url}/login', json=login_data)
    token = login_response.json()['return'][0]['token']
    
    # Make API call
    headers = {'X-Auth-Token': token}
    response = session.post(f'{salt_api_url}/{endpoint}', json=data, headers=headers)
    
    return response.json()

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')
    
    try:
        req_body = req.get_json()
        endpoint = req_body.get('endpoint')
        data = req_body.get('data')
        
        if not endpoint or not data:
            return func.HttpResponse(
                "Please pass endpoint and data in the request body",
                status_code=400
            )
            
        result = call_salt_api(endpoint, data)
        return func.HttpResponse(str(result))
        
    except ValueError:
        return func.HttpResponse(
            "Invalid JSON in request body",
            status_code=400
        ) 