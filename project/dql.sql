-- =========================================
-- DQL.SQL
-- Projeto: TwoPlayers
-- Banco: PostgreSQL
-- Segurança:
-- - AES-256 para dados sensíveis
-- - bcrypt para senhas
-- =========================================


-- =========================================
-- OBSERVAÇÃO
-- =========================================
--
-- Dados criptografados com:
--
-- pgp_sym_encrypt()
--
-- Devem ser lidos com:
--
-- pgp_sym_decrypt()
--
-- Chave utilizada:
--
-- 'MINHA_CHAVE_AES_256'
--
-- Em produção:
-- utilizar variável .env
--
-- =========================================



-- =========================================
-- LISTAR TODOS OS USUÁRIOS
-- =========================================

SELECT
    u.id,

    u.nome,

    pgp_sym_decrypt(
        u.email,
        'MINHA_CHAVE_AES_256'
    ) AS email,

    u.data_nascimento,

    pgp_sym_decrypt(
        u.cpf,
        'MINHA_CHAVE_AES_256'
    ) AS cpf,

    pgp_sym_decrypt(
        u.telefone,
        'MINHA_CHAVE_AES_256'
    ) AS telefone,

    pgp_sym_decrypt(
        u.documento_url,
        'MINHA_CHAVE_AES_256'
    ) AS documento_url,

    u.tipo_usuario,

    u.ativo,

    u.criado_em

FROM auth.usuario u

ORDER BY u.nome;


-- =========================================
-- LOGIN DE USUÁRIO
-- =========================================

SELECT
    id,
    nome,
    tipo_usuario

FROM auth.usuario

WHERE
    pgp_sym_decrypt(
        email,
        'MINHA_CHAVE_AES_256'
    ) = 'millenyevan.estudos@gmail.com'

AND senha_hash = crypt(
    'MyMy123@',
    senha_hash
);


-- =========================================
-- BUSCAR USUÁRIO POR CPF
-- =========================================

SELECT
    id,
    nome,

    pgp_sym_decrypt(
        cpf,
        'MINHA_CHAVE_AES_256'
    ) AS cpf

FROM auth.usuario

WHERE
    pgp_sym_decrypt(
        cpf,
        'MINHA_CHAVE_AES_256'
    ) = '12345678912';


-- =========================================
-- LISTAR PERFIS
-- =========================================

SELECT
    p.id,

    u.nome,

    pgp_sym_decrypt(
        u.email,
        'MINHA_CHAVE_AES_256'
    ) AS email,

    p.bio,

    p.discord_id,

    p.foto_url

FROM auth.perfil p

INNER JOIN auth.usuario u
ON u.id = p.usuario_id;


-- =========================================
-- LISTAR CATEGORIAS
-- =========================================

SELECT
    id,
    nome
FROM core.categoria
ORDER BY nome;


-- =========================================
-- LISTAR TAGS
-- =========================================

SELECT
    id,
    nome
FROM core.tag
ORDER BY nome;


-- =========================================
-- LISTAR SERVIÇOS
-- =========================================

SELECT
    s.id,

    s.titulo,

    s.descricao,

    s.preco,

    s.duracao_minutos,

    c.nome AS categoria,

    u.nome AS prestador

FROM marketplace.servico s

INNER JOIN core.categoria c
ON c.id = s.categoria_id

INNER JOIN auth.usuario u
ON u.id = s.prestador_id

WHERE s.ativo = TRUE

ORDER BY s.preco;


-- =========================================
-- LISTAR SERVIÇOS COM TAGS
-- =========================================

SELECT
    s.titulo,

    t.nome AS tag

FROM marketplace.servico s

INNER JOIN marketplace.servico_tag st
ON st.servico_id = s.id

INNER JOIN core.tag t
ON t.id = st.tag_id

ORDER BY s.titulo;


-- =========================================
-- LISTAR DISPONIBILIDADE DOS PRESTADORES
-- =========================================

SELECT
    d.id,

    u.nome AS prestador,

    d.dia_semana,

    d.hora_inicio,

    d.hora_fim

FROM marketplace.disponibilidade d

INNER JOIN auth.usuario u
ON u.id = d.prestador_id

ORDER BY d.dia_semana;


-- =========================================
-- LISTAR AGENDAMENTOS
-- =========================================

