import pandas as pd
from database import get_engine

def importar_dados():
    # 1. Carregar o CSV
    print("Lendo o arquivo CSV...")
    df = pd.read_csv('bank_transactions_data_2.csv')
    # Renomeia as colunas: remove espaços e substitui por underline
    df.columns = [c.replace(' ', '_') for c in df.columns]
    print(df.columns)

    # 1.1. Checando....
    #Valores nulos
    qtd_nulos = df.isnull().sum().sum()

    #Duplicatas
    qtd_duplicadas = df.duplicated().sum()

    #Negativos
    coluna_valor = df['TransactionAmount']

    negativos = df[coluna_valor < 0]
    qtd_negativos = len(negativos)



    # --- RELATÓRIO NO TERMINAL ---
    print(f"Relatório de Qualidade:")
    print(f"- Nulos encontrados: {qtd_nulos}")
    print(f"- Duplicatas removidas: {qtd_duplicadas}")
    print(f"- Valores negativos: {qtd_negativos}")

    if qtd_negativos > 0:
        print("Atenção: Dados inconsistentes detectados. Limpando...")
        df = df[coluna_valor >= 0]
    
    if qtd_nulos > 0:
        print("Atenção: Dados inconsistentes detectados. Limpando...")
        df = df.dropna()

    if qtd_nulos > 0:
        print("Atenção: Dados inconsistentes detectados. Limpando...")
        df = df.drop_duplicates()



    # 2. Pequena limpeza (Data Cleaning)
    # Exemplo: remover linhas com valores nulos que podem quebrar o SQL
    #df_limpo = df.dropna()
    
    # 3. Conectar ao Banco
    engine = get_engine()
    
    # 4. Enviar para o MySQL
    # Se a tabela 'transacoes' não existir, ele cria. Se existir, ele adiciona (append).
    print("Enviando dados para o MySQL...")
    #df_limpo.to_sql('transacoes', con=engine, if_exists='append', index=False)

    df.to_sql('data_bronze', con=engine, if_exists='replace', index=False)
    print("Sucesso! Dados integrados ao banco.")

if __name__ == "__main__":
    importar_dados()



  