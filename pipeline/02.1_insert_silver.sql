-- ============================================
-- ARQUIVO: 02.1_insert_silver
-- CAMADA: Silver
-- Descrição: Carga das tabelas silver a partir
--            da data_bronze. Os dados são tratados
--            e tipados durante a inserção via
--            INSERT INTO ... SELECT.
--            Ordem de carga obrigatória por causa
--            das Foreign Keys.
-- Database: silver
-- Autor: RicarteAnalyst
-- ============================================


USE silver;


-- --------------------------------------------
-- CARGA 1: silver_cidade
-- Sem dependências — pode ser carregada primeiro.
-- DISTINCT + GROUP BY garante uma linha por
-- combinação única de IP + cidade.
-- --------------------------------------------
INSERT INTO silver_cidade (endereco_ip, local)
SELECT DISTINCT
    IpAddress,
    Location
FROM projetinho.data_bronze
GROUP BY IpAddress, Location;


-- --------------------------------------------
-- CARGA 2: silver_cliente
-- Sem dependências — pode ser carregada antes
-- das transações.
-- MAX() utilizado pois o mesmo cliente aparece
-- em múltiplas linhas na bronze (uma por transação).
-- Para campos estáticos como idade e ocupação,
-- MAX() retorna o mesmo valor — é um atalho seguro.
-- Para balanco_conta, MAX() retorna o maior saldo
-- registrado (não necessariamente o mais recente).
-- --------------------------------------------
INSERT INTO silver_cliente (
    conta_id,
    tentativas_login,
    cliente_idade,
    ocupacao_cliente,
    balanco_conta
)
SELECT DISTINCT
    AccountId,
    MAX(LoginAttempts),
    MAX(CAST(CustomerAge AS UNSIGNED)),
    MAX(CustomerOccupation),
    MAX(CAST(AccountBalance AS DECIMAL(15, 2)))
FROM projetinho.data_bronze
GROUP BY AccountID;


-- --------------------------------------------
-- CARGA 3: silver_transactions
-- Depende de silver_cliente e silver_cidade.
-- Tipos convertidos explicitamente durante
-- a inserção: datas, decimais e inteiros.
-- id_cidade não é inserido aqui — é populado
-- no UPDATE abaixo via JOIN.
-- --------------------------------------------
INSERT INTO silver_transactions (
    id_transacao,
    conta_id,
    comerciante_id,
    valor_transacao,
    tipo_transacao,
    data_transacao,
    duracao_transacao,
    canal
)
SELECT DISTINCT
    TransactionID,
    AccountId,
    MerchantId,
    CAST(TransactionAmount AS DECIMAL(10, 2)),
    TransactionType,
    STR_TO_DATE(TransactionDate, '%Y-%m-%d %H:%i:%s'),
    CAST(TransactionDuration AS UNSIGNED),
    Channel
FROM projetinho.data_bronze;


-- --------------------------------------------
-- UPDATE: popula id_cidade nas transações
-- Feito após a carga das transações pois
-- requer JOIN entre três tabelas para
-- encontrar o id_cidade correto de cada
-- transação via IP + Location.
-- --------------------------------------------
UPDATE silver_transactions st
JOIN projetinho.data_bronze db ON st.id_transacao = db.TransactionId
JOIN silver_cidade sc
    ON sc.endereco_ip = db.IpAddress
    AND sc.local      = db.Location
SET st.id_cidade = sc.id_cidade;
