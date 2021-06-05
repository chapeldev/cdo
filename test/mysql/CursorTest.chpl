use DatabaseCommunicator;
use DatabaseCommunicator.QueryBuilder;
use UnitTest;
use MySQL;

proc cursorOpenExecuteTest(test: borrowed Test) throws {
  var conHandler = ConnectionHandler.ConnectionHandlerWithConfig(MySQLConnection, "dbconfig.toml");
  var cursor = conHandler.cursor();

  // Note: This test exists to test if the cursor executes the statements properly
  // and if an error is thrown in case the statement canno tbe executed

  // Testing if each of these statements were executed would require manually connecting to the
  // MySQL server and checking the records, as accessing and retrieving the records from here
  // would need other functions of the library, which would devoid the purpose of this test
  // being the first unit test for cursors

  // TODO: Add tests for bad statements (syntactically incorrect, etc.)
  cursor.execute(new Statement("SELECT * FROM sample"));
  cursor.execute(new Statement("INSERT INTO sample VALUES (89, 'GoodPerson', true)"));
  cursor.execute(new Statement("UPDATE sample SET Field2 = 'NicePerson' WHERE Field1 = 89"));
  cursor.execute(new Statement("DELETE FROM sample WHERE Field1 = 89"));

  cursor.close();
  conHandler.close();
}

proc cursorQueryTest(test: borrowed Test) throws {
  var conHandler = ConnectionHandler.ConnectionHandlerWithConfig(MySQLConnection, "dbconfig.toml");
  var cursor = conHandler.cursor();

  cursor.query(new Statement("SELECT * FROM sample"));

  cursor.close();
  conHandler.close();
}

proc fetchoneTest(test: borrowed Test) throws {
  var conHandler = ConnectionHandler.ConnectionHandlerWithConfig(MySQLConnection, "dbconfig.toml");
  var cursor = conHandler.cursor();

  cursor.execute(new Statement("SELECT * FROM sample"));
  var row = cursor.fetchone();

  test.assertTrue(isString(row![0]));
  test.assertTrue(isString(row![1]));
  test.assertTrue(isString(row![2]));

  cursor.close();
  conHandler.close();
}

proc fetchallTest(test: borrowed Test) throws {
  var conHandler = ConnectionHandler.ConnectionHandlerWithConfig(MySQLConnection, "dbconfig.toml");
  var cursor = conHandler.cursor();

  cursor.execute(new Statement("SELECT * FROM sample"));

  for row in cursor.fetchall() {
    writeln(row![0], "\t", row![1]);
    test.assertTrue(isString(row![0]));
    test.assertTrue(isString(row![1]));
    test.assertTrue(isString(row![2]));
  }

  cursor.close();
  conHandler.close();
}

proc executeBatchTest(test: borrowed Test) throws {
  var conHandler = ConnectionHandler.ConnectionHandlerWithConfig(MySQLConnection, "dbconfig.toml");
  var cursor = conHandler.cursor();

  var insertStatements = [new Statement("INSERT INTO sample VALUES (31, 'Person1', true)"),
              new Statement("INSERT INTO sample VALUES (32, 'Person2', true)"),
              new Statement("INSERT INTO sample VALUES (33, 'Person3', false)")];
  
  //ensure autocommit is on
  test.assertTrue(conHandler.isAutocommit());
  cursor.executeBatch(insertStatements);

  // ensure autocommit is on
  test.assertTrue(conHandler.isAutocommit());
  cursor.execute(new Statement("SELECT * from sample WHERE Field1 IN (31, 32, 33)"));

  var row1 = cursor.fetchone();
  test.assertTrue(row1![0] == "31");
  test.assertTrue(row1![1] == "Person1");
  test.assertTrue(row1![2] == "1");

  var row2 = cursor.fetchone();
  test.assertTrue(row2![0] == "32");
  test.assertTrue(row2![1] == "Person2");
  test.assertTrue(row2![2] == "1");

  var row3 = cursor.fetchone();
  test.assertTrue(row3![0] == "33");
  test.assertTrue(row3![1] == "Person3");
  test.assertTrue(row3![2] == "0");

  cursor.close();
  conHandler.close();
}

proc getFieldsInfoTest(test: borrowed Test) throws {
  var conHandler = ConnectionHandler.ConnectionHandlerWithConfig(MySQLConnection, "dbconfig.toml");
  var cursor = conHandler.cursor();

  cursor.execute(new Statement("SELECT * FROM sample"));

  for (i, fieldInfo) in zip(0.., cursor.getFieldsInfo()) {
    select i {
      when 0 do {
        test.assertTrue(fieldInfo.getFieldIdx() == 0);
        test.assertTrue(fieldInfo.getFieldName() == "Field1");
        test.assertTrue(fieldInfo.getFieldType() == MySQLFieldType.MYSQL_TYPE_LONG);
      }

      when 1 do {
        test.assertTrue(fieldInfo.getFieldIdx() == 1);
        test.assertTrue(fieldInfo.getFieldName() == "Field2");
        test.assertTrue(fieldInfo.getFieldType() == MySQLFieldType.MYSQL_TYPE_VAR_STRING);
      }

      when 2 do {
        test.assertTrue(fieldInfo.getFieldIdx() == 2);
        test.assertTrue(fieldInfo.getFieldName() == "Field3");
        test.assertTrue(fieldInfo.getFieldType() == MySQLFieldType.MYSQL_TYPE_TINY);
      }
    }
  }

  cursor.close();
  conHandler.close();
}

UnitTest.main();
