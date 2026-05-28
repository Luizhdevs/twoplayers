-- =========================================
-- DDL.SQL
-- Projeto: TwoPlayers 
-- Banco: PostgreSQL
-- Segurança:
-- - AES-256 para dados sensíveis
-- - bcrypt/crypt para senhas
-- =========================================


-- =========================================
-- EXTENSÃO
-- =========================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- =========================================
-- SCHEMAS
-- =========================================

CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS financial;
CREATE SCHEMA IF NOT EXISTS marketplace;
CREATE SCHEMA IF NOT EXISTS social;
CREATE SCHEMA IF NOT EXISTS support;


-- =========================================
-- ENUMS
-- =========================================

CREATE TYPE auth.tipo_usuario AS ENUM (
    'client',
    'provider',
    'admin'
);

CREATE TYPE financial.status_kyc AS ENUM (
    'pending',
    'approved',
    'rejected'
);

CREATE TYPE financial.status_transacao AS ENUM (
    'pending',
    'escrow',
    'released',
    'refunded',
    'failed'
);

CREATE TYPE marketplace.status_agendamento AS ENUM (
    'pending',
    'paid',
    'confirmed',
    'completed',
    'disputed',
    'canceled'
);

CREATE TYPE support.status_disputa AS ENUM (
    'open',
    'under_review',
    'accepted',
    'rejected',
    'closed'
);


-- =========================================
-- AUTH.USUARIO
-- =========================================

CREATE TABLE auth.usuario (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    nome VARCHAR(150) NOT NULL,

    -- AES-256
    email BYTEA NOT NULL,

    data_nascimento DATE NOT NULL,

    -- AES-256
    cpf BYTEA NOT NULL,

    -- HASH bcrypt
    senha_hash VARCHAR(255) NOT NULL,

    -- AES-256
    telefone BYTEA,

    -- AES-256
    documento_url BYTEA NOT NULL,

    tipo_usuario auth.tipo_usuario NOT NULL DEFAULT 'client',

    aceitou_termos BOOLEAN NOT NULL DEFAULT FALSE,

    data_aceite_termos TIMESTAMP,

    email_verificado BOOLEAN DEFAULT FALSE,

    ativo BOOLEAN DEFAULT TRUE,

    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    deletado_em TIMESTAMP
);


-- =========================================
-- AUTH.PERFIL
-- =========================================

CREATE TABLE auth.perfil (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    usuario_id UUID NOT NULL UNIQUE,

    foto_url TEXT,

    bio TEXT,

    discord_id VARCHAR(100),

    -- Desnormalizado para performance de leitura (RF10, RF11, RF16, RF57)
    -- Atualizado automaticamente pelo trigger trg_atualizar_media_avaliacao
    media_avaliacao NUMERIC(3,2) DEFAULT 0.00,

    total_avaliacoes INTEGER DEFAULT 0,

    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_media_avaliacao
        CHECK (media_avaliacao BETWEEN 0 AND 5),

    CONSTRAINT chk_total_avaliacoes
        CHECK (total_avaliacoes >= 0),

    CONSTRAINT fk_perfil_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES auth.usuario(id)
        ON DELETE CASCADE
);


-- =========================================
-- AUTH.OAUTH
-- =========================================

CREATE TABLE auth.oauth (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL,

    provider VARCHAR(50) NOT NULL,

    provider_user_id VARCHAR(255) NOT NULL,

    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_oauth_usuario
        FOREIGN KEY (user_id)
        REFERENCES auth.usuario(id)
        ON DELETE CASCADE
);


-- =========================================
-- CORE.CATEGORIA
-- =========================================

CREATE TABLE core.categoria (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    nome VARCHAR(100) UNIQUE NOT NULL
);


-- =========================================
-- CORE.TAG
-- =========================================

CREATE TABLE core.tag (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    nome VARCHAR(100) UNIQUE NOT NULL
);


-- =========================================
-- MARKETPLACE.SERVICO
-- =========================================

CREATE TABLE marketplace.servico (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    prestador_id UUID NOT NULL,

    categoria_id UUID NOT NULL,

    titulo VARCHAR(150) NOT NULL,

    descricao TEXT,

    preco NUMERIC(10,2) NOT NULL,

    duracao_minutos INTEGER NOT NULL,

    imagem_url TEXT,

    ativo BOOLEAN DEFAULT TRUE,

    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    deletado_em TIMESTAMP,

    CONSTRAINT chk_preco_positivo
        CHECK (preco > 0),

    CONSTRAINT chk_duracao_positiva
        CHECK (duracao_minutos > 0),

    CONSTRAINT fk_servico_prestador
        FOREIGN KEY (prestador_id)
        REFERENCES auth.usuario(id),

    CONSTRAINT fk_servico_categoria
        FOREIGN KEY (categoria_id)
        REFERENCES core.categoria(id)
);


-- =========================================
-- MARKETPLACE.SERVICO_TAG
-- =========================================

