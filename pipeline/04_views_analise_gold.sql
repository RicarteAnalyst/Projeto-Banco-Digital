-- ============================================
-- ARQUIVO: 04_views_analise_gold
-- CAMADA: Gold
-- Descrição: Criação do modelo dimensional
--            (Star Schema) e views analíticas
--            prontas para consumo em ferramentas
--            de BI como Power BI ou Metabase.
-- Database: dw_gold
-- Autor: RicarteAnalyst
-- ============================================


CREATE DATABASE dw_gold;
USE dw_gold;


-- --------------------------------------------
-- MODELO DIMENSIONAL — Star Schema
-- As tabelas dim e fato são criadas como cópia
-- das tabelas silver via CREATE TABLE AS SELECT.
-- OBS: Foreign Keys não são copiadas nesse processo
-- — as relações são mantidas via JOIN nas views.
--
--        dim_cliente
--              ↑
--              | conta_id
--              |
--    fato_transacoes ──id_cidade──> dim_cidade
-- --------------------------------------------
CREATE TABLE dw_gold.dim_cliente     AS SELECT * FROM silver.silver_cliente;
CREATE TABLE dw_gold.dim_cidade      AS SELECT * FROM silver.dim_cidade;
CREATE TABLE dw_gold.fato_transacoes AS SELECT * FROM silver.fato_transacoes;


-- --------------------------------------------
-- VIEW: visao_geografica
-- Volume financeiro total por conta e cidade.
-- --------------------------------------------
CREATE OR REPLACE VIEW dw_gold.visao_geografica AS
SELECT
    dc.conta_id,
    SUM(ft.valor_transacao) AS valor_total,
    dci.local
FROM dw_gold.fato_transacoes ft
INNER JOIN dw_gold.dim_cliente dc  ON dc.conta_id  = ft.conta_id
INNER JOIN dw_gold.dim_cidade  dci ON dci.id_cidade = ft.id_cidade
GROUP BY dc.conta_id, dci.local
ORDER BY valor_total DESC;


-- --------------------------------------------
-- VIEW: filtro_agrupamento
-- Transações agrupadas por tipo com status
-- Aprovada/Reprovada baseado no valor total.
-- --------------------------------------------
CREATE OR REPLACE VIEW dw_gold.filtro_agrupamento AS
WITH status AS (
    SELECT
        tipo_transacao,
        SUM(valor_transacao) AS valor_total,
        CASE
            WHEN SUM(valor_transacao) > 0 THEN 'Aprovada'
            ELSE 'Reprovada'
        END AS status_transacao
    FROM dw_gold.fato_transacoes
    GROUP BY tipo_transacao
)
SELECT * FROM status
WHERE status_transacao = 'Aprovada';


-- --------------------------------------------
-- VIEW: faturamento_total
-- Market share de cada conta no volume total
-- de transações usando Window Function OVER().
-- --------------------------------------------
CREATE OR REPLACE VIEW dw_gold.faturamento_total AS
SELECT
    conta_id,
    valor_total,
    CONCAT(ROUND((valor_total / SUM(valor_total) OVER()) * 100, 2), '%') AS market_share
FROM dw_gold.visao_geografica;


-- --------------------------------------------
-- VIEW: casos_criticos
-- Consome a view v_transacoes_intervalo_curto
-- da Silver e expõe os casos mais relevantes
-- para análise na camada Gold.
-- --------------------------------------------
CREATE OR REPLACE VIEW dw_gold.casos_criticos AS
SELECT
    conta_id,
    valor_transacao,
    id_transacao,
    data_transacao,
    minutos_diferenca,
    qtd_transacoes
FROM silver.v_transacoes_intervalo_curto;


-- --------------------------------------------
-- VIEW: v_ranking_cidades
-- Ranking de cidades por volume financeiro
-- usando RANK() com Window Function.
-- --------------------------------------------
CREATE OR REPLACE VIEW dw_gold.v_ranking_cidades AS
SELECT
    dci.local,
    SUM(ft.valor_transacao)                                   AS valor_total,
    RANK() OVER (ORDER BY SUM(ft.valor_transacao) DESC)       AS ranking
