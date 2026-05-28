-- =========================================
-- DML.SQL
-- Projeto: TwoPlayers 
-- Segurança:
-- - AES-256 para dados sensíveis
-- - bcrypt para senhas
-- =========================================


-- =========================================
-- CHAVE AES-256
-- =========================================
-- Em produção:
-- usar variável .env
--
-- Exemplo:
-- AES_KEY=MinhaChaveAES256SuperSegura
--
-- Neste DML:
-- chave usada apenas para testes
-- =========================================


-- =========================================
-- USUÁRIOS
-- =========================================

INSERT INTO auth.usuario (
    id,
    nome,
    email,
    data_nascimento,
    cpf,
    senha_hash,
    telefone,
    documento_url,
    tipo_usuario,
    aceitou_termos,
    data_aceite_termos,
    email_verificado,
    ativo
)
VALUES

(
    gen_random_uuid(),

    'Milleny Evan',

    pgp_sym_encrypt(
        'millenyevan.estudos@gmail.com',
        'MINHA_CHAVE_AES_256'
    ),

    '2005-03-01',

    pgp_sym_encrypt(
        '12345678912',
        'MINHA_CHAVE_AES_256'
    ),

    crypt(
        'MyMy123@',
        gen_salt('bf')
    ),

    pgp_sym_encrypt(
        '37998298954',
        'MINHA_CHAVE_AES_256'
    ),

    pgp_sym_encrypt(
        'https://site.com/documento_milleny.png',
        'MINHA_CHAVE_AES_256'
    ),

    'admin',

    TRUE,

    CURRENT_TIMESTAMP,

    TRUE,

    TRUE
),

(
    '56662c94-fe48-4288-adea-1ba8e09ed811',

    'Carlos Silva',

    pgp_sym_encrypt(
        'carlos@email.com',
        'MINHA_CHAVE_AES_256'
    ),

    '1998-05-20',

    pgp_sym_encrypt(
        '11111111111',
        'MINHA_CHAVE_AES_256'
    ),

    crypt(
        'Carlos123@',
        gen_salt('bf')
    ),

    pgp_sym_encrypt(
        '31999991111',
        'MINHA_CHAVE_AES_256'
    ),

    pgp_sym_encrypt(
        'https://site.com/doc1.png',
        'MINHA_CHAVE_AES_256'
    ),

    'client',

    TRUE,

    CURRENT_TIMESTAMP,

    FALSE,

    TRUE
),

(
    '00822e07-bcfa-407f-a797-6915ed8f091c',

    'Ana Costa',

    pgp_sym_encrypt(
        'ana@email.com',
        'MINHA_CHAVE_AES_256'
    ),

    '1995-03-10',

    pgp_sym_encrypt(
        '22222222222',
        'MINHA_CHAVE_AES_256'
    ),

    crypt(
        'Ana123@',
        gen_salt('bf')
    ),

    pgp_sym_encrypt(
        '31999992222',
        'MINHA_CHAVE_AES_256'
    ),

    pgp_sym_encrypt(
        'https://site.com/doc2.png',
        'MINHA_CHAVE_AES_256'
    ),

    'provider',

    TRUE,

    CURRENT_TIMESTAMP,

    FALSE,

    TRUE
),

(
    '3e1021bb-9218-42e3-9028-80d524660428',

    'Lucas Mendes',

    pgp_sym_encrypt(
        'lucas@email.com',
        'MINHA_CHAVE_AES_256'
    ),

    '1997-09-15',

    pgp_sym_encrypt(
        '33333333333',
        'MINHA_CHAVE_AES_256'
    ),

    crypt(
        'Lucas123@',
        gen_salt('bf')
    ),

    pgp_sym_encrypt(
        '31999993333',
        'MINHA_CHAVE_AES_256'
    ),

    pgp_sym_encrypt(
        'https://site.com/doc3.png',
        'MINHA_CHAVE_AES_256'
    ),

    'provider',

    TRUE,

    CURRENT_TIMESTAMP,

    FALSE,

    TRUE
);


-- =========================================
-- PERFIS
-- =========================================

INSERT INTO auth.perfil (
    usuario_id,
    foto_url,
    bio,
    discord_id,
    media_avaliacao,
    total_avaliacoes
)
VALUES

(
    '00822e07-bcfa-407f-a797-6915ed8f091c',
    'https://site.com/foto1.png',
    'Especialista em coaching gamer',
    'ana#1234',
    0.00,
    0
),

(
    '3e1021bb-9218-42e3-9028-80d524660428',
    'https://site.com/foto2.png',
    'Desenvolvedor Full Stack',
    'lucas#9999',
    0.00,
    0
);


