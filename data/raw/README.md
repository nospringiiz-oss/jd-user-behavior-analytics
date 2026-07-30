# Raw Data

The raw JD.com JData2016 CSV files are not included in this repository because of their large file size and dataset distribution requirements.

## Dataset Source

Download the dataset from Kaggle:

https://www.kaggle.com/datasets/owincontext/jdata2016

## Expected Files

Place the following files in this directory before running the Python ingestion scripts:

- `JData_User.csv`
- `JData_Product.csv`
- `JData_Comment.csv`
- `JData_Action_201602.csv`
- `JData_Action_201603.csv`
- `JData_Action_201604.csv`

## Local Directory

```text
data/raw/
```

## Notes

- The raw files are excluded from GitHub.
- Do not rename the source files unless the ingestion scripts are updated.
- `JData_User.csv` uses GBK encoding.
- The product, comment, and action files use UTF-8-SIG encoding.
- The action files contain more than 50 million behavioural records in total.
