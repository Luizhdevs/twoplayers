-- =========================================
-- DCL.SQL
-- Projeto: TwoPlayers
-- Banco: PostgreSQL
-- =========================================


-- =========================================
-- CRIAÇÃO DE ROLES
-- =========================================

CREATE ROLE administrador;
CREATE ROLE cliente;
CREATE ROLE prestador;
CREATE ROLE suporte;
CREATE ROLE financeiro;
CREATE ROLE leitura;


-- =========================================
-- PERMISSÕES DE SCHEMA
-- =========================================

GRANT USAGE ON SCHEMA auth TO administrador, cliente, prestador;
GRANT USAGE ON SCHEMA marketplace TO administrador, cliente, prestador;
GRANT USAGE ON SCHEMA financial TO administrador, financeiro;
GRANT USAGE ON SCHEMA social TO administrador, cliente, prestador;
GRANT USAGE ON SCHEMA support TO administrador, suporte;
GRANT USAGE ON SCHEMA core TO administrador, cliente, prestador;
GRANT USAGE ON SCHEMA audit TO administrador;


-- =========================================
-- PERMISSÕES - AUTH
-- =========================================

GRANT SELECT, INSERT, UPDATE
ON auth.usuario
TO administrador;

GRANT SELECT, INSERT, UPDATE
ON auth.perfil
TO administrador;

GRANT SELECT
ON auth.usuario
TO leitura;

GRANT SELECT
ON auth.perfil
TO leitura;


-- =========================================
-- PERMISSÕES - MARKETPLACE
-- =========================================

GRANT SELECT, INSERT, UPDATE, DELETE
ON marketplace.servico
TO administrador;

GRANT SELECT, INSERT, UPDATE
ON marketplace.servico
TO prestador;

GRANT SELECT
ON marketplace.servico
TO cliente, leitura;


GRANT SELECT, INSERT, UPDATE
ON marketplace.agendamento
TO administrador;

GRANT SELECT, INSERT
ON marketplace.agendamento
TO cliente;

GRANT SELECT, UPDATE
ON marketplace.agendamento
TO prestador;


GRANT SELECT, INSERT, UPDATE
ON marketplace.disponibilidade
TO prestador;

GRANT SELECT
ON marketplace.disponibilidade
TO cliente, leitura;


GRANT SELECT
ON marketplace.servico_tag
TO leitura;

GRANT SELECT
ON marketplace.servico
TO leitura;


-- =========================================
-- PERMISSÕES - FINANCIAL
-- =========================================

GRANT SELECT, INSERT, UPDATE
ON financial.carteira
TO administrador, financeiro;

GRANT SELECT
ON financial.carteira
TO leitura;


GRANT SELECT, INSERT, UPDATE
ON financial.transacao
TO administrador, financeiro;

GRANT SELECT
ON financial.transacao
TO leitura;


GRANT SELECT, INSERT, UPDATE
ON financial.conta_recebimento
TO administrador, financeiro;

GRANT SELECT
ON financial.conta_recebimento
TO leitura;


GRANT SELECT, INSERT, UPDATE
ON financial.kyc
TO administrador, financeiro;

GRANT SELECT
ON financial.kyc
TO leitura;


-- =========================================
-- PERMISSÕES - SOCIAL
-- =========================================

GRANT SELECT, INSERT, UPDATE, DELETE
ON social.postagem
TO administrador;

GRANT SELECT, INSERT, UPDATE
ON social.postagem
TO cliente, prestador;

GRANT SELECT
ON social.postagem
TO leitura;


GRANT SELECT, INSERT, DELETE
ON social.curtida
TO cliente, prestador;

GRANT SELECT
ON social.curtida
TO leitura;


GRANT SELECT, INSERT
ON social.avaliacao
TO cliente;

GRANT SELECT
ON social.avaliacao
TO leitura;


-- =========================================
-- PERMISSÕES - SUPPORT
-- =========================================

GRANT SELECT, INSERT, UPDATE
ON support.disputa
TO administrador, suporte;

GRANT SELECT, INSERT
ON support.disputa
TO cliente, prestador;

GRANT SELECT
ON support.disputa
TO leitura;


GRANT SELECT, INSERT, UPDATE
ON support.prova_disputa
TO administrador, suporte;

GRANT SELECT, INSERT
ON support.prova_disputa
TO cliente, prestador;

GRANT SELECT
ON support.prova_disputa
TO leitura;


-- =========================================
-- PERMISSÕES - CORE
-- =========================================

