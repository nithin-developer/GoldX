import re
import secrets
import string
import uuid
from collections.abc import AsyncGenerator
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import inspect, text
from sqlalchemy.orm import DeclarativeBase
from app.core.config import settings


USER_ID_START = 1_000_000
INVITE_CODE_LENGTH = 8
_INVITE_CODE_PATTERN = re.compile(r"^[A-Z0-9]{8}$")
_INVITE_CODE_CHARS = string.ascii_uppercase + string.digits


engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    pool_size=20,
    max_overflow=10,
    pool_pre_ping=True,
)

async_session_factory = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    pass


def _quote_identifier(identifier: str) -> str:
    return '"' + identifier.replace('"', '""') + '"'


def _normalize_existing_invite_code(invite_code: str | None) -> str | None:
    normalized = (invite_code or "").strip().upper()
    if not normalized:
        return None

    if (
        normalized.startswith("INV")
        and len(normalized) == 11
        and _INVITE_CODE_PATTERN.fullmatch(normalized[3:]) is not None
    ):
        normalized = normalized[3:]

    if _INVITE_CODE_PATTERN.fullmatch(normalized) is None:
        return None

    return normalized


def _to_utc_datetime(value):
    """Normalize datetime values to UTC-aware datetimes for timestamptz columns."""
    if not isinstance(value, datetime):
        return value

    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)

    return value.astimezone(timezone.utc)


def _generate_random_invite_code(used_codes: set[str]) -> str:
    while True:
        invite_code = "".join(
            secrets.choice(_INVITE_CODE_CHARS) for _ in range(INVITE_CODE_LENGTH)
        )
        if invite_code not in used_codes:
            return invite_code


def _apply_int_mapping(
    sync_conn,
    table_name: str,
    column_name: str,
    id_mapping: list[tuple[int, int]],
) -> None:
    if not id_mapping:
        return

    old_ids = ",".join(str(old_id) for old_id, _ in id_mapping)
    case_clauses = " ".join(
        f"WHEN {old_id} THEN {new_id}" for old_id, new_id in id_mapping
    )
    quoted_table = _quote_identifier(table_name)
    quoted_column = _quote_identifier(column_name)

    sync_conn.execute(
        text(
            f"UPDATE {quoted_table} "
            f"SET {quoted_column} = CASE {quoted_column} {case_clauses} ELSE {quoted_column} END "
            f"WHERE {quoted_column} IN ({old_ids})"
        )
    )


def _apply_int_mapping_with_temporary_values(
    sync_conn,
    table_name: str,
    column_name: str,
    id_mapping: list[tuple[int, int]],
) -> None:
    """Apply integer remapping in two phases to avoid unique-key collisions.

    Example: remapping {3->2, 4->3} can fail under immediate uniqueness checks
    when done in-place. We first map old ids to guaranteed-free temporary ids,
    then map temporary ids to final targets.
    """
    if not id_mapping:
        return

    quoted_table = _quote_identifier(table_name)
    quoted_column = _quote_identifier(column_name)
    min_value = sync_conn.execute(
        text(f"SELECT COALESCE(MIN({quoted_column}), 0) FROM {quoted_table}")
    ).scalar()

    safe_floor = int(min_value or 0)
    temp_start = min(safe_floor, 0) - len(id_mapping) - 10

    temp_mapping: list[tuple[int, int]] = []
    next_temp = temp_start
    for old_id, _ in id_mapping:
        temp_mapping.append((old_id, next_temp))
        next_temp += 1

    _apply_int_mapping(sync_conn, table_name, column_name, temp_mapping)

    final_mapping = [
        (temp_id, new_id)
        for (_, temp_id), (_, new_id) in zip(temp_mapping, id_mapping)
    ]
    _apply_int_mapping(sync_conn, table_name, column_name, final_mapping)


