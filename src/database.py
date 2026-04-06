# database.py
from sqlalchemy import create_engine
import os
from dotenv import load_dotenv

# Carrega as variáveis do arquivo .env
basedir = os.path.abspath(os.path.dirname(__file__))
load_dotenv(os.path.join(basedir, "../.env"))

def get_engine():
    # Pega os dados do seu arquivo .env para não expor sua senha
    user = os.getenv('DB_USER', 'root')
    password = os.getenv('DB_PASSWORD')
    host = os.getenv('DB_HOST', 'localhost')
    port = os.getenv('DB_PORT', '3306')
    db_name = os.getenv('DB_DATABASE')

    # Monta a URL de conexão
    url = f"mysql+mysqlconnector://{user}:{password}@{host}:{port}/{db_name}"
    
    return create_engine(url)