# ERC20 Token Success Prediction

## Project Overview
In this project completed at ETHDam 2024, I predict the success of newly minted ERC20 tokens on Ethereum using only features extracted from their smart contracts via Slither. Success is defined as reaching a 100k market cap at any point within the same month they were created. I employ a LightGBM model to predict this binary success variable, achieving a model significantly better than random chance.

## Performance Metrics
- **Accuracy:** 63%
- **Precision:** 69%
- **Recall:** 80%
- **F1 Score:** 74%

These metrics are averaged over training using cross-validation across 10 folds to avoid overfitting to the training set.

## Data Collection
I collect data by querying the Ethereum blockchain using Web3.py and an RPC. I specifically look for newly minted ERC20 tokens in the first few days of March 2024. I record the highest market capitalization these tokens achieve within the month. Prices are derived from BitQuery for the pool against WETH, and Web3.py is used to determine the supply.

## Feature Extraction
I analyze the smart contracts of these tokens using Slither to extract the following features:
- Number of state variables used across all contracts of each token
- Number of contracts each token includes
- Uniqueness of the names of these state variables and contracts, using TF-IDF to compare the state names of each token against a corpus of state variables of all other tokens considered.