GRANT SELECT
ON core.categoria
TO cliente, prestador, leitura;

GRANT SELECT
ON core.tag
TO cliente, prestador, leitura;


-- =========================================
-- PERMISSÕES - AUDITORIA
-- =========================================

GRANT SELECT, INSERT
ON audit.log
TO administrador;

GRANT SELECT
ON audit.log
TO leitura;


-- =========================================
-- PERMISSÕES NAS PROCEDURES
-- =========================================

GRANT EXECUTE
ON PROCEDURE auth.sp_criar_usuario
TO administrador;

GRANT EXECUTE
ON FUNCTION auth.fn_login_usuario(TEXT, TEXT)
TO administrador, cliente, prestador;

GRANT EXECUTE
ON PROCEDURE marketplace.sp_criar_agendamento
TO cliente;

GRANT EXECUTE
ON PROCEDURE financial.sp_adicionar_saldo
TO financeiro;

GRANT EXECUTE
ON PROCEDURE social.sp_criar_avaliacao
TO cliente;

GRANT EXECUTE
ON PROCEDURE support.sp_abrir_disputa
TO cliente, prestador;

GRANT EXECUTE
ON PROCEDURE social.sp_criar_postagem
TO cliente, prestador;

GRANT EXECUTE
ON PROCEDURE social.sp_curtir_postagem
TO cliente, prestador;


-- =========================================
-- CRIAÇÃO DE USUÁRIOS DO BANCO
-- =========================================

CREATE USER admin_db
WITH PASSWORD 'Admin123@';

CREATE USER cliente_db
WITH PASSWORD 'Cliente123@';

CREATE USER prestador_db
WITH PASSWORD 'Prestador123@';

CREATE USER suporte_db
WITH PASSWORD 'Suporte123@';

CREATE USER financeiro_db
WITH PASSWORD 'Financeiro123@';


-- =========================================
-- VINCULAR ROLES AOS USUÁRIOS
-- =========================================

GRANT administrador TO admin_db;
GRANT cliente TO cliente_db;
GRANT prestador TO prestador_db;
GRANT suporte TO suporte_db;
GRANT financeiro TO financeiro_db;


-- =========================================
-- REVOGAR PERMISSÕES PÚBLICAS
-- =========================================

REVOKE ALL ON SCHEMA auth FROM PUBLIC;
REVOKE ALL ON SCHEMA marketplace FROM PUBLIC;
REVOKE ALL ON SCHEMA financial FROM PUBLIC;
REVOKE ALL ON SCHEMA social FROM PUBLIC;
REVOKE ALL ON SCHEMA support FROM PUBLIC;
REVOKE ALL ON SCHEMA audit FROM PUBLIC;
REVOKE ALL ON SCHEMA core FROM PUBLIC;


-- =========================================
-- PERMISSÕES - ESCROW E REPASSE
-- =========================================

GRANT SELECT, INSERT, UPDATE
ON financial.escrow_movimentacao
TO administrador, financeiro;

GRANT SELECT
ON financial.escrow_movimentacao
TO prestador, leitura;


GRANT SELECT, INSERT, UPDATE
ON financial.repasse_mensal
TO administrador, financeiro;

GRANT SELECT
ON financial.repasse_mensal
TO prestador, leitura;


-- =========================================
-- PERMISSÕES NAS NOVAS PROCEDURES
-- =========================================

GRANT EXECUTE
ON PROCEDURE financial.sp_entrada_escrow
TO financeiro, administrador;

GRANT EXECUTE
ON PROCEDURE financial.sp_liberar_escrow
TO financeiro, administrador;

GRANT EXECUTE
ON PROCEDURE financial.sp_estornar_escrow
TO administrador;

GRANT EXECUTE
ON PROCEDURE financial.sp_processar_repasse_mensal
TO financeiro, administrador;

GRANT EXECUTE
ON PROCEDURE social.sp_criar_avaliacao
TO cliente;


-- =========================================
-- PERMISSÕES - CRIAÇÃO DE ROLES (complemento)
-- =========================================

GRANT USAGE ON SCHEMA financial TO prestador;

GRANT SELECT
ON financial.carteira
TO prestador;

GRANT SELECT
ON financial.transacao
TO prestador;

GRANT SELECT
ON financial.repasse_mensal
TO prestador;

GRANT SELECT
ON financial.escrow_movimentacao
TO prestador;


-- =========================================
-- COMMIT
-- =========================================

COMMIT;