def _get_user_fk_references(inspector, table_names: set[str]) -> list[dict]:
    references: list[dict] = []

    for table_name in table_names:
        if table_name == "users":
            continue

        for fk in inspector.get_foreign_keys(table_name):
            if fk.get("referred_table") != "users":
                continue

            constrained_columns = fk.get("constrained_columns") or []
            referred_columns = fk.get("referred_columns") or []
            if not constrained_columns or not referred_columns:
                continue
            user_id_columns = [
                constrained_columns[index]
                for index, referred_column in enumerate(referred_columns)
                if referred_column == "id"
            ]
            if not user_id_columns:
                continue

            references.append(
                {
                    "table_name": table_name,
                    "name": fk.get("name"),
                    "constrained_columns": constrained_columns,
                    "referred_schema": fk.get("referred_schema"),
                    "referred_table": fk.get("referred_table"),
                    "referred_columns": referred_columns,
                    "user_id_columns": user_id_columns,
                    "options": fk.get("options") or {},
                    "deferrable": fk.get("deferrable"),
                    "initially": fk.get("initially"),
                }
            )

    return references


def _drop_user_fk_constraints(sync_conn, fk_references: list[dict]) -> None:
    for fk in fk_references:
        constraint_name = fk.get("name")
        if not constraint_name:
            continue

        quoted_table = _quote_identifier(str(fk["table_name"]))
        quoted_constraint = _quote_identifier(str(constraint_name))
        sync_conn.execute(
            text(f"ALTER TABLE {quoted_table} DROP CONSTRAINT {quoted_constraint}")
        )


def _add_user_fk_constraints(sync_conn, fk_references: list[dict]) -> None:
    for fk in fk_references:
        constraint_name = fk.get("name")
        if not constraint_name:
            continue

        quoted_table = _quote_identifier(str(fk["table_name"]))
        quoted_constraint = _quote_identifier(str(constraint_name))
        constrained_columns = ", ".join(
            _quote_identifier(column_name)
            for column_name in fk.get("constrained_columns", [])
        )
        referred_columns = ", ".join(
            _quote_identifier(column_name)
            for column_name in fk.get("referred_columns", [])
        )

        referred_table = _quote_identifier(str(fk["referred_table"]))
        referred_schema = fk.get("referred_schema")
        referred_target = (
            f"{_quote_identifier(str(referred_schema))}.{referred_table}"
            if referred_schema
            else referred_table
        )

        add_fk_sql = (
            f"ALTER TABLE {quoted_table} "
            f"ADD CONSTRAINT {quoted_constraint} "
            f"FOREIGN KEY ({constrained_columns}) REFERENCES {referred_target} ({referred_columns})"
        )

        options = fk.get("options") or {}
        if options.get("ondelete"):
            add_fk_sql += f" ON DELETE {options['ondelete']}"
        if options.get("onupdate"):
            add_fk_sql += f" ON UPDATE {options['onupdate']}"

        if fk.get("deferrable") is True:
            add_fk_sql += " DEFERRABLE"
        elif fk.get("deferrable") is False:
            add_fk_sql += " NOT DEFERRABLE"

        if fk.get("initially"):
            add_fk_sql += f" INITIALLY {str(fk['initially']).upper()}"

        sync_conn.execute(text(add_fk_sql))


def _sync_users_sequence(sync_conn, next_user_id: int) -> None:
    next_user_id = max(next_user_id, USER_ID_START)
    dialect_name = sync_conn.dialect.name

    if dialect_name == "postgresql":
        sequence_name = sync_conn.execute(
            text("SELECT pg_get_serial_sequence('users', 'id')")
        ).scalar()

        if sequence_name:
            sync_conn.execute(
                text("SELECT setval(:sequence_name, :sequence_value, true)"),
                {
                    "sequence_name": sequence_name,
                    "sequence_value": next_user_id - 1,
                },
            )

        return

    if dialect_name == "sqlite":
        try:
            existing = sync_conn.execute(
                text("SELECT seq FROM sqlite_sequence WHERE name = 'users'")
            ).fetchone()

            if existing is None:
                sync_conn.execute(
                    text(
                        "INSERT INTO sqlite_sequence(name, seq) VALUES ('users', :sequence_value)"
                    ),
                    {"sequence_value": next_user_id - 1},
                )
            else:
                sync_conn.execute(
                    text(
                        "UPDATE sqlite_sequence SET seq = :sequence_value WHERE name = 'users'"
                    ),
                    {"sequence_value": next_user_id - 1},
                )
        except Exception:
            # sqlite_sequence may not exist depending on table creation mode.
            pass