SELECT
    a.id,

    s.titulo AS servico,

    uc.nome AS cliente,

    up.nome AS prestador,

    a.data_hora,

    a.status

FROM marketplace.agendamento a

INNER JOIN marketplace.servico s
ON s.id = a.servico_id

INNER JOIN auth.usuario uc
ON uc.id = a.cliente_id

INNER JOIN auth.usuario up
ON up.id = a.prestador_id

ORDER BY a.data_hora;


-- =========================================
-- LISTAR TRANSAÇÕES
-- =========================================

SELECT
    t.id,

    s.titulo,

    t.valor,

    t.taxa,

    t.valor_liquido,

    t.status,

    t.gateway_id,

    t.criado_em

FROM financial.transacao t

INNER JOIN marketplace.agendamento a
ON a.id = t.agendamento_id

INNER JOIN marketplace.servico s
ON s.id = a.servico_id

ORDER BY t.criado_em DESC;


-- =========================================
-- LISTAR CARTEIRAS
-- =========================================

SELECT
    c.id,

    u.nome,

    c.saldo_disponivel,

    c.saldo_pendente

FROM financial.carteira c

INNER JOIN auth.usuario u
ON u.id = c.usuario_id;


-- =========================================
-- LISTAR CONTAS DE RECEBIMENTO
-- =========================================

SELECT
    cr.id,

    u.nome,

    cr.tipo,

    pgp_sym_decrypt(
        cr.chave_pix,
        'MINHA_CHAVE_AES_256'
    ) AS chave_pix,

    cr.banco,

    CASE WHEN cr.agencia IS NOT NULL
        THEN pgp_sym_decrypt(cr.agencia, 'MINHA_CHAVE_AES_256')
        ELSE NULL END AS agencia,

    CASE WHEN cr.conta IS NOT NULL
        THEN pgp_sym_decrypt(cr.conta, 'MINHA_CHAVE_AES_256')
        ELSE NULL END AS conta

FROM financial.conta_recebimento cr

INNER JOIN auth.usuario u
ON u.id = cr.usuario_id;


-- =========================================
-- LISTAR KYC
-- =========================================

SELECT
    k.id,

    u.nome,

    pgp_sym_decrypt(
        k.documento,
        'MINHA_CHAVE_AES_256'
    ) AS documento,

    k.status,

    k.validated_at

FROM financial.kyc k

INNER JOIN auth.usuario u
ON u.id = k.usuario_id;


-- =========================================
-- LISTAR POSTAGENS
-- =========================================

SELECT
    p.id,

    u.nome AS autor,

    p.conteudo,

    p.imagem_url,

    p.criado_em

FROM social.postagem p

INNER JOIN auth.usuario u
ON u.id = p.usuario_id

ORDER BY p.criado_em DESC;


-- =========================================
-- CONTAR CURTIDAS POR POSTAGEM
-- =========================================

SELECT
    p.id,

    p.conteudo,

    COUNT(c.usuario_id) AS total_curtidas

FROM social.postagem p

LEFT JOIN social.curtida c
ON c.postagem_id = p.id

GROUP BY p.id

ORDER BY total_curtidas DESC;


-- =========================================
-- LISTAR AVALIAÇÕES
-- =========================================

SELECT
    a.id,

    uc.nome AS cliente,

    up.nome AS prestador,

    a.nota,

    a.comentario,

    a.criado_em

FROM social.avaliacao a

INNER JOIN auth.usuario uc
ON uc.id = a.cliente_id

INNER JOIN auth.usuario up
ON up.id = a.prestador_id

ORDER BY a.criado_em DESC;


-- =========================================
-- MÉDIA DE AVALIAÇÕES DOS PRESTADORES
-- =========================================

SELECT
    up.nome AS prestador,

    ROUND(AVG(a.nota), 2) AS media_avaliacao,

    COUNT(a.id) AS total_avaliacoes

FROM social.avaliacao a

INNER JOIN auth.usuario up
ON up.id = a.prestador_id

GROUP BY up.nome

ORDER BY media_avaliacao DESC;


-- =========================================
-- LISTAR DISPUTAS
-- =========================================

SELECT
    d.id,

    u.nome,

    d.status,

    d.descricao,

    d.criado_em

FROM support.disputa d

INNER JOIN auth.usuario u
ON u.id = d.usuario_id

