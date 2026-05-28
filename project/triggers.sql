-- =========================================
-- TRIGGERS.SQL
-- Projeto: TwoPlayers
-- Banco: PostgreSQL
-- =========================================


-- =========================================
-- FUNÇÃO: Atualizar campo atualizado_em
-- =========================================

CREATE OR REPLACE FUNCTION public.fn_atualizar_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    NEW.atualizado_em = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


-- =========================================
-- TRIGGERS DE UPDATE TIMESTAMP
-- =========================================

CREATE TRIGGER trg_usuario_updated_at
BEFORE UPDATE ON auth.usuario
FOR EACH ROW
EXECUTE FUNCTION public.fn_atualizar_timestamp();


CREATE TRIGGER trg_perfil_updated_at
BEFORE UPDATE ON auth.perfil
FOR EACH ROW
EXECUTE FUNCTION public.fn_atualizar_timestamp();


CREATE TRIGGER trg_servico_updated_at
BEFORE UPDATE ON marketplace.servico
FOR EACH ROW
EXECUTE FUNCTION public.fn_atualizar_timestamp();


CREATE TRIGGER trg_agendamento_updated_at
BEFORE UPDATE ON marketplace.agendamento
FOR EACH ROW
EXECUTE FUNCTION public.fn_atualizar_timestamp();


CREATE TRIGGER trg_transacao_updated_at
BEFORE UPDATE ON financial.transacao
FOR EACH ROW
EXECUTE FUNCTION public.fn_atualizar_timestamp();


CREATE TRIGGER trg_carteira_updated_at
BEFORE UPDATE ON financial.carteira
FOR EACH ROW
EXECUTE FUNCTION public.fn_atualizar_timestamp();


CREATE TRIGGER trg_postagem_updated_at
BEFORE UPDATE ON social.postagem
FOR EACH ROW
EXECUTE FUNCTION public.fn_atualizar_timestamp();


CREATE TRIGGER trg_disputa_updated_at
BEFORE UPDATE ON support.disputa
FOR EACH ROW
EXECUTE FUNCTION public.fn_atualizar_timestamp();


-- =========================================
-- FUNÇÃO: Registrar logs automáticos
-- =========================================

CREATE OR REPLACE FUNCTION audit.fn_registrar_log()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    INSERT INTO audit.log (
        id,
        usuario_id,
        acao,
        tabela,
        ip_address,
        criado_em
    )
    VALUES (
        gen_random_uuid(),
        NULL,
        TG_OP,
        TG_TABLE_NAME,
        '127.0.0.1',
        CURRENT_TIMESTAMP
    );

    RETURN NEW;

END;
$$;


-- =========================================
-- TRIGGERS DE AUDITORIA
-- =========================================

CREATE TRIGGER trg_log_usuario
AFTER INSERT OR UPDATE OR DELETE
ON auth.usuario
FOR EACH ROW
EXECUTE FUNCTION audit.fn_registrar_log();


CREATE TRIGGER trg_log_servico
AFTER INSERT OR UPDATE OR DELETE
ON marketplace.servico
FOR EACH ROW
EXECUTE FUNCTION audit.fn_registrar_log();


CREATE TRIGGER trg_log_agendamento
AFTER INSERT OR UPDATE OR DELETE
ON marketplace.agendamento
FOR EACH ROW
EXECUTE FUNCTION audit.fn_registrar_log();


CREATE TRIGGER trg_log_transacao
AFTER INSERT OR UPDATE OR DELETE
ON financial.transacao
FOR EACH ROW
EXECUTE FUNCTION audit.fn_registrar_log();


-- =========================================
-- FUNÇÃO: Validar saldo negativo
-- =========================================

CREATE OR REPLACE FUNCTION financial.fn_validar_saldo()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NEW.saldo_disponivel < 0 THEN
        RAISE EXCEPTION 'Saldo disponível não pode ser negativo.';
    END IF;

    IF NEW.saldo_pendente < 0 THEN
        RAISE EXCEPTION 'Saldo pendente não pode ser negativo.';
    END IF;

    RETURN NEW;

