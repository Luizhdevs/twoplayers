-- =========================================
-- PROCEDURES.SQL
-- Projeto: TwoPlayers
-- Banco: PostgreSQL
-- Segurança:
-- - AES-256 com pgcrypto
-- - bcrypt para senhas
-- =========================================



-- =========================================
-- EXTENSÃO NECESSÁRIA
-- =========================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;



-- =========================================
-- PROCEDURE:
-- CRIAR USUÁRIO
-- =========================================

CREATE OR REPLACE PROCEDURE auth.sp_criar_usuario(
    p_nome              VARCHAR(150),
    p_email             TEXT,
    p_data_nascimento   DATE,
    p_cpf               TEXT,
    p_senha             TEXT,
    p_telefone          TEXT,
    p_documento_url     TEXT,
    p_tipo_usuario      auth.tipo_usuario
)
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO auth.usuario (
        nome,
        email,
        data_nascimento,
        cpf,
        senha_hash,
        telefone,
        documento_url,
        tipo_usuario,
        aceitou_termos,
        data_aceite_termos
    )
    VALUES (
        p_nome,

        pgp_sym_encrypt(
            p_email,
            'MINHA_CHAVE_AES_256'
        ),

        p_data_nascimento,

        pgp_sym_encrypt(
            p_cpf,
            'MINHA_CHAVE_AES_256'
        ),

        crypt(
            p_senha,
            gen_salt('bf')
        ),

        pgp_sym_encrypt(
            p_telefone,
            'MINHA_CHAVE_AES_256'
        ),

        pgp_sym_encrypt(
            p_documento_url,
            'MINHA_CHAVE_AES_256'
        ),

        p_tipo_usuario,

        TRUE,
        CURRENT_TIMESTAMP
    );

END;
$$;



-- =========================================
-- PROCEDURE:
-- LOGIN DE USUÁRIO
-- =========================================

