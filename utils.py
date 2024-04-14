def get_monthly_prices_for_a_token(token_contract_address_token):
    import requests
    import os
    api_key = os.getenv('BITQUERY_API_KEY')

    url = 'https://graphql.bitquery.io/'
    query = f"""
    {{
    ethereum(network: ethereum) {{
            dexTrades(options: {{limit: 10, asc: "timeInterval.month"}}, 
            protocol: {{is: "Uniswap v2"}}, 
            date: {{ after: "2023-07-17T00:00:00Z" }},
            buyCurrency: {{is: "{token_contract_address_token}"}}, 
            sellCurrency: {{is: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"}}) {{
                timeInterval {{
                    month(count: 5)
                }}
                buyCurrency {{
                    symbol
                    address
                }}
                buyAmount
                sellCurrency {{
                    symbol
                    address
                }}
                sellAmount
                trades: count
                maximum_price: price(calculate: maximum)
                minimum_price: price(calculate: minimum)
                open_price: minimum(of: block, get: price)
                close_price: maximum(of: block, get: price)
            }}
        }}
    }}
    """

    # Headers including your API key
    headers = {
        'Content-Type': 'application/json',
        'X-API-KEY': api_key
    }

    # Make the POST request
    response = requests.post(url, json={'query': query}, headers=headers)

    # Check the response
    if response.status_code == 200:
        try:
            print(response.json())
        except ValueError:
            print("Failed to decode JSON from response:", response.text)
    else:
        print("Failed to retrieve data:", response.status_code, response.text)
    return response


def get_supply(contract_address):
    from web3 import Web3

    web3 = Web3(Web3.HTTPProvider('https://eth.llamarpc.com'))
    contract_abi = '''
    [
        {
            "constant":true,
            "inputs":[],
            "name":"totalSupply",
            "outputs":[{"name":"","type":"uint256"}],
            "payable":false,
            "stateMutability":"view",
            "type":"function"
        }
    ]
    '''

    # Create the contract instance
    contract = web3.eth.contract(address=contract_address, abi=contract_abi)

    # Call the totalSupply function
    total_supply = contract.functions.totalSupply().call()

    # Convert to a human-readable format (assuming the token uses 18 decimal places)
    total_supply_readable = total_supply / 10**18

    print("Total Supply:", total_supply_readable)
    return total_supply_readable