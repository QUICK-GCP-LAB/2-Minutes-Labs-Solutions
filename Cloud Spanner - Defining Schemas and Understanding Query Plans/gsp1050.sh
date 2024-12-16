#!/bin/bash
# Define color variables

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`
#----------------------------------------------------start--------------------------------------------------#

echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Portfolio (PortfolioId, Name, ShortName, PortfolioInfo) VALUES (1, 'Banking', 'Bnkg', 'All Banking Business')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Portfolio (PortfolioId, Name, ShortName, PortfolioInfo) VALUES (2, 'Asset Growth', 'AsstGrwth', 'All Asset Focused Products')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Portfolio (PortfolioId, Name, ShortName, PortfolioInfo) VALUES (3, 'Insurance', 'Ins', 'All Insurance Focused Products')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Category (CategoryId, PortfolioId, CategoryName) VALUES (1, 1, 'Cash')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Category (CategoryId, PortfolioId, CategoryName) VALUES (2, 2, 'Investments - Short Return')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Category (CategoryId, PortfolioId, CategoryName) VALUES (3, 2, 'Annuities')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Category (CategoryId, PortfolioId, CategoryName) VALUES (4, 3, 'Life Insurance')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (1, 1, 1, 'Checking Account', 'ChkAcct', 'Banking LOB')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (2, 2, 2, 'Mutual Fund Consumer Goods', 'MFundCG', 'Investment LOB')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (3, 3, 2, 'Annuity Early Retirement', 'AnnuFixed', 'Investment LOB')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (4, 4, 3, 'Term Life Insurance', 'TermLife', 'Insurance LOB')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (5, 1, 1, 'Savings Account', 'SavAcct', 'Banking LOB')"


gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (6, 1, 1, 'Personal Loan', 'PersLn', 'Banking LOB')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (7, 1, 1, 'Auto Loan', 'AutLn', 'Banking LOB')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (8, 4, 3, 'Permanent Life Insurance', 'PermLife', 'Insurance LOB')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (9, 2, 2, 'US Savings Bonds', 'USSavBond', 'Investment LOB')"

mkdir python-helper
cd python-helper

wget https://storage.googleapis.com/cloud-training/OCBL373/requirements.txt
wget https://storage.googleapis.com/cloud-training/OCBL373/snippets.py

pip install -r requirements.txt
pip install setuptools

python snippets.py banking-ops-instance --database-id  banking-ops-db insert_data

python snippets.py banking-ops-instance --database-id  banking-ops-db query_data

python snippets.py banking-ops-instance --database-id  banking-ops-db add_column

python snippets.py banking-ops-instance --database-id  banking-ops-db update_data

python snippets.py banking-ops-instance --database-id  banking-ops-db query_data_with_new_column

python snippets.py banking-ops-instance --database-id  banking-ops-db add_index

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