END;
$$;


-- =========================================
-- TRIGGER: Bloquear saldo negativo
-- =========================================

CREATE TRIGGER trg_validar_saldo
BEFORE INSERT OR UPDATE
ON financial.carteira
FOR EACH ROW
EXECUTE FUNCTION financial.fn_validar_saldo();


-- =========================================
-- FUNÇÃO: Validar nota da avaliação
-- =========================================

CREATE OR REPLACE FUNCTION social.fn_validar_nota()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NEW.nota < 1 OR NEW.nota > 5 THEN
        RAISE EXCEPTION 'A nota deve estar entre 1 e 5.';
    END IF;

    RETURN NEW;

END;
$$;


-- =========================================
-- TRIGGER: Validar avaliação
-- =========================================

CREATE TRIGGER trg_validar_nota
BEFORE INSERT OR UPDATE
ON social.avaliacao
FOR EACH ROW
EXECUTE FUNCTION social.fn_validar_nota();


-- =========================================
-- FUNÇÃO: Impedir agendamento no passado
-- =========================================

CREATE OR REPLACE FUNCTION marketplace.fn_validar_data_agendamento()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NEW.data_hora < CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'Não é permitido criar agendamentos no passado.';
    END IF;

    RETURN NEW;

END;
$$;


-- =========================================
-- TRIGGER: Validar data do agendamento
-- =========================================

CREATE TRIGGER trg_validar_data_agendamento
BEFORE INSERT
ON marketplace.agendamento
FOR EACH ROW
EXECUTE FUNCTION marketplace.fn_validar_data_agendamento();


-- =========================================
-- FUNÇÃO: Criar carteira automática
-- =========================================

