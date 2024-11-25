from salt import SaltAPIClient
import os
from dotenv import load_dotenv

def main():
    load_dotenv()
    
    client = SaltAPIClient(
        base_url=os.getenv('SALT_API_URL', 'http://localhost:8000'),
        verify_ssl=False
    )
    
    if client.login(
        username=os.getenv('SALT_API_USER', 'saltapi'),
        password=os.getenv('SALT_API_PASSWORD')
    ):
        # Execute test.ping and print formatted result
        result = client.execute_command('test.ping')
        print("\nTest ping result:")
        client.pretty_print(result)

        # Execute state.highstate and print formatted result
        result = client.execute_command('state.highstate')
        print("\nState highstate result:")
        client.pretty_print(result)
    else:
        print("Failed to authenticate with Salt API")

if __name__ == "__main__":
    main() 