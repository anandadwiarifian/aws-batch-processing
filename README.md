# Batch Processing in AWS
The project simulates the flow of retail sales data from an online shop. The data from the online shop is stored in S3 bucket as the staging area, and then loaded to Amazon Redshift.
![image](https://user-images.githubusercontent.com/47022822/119691422-c2e1e500-be74-11eb-9a63-78930d86242b.png)

AWS account is needed to run this repo. 
Get your AWS access key and secret key by `clicking on your name -> My Security Credentials` in the AWS website.

## Setup
### Start the Airflow and Postgres containers
First, run the containers by `cd`-ing to the project file and running this code.
```
docker-compose -f docker-compose-LocalExecutor.yml up -d
```
The postgres and airflow container should be up and running now. 

### Create table and load the user purchase data to the 'data store' 
Create a postgres connection using pgcli.
```
pgcli -h localhost -p 5432 -U airflow -d airflow
```

Note that the port, username, and database name match with the ones in [docker-compose-LocalExecutor.yml](/docker-compose-LocalExecutor.yml), for postgres container.

Next, create a scheme: retail, table: user_purchase, and import the data from `setup/raw_input_data/retail/OnlineRetail.csv` 

Or just execute the [sql script](/setup/postgres/create_user_purchase.sql) by running this code in the `pg` session.

`\i setup/postgres/create_user_purchase.sql`

The pg table is now ready to act as the data source.

### Create the table in Amazon Redshift
To access the Redshift from our script, we need to create a redshift cluster.
Once the cluster is created, note down the username, database name, endpoint url, port, and iam-role for the cluster.

After that, we can access the redshift cluster from the pgcli.
```
pgcli -h <endpoint_url> -U <usernane> -d <database_name> -p <port>
```
Then, create the user_purchase_staging table by executing the [create_external_schema.sql](/setup/redshift/create_external_schema.sql) file.

The file above will create user_purchase_staging in spectrum database in external schema spectrum.
External schema means the data is stored outside S3 (database), but inside a `data catalog`, which in this case, AWS Glue.
This is to separate storage and processing since it will be cheaper than storing directly in the database.

### Airflow
You can see the script for the DAG with comments [here](/dags/user_behaviour.py).
Overall, the flow is like this
- pg_unload:

The data in the data source is filtered based on the execution of the script (for this project, the date is set to 2010-12-01) by running this sql [script](/scripts/sql/filter_unload_user_purchase.sql). The `{{ }}` variables are airflow macro variables that are set in the dag file.
The filtered data is saved to local drive in a csv.

- user_purchase_to_s3_stage:

The data in the csv file then pushed to S3 bucket

- remove_local_user_purchase_file:

After the data successfully pushed to S3 bucket, the csv is deleted from the local drive.

- user_purchase_to_rs_stage:

load user purchase data from S3 bucket to redshift, partitioned by date.

- end_of_data_pipeline:

The final task that doesn't do anything (dummy task)

Before you turn on the DAG, in the airflow GUI, `Admin -> Connections` then add `{"aws_access_key_id":"your_access_key", "aws_secret_access_key": "your_secret_ccess_key"}` in `Extra` field in `aws_default` connection.

The screenshot of the airflow GUI:
![DAG: Graph View](https://user-images.githubusercontent.com/47022822/117568817-c2afbe80-b0ec-11eb-89d9-465058967029.PNG)
![DAG: Tree View](https://user-images.githubusercontent.com/47022822/117568829-d824e880-b0ec-11eb-953e-22c12f9fff03.PNG)

The screenshot of S3 bucket:
![s3 bucket](https://user-images.githubusercontent.com/47022822/117568850-ea068b80-b0ec-11eb-9694-8c570db32283.PNG)
![s3 bucket](https://user-images.githubusercontent.com/47022822/117568852-ec68e580-b0ec-11eb-83ef-264d6c4802ff.PNG)

The screenshot of database in Redshift:
![user_purchase_staging schema](https://user-images.githubusercontent.com/47022822/117569013-ae1ff600-b0ed-11eb-8baa-40e750ea5921.PNG)
![user_purchase_staging preview](https://user-images.githubusercontent.com/47022822/117568998-95174500-b0ed-11eb-8bc5-610cafbde62b.PNG)



