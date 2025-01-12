# Start DB:

To start the database, run the following command:

```bash
docker-compose up -d

```

# monitor db:

```bash
`docker stats postgres-container`
```

to get the number of active connections run the following command

```bash
watch -n 1 "docker exec -i postgres-container psql -U tin -d mydb -c \"select
usename, state, application_name, count(*) over ()as total_connections
from pg_stat_activity
where state is not null;\""
```

# run the db testing script:

run the below command

```bash
npm run dev
```
