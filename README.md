# 🏦 Banco Digital — Da Modelagem Relacional ao Pipeline ELT com Detecção de Fraudes

Este repositório documenta a evolução completa do meu aprendizado em Banco de Dados e Engenharia de Dados, partindo de conceitos fundamentais de modelagem relacional até a construção de um pipeline ELT moderno com camadas Bronze, Silver e Gold.

> **Nota de Histórico:** Este portfólio integra meu aprendizado inicial com minha evolução atual, demonstrando a base sólida que permitiu o desenvolvimento do pipeline de detecção de fraudes.

---

## 📁 Estrutura do Repositório

```
projeto-banco-digital-v1/
├── diagramas/
│   ├── modelo_conceitual.png
│   └── modelo_logico.png
├── sql/                          ← Parte 1
│   ├── 01_schema.sql
│   ├── 02_inserts.sql
│   └── 03_views.sql
├── pipeline/                     ← Parte 2
│   ├── bronze_ddl.sql
│   ├── silver_ddl.sql
│   ├── silver_inserts.sql
│   ├── gold_ddl.sql
│   └── gold_views.sql
├── src/                          ← Python
│   ├── database.py
│   └── main.py
├── bank_transactions_data_2.csv
└── README.md
```

---

## 🗂️ Parte 1 — Banco Digital: Modelagem Relacional e Auditoria

### 🎯 O Desafio

Projeto fundamentado em um case real de auditoria do **JPMorgan / StrataScratch**, exigindo a detecção de transações inválidas ocorridas em dezembro de 2022 para o Bank of Ireland.

**Regra de Negócio para Auditoria:** Uma transação é considerada inválida se ocorrer fora do horário normal de operação:
- **Segunda a Sexta:** Fora do intervalo 09h00 – 16h00
- **Sábados e Domingos:** Fechado
- **Feriados Bancários:** 25 e 26 de Dezembro

---

### 🛠️ Etapas do Desenvolvimento

#### 1. Modelo Conceitual
Representação de alto nível utilizando o Diagrama Entidade-Relacionamento (DER), definindo as entidades `clientes`, `conta` e `transacoes` e seus relacionamentos.
![Modelo Conceitual](diagramas/Modelo-Conceitual.png)

#### 2. Modelo Lógico
Tradução do conceito para tabelas e colunas, definindo tipos de dados e Chaves Estrangeiras (FK) para garantir a integridade referencial.
![Modelo Conceitual](diagramas/Modelo-Lógico.png)

```
clientes (1) ──possui──> (N) conta (1) ──realiza──> (N) transacoes
```

| Tabela | Colunas principais |
|---|---|
| `clientes` | `id_cliente`, `nome`, `cpf`, `data_nascimento` |
| `conta` | `id_conta`, `status`, `saldo`, `tipo_conta`, `data_abertura`, `id_clientes` |
| `transacoes` | `id_transacao`, `data_transacao`, `valor`, `tipo_transacao`, `id_conta_origem`, `id_conta_destino` |

#### 3. Implementação Técnica
O projeto está modularizado:
- `sql/01_schema.sql` — Estrutura de tabelas e constraints
- `sql/02_inserts.sql` — Dados de teste para validação das regras
- `sql/03_views.sql` — Camada de auditoria e inteligência

---

### ✨ Diferenciais Técnicos

- **Auditoria Automatizada (Case JPMorgan):** View `v_auditoria_fraude` que filtra automaticamente transações que violam os horários de operação bancária
- **Tratamento de Dados Inativos:** Uso de `LEFT JOIN` com `IFNULL` para reportar clientes sem movimentação
- **Integridade de Fluxo:** Dupla Chave Estrangeira (`id_conta_origem` e `id_conta_destino`) para garantir consistência nas transações
- **Pronto para BI:** Views criadas para entrega direta ao Power BI ou Tableau

> Aprovado com **94% de aproveitamento** na disciplina de Modelagem Relacional (Uninter).

### ⚙️ Como Executar

Execute os scripts no MySQL Workbench na seguinte ordem:
```
sql/01_schema.sql   → criação das tabelas e constraints
sql/02_inserts.sql  → inserção dos dados de teste
sql/03_views.sql    → criação das views de auditoria
```

---

## 🚀 Parte 2 — Pipeline ELT: Detecção de Fraudes Bancárias

Evolução natural do projeto anterior, aplicando os conceitos de modelagem em um pipeline ELT moderno com dados reais do Kaggle.

### 🗺️ Arquitetura

```
CSV (Kaggle — bank_transactions_data_2.csv)
          ↓
     [ BRONZE ]  →  data_bronze           (carga bruta via Python)
          ↓
     [ SILVER ]  →  Tabelas tratadas      (tipagem, modelagem, views de auditoria)
          ↓
     [ GOLD   ]  →  Modelo dimensional    (Star Schema, views de negócio e BI)
```

---

### 🛠️ Tecnologias

- **MySQL** — banco de dados relacional
- **Python** — ingestão do CSV via `pandas` + `SQLAlchemy`
- **SQL** — modelagem, transformações e views analíticas

---

### 📦 Camada Bronze — `projetinho`

Ingestão bruta do CSV. Todas as colunas são carregadas como `VARCHAR` para evitar erros de conversão, garantindo que nenhum dado seja perdido na entrada.

| Tabela | Descrição |
|---|---|
| `data_bronze` | Dados brutos das transações bancárias (2.512 registros) |

---

### 🥈 Camada Silver — `silver`

Dados tratados, tipados e modelados com integridade referencial. A carga é feita via `INSERT INTO ... SELECT` com conversões explícitas de tipos.

