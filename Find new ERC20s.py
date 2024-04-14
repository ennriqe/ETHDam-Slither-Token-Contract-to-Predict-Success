import pandas as pd
from sqlalchemy import create_engine
from web3 import Web3
import json
from concurrent.futures import ThreadPoolExecutor, as_completed
from requests.exceptions import Timeout

# Initialize SQL database connection using SQLAlchemy
engine = create_engine('sqlite:///contracts_found.db')

# Load the ABI for the ERC20 contract
with open('ERC20_ABI.json', 'r') as abi_file:
    ERC20_ABI = json.load(abi_file)

web3 = Web3(Web3.HTTPProvider('https://api.zmok.io/mainnet/oaen6dy8ff6hju9k', request_kwargs={'timeout': 20}))

def robust_get_block(block_number):
    attempts = 0
    while attempts < 5:
        try:
            return web3.eth.get_block(block_number, full_transactions=True)
        except Timeout as e:
            print(f"Timeout occurred for block {block_number}, retrying...")
        except Exception as e:
            print(f"Exception for block {block_number}: {e}, retrying...")
        attempts += 1
        print(f"Attempt {attempts} for block {block_number}")
    return None  # Return None if all attempts fail, signaling the main function to skip this block

def get_new_tokens(block_):
    block = robust_get_block(block_)
    if block is None:
        return None  # Skip this block if we couldn't fetch it after several attempts
    contracts = []
    for tx in block.transactions:
        if tx.to is None:  # Indicates a contract creation
            receipt = web3.eth.get_transaction_receipt(tx.hash)
            contract_address = receipt['contractAddress']
            if contract_address:
                contract = web3.eth.contract(address=contract_address, abi=ERC20_ABI)
                try:
                    name = contract.functions.name().call()
                    symbol = contract.functions.symbol().call()
                    contracts.append((name, symbol, contract_address))
                except Exception as e:
                    print(f"Error fetching contract details for {contract_address}: {e}")
    return contracts

def process_block(block_number, failed_blocks):
    new_contracts = get_new_tokens(block_number)
    if new_contracts:
        # Save to SQL database
        df = pd.DataFrame(new_contracts, columns=['Name', 'Ticker', 'Contract'])
        df.to_sql('contracts_found', con=engine, index=False, if_exists='append')
    else:
        failed_blocks.append(block_number)  # Add the block number to the list of failed blocks
    print(f"Completed processing block: {block_number}")

def process_blocks(start_block, end_block):
    failed_blocks = []  # Initialize a list to keep track of failed blocks
    # ThreadPoolExecutor to process each block in the range
    with ThreadPoolExecutor(max_workers=4) as executor:
        block_futures = {executor.submit(process_block, bn, failed_blocks): bn for bn in range(start_block, end_block)}
        for future in as_completed(block_futures):
            block = block_futures[future]
            if future.exception() is not None:
                failed_blocks.append(block)  # Add the block number to the list of failed blocks
                print(f"Block {block} resulted in an error: {future.exception()}")

    print("Failed blocks:", failed_blocks)  # Print the list of blocks that failed to process
    return failed_blocks

start_block = 19336313
end_block = 1956308
failed_blocks = process_blocks(start_block, end_block)