CREATE OR REPLACE FUNCTION auth.fn_login_usuario(
    p_email TEXT,
    p_senha TEXT
)
RETURNS TABLE (
    id UUID,
    nome VARCHAR,
    tipo_usuario auth.tipo_usuario
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY

    SELECT
        u.id,
        u.nome,
        u.tipo_usuario

    FROM auth.usuario u

    WHERE

        pgp_sym_decrypt(
            u.email,
            'MINHA_CHAVE_AES_256'
        ) = p_email

    AND

        u.senha_hash = crypt(
            p_senha,
            u.senha_hash
        )

    AND u.ativo = TRUE;

END;
$$;



-- =========================================
-- PROCEDURE:
-- ATUALIZAR TELEFONE
-- =========================================

CREATE OR REPLACE PROCEDURE auth.sp_atualizar_telefone(
    p_usuario_id UUID,
    p_telefone TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN

    UPDATE auth.usuario
    SET
        telefone = pgp_sym_encrypt(
            p_telefone,
            'MINHA_CHAVE_AES_256'
        ),

        atualizado_em = CURRENT_TIMESTAMP

    WHERE id = p_usuario_id;

END;
$$;



-- =========================================
-- PROCEDURE:
-- ALTERAR SENHA
-- =========================================

CREATE OR REPLACE PROCEDURE auth.sp_alterar_senha(
    p_usuario_id UUID,
    p_nova_senha TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN

    UPDATE auth.usuario
    SET
        senha_hash = crypt(
            p_nova_senha,
            gen_salt('bf')
        ),

        atualizado_em = CURRENT_TIMESTAMP

    WHERE id = p_usuario_id;

END;
$$;



-- =========================================
-- PROCEDURE:
-- DESATIVAR USUÁRIO
-- =========================================

CREATE OR REPLACE PROCEDURE auth.sp_desativar_usuario(
    p_usuario_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN

    UPDATE auth.usuario
    SET
        ativo = FALSE,
        deletado_em = CURRENT_TIMESTAMP
    WHERE id = p_usuario_id;

END;
$$;



-- =========================================
-- PROCEDURE:
-- CRIAR SERVIÇO
-- =========================================

CREATE OR REPLACE PROCEDURE marketplace.sp_criar_servico(
    p_prestador_id UUID,
    p_categoria_id UUID,
    p_titulo VARCHAR(150),
    p_descricao TEXT,
    p_preco NUMERIC(10,2),
    p_duracao_minutos INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO marketplace.servico (
        prestador_id,
        categoria_id,
        titulo,
        descricao,
        preco,
        duracao_minutos
    )
    VALUES (
        p_prestador_id,
        p_categoria_id,
        p_titulo,
        p_descricao,
        p_preco,
        p_duracao_minutos
    );

END;
$$;



-- =========================================
-- PROCEDURE:
-- CRIAR AGENDAMENTO
-- =========================================

CREATE OR REPLACE PROCEDURE marketplace.sp_criar_agendamento(
    p_servico_id UUID,
    p_cliente_id UUID,
    p_prestador_id UUID,
    p_data_hora TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO marketplace.agendamento (
        servico_id,
        cliente_id,
        prestador_id,
        data_hora
    )
    VALUES (
        p_servico_id,
        p_cliente_id,
        p_prestador_id,
        p_data_hora
    );

END;
$$;



-- =========================================
-- PROCEDURE:
-- CANCELAR AGENDAMENTO
-- =========================================

CREATE OR REPLACE PROCEDURE marketplace.sp_cancelar_agendamento(
    p_agendamento_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN

    UPDATE marketplace.agendamento
    SET
        status = 'canceled',
        atualizado_em = CURRENT_TIMESTAMP
    WHERE id = p_agendamento_id;

END;
$$;



-- =========================================
-- PROCEDURE:
-- REGISTRAR TRANSAÇÃO
-- =========================================

CREATE OR REPLACE PROCEDURE financial.sp_registrar_transacao(
    p_agendamento_id UUID,
    p_valor NUMERIC(10,2),
    p_taxa NUMERIC(10,2),
    p_gateway_id VARCHAR(255)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_valor_liquido NUMERIC(10,2);
BEGIN

    v_valor_liquido := p_valor - p_taxa;

    INSERT INTO financial.transacao (
        agendamento_id,
        valor,
        taxa,
        valor_liquido,
        gateway_id
    )
    VALUES (
        p_agendamento_id,
        p_valor,
        p_taxa,
        v_valor_liquido,
        p_gateway_id
    );

END;
$$;



-- =========================================
-- PROCEDURE:
-- ADICIONAR SALDO
-- =========================================

CREATE OR REPLACE PROCEDURE financial.sp_adicionar_saldo(
    p_usuario_id UUID,
    p_valor NUMERIC(10,2)
)
LANGUAGE plpgsql
AS $$
BEGIN

    UPDATE financial.carteira
    SET
        saldo_disponivel = saldo_disponivel + p_valor,
        atualizado_em = CURRENT_TIMESTAMP
    WHERE usuario_id = p_usuario_id;

END;
$$;



-- =========================================
-- PROCEDURE:
-- CADASTRAR CONTA PIX
-- =========================================

CREATE OR REPLACE PROCEDURE financial.sp_cadastrar_pix(
    p_usuario_id UUID,
    p_chave_pix TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO financial.conta_recebimento (
        usuario_id,
        tipo,
        chave_pix
    )
    VALUES (
        p_usuario_id,
        'pix',

        pgp_sym_encrypt(
            p_chave_pix,
            'MINHA_CHAVE_AES_256'
        )
    );

END;
$$;



-- =========================================
-- PROCEDURE:
-- CRIAR POSTAGEM
-- =========================================

CREATE OR REPLACE PROCEDURE social.sp_criar_postagem(
    p_usuario_id UUID,
    p_conteudo TEXT,
    p_imagem_url TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO social.postagem (
        usuario_id,
        conteudo,
        imagem_url
    )
    VALUES (
        p_usuario_id,
        p_conteudo,
        p_imagem_url
    );

END;
$$;



-- =========================================
-- PROCEDURE:
-- CURTIR POSTAGEM
-- =========================================

CREATE OR REPLACE PROCEDURE social.sp_curtir_postagem(
    p_postagem_id UUID,
    p_usuario_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO social.curtida (
        postagem_id,
        usuario_id
    )
    VALUES (
        p_postagem_id,
        p_usuario_id
    );

END;
$$;



-- =========================================
-- PROCEDURE:
-- CRIAR AVALIAÇÃO
-- =========================================

CREATE OR REPLACE PROCEDURE social.sp_criar_avaliacao(
    p_agendamento_id UUID,
    p_cliente_id UUID,
    p_prestador_id UUID,
    p_nota INTEGER,
    p_comentario TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO social.avaliacao (
        agendamento_id,
        cliente_id,
        prestador_id,
        nota,
        comentario
    )
    VALUES (
        p_agendamento_id,
        p_cliente_id,
        p_prestador_id,
        p_nota,
        p_comentario
    );

END;
$$;



-- =========================================
-- PROCEDURE:
-- ABRIR DISPUTA
-- =========================================

CREATE OR REPLACE PROCEDURE support.sp_abrir_disputa(
    p_agendamento_id UUID,
    p_usuario_id UUID,
    p_descricao TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO support.disputa (
        agendamento_id,
        usuario_id,
        descricao
    )
    VALUES (
        p_agendamento_id,
        p_usuario_id,
        p_descricao
    );

END;
$$;



-- =========================================
-- PROCEDURE:
-- ADICIONAR PROVA
-- =========================================

CREATE OR REPLACE PROCEDURE support.sp_adicionar_prova(
    p_disputa_id UUID,
    p_arquivo_url TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO support.prova_disputa (
        disputa_id,
        arquivo_url
    )
    VALUES (
        p_disputa_id,
        p_arquivo_url
    );

END;
$$;



-- =========================================
-- PROCEDURE:
-- REGISTRAR LOG
-- =========================================

CREATE OR REPLACE PROCEDURE audit.sp_registrar_log(
    p_usuario_id UUID,
    p_acao VARCHAR(255),
    p_tabela VARCHAR(100),
    p_ip VARCHAR(45)
)
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO audit.log (
        usuario_id,
        acao,
        tabela,
        ip_address
    )
    VALUES (
        p_usuario_id,
        p_acao,
        p_tabela,
        p_ip
    );

END;
$$;



-- =========================================
-- PROCEDURE:
-- MOVER VALOR PARA ESCROW
-- =========================================
-- Chamada após confirmação do pagamento (RF29, RF30)
-- Move valor para saldo_pendente da carteira
-- e registra movimentação de escrow

CREATE OR REPLACE PROCEDURE financial.sp_entrada_escrow(
    p_agendamento_id UUID,
    p_prestador_id   UUID,
    p_valor_liquido  NUMERIC(10,2)
)
LANGUAGE plpgsql
AS $$
BEGIN

    -- Incrementa saldo pendente do prestador
    UPDATE financial.carteira
    SET
        saldo_pendente = saldo_pendente + p_valor_liquido,
        atualizado_em  = CURRENT_TIMESTAMP
    WHERE usuario_id = p_prestador_id;

    -- Registra movimentação para rastreabilidade
    INSERT INTO financial.escrow_movimentacao (
        agendamento_id,
        tipo,
        valor,
        descricao
    )
    VALUES (
        p_agendamento_id,
        'entrada',
        p_valor_liquido,
        'Valor retido em escrow após confirmação do pagamento'
    );

END;
$$;



-- =========================================
-- PROCEDURE:
-- LIBERAR ESCROW PARA SALDO DISPONÍVEL
-- =========================================
-- Chamada ao confirmar serviço (RF35) ou
-- após auto-confirmação 24h (RF37)
-- Libera saldo_pendente → saldo_disponivel

CREATE OR REPLACE PROCEDURE financial.sp_liberar_escrow(
    p_agendamento_id UUID,
    p_prestador_id   UUID,
    p_valor_liquido  NUMERIC(10,2)
)
LANGUAGE plpgsql
AS $$
BEGIN

    UPDATE financial.carteira
    SET
        saldo_pendente   = saldo_pendente   - p_valor_liquido,
        saldo_disponivel = saldo_disponivel + p_valor_liquido,
        atualizado_em    = CURRENT_TIMESTAMP
    WHERE usuario_id = p_prestador_id;

    -- Registra liberação
    INSERT INTO financial.escrow_movimentacao (
        agendamento_id,
        tipo,
        valor,
        descricao
    )
    VALUES (
        p_agendamento_id,
        'liberacao',
        p_valor_liquido,
        'Valor liberado para carteira após confirmação do serviço'
    );

    -- Atualiza status da transação
    UPDATE financial.transacao
    SET
        status        = 'released',
        atualizado_em = CURRENT_TIMESTAMP
    WHERE agendamento_id = p_agendamento_id;

END;
$$;



-- =========================================
-- PROCEDURE:
-- ESTORNAR ESCROW (DISPUTA ACEITA)
-- =========================================
-- Chamada pelo administrador ao resolver
-- disputa em favor do cliente (RF43)

CREATE OR REPLACE PROCEDURE financial.sp_estornar_escrow(
    p_agendamento_id UUID,
    p_prestador_id   UUID,
    p_valor_liquido  NUMERIC(10,2)
)
LANGUAGE plpgsql
AS $$
BEGIN

    UPDATE financial.carteira
    SET
        saldo_pendente = saldo_pendente - p_valor_liquido,
        atualizado_em  = CURRENT_TIMESTAMP
    WHERE usuario_id = p_prestador_id;

    -- Registra estorno
    INSERT INTO financial.escrow_movimentacao (
        agendamento_id,
        tipo,
        valor,
        descricao
    )
    VALUES (
        p_agendamento_id,
        'estorno',
        p_valor_liquido,
        'Estorno por resolução de disputa em favor do cliente'
    );

    -- Marca transação como estornada
    UPDATE financial.transacao
    SET
        status        = 'refunded',
        atualizado_em = CURRENT_TIMESTAMP
    WHERE agendamento_id = p_agendamento_id;

END;
$$;



-- =========================================
-- PROCEDURE:
-- PROCESSAR REPASSE MENSAL
-- =========================================
-- Executada automaticamente no dia 20 de
-- cada mês para todos os prestadores com
-- KYC aprovado e saldo disponível (RF50, RF51, RF52, RF53)

CREATE OR REPLACE PROCEDURE financial.sp_processar_repasse_mensal(
    p_referencia_mes DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_rec RECORD;
BEGIN

    -- Percorre prestadores aptos a receber
    FOR v_rec IN
        SELECT
            c.usuario_id,
            c.saldo_disponivel
        FROM financial.carteira c
        INNER JOIN financial.kyc k
            ON k.usuario_id = c.usuario_id
        WHERE
            k.status            = 'approved'
            AND c.saldo_disponivel > 0
    LOOP

        -- Registra o repasse
        INSERT INTO financial.repasse_mensal (
            usuario_id,
            valor,
            status,
            referencia_mes,
            processado_em
        )
        VALUES (
            v_rec.usuario_id,
            v_rec.saldo_disponivel,
            'processado',
            p_referencia_mes,
            CURRENT_TIMESTAMP
        );

        -- Zera saldo disponível após repasse
        UPDATE financial.carteira
        SET
            saldo_disponivel = 0.00,
            atualizado_em    = CURRENT_TIMESTAMP
        WHERE usuario_id = v_rec.usuario_id;

    END LOOP;

END;
$$;



-- =========================================
-- PROCEDURE:
-- CRIAR AVALIAÇÃO (COM VALIDAÇÃO)
-- =========================================
-- Substitui a procedure simples existente
-- Garante: agendamento concluído, avaliação única,
-- e dispara atualização de média (RF38, RF39, RF40)

CREATE OR REPLACE PROCEDURE social.sp_criar_avaliacao(
    p_agendamento_id UUID,
    p_cliente_id     UUID,
    p_prestador_id   UUID,
    p_nota           INTEGER,
    p_comentario     TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status marketplace.status_agendamento;
BEGIN

    -- Valida que o agendamento está concluído
    SELECT status INTO v_status
    FROM marketplace.agendamento
    WHERE id = p_agendamento_id;

    IF v_status <> 'completed' THEN
        RAISE EXCEPTION
            'Avaliação permitida somente para agendamentos com status completed. Status atual: %',
            v_status;
    END IF;

    -- Insere avaliação; a UNIQUE constraint impede duplicata
    INSERT INTO social.avaliacao (
        agendamento_id,
        cliente_id,
        prestador_id,
        nota,
        comentario
    )
    VALUES (
        p_agendamento_id,
        p_cliente_id,
        p_prestador_id,
        p_nota,
        p_comentario
    );

    -- Atualiza média e total no perfil do prestador
    -- O trigger trg_atualizar_media_avaliacao cuida disso automaticamente.
    -- Esta chamada explícita serve de fallback.
    UPDATE auth.perfil
    SET
        media_avaliacao = (
            SELECT ROUND(AVG(nota), 2)
            FROM social.avaliacao
            WHERE prestador_id = p_prestador_id
        ),
        total_avaliacoes = (
            SELECT COUNT(*)
            FROM social.avaliacao
            WHERE prestador_id = p_prestador_id
        ),
        atualizado_em = CURRENT_TIMESTAMP
    WHERE usuario_id = p_prestador_id;

END;
$$;



-- =========================================
-- EXEMPLOS DE USO
-- =========================================

/*

CALL auth.sp_criar_usuario(
    'Milleny Evan',
    'millenyevan.estudos@gmail.com',
    '2005-03-01',
    '12345678912',
    'MyMy123@',
    '37998298954',
    'https://site.com/documento.png',
    'admin'
);

SELECT * FROM auth.fn_login_usuario(
    'millenyevan.estudos@gmail.com',
    'MyMy123@'
);

CALL auth.sp_alterar_senha(
    'UUID_DO_USUARIO',
    'NovaSenha123'
);

CALL marketplace.sp_criar_servico(
    'UUID_PRESTADOR',
    'UUID_CATEGORIA',
    'Mentoria React',
    'Mentoria completa',
    150.00,
    90
);

-- Após pagamento confirmado:
CALL financial.sp_entrada_escrow(
    'UUID_AGENDAMENTO',
    'UUID_PRESTADOR',
    135.00  -- valor_liquido após desconto da taxa
);

-- Após cliente confirmar entrega:
CALL financial.sp_liberar_escrow(
    'UUID_AGENDAMENTO',
    'UUID_PRESTADOR',
    135.00
);

-- Repasse mensal (executar no cron do dia 20):
CALL financial.sp_processar_repasse_mensal('2026-06-01');

-- Avaliação após serviço concluído:
CALL social.sp_criar_avaliacao(
    'UUID_AGENDAMENTO',
    'UUID_CLIENTE',
    'UUID_PRESTADOR',
    5,
    'Excelente atendimento!'
);

*/


-- =========================================
-- FIM
-- =========================================
