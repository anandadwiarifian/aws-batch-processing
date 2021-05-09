create external schema spectrum 
from data catalog 
database 'spectrumdb' 
iam_role '<your-iam-role-ARN>'
create external database if not exists;

-- user purchase staging table with an insert_date partition
-- drop table if exists spectrum.user_purchase_staging;
create external table spectrum.user_purchase_staging (
    InvoiceNo varchar(10),
    StockCode varchar(20),
    detail varchar(1000),
    Quantity integer,
    InvoiceDate timestamp,
    UnitPrice decimal(8,3),
    customerid integer,
    Country varchar(20)
)
partitioned by (insert_date date)
row format delimited fields terminated by ','
stored as textfile
location 's3://<bucket-name>/user_purchase/stage/'
table properties ('skip.header.line.count'='1');

