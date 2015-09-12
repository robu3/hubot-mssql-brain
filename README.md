# hubot-mssql-brain

Stores Hubot's brain in SQL Server.

## Setup

You will need to set a new environment variable, HUBOT_MSSQL_CONNECTION, to a connection string of the the following form: server|db_name|username|password

Then run the following SQL to setup the table for storage:

```sql
create table hubot_brain (
 id int identity primary key,
 storage nvarchar(max)
)

insert into hubot_brain
values(1, null)
```

## Shoutouts

Thanks to danthompson and the pg-brain script for inspiration: https://github.com/github/hubot-scripts/blob/master/src/scripts/pg-brain.coffee