#### Tabelas

| Tabela | Descrição |
|---|---|
| `silver_cliente` | Clientes com conta, idade, ocupação, saldo , balanco da conta e tentativas de login |
| `silver_cidade` | Endereços IP e cidades das transações |
| `silver_transactions` | Transações com FK para cliente e cidade |

#### Fluxo de Carga

```sql
-- 1. silver_cidade      (sem dependências)
-- 2. silver_cliente     (sem dependências)
-- 3. silver_transactions (referencia cliente e cidade)
-- 4. UPDATE id_cidade via JOIN (popula a FK após carga)
```

#### Views Silver

| View | Descrição |
|---|---|
| `v_extrato_detalhado` | Extrato com classificação de status por regra de negócio |
| `v_auditoria_fraude` | Transações fora do horário comercial, fins de semana e feriados |
| `v_ataque_esteira` | Detecção de múltiplas transações pequenas em sequência (Window Functions) |
| `v_transacoes_intervalo_curto` | Transações do mesmo cliente com menos de 60 minutos de diferença |
| `v_transacoes_fim_de_semana` | Transações em sábados e domingos |
| `v_clientes_saldo_negativo` | Clientes com saldo negativo |
| `v_transacoes_por_canal` | Volume e quantidade por canal (ATM, Online, Branch) |

---

### 🥇 Camada Gold — `dw_gold`

Modelo dimensional (Star Schema) pronto para consumo em ferramentas de BI.

#### Star Schema

```
         dim_cliente
               ↑
               | conta_id
               |
     fato_transacoes  ──id_cidade──>  dim_cidade
```

#### Views Gold

| View | Descrição |
|---|---|
| `visao_geografica` | Volume financeiro por conta e cidade |
| `faturamento_total` | Market share por conta no volume total |
| `filtro_agrupamento` | Transações aprovadas agrupadas por tipo |
| `casos_criticos` | Casos críticos de intervalo curto entre transações |
| `v_ranking_cidades` | Ranking de cidades por volume financeiro com `RANK()` |
| `v_distribuicao_tipo_transacao` | Percentual de Débito vs Crédito |
| `v_clientes_high_value` | Clientes acima da média geral de gastos |
| `v_ticket_medio_por_cidade` | Ticket médio por cidade |
| `v_market_share_canal` | Participação percentual por canal |
| `v_evolucao_mensal` | Volume mês a mês com comparativo ao período anterior via `LAG()` |

---

### 🔍 Regras de Detecção de Fraude

#### Classificação por Status (`v_extrato_detalhado`)

| Status | Critério |
|---|---|
| `SUSPEITO` | Mais de 1 tentativa de login + horário entre 16h e 18h50 + valor acima de R$ 200 |
| `Teste de Cartão` | Mais de 2 tentativas de login + valor abaixo de R$ 60 |
| `Alto Valor` | Valor acima de R$ 10.000 |
| `Regular` | Demais casos |

#### Auditoria de Horário (`v_auditoria_fraude`)
- Transações antes das 9h ou após as 16h
- Transações em fins de semana
- Transações em feriados (25/12 e 26/12)

#### Ataque de Esteira (`v_ataque_esteira`)
Detecta múltiplas transações pequenas em sequência usando Window Functions (`COUNT OVER`, `AVG OVER`, `MIN OVER`):
- Mais de 3 transações em bloco de 5
- Intervalo inferior a 120 horas
- Média de valor abaixo de R$ 10

---

### ⚙️ Como Executar

#### 1. Instalar dependências Python
```bash
pip install pandas sqlalchemy pymysql python-dotenv
```

#### 2. Configurar variáveis de ambiente
Crie um arquivo `.env` na raiz:
```
DB_USER=root
DB_PASSWORD=sua_senha
DB_HOST=localhost
DB_PORT=3306
DB_NAME=projetinho
```

#### 3. Criar a tabela staging e carregar os dados
```bash
python src/main.py
```

#### 4. Executar os scripts SQL na ordem
```
pipeline/bronze_ddl.sql       → criação da camada bronze
pipeline/silver_ddl.sql       → criação da camada silver
pipeline/silver_inserts.sql   → carga da silver
pipeline/gold_ddl.sql         → criação da camada gold
pipeline/gold_views.sql       → views analíticas
```

---

### ⚠️ Observações sobre a Qualidade dos Dados

Durante a análise exploratória, foram identificadas limitações no dataset simulado que impactam as regras de detecção de fraude:

- **Ausência de transações nos fins de semana** — o dataset cobre apenas dias úteis, o que inviabiliza regras baseadas em comportamento atípico em sábados e domingos. Em produção, transações nesses dias seriam um sinal relevante de risco.

- **Concentração anômala às segundas-feiras** — aproximadamente 42% das transações estão concentradas nesse dia, distribuição atípica que em dados reais indicaria problema de coleta ou geração.

- **Baixa densidade temporal por conta** — cada cliente possui poucas transações ao longo do período, inviabilizando a detecção de padrões como ataque de esteira. As regras foram implementadas corretamente e funcionariam em produção com volume adequado.

> Essas limitações foram identificadas e documentadas intencionalmente, demonstrando a importância da análise crítica da qualidade dos dados antes da aplicação de regras de negócio.

---

## 📈 Próximos Passos

- Conectar a camada Gold ao Power BI ou Metabase para dashboards de fraude
- Implementar o pipeline no Apache Airflow para carga automatizada
- Adicionar modelo preditivo (ML) para scoring de risco de fraude
