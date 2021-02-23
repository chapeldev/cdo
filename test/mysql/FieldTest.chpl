use DatabaseCommunicator;
use DatabaseCommunicator.DatabaseCommunicationObjects.QueryBuilder;
use UnitTest;
use MySQL;

proc fieldTest(test: borrowed Test) throws {
    var conHandler = ConnectionHandlerWithConfig(MySQLConnection, "dbconfig.toml");
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