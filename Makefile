
query_builder_ex:
	chpl -o ./bin/query_builder_ex ./examples/query_builder_ex.chpl  -M ./src -I/usr/include/postgresql/

execute_pg:
	chpl -o ./bin/execute_pg ./examples/execute_pg.chpl  -M ./src -I/usr/include/postgresql/


insert_pg_ex:
	chpl -o ./bin/insert_pg_ex ./examples/insert_pg_ex.chpl  -M ./src -I/usr/include/postgresql/

insert_domain_pg:
	chpl -o ./bin/insert_domain_pg ./examples/insert_domain_pg.chpl  -M ./src -I/usr/include/postgresql/

delete_pg_ex:
	chpl -o ./bin/delete_pg_ex ./examples/delete_pg_ex.chpl  -M ./src -I/usr/include/postgresql/

model_pg_ex:
	chpl -o ./bin/model_pg_ex ./examples/model_pg_ex.chpl  -M ./src -I/usr/include/postgresql/

parallel:
	chpl -o ./bin/parallel ./examples/parallel.chpl  -M ./src -I/usr/include/postgresql/

array_agg_pg:
	chpl -o ./bin/array_agg_pg ./examples/array_agg_pg.chpl  -M ./src -I/usr/include/postgresql/

model_pg_ex2:
	chpl -o ./bin/model_pg_ex2 ./examples/model_pg_ex2.chpl  -M ./src -I/usr/include/postgresql/
model_pg_ex3:
	chpl -o ./bin/model_pg_ex3 ./examples/model_pg_ex3.chpl  -M ./src -I/usr/include/postgresql/
update_pg_ex:
	chpl -o ./bin/update_pg_ex ./examples/update_pg_ex.chpl  -M ./src -I/usr/include/postgresql/

pgsql:
	chpl -o ./bin/expq ./examples/expq.chpl  -M ./src -I/usr/include/postgresql/ 

#WArning, you should run `mysql_config --cflags --libs` in order to know the library path
mysqlex:
	chpl -o ./bin/mysqlex ./examples/exmysql.chpl ./src/mysql_helper.c ./src/mysql_helper.c    -M ./src -I./src -I/usr/include/mysql -L/usr/lib/x86_64-linux-gnu -lmysqlclient -lpthread -lz -lm -lrt -latomic -ldl

update_mysql_ex:
	chpl -o ./bin/update_mysql_ex ./examples/update_mysql_ex.chpl  -M ./src  ./src/mysql_helper.c -I./src -I/usr/include/mysql -L/usr/lib/x86_64-linux-gnu -lmysqlclient -lpthread -lz -lm -lrt -latomic -ldl

delete_mysql_ex:
	chpl -o ./bin/delete_mysql_ex ./examples/delete_mysql_ex.chpl  -M ./src -I/usr/include/postgresql/ ./src/mysql_helper.c -I./src -I/usr/include/mysql -L/usr/lib/x86_64-linux-gnu -lmysqlclient -lpthread -lz -lm -lrt -latomic -ldl
insert_mysql_ex:
	chpl -o ./bin/insert_mysql_ex ./examples/insert_mysql_ex.chpl  -M ./src  ./src/mysql_helper.c -I./src -I/usr/include/mysql -L/usr/lib/x86_64-linux-gnu -lmysqlclient -lpthread -lz -lm -lrt -latomic -ldl

query_builder_mysql_ex:
	chpl -o ./bin/query_builder_mysql_ex ./examples/query_builder_mysql_ex.chpl  -M ./src  ./src/mysql_helper.c -I./src -I/usr/include/mysql -L/usr/lib/x86_64-linux-gnu -lmysqlclient -lpthread -lz -lm -lrt -latomic -ldl

sqlitex:
	chpl -o ./bin/sqlitex ./examples/exsqlite.chpl    -M ./src

clear:
	rm	pgsql
	rm	mysqlex
	rm	sqlitex
