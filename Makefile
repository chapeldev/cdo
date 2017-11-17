
query_builder_ex:
	chpl -o ./bin/query_builder_ex ./examples/query_builder_ex.chpl  -M ./src -I/usr/include/postgresql/

insert_pg_ex:
	chpl -o ./bin/insert_pg_ex ./examples/insert_pg_ex.chpl  -M ./src -I/usr/include/postgresql/

delete_pg_ex:
	chpl -o ./bin/delete_pg_ex ./examples/delete_pg_ex.chpl  -M ./src -I/usr/include/postgresql/


update_pg_ex:
	chpl -o ./bin/update_pg_ex ./examples/update_pg_ex.chpl  -M ./src -I/usr/include/postgresql/

pgsql:
	chpl -o ./bin/expq ./examples/expq.chpl  -M ./src -I/usr/include/postgresql/ 

#WArning, you should run `mysql_config --cflags --libs` in order to know the library path
mysqlex:
	chpl -o ./bin/mysqlex ./examples/exmysql.chpl ./src/mysql_helper.c ./src/mysql_helper.c    -M ./src -I./src -I/usr/include/mysql -L/usr/lib/x86_64-linux-gnu -lmysqlclient -lpthread -lz -lm -lrt -latomic -ldl

sqlitex:
	chpl -o ./bin/sqlitex ./examples/exsqlite.chpl    -M ./src

clear:
	rm	pgsql
	rm	mysqlex
	rm	sqlitex

