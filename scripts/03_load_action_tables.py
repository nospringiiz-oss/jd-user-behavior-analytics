from pathlib import Path
import os
import sys
import time

import mysql.connector
from dotenv import load_dotenv
from mysql.connector import Error


PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"
ENV_FILE = PROJECT_ROOT / ".env"

ACTION_FILES = [
    "JData_Action_201602.csv",
    "JData_Action_201603.csv",
    "JData_Action_201604.csv",
]


def get_connection():
    """Create a MySQL connection from the .env configuration."""

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
        if not os.getenv(variable)
    ]

    if missing_variables:
        raise ValueError(
            "Missing environment variables: "
            + ", ".join(missing_variables)
        )

    return mysql.connector.connect(
        host=os.getenv("DB_HOST"),
        port=int(os.getenv("DB_PORT", "3306")),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME"),
        allow_local_infile=True,
        autocommit=False,
    )


def format_duration(seconds: float) -> str:
    minutes, remaining_seconds = divmod(int(seconds), 60)
    hours, minutes = divmod(minutes, 60)

    if hours:
        return f"{hours}h {minutes}m {remaining_seconds}s"

    if minutes:
        return f"{minutes}m {remaining_seconds}s"

    return f"{remaining_seconds}s"


def load_action_file(cursor, connection, file_path: Path) -> int:
    """Load one action CSV into the staging action table."""

    mysql_path = file_path.resolve().as_posix().replace("'", "''")

    cursor.execute("SELECT COUNT(*) FROM stg_actions")
    rows_before = cursor.fetchone()[0]

    load_sql = f"""
        LOAD DATA LOCAL INFILE '{mysql_path}'
        INTO TABLE stg_actions
        CHARACTER SET utf8mb4
        FIELDS TERMINATED BY ','
        OPTIONALLY ENCLOSED BY '"'
        LINES TERMINATED BY '\\n'
        IGNORE 1 LINES
        (
            @user_id,
            @sku_id,
            @action_time,
            @model_id,
            @action_type,
            @cate,
            @brand
        )
        SET
            user_id = NULLIF(TRIM(@user_id), ''),
            sku_id = NULLIF(TRIM(@sku_id), ''),
            action_time = STR_TO_DATE(
                TRIM(@action_time),
                '%Y-%m-%d %H:%i:%s'
            ),
            model_id = NULLIF(TRIM(@model_id), ''),
            action_type = NULLIF(TRIM(@action_type), ''),
            cate = NULLIF(TRIM(@cate), ''),
            brand = NULLIF(
                REPLACE(TRIM(@brand), '\\r', ''),
                ''
            )
    """

    cursor.execute(load_sql)
    connection.commit()

    cursor.execute("SELECT COUNT(*) FROM stg_actions")
    rows_after = cursor.fetchone()[0]

    return rows_after - rows_before


def main() -> None:
    for file_name in ACTION_FILES:
        file_path = RAW_DATA_DIR / file_name

        if not file_path.exists():
            raise FileNotFoundError(f"File not found: {file_path}")

    connection = None
    cursor = None
    total_start = time.perf_counter()

    try:
        connection = get_connection()
        cursor = connection.cursor()

        print("MySQL connection successful.")

        cursor.execute("SHOW GLOBAL VARIABLES LIKE 'local_infile'")
        local_infile_result = cursor.fetchone()

        if local_infile_result:
            print(
                f"MySQL local_infile status: "
                f"{local_infile_result[1]}"
            )

        if local_infile_result and local_infile_result[1].upper() != "ON":
            print("Enabling MySQL local_infile...")

            cursor.execute("SET GLOBAL local_infile = 1")
            connection.commit()

        print("Clearing stg_actions...")
        cursor.execute("TRUNCATE TABLE stg_actions")
        connection.commit()

        for file_name in ACTION_FILES:
            file_path = RAW_DATA_DIR / file_name
            file_size_mb = file_path.stat().st_size / (1024 ** 2)

            print()
            print("=" * 70)
            print(f"Loading: {file_name}")
            print(f"File size: {file_size_mb:,.2f} MB")

            file_start = time.perf_counter()

            imported_rows = load_action_file(
                cursor=cursor,
                connection=connection,
                file_path=file_path,
            )

            elapsed = time.perf_counter() - file_start

            print(f"Rows imported: {imported_rows:,}")
            print(f"Time used: {format_duration(elapsed)}")

        cursor.execute("SELECT COUNT(*) FROM stg_actions")
        total_rows = cursor.fetchone()[0]

        total_elapsed = time.perf_counter() - total_start

        print()
        print("=" * 70)
        print("All action files imported successfully.")
        print(f"Total rows: {total_rows:,}")
        print(f"Total time: {format_duration(total_elapsed)}")
        print("=" * 70)

    except Error as error:
        if connection:
            connection.rollback()

        print("MySQL import error:")
        print(error)
        sys.exit(1)

    except Exception as error:
        if connection:
            connection.rollback()

        print("Import failed:")
        print(error)
        sys.exit(1)

    finally:
        if cursor:
            cursor.close()

        if connection and connection.is_connected():
            connection.close()


if __name__ == "__main__":
    main()