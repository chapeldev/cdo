use DatabaseCommunicator;
use DatabaseCommunicator.DatabaseCommunicationObjects.QueryBuilder;
use UnitTest;
use MySQL;

proc simpleTransactionTest(test: borrowed Test) throws {
    var conHandler = ConnectionHandlerWithConfig(MySQLConnection, "dbconfig.toml");
    var cursor = conHandler.cursor();

    test.assertTrue(conHandler.isAutocommit());

    conHandler.beginTransaction();
    test.assertFalse(conHandler.isAutocommit());

    cursor.execute(new Statement("INSERT INTO sample VALUES (10, 'Sample', true)"));
    cursor.execute(new Statement("INSERT INTO sample VALUES (11, 'Sample2', true)"));

    conHandler.commit();
    test.assertTrue(conHandler.isAutocommit());

    cursor.close();
    conHandler.close();
}

proc transactionRollbackTest(test: borrowed Test) throws {
    var conHandler = ConnectionHandlerWithConfig(MySQLConnection, "dbconfig.toml");
    var cursor = conHandler.cursor();

    test.assertTrue(conHandler.isAutocommit());

    conHandler.beginTransaction();
    test.assertFalse(conHandler.isAutocommit());

    cursor.execute(new Statement("INSERT INTO sample VALUES (20, 'Sample', true)"));
    cursor.execute(new Statement("INSERT INTO sample VALUES (21, 'Sample2', true)"));

    conHandler.rollback();
    test.assertTrue(conHandler.isAutocommit());

    cursor.close();
    conHandler.close();
}

UnitTest.main();