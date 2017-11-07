pgsql:
	chpl -o expq ./examples/expq.chpl -M ./src

#WArning, you should run `mysql_config --cflags --libs` in order to know the library path
mysqlex:
	chpl -o mysqlex ./examples/exmysql.chpl ./src/mysql_helper.c ./src/mysql_helper.c    -M ./src -I./src -I/usr/include/mysql -L/usr/lib/x86_64-linux-gnu -lmysqlclient -lpthread -lz -lm -lrt -latomic -ldl

sqlitex:
	chpl -o sqlitex ./examples/exsqlite.chpl    -M ./src