FROM silver.fato_transacoes ft
INNER JOIN dw_gold.dim_cidade dci ON dci.id_cidade = ft.id_cidade
GROUP BY dci.local
ORDER BY ranking;


-- --------------------------------------------
-- VIEW: v_distribuicao_tipo_transacao
-- Percentual de Débito vs Crédito no total
-- de transações usando Window Function OVER().
-- Resultado: Debit ~77% | Credit ~23%
-- --------------------------------------------
CREATE OR REPLACE VIEW dw_gold.v_distribuicao_tipo_transacao AS
WITH contagem AS (
    SELECT
        tipo_transacao,
        COUNT(*) AS qtd
    FROM dw_gold.fato_transacoes
    GROUP BY tipo_transacao
)
SELECT
    tipo_transacao,
    qtd,
    CONCAT(ROUND((qtd / SUM(qtd) OVER()) * 100, 2), '%') AS percentual
FROM contagem;


-- --------------------------------------------
-- VIEW: v_clientes_high_value
-- Clientes com gasto total acima da média geral.
-- Duas CTEs: primeira calcula o total por cliente,
-- segunda calcula a média geral via AVG() OVER().
-- --------------------------------------------
CREATE OR REPLACE VIEW dw_gold.v_clientes_high_value AS
WITH geral_gastos AS (
    SELECT
        conta_id,
        SUM(valor_transacao) AS total_cliente
    FROM dw_gold.fato_transacoes
    GROUP BY conta_id
),
media_geral AS (
    SELECT
        conta_id,
        total_cliente,
        ROUND(AVG(total_cliente) OVER(), 2) AS media_geral_gastos
    FROM geral_gastos
)
SELECT
    conta_id,
    total_cliente,
    media_geral_gastos
FROM media_geral
WHERE total_cliente > media_geral_gastos
ORDER BY total_cliente DESC;


-- --------------------------------------------
-- VIEW: v_ticket_medio_por_cidade
-- Ticket médio de transação agrupado por cidade.
-- Útil para identificar cidades com maior
-- poder de compra ou concentração de fraudes.
-- --------------------------------------------
CREATE OR REPLACE VIEW dw_gold.v_ticket_medio_por_cidade AS
WITH agrupando AS (
    SELECT
        dci.local,
        AVG(ft.valor_transacao) AS ticket_medio
    FROM silver.fato_transacoes ft
    INNER JOIN dw_gold.dim_cidade dci ON dci.id_cidade = ft.id_cidade
    GROUP BY dci.local
)
SELECT
    local,
    ROUND(ticket_medio, 2) AS ticket_medio
FROM agrupando
ORDER BY ticket_medio DESC;


-- --------------------------------------------
-- VIEW: v_market_share_canal
-- Participação percentual de cada canal
-- (ATM, Online, Branch) no total de transações.
-- Resultado: distribuição quase uniforme ~33% cada
-- (característica do dataset simulado).
-- --------------------------------------------
CREATE OR REPLACE VIEW dw_gold.v_market_share_canal AS
WITH contagem AS (
    SELECT
        canal,
        COUNT(*) AS qtd
    FROM dw_gold.fato_transacoes
    GROUP BY canal
)
SELECT
    canal,
    qtd,
    CONCAT(ROUND((qtd / SUM(qtd) OVER()) * 100, 2), '%') AS percentual
FROM contagem;


-- --------------------------------------------
-- VIEW: v_evolucao_mensal
-- Volume financeiro mês a mês com comparativo
-- ao período anterior usando LAG().
-- O NULL no primeiro mês é esperado — não há
-- período anterior para comparar.
-- --------------------------------------------
CREATE OR REPLACE VIEW dw_gold.v_evolucao_mensal AS
WITH extracao AS (
    SELECT
        DATE_FORMAT(data_transacao, '%Y-%m') AS mes_ano,
        SUM(valor_transacao)                 AS volume,
        COUNT(*)                             AS qtd_transacoes
    FROM dw_gold.fato_transacoes
    GROUP BY mes_ano
)
SELECT
    mes_ano,
    ROUND(volume, 2)                                    AS volume,
    qtd_transacoes,
    ROUND(LAG(volume) OVER (ORDER BY mes_ano), 2)       AS volume_mes_anterior
FROM extracao
ORDER BY mes_ano;
