#!/usr/bin/env python3
"""Run all SQL files in the ./sql folder against Supabase Postgres."""

from __future__ import annotations

import os
from pathlib import Path
from typing import List

import psycopg2
import sqlparse
from dotenv import load_dotenv

SQL_DIR = Path(__file__).resolve().parents[1] / "sql"


def load_sql_files(sql_dir: Path) -> List[Path]:
    if not sql_dir.exists():
        raise FileNotFoundError(f"SQL directory not found: {sql_dir}")
    sql_files = sorted(sql_dir.glob("*.sql"))
    if not sql_files:
        raise FileNotFoundError(f"No SQL files found in: {sql_dir}")
    return sql_files


def split_statements(sql_text: str) -> List[str]:
    statements = [stmt.strip() for stmt in sqlparse.split(sql_text) if stmt.strip()]
    return statements


def execute_sql_file(cursor: psycopg2.extensions.cursor, sql_file: Path) -> None:
    sql_text = sql_file.read_text(encoding="utf-8")
    statements = split_statements(sql_text)
    for statement in statements:
        cursor.execute(statement)
    print(f"Ran {sql_file.name} ({len(statements)} statements)")


def main() -> None:
    load_dotenv()

    db_url = os.getenv("SUPABASE_DB_URL")
    if not db_url:
        raise ValueError("SUPABASE_DB_URL is required in the environment.")

    sql_files = load_sql_files(SQL_DIR)

    try:
        with psycopg2.connect(db_url, sslmode="require") as conn:
            with conn.cursor() as cursor:
                for sql_file in sql_files:
                    execute_sql_file(cursor, sql_file)
            conn.commit()
    except Exception as exc:
        raise RuntimeError(f"Failed to execute SQL files: {exc}") from exc


if __name__ == "__main__":
    main()