def _ensure_user_ids_and_invite_codes(sync_conn) -> None:
    """Backfill users to 7-digit ids and 8-character invite codes."""
    inspector = inspect(sync_conn)
    table_names = set(inspector.get_table_names())
    if "users" not in table_names:
        return

    user_rows = sync_conn.execute(
        text("SELECT id, invite_code FROM users ORDER BY id")
    ).fetchall()

    if not user_rows:
        _sync_users_sequence(sync_conn, USER_ID_START)
        return

    used_codes: set[str] = set()
    invite_updates: list[tuple[int, str]] = []

    for row in user_rows:
        user_id = int(row[0])
        current_code = row[1]
        normalized_code = _normalize_existing_invite_code(current_code)

        if normalized_code is None or normalized_code in used_codes:
            normalized_code = _generate_random_invite_code(used_codes)

        used_codes.add(normalized_code)

        if current_code != normalized_code:
            invite_updates.append((user_id, normalized_code))

    for user_id, invite_code in invite_updates:
        sync_conn.execute(
            text("UPDATE users SET invite_code = :invite_code WHERE id = :id"),
            {"invite_code": invite_code, "id": user_id},
        )

    if sync_conn.dialect.name == "postgresql":
        user_columns = inspector.get_columns("users")
        invite_column = next(
            (column for column in user_columns if column.get("name") == "invite_code"),
            None,
        )
        invite_length = getattr(invite_column.get("type"), "length", None) if invite_column else None

        if invite_length != INVITE_CODE_LENGTH:
            sync_conn.execute(
                text("ALTER TABLE users ALTER COLUMN invite_code TYPE VARCHAR(8)")
            )

    current_ids = [int(row[0]) for row in user_rows]
    target_ids = [USER_ID_START + index for index in range(len(current_ids))]
    id_mapping = [
        (old_id, target_id)
        for old_id, target_id in zip(current_ids, target_ids)
        if old_id != target_id
    ]

    if id_mapping:
        fk_references = _get_user_fk_references(inspector, table_names)
        dialect_name = sync_conn.dialect.name

        if dialect_name == "postgresql":
            _drop_user_fk_constraints(sync_conn, fk_references)
        elif dialect_name == "mysql":
            sync_conn.execute(text("SET FOREIGN_KEY_CHECKS = 0"))
        elif dialect_name == "sqlite":
            sync_conn.execute(text("PRAGMA foreign_keys=OFF"))

        for fk in fk_references:
            for column_name in fk.get("user_id_columns", []):
                _apply_int_mapping(
                    sync_conn,
                    str(fk["table_name"]),
                    str(column_name),
                    id_mapping,
                )

        user_column_names = {col["name"] for col in inspector.get_columns("users")}
        if "referred_by" in user_column_names:
            _apply_int_mapping(sync_conn, "users", "referred_by", id_mapping)

        _apply_int_mapping_with_temporary_values(sync_conn, "users", "id", id_mapping)

        if dialect_name == "postgresql":
            _add_user_fk_constraints(sync_conn, fk_references)
        elif dialect_name == "mysql":
            sync_conn.execute(text("SET FOREIGN_KEY_CHECKS = 1"))
        elif dialect_name == "sqlite":
            sync_conn.execute(text("PRAGMA foreign_keys=ON"))

    max_user_id = sync_conn.execute(
        text("SELECT COALESCE(MAX(id), 0) FROM users")
    ).scalar()
    next_user_id = max(int(max_user_id or 0) + 1, USER_ID_START)
    _sync_users_sequence(sync_conn, next_user_id)


