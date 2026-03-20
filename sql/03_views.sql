CREATE OR REPLACE VIEW v_extrato_detalhado AS
SELECT
    c.nome AS cliente,
    IFNULL(ct.tipo_conta, 'N/A') AS tipo_conta,
    IFNULL(t.data_transacao, 'N/A') AS data_transacao,
    IFNULL(t.valor, 0) AS valor,
    IFNULL(t.status, 'N/A') AS status
FROM clientes c
LEFT JOIN conta ct ON c.id_cliente = ct.id_cliente
LEFT JOIN transacoes t ON ct.id_conta = t.id_conta_origem
ORDER BY t.data_transacao DESC;


CREATE OR REPLACE VIEW v_auditoria_fraude AS
SELECT * FROM transacoes
WHERE (TIME(data_transacao) < '09:00:00' OR TIME(data_transacao) > '16:00:00')
   OR WEEKDAY(data_transacao) IN (5,6)
   OR DATE(data_transacao) IN ('2022-12-25', '2022-12-26');


SELECT * FROM v_auditoria_fraude;
SELECT * FROM v_extrato_detalhado;
