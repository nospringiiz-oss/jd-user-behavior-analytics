from pathlib import Path
import os
import sys

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from sqlalchemy.exc import SQLAlchemyError


PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"
ENV_FILE = PROJECT_ROOT / ".env"


def get_database_engine():
    """Create a MySQL database connection using values from .env."""

    load_dotenv(ENV_FILE)

    required_variables = [
        "DB_HOST",
        "DB_PORT",
        "DB_USER",
        "DB_PASSWORD",
        "DB_NAME",
    ]

    missing_variables = [
        variable
        for variable in required_variables
        if os.getenv(variable) is None
    ]

    if missing_variables:
        raise ValueError(
            "Missing environment variables: "
            + ", ".join(missing_variables)
        )

    database_url = URL.create(
        drivername="mysql+mysqlconnector",
        username=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        host=os.getenv("DB_HOST"),
        port=int(os.getenv("DB_PORT", "3306")),
        database=os.getenv("DB_NAME"),
    )

    return create_engine(
        database_url,
        future=True,
        pool_pre_ping=True,
    )


def load_csv_to_mysql(
    engine,
    file_name: str,
    table_name: str,
    encoding: str,
    rename_columns: dict | None = None,
    date_columns: list[str] | None = None,
) -> None:
    """Read one CSV file, clean required columns, and load it into MySQL."""

    file_path = RAW_DATA_DIR / file_name

    if not file_path.exists():
        raise FileNotFoundError(f"File not found: {file_path}")

    print("=" * 70)
    print(f"Reading: {file_name}")
    print(f"Target table: {table_name}")
    print(f"Encoding: {encoding}")

    dataframe = pd.read_csv(
        file_path,
        encoding=encoding,
        low_memory=False,
    )

    if rename_columns:
        dataframe = dataframe.rename(columns=rename_columns)

    if date_columns:
        for column in date_columns:
            dataframe[column] = pd.to_datetime(
                dataframe[column],
                errors="coerce",
            )

    print(f"Rows read: {len(dataframe):,}")
    print(f"Columns: {list(dataframe.columns)}")

    invalid_dates = {}

    if date_columns:
        for column in date_columns:
            invalid_dates[column] = int(dataframe[column].isna().sum())

    # Clear the target table so rerunning the script does not create duplicates.
    with engine.begin() as connection:
        connection.execute(text(f"DELETE FROM {table_name}"))

    dataframe.to_sql(
        name=table_name,
        con=engine,
        if_exists="append",
        index=False,
        chunksize=5000,
        method="multi",
    )

    with engine.connect() as connection:
        imported_rows = connection.execute(
            text(f"SELECT COUNT(*) FROM {table_name}")
        ).scalar_one()

    print(f"Rows imported: {imported_rows:,}")

    for column, count in invalid_dates.items():
        print(f"Invalid or missing dates in {column}: {count:,}")

    if imported_rows != len(dataframe):
        raise RuntimeError(
            f"Row-count mismatch for {table_name}: "
            f"CSV={len(dataframe):,}, MySQL={imported_rows:,}"
        )

    print(f"Completed: {table_name}")


def main() -> None:
    if not RAW_DATA_DIR.exists():
        raise FileNotFoundError(
            f"Raw data directory does not exist: {RAW_DATA_DIR}"
        )

    engine = get_database_engine()

    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))

        print("MySQL connection successful.")

        load_csv_to_mysql(
            engine=engine,
            file_name="JData_User.csv",
            table_name="stg_users",
            encoding="gbk",
            date_columns=["user_reg_tm"],
        )

        load_csv_to_mysql(
            engine=engine,
            file_name="JData_Product.csv",
            table_name="stg_products",
            encoding="utf-8-sig",
        )

        load_csv_to_mysql(
            engine=engine,
            file_name="JData_Comment.csv",
            table_name="stg_comments",
            encoding="utf-8-sig",
            rename_columns={"dt": "comment_date"},
            date_columns=["comment_date"],
        )

        print()
        print("=" * 70)
        print("All small tables imported successfully.")
        print("=" * 70)

    except SQLAlchemyError as error:
        print("MySQL error:")
        print(error)
        sys.exit(1)

    except Exception as error:
        print("Import failed:")
        print(error)
        sys.exit(1)

    finally:
        engine.dispose()


if __name__ == "__main__":
    main()