CREATE SCHEMA IF NOT EXISTS `banco_digital` DEFAULT CHARACTER SET utf8 ;
USE `banco_digital` ;

-- Tabela Clientes
CREATE TABLE IF NOT EXISTS clientes(
  `id_cliente` INT PRIMARY KEY AUTO_INCREMENT,
  `nome` VARCHAR(100) NOT NULL,
  `cpf` VARCHAR(11) NOT NULL UNIQUE,
  `data_nascimento` DATE NOT NULL
  );
  

-- Tabela Conta
CREATE TABLE IF NOT EXISTS conta (
	id_conta INT PRIMARY KEY AUTO_INCREMENT,
	status VARCHAR(45) DEFAULT 'Ativo',
	saldo DECIMAL(10,2) DEFAULT 0.00,
	tipo_conta VARCHAR(45),
	data_abertura DATE,
	id_cliente INT NOT NULL, -- FK também não pode ser nula se a conta precisa de um dono
	CONSTRAINT fk_conta_clientes
    FOREIGN KEY (id_cliente)
    REFERENCES clientes (id_cliente)
    );
   

-- Tabela Transacoes
CREATE TABLE IF NOT EXISTS transacoes(
  `id_transacao` INT PRIMARY KEY AUTO_INCREMENT,
  `data_transacao` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `valor` DECIMAL(10,2) NOT NULL,
  `tipo_transacao` VARCHAR(45),
  `id_conta_destino` INT NOT NULL,
   status VARCHAR(20),
  `descricao` VARCHAR(45),
  `id_conta_origem` INT NOT NULL,                        
  CONSTRAINT fk_transacao_origem
    FOREIGN KEY (id_conta_origem)
    REFERENCES conta (id_conta),
  CONSTRAINT fk_transacao_destino
    FOREIGN KEY (id_conta_destino)
    REFERENCES conta (id_conta)
);

SET FOREIGN_KEY_CHECKS = 0; -- Desativa a trava de chaves temporariamente
TRUNCATE TABLE transacoes;
TRUNCATE TABLE conta;
TRUNCATE TABLE clientes;
SET FOREIGN_KEY_CHECKS = 1;