def _ensure_signal_public_ids(sync_conn) -> None:
    """Backfill UUID-style public ids for signals in existing databases."""
    inspector = inspect(sync_conn)
    table_names = set(inspector.get_table_names())
    if "signals" not in table_names:
        return

    signal_columns = {col["name"] for col in inspector.get_columns("signals")}
    if "public_id" not in signal_columns:
        sync_conn.execute(text("ALTER TABLE signals ADD COLUMN public_id VARCHAR(36)"))

    if "vip_only" not in signal_columns:
        sync_conn.execute(
            text("ALTER TABLE signals ADD COLUMN vip_only BOOLEAN DEFAULT FALSE")
        )

    if "duration_unit" not in signal_columns:
        sync_conn.execute(
            text("ALTER TABLE signals ADD COLUMN duration_unit VARCHAR(10) DEFAULT 'hours'")
        )

    sync_conn.execute(text("UPDATE signals SET vip_only = FALSE WHERE vip_only IS NULL"))
    sync_conn.execute(
        text(
            "UPDATE signals "
            "SET duration_unit = 'hours' "
            "WHERE duration_unit IS NULL OR LOWER(duration_unit) NOT IN ('hours', 'minutes')"
        )
    )

    rows = sync_conn.execute(
        text("SELECT id FROM signals WHERE public_id IS NULL OR public_id = ''")
    ).fetchall()

    for row in rows:
        sync_conn.execute(
            text("UPDATE signals SET public_id = :public_id WHERE id = :id"),
            {"public_id": str(uuid.uuid4()), "id": row[0]},
        )

    sync_conn.execute(
        text("CREATE UNIQUE INDEX IF NOT EXISTS ix_signals_public_id ON signals (public_id)")
    )


def _ensure_wallet_public_ids_and_payment_proofs(sync_conn) -> None:
    """Backfill UUID-style public ids for deposits/withdrawals and payment proof column."""
    inspector = inspect(sync_conn)
    table_names = set(inspector.get_table_names())

    if "deposits" in table_names:
        deposit_columns = {col["name"] for col in inspector.get_columns("deposits")}

        if "public_id" not in deposit_columns:
            sync_conn.execute(text("ALTER TABLE deposits ADD COLUMN public_id VARCHAR(36)"))

        if "payment_proof_filename" not in deposit_columns:
            sync_conn.execute(
                text("ALTER TABLE deposits ADD COLUMN payment_proof_filename VARCHAR(255)")
            )

        if "self_reward_amount" not in deposit_columns:
            sync_conn.execute(
                text(
                    "ALTER TABLE deposits "
                    "ADD COLUMN self_reward_amount NUMERIC(18,2) DEFAULT 0"
                )
            )

        if "referrer_reward_amount" not in deposit_columns:
            sync_conn.execute(
                text(
                    "ALTER TABLE deposits "
                    "ADD COLUMN referrer_reward_amount NUMERIC(18,2) DEFAULT 0"
                )
            )

        sync_conn.execute(
            text(
                "UPDATE deposits "
                "SET self_reward_amount = COALESCE(self_reward_amount, 0), "
                "referrer_reward_amount = COALESCE(referrer_reward_amount, 0)"
            )
        )

        deposit_rows = sync_conn.execute(
            text("SELECT id FROM deposits WHERE public_id IS NULL OR public_id = ''")
        ).fetchall()

        for row in deposit_rows:
            sync_conn.execute(
                text("UPDATE deposits SET public_id = :public_id WHERE id = :id"),
                {"public_id": str(uuid.uuid4()), "id": row[0]},
            )

        sync_conn.execute(
            text(
                "CREATE UNIQUE INDEX IF NOT EXISTS ix_deposits_public_id ON deposits (public_id)"
            )
        )

    if "withdrawals" in table_names:
        withdrawal_columns = {col["name"] for col in inspector.get_columns("withdrawals")}

        if "public_id" not in withdrawal_columns:
            sync_conn.execute(
                text("ALTER TABLE withdrawals ADD COLUMN public_id VARCHAR(36)")
            )

        if "capital_amount" not in withdrawal_columns:
            sync_conn.execute(
                text(
                    "ALTER TABLE withdrawals "
                    "ADD COLUMN capital_amount NUMERIC(18,2) DEFAULT 0"
                )
            )

        if "signal_profit_amount" not in withdrawal_columns:
            sync_conn.execute(
                text(
                    "ALTER TABLE withdrawals "
                    "ADD COLUMN signal_profit_amount NUMERIC(18,2) DEFAULT 0"
                )
            )

        if "reward_amount" not in withdrawal_columns:
            sync_conn.execute(
                text(
                    "ALTER TABLE withdrawals "
                    "ADD COLUMN reward_amount NUMERIC(18,2) DEFAULT 0"
                )
            )

        if "fee_rate_percent" not in withdrawal_columns:
            sync_conn.execute(
                text(
                    "ALTER TABLE withdrawals "
                    "ADD COLUMN fee_rate_percent NUMERIC(5,2) DEFAULT 10"
                )
            )

        if "fee_amount" not in withdrawal_columns:
            sync_conn.execute(
                text(
                    "ALTER TABLE withdrawals "
                    "ADD COLUMN fee_amount NUMERIC(18,2) DEFAULT 0"
                )
            )

        if "net_amount" not in withdrawal_columns:
            sync_conn.execute(
                text(
                    "ALTER TABLE withdrawals "
                    "ADD COLUMN net_amount NUMERIC(18,2) DEFAULT 0"
                )
            )

        sync_conn.execute(
            text(
                "UPDATE withdrawals "
                "SET capital_amount = COALESCE(capital_amount, 0), "
                "signal_profit_amount = COALESCE(signal_profit_amount, 0), "
                "reward_amount = COALESCE(reward_amount, 0)"
            )
        )

        sync_conn.execute(
            text(
                "UPDATE withdrawals "
                "SET fee_rate_percent = 10 "
                "WHERE fee_rate_percent IS NULL OR fee_rate_percent <= 0"
            )
        )

        sync_conn.execute(
            text(
                "UPDATE withdrawals "
                "SET fee_amount = ROUND(COALESCE(amount, 0) * 0.10, 2) "
                "WHERE (fee_amount IS NULL OR fee_amount <= 0) "
                "AND COALESCE(amount, 0) > 0"
            )
        )

        sync_conn.execute(
            text(
                "UPDATE withdrawals "
                "SET net_amount = ROUND(COALESCE(amount, 0) - COALESCE(fee_amount, 0), 2) "
                "WHERE (net_amount IS NULL OR net_amount <= 0) "
                "AND COALESCE(amount, 0) > 0"
            )
        )

        sync_conn.execute(
            text(
                "UPDATE withdrawals "
                "SET net_amount = 0 "
                "WHERE COALESCE(amount, 0) <= 0"
            )
        )

        withdrawal_rows = sync_conn.execute(
            text("SELECT id FROM withdrawals WHERE public_id IS NULL OR public_id = ''")
        ).fetchall()

        for row in withdrawal_rows:
            sync_conn.execute(
                text("UPDATE withdrawals SET public_id = :public_id WHERE id = :id"),
                {"public_id": str(uuid.uuid4()), "id": row[0]},
            )

        sync_conn.execute(
            text(
                "CREATE UNIQUE INDEX IF NOT EXISTS ix_withdrawals_public_id ON withdrawals (public_id)"
            )
        )


