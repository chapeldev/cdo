#!/usr/bin/bash

# ensure that $CHPL_HOME is set for this user for
# successful execution of this script

if [ $(pwd) == *"test/mysql" ]
then
  cd ../..
fi

compiletests=1

if [ $# -ge 1 ] && [ $1 == "--no-compile" ]
then
  compiletests=0
fi

if [ $compiletests -eq 1 ]
then
  echo "[Info] Making tests..."
  make tests
  cp -f ./test/mysql/configs/*.toml ./bin
fi
cd ./bin

# start mysql server if not yet started
echo "[Info] Starting MySQL Server"
service mysql start

echo "[Info] STARTING TESTS"

echo "[Info] Running tests for Statement class"
./statements_test

echo "[Info] Populating test DB table"
./test_db_init

echo "[Info] Running ConnectionTest"
./mysql_connection_test

echo "[Info] Running ConnectionTestAutocommit"
./mysql_connection_test_autoc

echo "[Info] Running CursorTest"
./mysql_cursor_test

echo "[Info] Running FieldTest"
./mysql_field_test

echo "[Info] Running TransactionTest"
./mysql_transaction_test
