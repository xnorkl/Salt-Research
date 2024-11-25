import requests
from typing import Dict, Any, Optional, Union, List
from urllib.parse import urljoin
from pprint import pformat

class SaltAPIClient:
    def __init__(self, base_url: str = 'http://localhost:8000', verify_ssl: bool = True):
        self.base_url = base_url
        self.verify_ssl = verify_ssl
        self.token: Optional[str] = None

    def login(self, username: str, password: str, eauth: str = 'pam') -> bool:
        """Authenticate with Salt API and store the token."""
        login_data = {
            'username': username,
            'password': password,
            'eauth': eauth,
            'scope': 'runner,wheel,jobs'
        }
        
        try:
            response = requests.post(
                urljoin(self.base_url, '/login'),
                json=login_data,
                verify=self.verify_ssl,
                headers={'Content-Type': 'application/json'}
            )
            response.raise_for_status()
            
            if response.status_code != 200:
                print(f"Authentication failed with status code: {response.status_code}")
                print(f"Response content: {response.text}")
                return False
            
            self.token = response.json()['return'][0]['token']
            return True
        except requests.exceptions.RequestException as e:
            print(f"Login failed: {e}")
            if hasattr(e.response, 'text'):
                print(f"Response content: {e.response.text}")
            return False

    def _format_response(self, response_data: Dict[str, Any]) -> Dict[str, Any]:
        """Format the Salt API response for better readability.
        
        Args:
            response_data: Raw response data from Salt API
            
        Returns:
            Formatted response with simplified structure
        """
        try:
            # Extract the 'return' list from response
            ret_data = response_data.get('return', [])
            
            if not ret_data:
                return {'success': False, 'message': 'Empty response'}
                
            # Handle different response formats
            if isinstance(ret_data, list):
                if len(ret_data) == 1:
                    # Single minion response
                    return {
                        'success': True,
                        'result': ret_data[0]
                    }
                # Multiple minion responses
                return {
                    'success': True,
                    'results': ret_data
                }
            
            return {
                'success': True,
                'result': ret_data
            }
            
        except Exception as e:
            return {
                'success': False,
                'message': f'Error formatting response: {str(e)}',
                'raw_response': response_data
            }

    def execute_command(self, command: str, target: str = '*', client: str = 'local') -> Dict[str, Any]:
        """Execute a Salt command through the API."""
        if not self.token:
            raise ValueError("Not authenticated. Call login() first.")

        headers = {
            'X-Auth-Token': self.token,
            'Accept': 'application/json'
        }
        
        data = {
            'client': client,
            'tgt': target,
            'fun': command
        }
        
        try:
            response = requests.post(
                self.base_url,
                json=data,
                headers=headers,
                verify=self.verify_ssl
            )
            response.raise_for_status()
            return self._format_response(response.json())
        except requests.exceptions.RequestException as e:
            return {
                'success': False,
                'message': f'Command execution failed: {str(e)}',
                'error': str(e)
            }

    def pretty_print(self, data: Dict[str, Any]) -> None:
        """Pretty print the response data."""
        print(pformat(data, indent=2, width=80))