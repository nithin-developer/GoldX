from decimal import Decimal
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from fastapi import HTTPException, status
from app.models.user import User
from app.models.wallet import WalletTransaction, Deposit, Withdrawal
from app.core.security import hash_password, verify_password


async def get_wallet_summary(user: User, db: AsyncSession) -> dict:
    """Get wallet balance and pending amounts."""
    # Pending deposits
    pending_deposits_result = await db.execute(
        select(func.coalesce(func.sum(Deposit.amount), 0)).where(
            Deposit.user_id == user.id, Deposit.status == "pending"
        )
    )
    pending_deposits = pending_deposits_result.scalar()

    # Pending withdrawals
    pending_withdrawals_result = await db.execute(
        select(func.coalesce(func.sum(Withdrawal.amount), 0)).where(
            Withdrawal.user_id == user.id, Withdrawal.status == "pending"
        )
    )
    pending_withdrawals = pending_withdrawals_result.scalar()

    return {
        "balance": user.wallet_balance,
        "pending_deposits": pending_deposits,
        "pending_withdrawals": pending_withdrawals,
    }


async def get_transactions(
    user: User, db: AsyncSession, skip: int = 0, limit: int = 50
) -> list[WalletTransaction]:
    """Get paginated wallet transactions."""
    result = await db.execute(
        select(WalletTransaction)
        .where(WalletTransaction.user_id == user.id)
        .order_by(WalletTransaction.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()


async def create_deposit(
    user: User, amount: Decimal, transaction_ref: str | None, db: AsyncSession
) -> Deposit:
    """Create a new deposit request (pending admin approval)."""
    deposit = Deposit(
        user_id=user.id,
        amount=amount,
        status="pending",
        transaction_ref=transaction_ref,
    )
    db.add(deposit)
    await db.flush()
    return deposit


async def get_user_deposits(
    user: User, db: AsyncSession, skip: int = 0, limit: int = 50
) -> list[Deposit]:
    """Get paginated deposit history."""
    result = await db.execute(
        select(Deposit)
        .where(Deposit.user_id == user.id)
        .order_by(Deposit.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()


async def create_withdrawal(
    user: User,
    amount: Decimal,
    withdrawal_password: str,
    wallet_address: str | None,
    db: AsyncSession,
) -> Withdrawal:
    """Create a withdrawal request after verifying withdrawal password."""
    # Check withdrawal password is set
    if not user.withdrawal_password_hash:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Withdrawal password not set. Please set it first.",
        )

    # Verify withdrawal password
    if not verify_password(withdrawal_password, user.withdrawal_password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid withdrawal password",
        )

    # Check sufficient balance
    if user.wallet_balance < amount:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Insufficient wallet balance",
        )

    withdrawal = Withdrawal(
        user_id=user.id,
        amount=amount,
        status="pending",
        wallet_address=wallet_address,
    )
    db.add(withdrawal)
    await db.flush()
    return withdrawal


async def set_withdrawal_password(
    user: User, withdrawal_password: str, db: AsyncSession
) -> None:
    """Set or update the withdrawal password."""
    user.withdrawal_password_hash = hash_password(withdrawal_password)
    await db.flush()


async def approve_deposit(deposit_id: int, admin_note: str | None, db: AsyncSession) -> Deposit:
    """Admin approves a deposit — credits the user's wallet."""
    result = await db.execute(select(Deposit).where(Deposit.id == deposit_id))
    deposit = result.scalar_one_or_none()

    if not deposit:
        raise HTTPException(status_code=404, detail="Deposit not found")
    if deposit.status != "pending":
        raise HTTPException(status_code=400, detail="Deposit already processed")

    deposit.status = "approved"
    deposit.admin_note = admin_note

    # Credit user wallet
    user_result = await db.execute(select(User).where(User.id == deposit.user_id))
    user = user_result.scalar_one()
    user.wallet_balance += deposit.amount

    # Create wallet transaction
    txn = WalletTransaction(
        user_id=user.id,
        type="deposit",
        amount=deposit.amount,
        description=f"Deposit approved (ref: {deposit.transaction_ref or 'N/A'})",
    )
    db.add(txn)
    await db.flush()

    # Update referral deposit tracking
    from app.models.referral import Referral

    if user.referred_by:
        ref_result = await db.execute(
            select(Referral).where(
                Referral.referred_user_id == user.id,
                Referral.referrer_id == user.referred_by,
            )
        )
        referral = ref_result.scalar_one_or_none()
        if referral and referral.status == "pending":
            referral.deposit_amount += deposit.amount
            referral.status = "qualified"

    return deposit


async def reject_deposit(deposit_id: int, admin_note: str | None, db: AsyncSession) -> Deposit:
    """Admin rejects a deposit."""
    result = await db.execute(select(Deposit).where(Deposit.id == deposit_id))
    deposit = result.scalar_one_or_none()

    if not deposit:
        raise HTTPException(status_code=404, detail="Deposit not found")
    if deposit.status != "pending":
        raise HTTPException(status_code=400, detail="Deposit already processed")

    deposit.status = "rejected"
    deposit.admin_note = admin_note
    await db.flush()
    return deposit


async def approve_withdrawal(
    withdrawal_id: int, admin_note: str | None, db: AsyncSession
) -> Withdrawal:
    """Admin approves a withdrawal — debits the user's wallet."""
    result = await db.execute(select(Withdrawal).where(Withdrawal.id == withdrawal_id))
    withdrawal = result.scalar_one_or_none()

    if not withdrawal:
        raise HTTPException(status_code=404, detail="Withdrawal not found")
    if withdrawal.status != "pending":
        raise HTTPException(status_code=400, detail="Withdrawal already processed")

    # Get user and verify balance
    user_result = await db.execute(select(User).where(User.id == withdrawal.user_id))
    user = user_result.scalar_one()

    if user.wallet_balance < withdrawal.amount:
        raise HTTPException(status_code=400, detail="User has insufficient balance")

    withdrawal.status = "approved"
    withdrawal.admin_note = admin_note

    # Debit wallet
    user.wallet_balance -= withdrawal.amount

    # Create wallet transaction
    txn = WalletTransaction(
        user_id=user.id,
        type="withdrawal",
        amount=-withdrawal.amount,
        description=f"Withdrawal approved to {withdrawal.wallet_address or 'N/A'}",
    )
    db.add(txn)
    await db.flush()
    return withdrawal


async def reject_withdrawal(
    withdrawal_id: int, admin_note: str | None, db: AsyncSession
) -> Withdrawal:
    """Admin rejects a withdrawal."""
    result = await db.execute(select(Withdrawal).where(Withdrawal.id == withdrawal_id))
    withdrawal = result.scalar_one_or_none()

    if not withdrawal:
        raise HTTPException(status_code=404, detail="Withdrawal not found")
    if withdrawal.status != "pending":
        raise HTTPException(status_code=400, detail="Withdrawal already processed")

    withdrawal.status = "rejected"
    withdrawal.admin_note = admin_note
    await db.flush()
    return withdrawal
