all: insert_mysql_ex delete_mysql_ex update_mysql_ex mysqlex pgsql insert_pg_ex delete_pg_ex \
update_pg_ex array_agg_pg

# query_builder_ex:
# 	chpl -o ./bin/query_builder_ex ./example/query_builder_ex.chpl  -M ./src -I/usr/include/postgresql/

insert_pg_ex:
	chpl -o ./bin/insert_pg_ex ./example/insert_pg_ex.chpl  -M ./src -I/usr/include/postgresql/

delete_pg_ex:
	chpl -o ./bin/delete_pg_ex ./example/delete_pg_ex.chpl  -M ./src -I/usr/include/postgresql/

# model_pg_ex:
# 	chpl -o ./bin/model_pg_ex ./example/model_pg_ex.chpl  -M ./src -I/usr/include/postgresql/

array_agg_pg:
	chpl -o ./bin/array_agg_pg ./example/array_agg_pg.chpl  -M ./src -I/usr/include/postgresql/

# model_pg_ex2:
# 	chpl -o ./bin/model_pg_ex2 ./example/model_pg_ex2.chpl  -M ./src -I/usr/include/postgresql/
# model_pg_ex3:
# 	chpl -o ./bin/model_pg_ex3 ./example/model_pg_ex3.chpl  -M ./src -I/usr/include/postgresql/

update_pg_ex:
	chpl -o ./bin/update_pg_ex ./example/update_pg_ex.chpl  -M ./src -I/usr/include/postgresql/

pgsql:
	chpl -o ./bin/expq ./example/expq.chpl  -M ./src -I/usr/include/postgresql/ 

#WArning, you should run `mysql_config --cflags --libs` in order to know the library path
mysqlex:
	chpl -o ./bin/mysqlex ./example/exmysql.chpl ./src/mysql_helper.c ./src/mysql_helper.c  -M ./src -I./src -I/usr/include/mysql -L/usr/lib/x86_64-linux-gnu -lmysqlclient -lpthread -lz -lm -lrt -latomic -ldl

update_mysql_ex:
	chpl -o ./bin/update_mysql_ex ./example/update_mysql_ex.chpl  -M ./src  ./src/mysql_helper.c -I./src -I/usr/include/mysql -L/usr/lib/x86_64-linux-gnu -lmysqlclient -lpthread -lz -lm -lrt -latomic -ldl

delete_mysql_ex:
	chpl -o ./bin/delete_mysql_ex ./example/delete_mysql_ex.chpl  -M ./src -I/usr/include/postgresql/ ./src/mysql_helper.c -I./src -I/usr/include/mysql -L/usr/lib/x86_64-linux-gnu -lmysqlclient -lpthread -lz -lm -lrt -latomic -ldl
insert_mysql_ex:
	chpl -o ./bin/insert_mysql_ex ./example/insert_mysql_ex.chpl  -M ./src -I/usr/include/postgresql/ ./src/mysql_helper.c -I./src -I/usr/include/mysql -L/usr/lib/x86_64-linux-gnu -lmysqlclient -lpthread -lz -lm -lrt -latomic -ldl

# query_builder_mysql_ex:
# 	chpl -o ./bin/query_builder_mysql_ex ./example/query_builder_mysql_ex.chpl  -M ./src -I/usr/include/postgresql/ ./src/mysql_helper.c -I./src -I/usr/include/mysql -L/usr/lib/x86_64-linux-gnu -lmysqlclient -lpthread -lz -lm -lrt -latomic -ldl


# sqlitex:
# 	chpl -o ./bin/sqlitex ./example/exsqlite.chpl  -M ./src

tests: statements_test test_db_init mysql_connection_test mysql_cursor_test mysql_field_test mysql_transaction_test

mysql_ex1:
	chpl -o ./bin/mysql_ex1 ./example/mysql_ex1.chpl -M ./src -M ./src/mysql

mysql_ex2:
	chpl -o ./bin/mysql_ex2 ./example/mysql_ex2.chpl -M ./src -M ./src/mysql

statements_test:
	chpl -o ./bin/statements_test ./test/StatementsTest.chpl -M ./src

mysql_connection_test:
	chpl -o ./bin/mysql_connection_test ./test/mysql/ConnectionTest.chpl -M ./src -M ./src/mysql -I/usr/include/mysql
	chpl -o ./bin/mysql_connection_test_autoc ./test/mysql/ConnectionTestAutocommit.chpl -M ./src -M ./src/mysql -I/usr/include/mysql

mysql_cursor_test:
	chpl -o ./bin/mysql_cursor_test ./test/mysql/CursorTest.chpl -M ./src -M ./src/mysql -I/usr/include/mysql

mysql_field_test:
	chpl -o ./bin/mysql_field_test ./test/mysql/FieldTest.chpl -M ./src -M ./src/mysql -I/usr/include/mysql

mysql_transaction_test:
	chpl -o ./bin/mysql_transaction_test ./test/mysql/TransactionTest.chpl -M ./src -M ./src/mysql -I/usr/include/mysql

test_db_init:
	chpl -o ./bin/test_db_init ./test/mysql/TestDBInit.chpl -M ./src -M ./src/mysql -I/usr/include/mysql

clear:
	rm	pgsql
	rm	mysqlex
	# rm	sqlitex