CREATE OR REPLACE FUNCTION financial.fn_criar_carteira()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    INSERT INTO financial.carteira (
        id,
        usuario_id,
        saldo_disponivel,
        saldo_pendente,
        criado_em,
        atualizado_em
    )
    VALUES (
        gen_random_uuid(),
        NEW.id,
        0.00,
        0.00,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

    RETURN NEW;

END;
$$;


-- =========================================
-- TRIGGER: Criar carteira ao cadastrar usuário
-- =========================================

CREATE TRIGGER trg_criar_carteira
AFTER INSERT
ON auth.usuario
FOR EACH ROW
EXECUTE FUNCTION financial.fn_criar_carteira();


-- =========================================
-- FUNÇÃO: Atualizar média de avaliação no perfil
-- =========================================
-- Executada após INSERT em social.avaliacao
-- Mantém media_avaliacao e total_avaliacoes
-- atualizados em auth.perfil para leitura
-- rápida no feed e Top 10 (RF10, RF11, RF16, RF57)

CREATE OR REPLACE FUNCTION social.fn_atualizar_media_avaliacao()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    UPDATE auth.perfil
    SET
        media_avaliacao = (
            SELECT ROUND(AVG(nota), 2)
            FROM social.avaliacao
            WHERE prestador_id = NEW.prestador_id
        ),
        total_avaliacoes = (
            SELECT COUNT(*)
            FROM social.avaliacao
            WHERE prestador_id = NEW.prestador_id
        ),
        atualizado_em = CURRENT_TIMESTAMP
    WHERE usuario_id = NEW.prestador_id;

    RETURN NEW;

END;
$$;


-- =========================================
-- TRIGGER: Atualizar média após avaliação
-- =========================================

CREATE TRIGGER trg_atualizar_media_avaliacao
AFTER INSERT OR UPDATE
ON social.avaliacao
FOR EACH ROW
EXECUTE FUNCTION social.fn_atualizar_media_avaliacao();


-- =========================================
-- FUNÇÃO: Bloquear avaliação de agendamento
--         que não está concluído
-- =========================================
-- Garante que o cliente só avalia após
-- confirmação da entrega (RF38)

CREATE OR REPLACE FUNCTION social.fn_bloquear_avaliacao_invalida()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
DECLARE
    v_status marketplace.status_agendamento;
BEGIN

    SELECT status INTO v_status
    FROM marketplace.agendamento
    WHERE id = NEW.agendamento_id;

    IF v_status <> 'completed' THEN
        RAISE EXCEPTION
            'Avaliação não permitida. Agendamento % com status: %. Necessário: completed.',
            NEW.agendamento_id,
            v_status;
    END IF;

    RETURN NEW;

END;
$$;


-- =========================================
-- TRIGGER: Bloquear avaliação inválida
-- =========================================

CREATE TRIGGER trg_bloquear_avaliacao_invalida
BEFORE INSERT
ON social.avaliacao
FOR EACH ROW
EXECUTE FUNCTION social.fn_bloquear_avaliacao_invalida();


-- =========================================
-- FUNÇÃO: Bloquear horário após pagamento
-- =========================================
-- Quando o agendamento passa para 'paid',
-- nenhum outro agendamento pode ocupar o
-- mesmo horário (RNF12 — race condition)

CREATE OR REPLACE FUNCTION marketplace.fn_bloquear_horario_pago()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NEW.status = 'paid' AND OLD.status = 'pending' THEN

        -- Cancela agendamentos pendentes no mesmo horário
        UPDATE marketplace.agendamento
        SET
            status       = 'canceled',
            atualizado_em = CURRENT_TIMESTAMP
        WHERE
            prestador_id = NEW.prestador_id
            AND data_hora = NEW.data_hora
            AND id        <> NEW.id
            AND status    = 'pending';

    END IF;

    RETURN NEW;

END;
$$;


-- =========================================
-- TRIGGER: Bloquear horário ao confirmar pagamento
-- =========================================

CREATE TRIGGER trg_bloquear_horario_pago
AFTER UPDATE
ON marketplace.agendamento
FOR EACH ROW
EXECUTE FUNCTION marketplace.fn_bloquear_horario_pago();


-- =========================================
-- FUNÇÃO: Mover saldo pendente ao confirmar serviço
-- =========================================
-- Quando agendamento passa para 'completed',
-- dispara automaticamente a liberação do escrow
-- para saldo_disponivel (RF35, RF37)

CREATE OR REPLACE FUNCTION financial.fn_liberar_escrow_automatico()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
DECLARE
    v_valor_liquido NUMERIC(10,2);
BEGIN

    IF NEW.status = 'completed' AND OLD.status <> 'completed' THEN

        SELECT valor_liquido INTO v_valor_liquido
        FROM financial.transacao
        WHERE agendamento_id = NEW.id
          AND status = 'escrow';

        IF v_valor_liquido IS NOT NULL THEN

            CALL financial.sp_liberar_escrow(
                NEW.id,
                NEW.prestador_id,
                v_valor_liquido
            );

        END IF;

    END IF;

    RETURN NEW;

END;
$$;


-- =========================================
-- TRIGGER: Liberar escrow ao completar serviço
-- =========================================

CREATE TRIGGER trg_liberar_escrow_automatico
AFTER UPDATE
ON marketplace.agendamento
FOR EACH ROW
EXECUTE FUNCTION financial.fn_liberar_escrow_automatico();


-- =========================================
-- FUNÇÃO: Soft Delete de usuário
-- =========================================

CREATE OR REPLACE FUNCTION auth.fn_soft_delete_usuario()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    UPDATE auth.usuario
    SET
        deletado_em = CURRENT_TIMESTAMP,
        ativo = FALSE
    WHERE id = OLD.id;

    RETURN NULL;

END;
$$;


-- =========================================
-- TRIGGER: Soft delete usuário
-- =========================================

CREATE TRIGGER trg_soft_delete_usuario
BEFORE DELETE
ON auth.usuario
FOR EACH ROW
EXECUTE FUNCTION auth.fn_soft_delete_usuario();


-- =========================================
-- FIM
-- =========================================