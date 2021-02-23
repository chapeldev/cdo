#!/usr/bin/bash

# ensure that $CHPL_HOME is set for this user for
# successful execution of this script

cd ../..

echo "[Info] Making tests..."
make tests
cp -f ./test/mysql/configs/*.toml ./bin
cd ./bin

# start mysql server if not yet started
echo "[Info] Starting MySQL Server"
service mysql start

echo "[Info] STARTING TESTS"

echo "[Info] Running tests for Statement class"
./statements_test

echo "[Info] Initializing db"
./test_db_init

echo "[Info] Running ConnectionTest"
./mysql_connection_test

echo "[Info] Running CursorTest"
./mysql_cursor_test

echo "[Info] Running FieldTest"
./mysql_field_test

echo "[Info] Running RowTest"
./mysql_row_test

echo "[Info] Running TransactionTest"
./mysql_transaction_test