ORDER BY d.criado_em DESC;


-- =========================================
-- LISTAR PROVAS DE DISPUTA
-- =========================================

SELECT
    pd.id,

    d.id AS disputa_id,

    pd.arquivo_url,

    pd.criado_em

FROM support.prova_disputa pd

INNER JOIN support.disputa d
ON d.id = pd.disputa_id;


-- =========================================
-- LOGS DE AUDITORIA
-- =========================================

SELECT
    l.id,

    u.nome,

    l.acao,

    l.tabela,

    l.ip_address,

    l.criado_em

FROM audit.log l

LEFT JOIN auth.usuario u
ON u.id = l.usuario_id

ORDER BY l.criado_em DESC;


-- =========================================
-- TOTAL DE USUÁRIOS POR TIPO
-- =========================================

SELECT
    tipo_usuario,
    COUNT(*) AS total
FROM auth.usuario
GROUP BY tipo_usuario;


-- =========================================
-- TOTAL DE SERVIÇOS POR CATEGORIA
-- =========================================

SELECT
    c.nome AS categoria,
    COUNT(s.id) AS total_servicos

FROM core.categoria c

LEFT JOIN marketplace.servico s
ON s.categoria_id = c.id

GROUP BY c.nome

ORDER BY total_servicos DESC;


-- =========================================
-- FATURAMENTO TOTAL
-- =========================================

SELECT
    SUM(valor) AS faturamento_bruto,
    SUM(taxa) AS total_taxas,
    SUM(valor_liquido) AS faturamento_liquido
FROM financial.transacao
WHERE status = 'released';


-- =========================================
-- SERVIÇOS MAIS CAROS
-- =========================================

SELECT
    titulo,
    preco
FROM marketplace.servico
ORDER BY preco DESC
LIMIT 5;


-- =========================================
-- AGENDAMENTOS FUTUROS
-- =========================================

SELECT
    id,
    data_hora,
    status
FROM marketplace.agendamento
WHERE data_hora > CURRENT_TIMESTAMP
ORDER BY data_hora;


-- =========================================
-- FIM
-- =========================================
-- =========================================
-- PRESTADORES MAIS BEM AVALIADOS
-- =========================================
-- Usa a média desnormalizada em auth.perfil
-- para leitura rápida no feed e Top 10 (RF10, RF11, RF16)

SELECT
    up.nome,

    p.media_avaliacao,

    p.total_avaliacoes,

    p.foto_url,

    p.bio

FROM auth.perfil p

INNER JOIN auth.usuario up
ON up.id = p.usuario_id

WHERE p.media_avaliacao >= 4

ORDER BY p.media_avaliacao DESC, p.total_avaliacoes DESC;


-- =========================================
-- TOP 10 PRESTADORES (HOME FEED)
-- =========================================
-- Alimenta a seção Top 10 da tela Home (RF10)

SELECT
    up.nome,

    p.foto_url,

    p.media_avaliacao,

    p.total_avaliacoes,

    MIN(s.preco) AS preco_base,

    c.nome AS categoria_principal

FROM auth.perfil p

INNER JOIN auth.usuario up
ON up.id = p.usuario_id

INNER JOIN marketplace.servico s
ON s.prestador_id = up.id AND s.ativo = TRUE

INNER JOIN core.categoria c
ON c.id = s.categoria_id

GROUP BY
    up.nome,
    p.foto_url,
    p.media_avaliacao,
    p.total_avaliacoes,
    c.nome

ORDER BY p.media_avaliacao DESC, p.total_avaliacoes DESC

LIMIT 10;


-- =========================================
-- AVALIAÇÕES DE UM PRESTADOR (PERFIL PÚBLICO)
-- =========================================
-- Exibe avaliações e comentários no perfil (RF20, RF38, RF39, RF40)

SELECT
    a.nota,

    a.comentario,

    uc.nome AS cliente,

    a.criado_em

FROM social.avaliacao a

INNER JOIN auth.usuario uc
ON uc.id = a.cliente_id

WHERE a.prestador_id = '00822e07-bcfa-407f-a797-6915ed8f091c'

ORDER BY a.criado_em DESC;


-- =========================================
-- VERIFICAR SE AVALIAÇÃO JÁ EXISTE
-- =========================================
-- Impede avaliação duplicada por agendamento (UNIQUE em social.avaliacao)

