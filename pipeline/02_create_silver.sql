-- ============================================
-- ARQUIVO: 02_create_silver
-- CAMADA: Silver
-- Descrição: Criação das tabelas tratadas com
--            tipos corretos, constraints e FKs.
--            As tabelas já foram modeladas pensando
--            na evolução para o modelo dimensional
--            da camada Gold (Fato + Dimensões).
-- Database: silver
-- Autor: RicarteAnalyst
-- ============================================


CREATE DATABASE IF NOT EXISTS silver;
USE silver;


-- --------------------------------------------
-- TABELA: silver_cidade (futura dim_cidade)
-- Armazena endereços IP e cidades únicas.
-- Separada da tabela de transações para evitar
-- redundância e facilitar análises geográficas.
-- --------------------------------------------
CREATE TABLE silver_cidade (
    id_cidade  INT          PRIMARY KEY AUTO_INCREMENT,
    endereco_ip VARCHAR(50),
    local       VARCHAR(100)
);


-- --------------------------------------------
-- TABELA: silver_cliente (futura dim_cliente)
-- Armazena os dados cadastrais do cliente.
-- O MAX() nos inserts foi necessário pois um
-- mesmo cliente aparece em múltiplas linhas
-- na bronze (uma por transação).
-- --------------------------------------------
CREATE TABLE silver_cliente (
    conta_id         VARCHAR(50)      PRIMARY KEY NOT NULL,
    tentativas_login INT,
    cliente_idade    TINYINT UNSIGNED NOT NULL,
    ocupacao_cliente VARCHAR(50)      NOT NULL,
    balanco_conta    DECIMAL(15, 2)
);


-- --------------------------------------------
-- TABELA: silver_transactions (futura fato_transacoes)
-- Tabela central do modelo. Referencia cliente
-- e cidade via Foreign Keys, garantindo
-- integridade referencial.
-- Ordem de criação importa: cidade e cliente
-- devem existir antes desta tabela.
-- --------------------------------------------
CREATE TABLE silver_transactions (
    id_transacao      VARCHAR(50)  PRIMARY KEY,
    conta_id          VARCHAR(50),
    id_cidade         INT,
    valor_transacao   DECIMAL(10, 2),
    comerciante_id    VARCHAR(50),
    tipo_transacao    VARCHAR(100) NOT NULL,
    data_transacao    DATETIME,
    duracao_transacao INT,
    canal             VARCHAR(30),

    CONSTRAINT FkTransacaoCliente FOREIGN KEY (conta_id)
        REFERENCES silver_cliente (conta_id),

    CONSTRAINT FkCidadeCliente FOREIGN KEY (id_cidade)
        REFERENCES silver_cidade (id_cidade)
);
