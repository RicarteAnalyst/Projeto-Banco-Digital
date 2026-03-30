-- ============================================
-- ARQUIVO: 01_database_bronze
-- CAMADA: Bronze
-- Descrição: Criação do database e tabela de ingestão bruta.
--            Todas as colunas são VARCHAR para evitar erros
--            de conversão — os tipos corretos são aplicados
--            apenas na camada Silver.
-- Database: projetinho
-- Autor: RicarteAnalyst
-- ============================================


CREATE DATABASE projetinho;
USE projetinho;


-- --------------------------------------------
-- TABELA: data_bronze
-- Recebe os dados brutos do CSV via Python
-- (pandas + SQLAlchemy). Nenhuma transformação
-- é aplicada aqui — é a fonte da verdade bruta.
-- --------------------------------------------
CREATE TABLE data_bronze (

    -- Identificadores
    transaction_id            VARCHAR(255),
    account_id                VARCHAR(255),
    merchant_id               VARCHAR(255),
    device_id                 VARCHAR(255),

    -- Dados da transação (como texto — sujos)
    transaction_amount        VARCHAR(255),
    transaction_type          VARCHAR(255),
    transaction_date          VARCHAR(255),
    transaction_duration      VARCHAR(255),
    channel                   VARCHAR(255),

    -- Dados do cliente (como texto — sujos)
    customer_age              VARCHAR(255),
    customer_occupation       VARCHAR(255),
    account_balance           VARCHAR(255),
    previous_transaction_date VARCHAR(255),

    -- Localização e rede
    location                  VARCHAR(255),
    ip_address                VARCHAR(255),

    -- Segurança
    login_attempts            VARCHAR(255),

    -- Metadados de controle gerados automaticamente pelo MySQL
    stg_loaded_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    stg_source_file           VARCHAR(255) DEFAULT 'bank_transactions_data_2.csv'

) ENGINE=InnoDB;


-- --------------------------------------------
-- A coluna IP Address veio com espaço no nome
-- vindo do CSV, o que impedia o acesso normal.
-- Renomeada aqui para evitar erros nas queries
-- da camada Silver.
-- --------------------------------------------
ALTER TABLE data_bronze RENAME COLUMN `IP Address` TO IpAddress;