def _ensure_user_balance_breakdown_columns(sync_conn) -> None:
    """Add user balance breakdown fields and backfill safe defaults for existing users."""
    inspector = inspect(sync_conn)
    table_names = set(inspector.get_table_names())
    if "users" not in table_names:
        return

    user_column_definitions = {
        column["name"]: column for column in inspector.get_columns("users")
    }
    user_columns = set(user_column_definitions)

    if "capital_balance" not in user_columns:
        sync_conn.execute(
            text("ALTER TABLE users ADD COLUMN capital_balance NUMERIC(18,2) DEFAULT 0")
        )

    if "signal_profit_balance" not in user_columns:
        sync_conn.execute(
            text(
                "ALTER TABLE users "
                "ADD COLUMN signal_profit_balance NUMERIC(18,2) DEFAULT 0"
            )
        )

    if "reward_balance" not in user_columns:
        sync_conn.execute(
            text("ALTER TABLE users ADD COLUMN reward_balance NUMERIC(18,2) DEFAULT 0")
        )

    if "first_deposit_approved_at" not in user_columns:
        sync_conn.execute(
            text(
                "ALTER TABLE users "
                "ADD COLUMN first_deposit_approved_at TIMESTAMP WITH TIME ZONE"
            )
        )
    else:
        first_deposit_type = user_column_definitions["first_deposit_approved_at"].get(
            "type"
        )
        is_timezone_aware = bool(getattr(first_deposit_type, "timezone", False))

        if not is_timezone_aware:
            # Legacy environments may have created this as TIMESTAMP without timezone.
            # Convert in-place and treat existing values as UTC.
            sync_conn.execute(
                text(
                    "ALTER TABLE users "
                    "ALTER COLUMN first_deposit_approved_at "
                    "TYPE TIMESTAMP WITH TIME ZONE "
                    "USING first_deposit_approved_at AT TIME ZONE 'UTC'"
                )
            )

    if "initial_capital_locked_amount" not in user_columns:
        sync_conn.execute(
            text(
                "ALTER TABLE users "
                "ADD COLUMN initial_capital_locked_amount NUMERIC(18,2) DEFAULT 0"
            )
        )

    # Preserve current totals for legacy users by treating existing balance as capital.
    sync_conn.execute(
        text(
            "UPDATE users "
            "SET capital_balance = COALESCE(wallet_balance, 0) "
            "WHERE COALESCE(capital_balance, 0) = 0 "
            "AND COALESCE(signal_profit_balance, 0) = 0 "
            "AND COALESCE(reward_balance, 0) = 0 "
            "AND COALESCE(wallet_balance, 0) <> 0"
        )
    )

    sync_conn.execute(
        text(
            "UPDATE users "
            "SET initial_capital_locked_amount = COALESCE(initial_capital_locked_amount, 0)"
        )
    )

    if "deposits" in table_names:
        users_without_first_deposit = sync_conn.execute(
            text("SELECT id FROM users WHERE first_deposit_approved_at IS NULL")
        ).fetchall()

        for row in users_without_first_deposit:
            user_id = int(row[0])
            first_deposit = sync_conn.execute(
                text(
                    "SELECT amount, created_at "
                    "FROM deposits "
                    "WHERE user_id = :user_id AND status = 'approved' "
                    "ORDER BY created_at ASC "
                    "LIMIT 1"
                ),
                {"user_id": user_id},
            ).fetchone()

            if not first_deposit:
                continue

            sync_conn.execute(
                text(
                    "UPDATE users "
                    "SET first_deposit_approved_at = :approved_at, "
                    "initial_capital_locked_amount = CASE "
                    "WHEN COALESCE(initial_capital_locked_amount, 0) > 0 "
                    "THEN initial_capital_locked_amount "
                    "ELSE :locked_amount END "
                    "WHERE id = :user_id"
                ),
                {
                    "approved_at": _to_utc_datetime(first_deposit[1]),
                    "locked_amount": first_deposit[0],
                    "user_id": user_id,
                },
            )

    sync_conn.execute(
        text(
            "UPDATE users "
            "SET wallet_balance = "
            "COALESCE(capital_balance, 0) + "
            "COALESCE(signal_profit_balance, 0) + "
            "COALESCE(reward_balance, 0)"
        )
    )


