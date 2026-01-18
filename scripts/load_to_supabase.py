#!/usr/bin/env python3
"""Load a local CSV or XLSX file into a Supabase Postgres table."""

from __future__ import annotations

import os
from io import StringIO
from typing import Dict, List

import pandas as pd
import psycopg2
from dotenv import load_dotenv
from psycopg2 import sql

REQUIRED_COLUMNS = [
    "invoice",
    "invoice_date",
    "customer_id",
    "stock_code",
    "description",
    "quantity",
    "unit_price",
    "country",
]

COLUMN_ALIASES: Dict[str, str] = {
    "invoiceno": "invoice",
    "invoice_no": "invoice",
    "invoice_number": "invoice",
    "invoice_date": "invoice_date",
    "invoicedate": "invoice_date",
    "customerid": "customer_id",
    "customer_id": "customer_id",
    "stockcode": "stock_code",
    "stock_code": "stock_code",
    "unitprice": "unit_price",
    "unit_price": "unit_price",
    "price": "unit_price",

}


def normalize_columns(columns: List[str]) -> List[str]:
    normalized = []
    for col in columns:
        cleaned = col.strip().lower().replace(" ", "_").replace("-", "_")
        normalized.append(cleaned)
    return normalized


def apply_column_aliases(df: pd.DataFrame) -> pd.DataFrame:
    mapped_columns = {
        col: COLUMN_ALIASES.get(col, col)
        for col in df.columns
    }
    df = df.rename(columns=mapped_columns)
    df = df.loc[:, ~df.columns.duplicated()]
    return df


def validate_required_columns(df: pd.DataFrame) -> None:
    missing = sorted(set(REQUIRED_COLUMNS) - set(df.columns))
    if missing:
        raise ValueError(
            "Missing required columns after normalization: "
            + ", ".join(missing)
        )


def load_dataframe(path: str) -> pd.DataFrame:
    if path.lower().endswith(".csv"):
        df = pd.read_csv(path)
    elif path.lower().endswith((".xlsx", ".xls")):
        df = pd.read_excel(path)
    else:
        raise ValueError("LOCAL_DATA_PATH must point to a .csv or .xlsx file.")

    df.columns = normalize_columns([str(col) for col in df.columns])
    df = apply_column_aliases(df)
    validate_required_columns(df)

    df["invoice_date"] = pd.to_datetime(df["invoice_date"], errors="coerce")

    return df


def ensure_table(cursor: psycopg2.extensions.cursor, table_name: str) -> None:
    create_table = sql.SQL(
        """
        CREATE TABLE IF NOT EXISTS {table} (
            invoice TEXT,
            invoice_date TIMESTAMP,
            customer_id TEXT,
            stock_code TEXT,
            description TEXT,
            quantity NUMERIC,
            unit_price NUMERIC,
            country TEXT
        );
        """
    ).format(table=sql.Identifier(table_name))
    cursor.execute(create_table)


def truncate_table(cursor: psycopg2.extensions.cursor, table_name: str) -> None:
    cursor.execute(sql.SQL("TRUNCATE TABLE {table};").format(table=sql.Identifier(table_name)))


def count_rows(cursor: psycopg2.extensions.cursor, table_name: str) -> int:
    cursor.execute(sql.SQL("SELECT COUNT(*) FROM {table};").format(table=sql.Identifier(table_name)))
    return int(cursor.fetchone()[0])


def copy_rows(
    cursor: psycopg2.extensions.cursor,
    table_name: str,
    df: pd.DataFrame,
) -> None:
    ordered_df = df[REQUIRED_COLUMNS]
    buffer = StringIO()
    ordered_df.to_csv(buffer, index=False, header=False)
    buffer.seek(0)

    columns = sql.SQL(", ").join(sql.Identifier(col) for col in REQUIRED_COLUMNS)
    copy_statement = sql.SQL(
        "COPY {table} ({columns}) FROM STDIN WITH (FORMAT CSV)"
    ).format(table=sql.Identifier(table_name), columns=columns)
    cursor.copy_expert(copy_statement.as_string(cursor), buffer)


def main() -> None:
    load_dotenv()

    db_url = os.getenv("SUPABASE_DB_URL")
    data_path = os.getenv("LOCAL_DATA_PATH")
    table_name = os.getenv("TABLE_NAME", "retail_transactions")

    if not db_url:
        raise ValueError("SUPABASE_DB_URL is required in the environment.")
    if not data_path:
        raise ValueError("LOCAL_DATA_PATH is required in the environment.")

    df = load_dataframe(data_path)

    try:
        with psycopg2.connect(db_url) as conn:
            with conn.cursor() as cursor:
                ensure_table(cursor, table_name)
                before_count = count_rows(cursor, table_name)
                print(f"Rows before load: {before_count}")

                truncate_table(cursor, table_name)
                copy_rows(cursor, table_name, df)

                after_count = count_rows(cursor, table_name)
                print(f"Rows after load: {after_count}")

            conn.commit()
    except Exception as exc:
        raise RuntimeError(f"Failed to load data into {table_name}: {exc}") from exc


if __name__ == "__main__":
    main()