-- =========================================
-- CATEGORIAS
-- =========================================

INSERT INTO core.categoria (
    id,
    nome
)
VALUES

(
    '0e8114a5-98a9-4466-acf6-2def203de1f4',
    'Jogos'
),

(
    '8c1f9ca3-84d4-4c72-9f17-2ad2aeb2e496',
    'Tecnologia'
),

(
    '9cfe0e24-dd20-4f80-9bca-8bcc7f8677ee',
    'Design'
),

(
    'f190e274-e4aa-4d5d-a7f6-95a031daee84',
    'Programação'
),

(
    'f9aa033c-f51a-4c4e-975a-5173e5b92e84',
    'Consultoria'
);


-- =========================================
-- TAGS
-- =========================================

INSERT INTO core.tag (
    id,
    nome
)
VALUES

(
    'bbf023db-780d-47d5-a9f2-2ce9ce61b1fb',
    'Valorant'
),

(
    '14136135-9cff-4640-a880-b720ee7bb3ec',
    'League of Legends'
),

(
    '41a34a36-3470-4684-b253-c3847386fd6f',
    'UI Design'
),

(
    'a627d27f-77bc-4dce-933e-95f963458155',
    'React'
),

(
    'fe01aed1-c86f-4ba1-b557-8ddaedc92a4e',
    'Python'
);


-- =========================================
-- SERVIÇOS
-- =========================================

INSERT INTO marketplace.servico (
    id,
    prestador_id,
    categoria_id,
    titulo,
    descricao,
    preco,
    duracao_minutos
)
VALUES

(
    'cfc6bcbb-e9a0-4a56-a9ca-168f2e0011c1',
    '00822e07-bcfa-407f-a797-6915ed8f091c',
    '0e8114a5-98a9-4466-acf6-2def203de1f4',
    'Mentoria Valorant',
    'Mentoria para melhorar gameplay',
    80.00,
    60
),

(
    'efdb7cb0-acf7-414b-a343-a55d54b3f9f3',
    '3e1021bb-9218-42e3-9028-80d524660428',
    'f190e274-e4aa-4d5d-a7f6-95a031daee84',
    'Aula de React',
    'Desenvolvimento Frontend moderno',
    120.00,
    90
);


-- =========================================
-- SERVIÇO TAG
-- =========================================

INSERT INTO marketplace.servico_tag (
    servico_id,
    tag_id
)
VALUES

(
    'cfc6bcbb-e9a0-4a56-a9ca-168f2e0011c1',
    'bbf023db-780d-47d5-a9f2-2ce9ce61b1fb'
),

(
    'efdb7cb0-acf7-414b-a343-a55d54b3f9f3',
    'a627d27f-77bc-4dce-933e-95f963458155'
);


-- =========================================
-- DISPONIBILIDADE
-- =========================================

INSERT INTO marketplace.disponibilidade (
    prestador_id,
    dia_semana,
    hora_inicio,
    hora_fim
)
VALUES

(
    '00822e07-bcfa-407f-a797-6915ed8f091c',
    1,
    '18:00',
    '22:00'
),

(
    '3e1021bb-9218-42e3-9028-80d524660428',
    3,
    '14:00',
    '20:00'
);


-- =========================================
-- AGENDAMENTO
-- =========================================

INSERT INTO marketplace.agendamento (
    id,
    servico_id,
    cliente_id,
    prestador_id,
    data_hora,
    status
)
VALUES

(
    'a803b177-5b95-4eaa-9c76-8b0c270b8dfa',
    'cfc6bcbb-e9a0-4a56-a9ca-168f2e0011c1',
    '56662c94-fe48-4288-adea-1ba8e09ed811',
    '00822e07-bcfa-407f-a797-6915ed8f091c',
    '2026-06-10 19:00:00',
    'completed'
);


-- =========================================
-- TRANSAÇÕES
-- =========================================

INSERT INTO financial.transacao (
    agendamento_id,
    valor,
    taxa,
    valor_liquido,
    status,
    gateway_id
)
VALUES

(
    'a803b177-5b95-4eaa-9c76-8b0c270b8dfa',
    80.00,
    8.00,
    72.00,
    'released',
    'PAY_123456'
);


-- =========================================
-- CARTEIRAS
-- =========================================
-- NOTA: Carteiras criadas automaticamente pelo trigger trg_criar_carteira.
-- Não é necessário inserir manualmente.


-- =========================================
-- CONTAS DE RECEBIMENTO
-- =========================================

INSERT INTO financial.conta_recebimento (
    usuario_id,
    tipo,
    chave_pix
)
VALUES