def _ensure_support_link_and_drop_legacy_support_table(sync_conn) -> None:
    """Add support link column and remove deprecated support chat table."""
    inspector = inspect(sync_conn)
    table_names = set(inspector.get_table_names())

    if "deposit_wallet_settings" in table_names:
        settings_columns = {
            column["name"] for column in inspector.get_columns("deposit_wallet_settings")
        }
        if "support_url" not in settings_columns:
            sync_conn.execute(
                text("ALTER TABLE deposit_wallet_settings ADD COLUMN support_url TEXT")
            )

    if "support_messages" in table_names:
        sync_conn.execute(text("DROP TABLE IF EXISTS support_messages"))


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency that provides an async database session."""
    async with async_session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db():
    """Create all database tables."""
    async with engine.begin() as conn:
        from app.models import user, signal, wallet, referral, notification, system_settings  # noqa: F401
        await conn.run_sync(Base.metadata.create_all)
        await conn.run_sync(_ensure_user_ids_and_invite_codes)
        await conn.run_sync(_ensure_signal_public_ids)
        await conn.run_sync(_ensure_wallet_public_ids_and_payment_proofs)
        await conn.run_sync(_ensure_user_balance_breakdown_columns)
        await conn.run_sync(_ensure_support_link_and_drop_legacy_support_table)


async def close_db():
    """Dispose the database engine."""
    await engine.dispose()
