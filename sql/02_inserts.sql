INSERT INTO clientes(nome, cpf, data_nascimento)VALUES
( 'nicollas', '323456', '2006-08-30'),
( 'gabriel', '654320', '2008-09-30'),
( 'lucas', '998765', '2000-01-11');



INSERT INTO conta (id_conta, status, saldo, tipo_conta, data_abertura, id_cliente) VALUES 
(1, 'Ativo', 1500.00, 'corrente', '2022-03-30', 1),
(2, 'Ativo', 3000.00, 'corrente', '2020-04-30', 2);



INSERT INTO transacoes(id_transacao, data_transacao, valor, tipo_transacao, id_conta_destino, id_conta_origem, status, descricao) VALUES
(1, '2025-01-01 00:30:00', 500.00, 'PIX', 2, 1, 'Aprovada', 'Lanche'),
(2, '2026-05-28 22:15:00', 1000.00, 'TED', 1, 2, 'Aprovada', 'Dívida');