(
    '00822e07-bcfa-407f-a797-6915ed8f091c',

    'pix',

    pgp_sym_encrypt(
        'ana@pix.com',
        'MINHA_CHAVE_AES_256'
    )
),

(
    '3e1021bb-9218-42e3-9028-80d524660428',

    'pix',

    pgp_sym_encrypt(
        'lucas@pix.com',
        'MINHA_CHAVE_AES_256'
    )
);


-- =========================================
-- KYC
-- =========================================

INSERT INTO financial.kyc (
    usuario_id,
    documento,
    status
)
VALUES

(
    '00822e07-bcfa-407f-a797-6915ed8f091c',

    pgp_sym_encrypt(
        'CPF_VALIDADO',
        'MINHA_CHAVE_AES_256'
    ),

    'approved'
),

(
    '3e1021bb-9218-42e3-9028-80d524660428',

    pgp_sym_encrypt(
        'CPF_VALIDADO',
        'MINHA_CHAVE_AES_256'
    ),

    'approved'
);


-- =========================================
-- POSTAGENS
-- =========================================

INSERT INTO social.postagem (
    id,
    usuario_id,
    conteudo,
    imagem_url
)
VALUES

(
    'e3817d8b-6f01-45dd-b5bd-1629e7379122',
    '00822e07-bcfa-407f-a797-6915ed8f091c',
    'Nova mentoria disponível essa semana!',
    'https://site.com/postagem1.png'
);


-- =========================================
-- CURTIDAS
-- =========================================

INSERT INTO social.curtida (
    postagem_id,
    usuario_id
)
VALUES

(
    'e3817d8b-6f01-45dd-b5bd-1629e7379122',
    '56662c94-fe48-4288-adea-1ba8e09ed811'
);


-- =========================================
-- AVALIAÇÕES
-- =========================================

INSERT INTO social.avaliacao (
    agendamento_id,
    cliente_id,
    prestador_id,
    nota,
    comentario
)
VALUES

(
    'a803b177-5b95-4eaa-9c76-8b0c270b8dfa',
    '56662c94-fe48-4288-adea-1ba8e09ed811',
    '00822e07-bcfa-407f-a797-6915ed8f091c',
    5,
    'Excelente atendimento!'
);


-- =========================================
-- DISPUTAS
-- =========================================

INSERT INTO support.disputa (
    id,
    agendamento_id,
    usuario_id,
    status,
    descricao
)
VALUES

(
    '7dc0c90b-be92-4f94-b078-cfe2c1d88a3e',
    'a803b177-5b95-4eaa-9c76-8b0c270b8dfa',
    '56662c94-fe48-4288-adea-1ba8e09ed811',
    'open',
    'Teste de disputa.'
);


-- =========================================
-- PROVAS DE DISPUTA
-- =========================================

INSERT INTO support.prova_disputa (
    disputa_id,
    arquivo_url
)
VALUES

(
    '7dc0c90b-be92-4f94-b078-cfe2c1d88a3e',
    'https://site.com/prova.png'
);


-- =========================================
-- ESCROW MOVIMENTAÇÕES
-- =========================================
-- Exemplifica rastreabilidade das movimentações
-- de escrow (RF30, RF47, RF48, RNF30, RNF31)

INSERT INTO financial.escrow_movimentacao (
    agendamento_id,
    tipo,
    valor,
    descricao
)
VALUES

(
    'a803b177-5b95-4eaa-9c76-8b0c270b8dfa',
    'entrada',
    80.00,
    'Pagamento retido em escrow após confirmação'
),

(
    'a803b177-5b95-4eaa-9c76-8b0c270b8dfa',
    'liberacao',
    72.00,
    'Liberação do valor líquido após confirmação do serviço'
);


-- =========================================
-- REPASSE MENSAL
-- =========================================
-- Exemplo de registro de ciclo de repasse (RF50)

INSERT INTO financial.repasse_mensal (
    usuario_id,
    valor,
    status,
    referencia_mes,
    processado_em,
    gateway_repasse_id
)
VALUES

(
    '00822e07-bcfa-407f-a797-6915ed8f091c',
    72.00,
    'processado',
    '2026-06-01',
    '2026-06-20 00:01:00',
    'REP_ANA_202606'
);




INSERT INTO audit.log (
    usuario_id,
    acao,
    tabela,
    ip_address
)
VALUES

(
    '00822e07-bcfa-407f-a797-6915ed8f091c',
    'LOGIN',
    'usuario',
    '127.0.0.1'
);


-- =========================================
-- FIM
-- =========================================