SELECT
    id,
    nota,
    comentario

FROM social.avaliacao

WHERE agendamento_id = 'a803b177-5b95-4eaa-9c76-8b0c270b8dfa';


-- =========================================
-- HISTÓRICO DE ESCROW POR AGENDAMENTO
-- =========================================
-- Rastreabilidade completa (RNF30, RNF31, RF47, RF48)

SELECT
    em.tipo,

    em.valor,

    em.descricao,

    em.criado_em,

    a.status AS status_agendamento

FROM financial.escrow_movimentacao em

INNER JOIN marketplace.agendamento a
ON a.id = em.agendamento_id

WHERE em.agendamento_id = 'a803b177-5b95-4eaa-9c76-8b0c270b8dfa'

ORDER BY em.criado_em;


-- =========================================
-- SALDO DISPONÍVEL + PENDENTE DA CARTEIRA
-- =========================================
-- Tela Minha Carteira (RF44, RF46, RF47)

SELECT
    c.saldo_disponivel,

    c.saldo_pendente,

    c.saldo_disponivel + c.saldo_pendente AS saldo_total

FROM financial.carteira c

WHERE c.usuario_id = '00822e07-bcfa-407f-a797-6915ed8f091c';


-- =========================================
-- HISTÓRICO FINANCEIRO DO PRESTADOR
-- =========================================
-- Tela Minha Carteira — histórico detalhado (RF48)

SELECT
    t.criado_em,

    s.titulo AS servico,

    uc.nome AS cliente,

    t.valor AS valor_bruto,

    t.taxa,

    t.valor_liquido,

    t.status,

    a.status AS status_agendamento

FROM financial.transacao t

INNER JOIN marketplace.agendamento a
ON a.id = t.agendamento_id

INNER JOIN marketplace.servico s
ON s.id = a.servico_id

INNER JOIN auth.usuario uc
ON uc.id = a.cliente_id

WHERE a.prestador_id = '00822e07-bcfa-407f-a797-6915ed8f091c'

ORDER BY t.criado_em DESC;


-- =========================================
-- RELATÓRIO FINANCEIRO POR PERÍODO
-- =========================================
-- Dashboard do prestador com filtro de data (RF57, RF58, RF59, RF62)

SELECT
    DATE_TRUNC('month', t.criado_em) AS mes,

    COUNT(t.id) AS total_servicos,

    SUM(t.valor) AS faturamento_bruto,

    SUM(t.taxa) AS total_taxas,

    SUM(t.valor_liquido) AS faturamento_liquido,

    ROUND(AVG(av.nota), 2) AS media_avaliacao_periodo

FROM financial.transacao t

INNER JOIN marketplace.agendamento a
ON a.id = t.agendamento_id

LEFT JOIN social.avaliacao av
ON av.agendamento_id = a.id

WHERE
    a.prestador_id = '00822e07-bcfa-407f-a797-6915ed8f091c'
    AND t.status = 'released'
    AND t.criado_em BETWEEN '2026-01-01' AND '2026-12-31'

GROUP BY DATE_TRUNC('month', t.criado_em)

ORDER BY mes;


-- =========================================
-- REPASSES MENSAIS DO PRESTADOR
-- =========================================
-- Histórico de repasses no dia 20 (RF50, RF52)

SELECT
    rm.referencia_mes,

    rm.valor,

    rm.status,

    rm.processado_em,

    rm.gateway_repasse_id

FROM financial.repasse_mensal rm

WHERE rm.usuario_id = '00822e07-bcfa-407f-a797-6915ed8f091c'

ORDER BY rm.referencia_mes DESC;


-- =========================================
-- VERIFICAR KYC ANTES DO REPASSE
-- =========================================
-- Bloqueia recebimento se KYC não validado (RF53)

SELECT
    u.id,

    u.nome,

    k.status AS kyc_status,

    c.saldo_disponivel

FROM auth.usuario u

INNER JOIN financial.kyc k
ON k.usuario_id = u.id

INNER JOIN financial.carteira c
ON c.usuario_id = u.id

WHERE
    u.tipo_usuario = 'provider'
    AND k.status = 'approved'
    AND c.saldo_disponivel > 0;


-- =========================================
-- FIM
-- =========================================
