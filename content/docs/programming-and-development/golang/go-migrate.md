# Go Migrate

## install cli

`go install -tags 'sqlserver' github.com/golang-migrate/migrate/v4/cmd/migrate@latest`

best practice put in top level folder named `migrations`
for each migration create a `up.sql` and `down.sql` script with naming convention:

```sql
<incremental_version_number>_<description>.up.sql
<incremental_version_number>_<description>.down.sql
```

```sql
000001_create_new_table.up.sql
000001_create_new_table.down.sql
```

for example insert the create table statement in up
drop table statement in down


## Run migrations in cli
`migrate -database "sqlserver://<username>:<password>@<host>:<port>?database=<database>" -path ./migrations up`

`migrate -database "sqlserver://<username>:<password>@<host>:<port>?database=<database>" -path ./migrations down `

### postgres

go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

### Increment version

`migrate create -ext sql -dir ./migrations/schema create_customer_table `

### Go to version

`migrate -database $databaseurl -dir ./migrations/schema goto [v]`

### Force goto

`migrate -database $databaseurl -dir ./migrations/schema force [v] `
