-- ============================================
-- ARQUIVO: 03_view_auditoria_operacoes_silver
-- CAMADA: Silver
-- Descrição: Views analíticas para auditoria,
--            detecção de fraudes e análise
--            operacional. Consomem as tabelas
--            silver e servem de base para a
--            camada Gold.
-- Database: silver
-- Autor: RicarteAnalyst
-- ============================================


USE silver;


-- --------------------------------------------
-- VIEW: v_extrato_detalhado
-- Extrato de transações com classificação de
-- status baseada em regras de negócio:
--   SUSPEITO      → login > 1 + horário tarde + valor alto
--   Teste de Cartão → login > 2 + valor baixo (card testing)
--   Alto Valor    → valor acima de R$ 10.000
--   Regular       → demais casos
-- --------------------------------------------
CREATE OR REPLACE VIEW silver.v_extrato_detalhado AS
SELECT
    sc.conta_id,
    sc.tentativas_login,
    st.valor_transacao,
    TIME(st.data_transacao) AS hora_transacao,
    st.tipo_transacao,
    CASE
        WHEN sc.tentativas_login > 1
             AND TIME(st.data_transacao) BETWEEN '16:00:00' AND '18:50:00'
             AND st.valor_transacao > 200.00
             THEN 'SUSPEITO'
        WHEN sc.tentativas_login > 2
             AND st.valor_transacao < 60.00
             THEN 'Teste de Cartão'
        WHEN valor_transacao > 10000
             THEN 'Alto Valor'
        ELSE 'Regular'
    END AS status
FROM silver.silver_cliente sc
JOIN silver.silver_transactions st ON sc.conta_id = st.conta_id
ORDER BY st.data_transacao DESC;


-- --------------------------------------------
-- VIEW: v_auditoria_fraude
-- Baseada no case real do JPMorgan/StrataScratch
-- para o Bank of Ireland. Filtra transações
-- fora do horário comercial, fins de semana
-- e feriados bancários de dezembro.
-- --------------------------------------------
CREATE OR REPLACE VIEW silver.v_auditoria_fraude AS
SELECT *
FROM silver.silver_transactions
WHERE (TIME(data_transacao) < '09:00:00' OR TIME(data_transacao) > '16:00:00')
   OR WEEKDAY(data_transacao) IN (5, 6)
   OR DATE(data_transacao)    IN ('2022-12-25', '2022-12-26');


-- --------------------------------------------
-- VIEW: v_ataque_esteira
-- Detecta padrão de múltiplas transações
-- pequenas em sequência rápida — técnica usada
-- por fraudadores para testar cartões antes de
-- realizar transações de alto valor.
-- Utiliza Window Functions com janela deslizante
-- de 5 transações (4 PRECEDING + CURRENT ROW).
-- OBS: Dataset simulado com baixa densidade
-- temporal — regra correta, sem disparos no dado.
-- --------------------------------------------
CREATE OR REPLACE VIEW silver.v_ataque_esteira AS
WITH calculos_cte AS (
    SELECT
        conta_id,
        id_transacao,
        data_transacao AS transacao_atual,
        valor_transacao AS valor_atual,
        MIN(data_transacao) OVER (
            PARTITION BY conta_id
            ORDER BY data_transacao
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS data_inicio_bloco,
        AVG(valor_transacao) OVER (
            PARTITION BY conta_id
            ORDER BY data_transacao
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS media_valor,
        COUNT(id_transacao) OVER (
            PARTITION BY conta_id
            ORDER BY data_transacao
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS qtd_transacoes
    FROM silver.silver_transactions
)
SELECT *,
    TIMESTAMPDIFF(HOUR, data_inicio_bloco, transacao_atual) AS tempo_intervalo,
    CASE
        WHEN qtd_transacoes > 3
             AND TIMESTAMPDIFF(HOUR, data_inicio_bloco, transacao_atual) < 120
             AND media_valor < 10
             THEN 'Suspeita de Ataque de Esteira'
        ELSE 'Normal'
    END AS status_fraude
FROM calculos_cte;


-- --------------------------------------------
-- VIEW: v_transacoes_fim_de_semana
-- Lista transações em sábados e domingos.
-- Dataset simulado cobre apenas dias úteis,
-- portanto retorna vazio — regra implementada
-- corretamente para uso em produção.
-- --------------------------------------------
CREATE OR REPLACE VIEW silver.v_transacoes_fim_de_semana AS
SELECT
    conta_id,
    data_transacao,
    CASE DAYOFWEEK(data_transacao)
        WHEN 1 THEN 'Domingo'
        WHEN 7 THEN 'Sábado'
    END AS dia_semana
FROM silver.fato_transacoes
WHERE DAYOFWEEK(data_transacao) IN (1, 7);


-- --------------------------------------------
-- VIEW: v_clientes_saldo_negativo
-- Clientes com saldo abaixo de zero.
-- --------------------------------------------
CREATE OR REPLACE VIEW silver.v_clientes_saldo_negativo AS
SELECT
    conta_id,
    balanco_conta
FROM silver.dim_cliente
WHERE balanco_conta < 0;


-- --------------------------------------------
-- VIEW: v_transacoes_por_canal
-- Volume e quantidade de transações agrupados
-- por canal (ATM, Online, Branch).
-- --------------------------------------------
CREATE OR REPLACE VIEW silver.v_transacoes_por_canal AS
SELECT
    canal,
    COUNT(canal)          AS contagem_p_canal,
    SUM(valor_transacao)  AS soma_transacao_p_canal
FROM silver.fato_transacoes
GROUP BY canal
ORDER BY soma_transacao_p_canal DESC;


-- --------------------------------------------
-- VIEW: v_transacoes_intervalo_curto
-- Detecta transações do mesmo cliente com
-- menos de 60 minutos de diferença.
-- Usa LAG() para comparar com a transação
-- anterior e COUNT() em janela deslizante
-- para medir frequência recente.
-- --------------------------------------------
CREATE OR REPLACE VIEW silver.v_transacoes_intervalo_curto AS
WITH transacao_anterior_cte AS (
    SELECT
        conta_id,
        valor_transacao,
        id_transacao,
        data_transacao,
        LAG(data_transacao) OVER (
            PARTITION BY conta_id
            ORDER BY data_transacao
        ) AS transacao_anterior
    FROM silver.fato_transacoes
),
filtro_p_hr AS (
    SELECT
        conta_id,
        valor_transacao,
        id_transacao,
        data_transacao,
        COUNT(conta_id) OVER (
            PARTITION BY conta_id
            ORDER BY data_transacao
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS qtd_transacoes,
        TIMESTAMPDIFF(MINUTE, transacao_anterior, data_transacao) AS minutos_diferenca
    FROM transacao_anterior_cte
    -- Exclui a primeira transação de cada cliente (LAG retorna NULL)
    WHERE transacao_anterior IS NOT NULL
)
SELECT *
FROM filtro_p_hr
WHERE minutos_diferenca < 60
ORDER BY conta_id, data_transacao DESC;
