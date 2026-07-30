from pathlib import Path
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"

POSSIBLE_ENCODINGS = [
    "utf-8-sig",
    "utf-8",
    "gbk",
    "gb18030",
]


def format_size(size_bytes: int) -> str:
    """Convert bytes to a readable file size."""
    units = ["B", "KB", "MB", "GB", "TB"]
    size = float(size_bytes)

    for unit in units:
        if size < 1024 or unit == units[-1]:
            return f"{size:.2f} {unit}"
        size /= 1024

    return f"{size_bytes} B"


def read_csv_sample(file_path: Path, rows: int = 5):
    """Try several common encodings and return a small sample."""
    last_error = None

    for encoding in POSSIBLE_ENCODINGS:
        try:
            dataframe = pd.read_csv(
                file_path,
                nrows=rows,
                encoding=encoding,
                low_memory=False,
            )
            return dataframe, encoding
        except UnicodeDecodeError as error:
            last_error = error
        except Exception as error:
            last_error = error

    raise RuntimeError(
        f"Unable to read {file_path.name}. Last error: {last_error}"
    )


def main() -> None:
    if not RAW_DATA_DIR.exists():
        raise FileNotFoundError(
            f"Raw data directory does not exist: {RAW_DATA_DIR}"
        )

    csv_files = sorted(RAW_DATA_DIR.glob("*.csv"))

    if not csv_files:
        print(f"No CSV files found in: {RAW_DATA_DIR}")
        return

    print("=" * 80)
    print("JD.COM RAW DATA PROFILE")
    print(f"Data directory: {RAW_DATA_DIR}")
    print(f"CSV files found: {len(csv_files)}")
    print("=" * 80)

    for file_path in csv_files:
        print()
        print("-" * 80)
        print(f"File: {file_path.name}")
        print(f"Size: {format_size(file_path.stat().st_size)}")

        try:
            sample, encoding = read_csv_sample(file_path)

            print(f"Detected encoding: {encoding}")
            print(f"Column count: {len(sample.columns)}")
            print("Columns:")

            for index, column in enumerate(sample.columns, start=1):
                print(f"  {index}. {column}")

            print("\nDetected data types:")
            print(sample.dtypes.to_string())

            print("\nFirst five rows:")
            print(sample.head().to_string(index=False))

            print("\nMissing values in sample:")
            print(sample.isna().sum().to_string())

        except Exception as error:
            print(f"ERROR: {error}")

    print()
    print("=" * 80)
    print("Profile completed.")
    print("=" * 80)


if __name__ == "__main__":
    main()