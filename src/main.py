import pandas as pd
from database import get_engine

def importar_dados():
    # 1. Carregar o CSV
    print("Lendo o arquivo CSV...")
    df = pd.read_csv('../bank_transactions_data_2.csv')
    
    # 2. Pequena limpeza (Data Cleaning)
    # Exemplo: remover linhas com valores nulos que podem quebrar o SQL
    #df_limpo = df.dropna()
    
    # 3. Conectar ao Banco
    engine = get_engine()
    
    # 4. Enviar para o MySQL
    # Se a tabela 'transacoes' não existir, ele cria. Se existir, ele adiciona (append).
    print("Enviando dados para o MySQL...")
    #df_limpo.to_sql('transacoes', con=engine, if_exists='append', index=False)

    df.to_sql('data_bronze', con=engine, if_exists='append', index=False)
    print("Sucesso! Dados integrados ao banco.")

if __name__ == "__main__":
    importar_dados()



  