CREATE TABLE marketplace.servico_tag (
    servico_id UUID NOT NULL,

    tag_id UUID NOT NULL,

    PRIMARY KEY (servico_id, tag_id),

    CONSTRAINT fk_servico_tag_servico
        FOREIGN KEY (servico_id)
        REFERENCES marketplace.servico(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_servico_tag_tag
        FOREIGN KEY (tag_id)
        REFERENCES core.tag(id)
        ON DELETE CASCADE
);


-- =========================================
-- MARKETPLACE.DISPONIBILIDADE
-- =========================================

CREATE TABLE marketplace.disponibilidade (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    prestador_id UUID NOT NULL,

    dia_semana INTEGER NOT NULL,

    hora_inicio TIME NOT NULL,

    hora_fim TIME NOT NULL,

    CONSTRAINT chk_dia_semana
        CHECK (dia_semana BETWEEN 0 AND 6),

    CONSTRAINT chk_horario_valido
        CHECK (hora_fim > hora_inicio),

    CONSTRAINT uq_disponibilidade
        UNIQUE (prestador_id, dia_semana, hora_inicio),

    CONSTRAINT fk_disponibilidade_usuario
        FOREIGN KEY (prestador_id)
        REFERENCES auth.usuario(id)
);


-- =========================================
-- MARKETPLACE.AGENDAMENTO
-- =========================================

CREATE TABLE marketplace.agendamento (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    servico_id UUID NOT NULL,

    cliente_id UUID NOT NULL,

    prestador_id UUID NOT NULL,

    data_hora TIMESTAMP NOT NULL,

    status marketplace.status_agendamento
        DEFAULT 'pending',

    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT unique_horario
        UNIQUE (prestador_id, data_hora),

    CONSTRAINT fk_agendamento_servico
        FOREIGN KEY (servico_id)
        REFERENCES marketplace.servico(id),

    CONSTRAINT fk_agendamento_cliente
        FOREIGN KEY (cliente_id)
        REFERENCES auth.usuario(id),

    CONSTRAINT fk_agendamento_prestador
        FOREIGN KEY (prestador_id)
        REFERENCES auth.usuario(id)
);


-- =========================================
-- FINANCIAL.CARTEIRA
-- =========================================

CREATE TABLE financial.carteira (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    usuario_id UUID UNIQUE NOT NULL,

    saldo_disponivel NUMERIC(10,2) DEFAULT 0.00,

    saldo_pendente NUMERIC(10,2) DEFAULT 0.00,

    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_carteira_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES auth.usuario(id)
        ON DELETE CASCADE
);


-- =========================================
-- FINANCIAL.CONTA_RECEBIMENTO
-- =========================================

CREATE TABLE financial.conta_recebimento (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    usuario_id UUID NOT NULL,

    tipo VARCHAR(50) NOT NULL,

    -- AES-256
    chave_pix BYTEA,

    banco VARCHAR(100),

    -- AES-256
    agencia BYTEA,

    -- AES-256
    conta BYTEA,

    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_conta_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES auth.usuario(id)
        ON DELETE CASCADE
);


-- =========================================
-- FINANCIAL.KYC
-- =========================================

CREATE TABLE financial.kyc (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    usuario_id UUID UNIQUE NOT NULL,

    -- AES-256
    documento BYTEA NOT NULL,

    status financial.status_kyc
        DEFAULT 'pending',

    validated_at TIMESTAMP,

    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_kyc_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES auth.usuario(id)
        ON DELETE CASCADE
);


-- =========================================
-- FINANCIAL.TRANSACAO
-- =========================================

CREATE TABLE financial.transacao (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    agendamento_id UUID UNIQUE NOT NULL,

    valor NUMERIC(10,2) NOT NULL,

    taxa NUMERIC(10,2) NOT NULL,

    valor_liquido NUMERIC(10,2) NOT NULL,

    status financial.status_transacao
        DEFAULT 'pending',

    gateway_id VARCHAR(255),

    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_transacao_agendamento
        FOREIGN KEY (agendamento_id)
        REFERENCES marketplace.agendamento(id)
);


-- =========================================
-- FINANCIAL.REPASSE_MENSAL
-- =========================================
-- Registra cada ciclo de repasse automático
-- executado no dia 20 de cada mês (RF50)

CREATE TABLE financial.repasse_mensal (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    usuario_id UUID NOT NULL,

    valor NUMERIC(10,2) NOT NULL,

    status VARCHAR(50) NOT NULL DEFAULT 'pendente',

    referencia_mes DATE NOT NULL,

    processado_em TIMESTAMP,

    gateway_repasse_id VARCHAR(255),

    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_valor_repasse
        CHECK (valor > 0),

    CONSTRAINT chk_status_repasse
        CHECK (status IN ('pendente', 'processado', 'falhou')),

    CONSTRAINT fk_repasse_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES auth.usuario(id)
);


-- =========================================
-- ÍNDICE REPASSE
-- =========================================

CREATE INDEX idx_repasse_usuario
ON financial.repasse_mensal(usuario_id);

CREATE INDEX idx_repasse_referencia
ON financial.repasse_mensal(referencia_mes);


-- =========================================
-- FINANCIAL.ESCROW_MOVIMENTACAO
-- =========================================
-- Rastreia cada movimentação de escrow
-- garantindo rastreabilidade (RNF30, RNF31, RF47, RF48)

CREATE TABLE financial.escrow_movimentacao (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    agendamento_id UUID NOT NULL,

    tipo VARCHAR(50) NOT NULL,

    valor NUMERIC(10,2) NOT NULL,

    descricao TEXT,

    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_tipo_escrow
        CHECK (tipo IN ('entrada', 'liberacao', 'estorno')),

    CONSTRAINT chk_valor_escrow
        CHECK (valor > 0),

    CONSTRAINT fk_escrow_agendamento
        FOREIGN KEY (agendamento_id)
        REFERENCES marketplace.agendamento(id)
);


CREATE INDEX idx_escrow_agendamento
ON financial.escrow_movimentacao(agendamento_id);




CREATE TABLE social.postagem (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    usuario_id UUID NOT NULL,

    conteudo TEXT NOT NULL,

    imagem_url TEXT,

    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_postagem_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES auth.usuario(id)
        ON DELETE CASCADE
);


-- =========================================
-- SOCIAL.CURTIDA
-- =========================================

CREATE TABLE social.curtida (
    postagem_id UUID NOT NULL,

    usuario_id UUID NOT NULL,

    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (postagem_id, usuario_id),

    CONSTRAINT fk_curtida_postagem
        FOREIGN KEY (postagem_id)
        REFERENCES social.postagem(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_curtida_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES auth.usuario(id)
        ON DELETE CASCADE
);


-- =========================================
-- SOCIAL.AVALIACAO
-- =========================================

CREATE TABLE social.avaliacao (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    agendamento_id UUID UNIQUE NOT NULL,

    cliente_id UUID NOT NULL,

    prestador_id UUID NOT NULL,

    nota INTEGER NOT NULL,

    comentario TEXT,

    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_nota
        CHECK (nota BETWEEN 1 AND 5),

    CONSTRAINT fk_avaliacao_agendamento
        FOREIGN KEY (agendamento_id)
        REFERENCES marketplace.agendamento(id),

    CONSTRAINT fk_avaliacao_cliente
        FOREIGN KEY (cliente_id)
        REFERENCES auth.usuario(id),

    CONSTRAINT fk_avaliacao_prestador
        FOREIGN KEY (prestador_id)
        REFERENCES auth.usuario(id)
);


-- =========================================
-- SUPPORT.DISPUTA
-- =========================================

CREATE TABLE support.disputa (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    agendamento_id UUID NOT NULL,

    usuario_id UUID NOT NULL,

    status support.status_disputa
        DEFAULT 'open',

    descricao TEXT NOT NULL,

    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_disputa_agendamento
        FOREIGN KEY (agendamento_id)
        REFERENCES marketplace.agendamento(id),

    CONSTRAINT fk_disputa_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES auth.usuario(id)
);


-- =========================================
-- SUPPORT.PROVA_DISPUTA
-- =========================================

CREATE TABLE support.prova_disputa (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    disputa_id UUID NOT NULL,

    arquivo_url TEXT NOT NULL,

    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_prova_disputa
        FOREIGN KEY (disputa_id)
        REFERENCES support.disputa(id)
        ON DELETE CASCADE
);


-- =========================================
-- AUDIT.LOG
-- =========================================

CREATE TABLE audit.log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    usuario_id UUID,

    acao VARCHAR(255) NOT NULL,

    tabela VARCHAR(100) NOT NULL,

    ip_address VARCHAR(45),

    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_log_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES auth.usuario(id)
);


-- =========================================
-- ÍNDICES
-- =========================================

CREATE INDEX idx_agendamento_data
ON marketplace.agendamento(data_hora);

CREATE INDEX idx_servico_categoria
ON marketplace.servico(categoria_id);

CREATE INDEX idx_servico_prestador
ON marketplace.servico(prestador_id);

CREATE INDEX idx_transacao_status
ON financial.transacao(status);

CREATE INDEX idx_avaliacao_prestador
ON social.avaliacao(prestador_id);

CREATE INDEX idx_perfil_media_avaliacao
ON auth.perfil(media_avaliacao DESC);


-- =========================================
-- OBSERVAÇÕES DE SEGURANÇA
-- =========================================
--
-- SENHAS:
-- Utilizar:
--
-- crypt('senha', gen_salt('bf'))
--
-- DADOS SENSÍVEIS:
-- Utilizar:
--
-- pgp_sym_encrypt(valor, 'CHAVE_AES_256')
-- pgp_sym_decrypt(valor, 'CHAVE_AES_256')
--
-- Campos protegidos com AES:
--
-- auth.usuario:
--     email
--     cpf
--     telefone
--     documento_url
--
-- financial.conta_recebimento:
--     chave_pix
--     agencia
--     conta
--
-- financial.kyc:
--     documento
--
-- =========================================