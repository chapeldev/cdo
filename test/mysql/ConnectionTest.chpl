use DatabaseCommunicator;
use DatabaseCommunicator.DatabaseCommunicationObjects.ErrorTypes;
use DatabaseCommunicator.DatabaseCommunicationObjects.QueryBuilder;
use UnitTest;
use MySQL;

proc simpleConnectionTest(test: borrowed Test) throws {
    var conHandler = new ConnectionHandler(MySQLConnection, "localhost;testdb;root;password");
    conHandler.close();

    // Invalid connection string, should throw exception:
    conHandler = new ConnectionHandler(MySQLConnection, "localhost;");
}

proc configConnectionTest(test: borrowed Test) throws {
    var conHandler = ConnectionHandlerWithConfig(MySQLConnection, "dbconfig.toml");
    conHandler.close();

    // different root element name in TOML file
    conHandler = ConnectionHandlerWithConfig(MySQLConnection, "dbconfig2.toml", "dbconf");
    conHandler.close();

    // wrong root element in TOML file, should throw exception:
    conHandler = ConnectionHandlerWithConfig(MySQLConnection, "dbconfig.toml", "root");
    conHandler.close();

    // Invalid file, should throw exception saying file not found
    conHandler = ConnectionHandlerWithConfig(MySQLConnection, "nofile");

    // Invalid file (not TOML), should throw TOML parsing error
    conHandler = ConnectionHandlerWithConfig(MySQLConnection, "TransactionTest.chpl");
}

proc testAutocommit(test: borrowed Test) throws {
    // Tests Part A: Connection init using autcommit specified/not specified
    // in config files

    // the config file in this does not specify autocommit
    var conHandler = ConnectionHandlerWithConfig(MySQLConnection, "dbconfig_noautoc.toml");
    test.assertTrue(conHandler.isAutocommit());
    conHandler.setAutocommit(false);
    test.assertFalse(conHandler.isAutocommit());
    conHandler.setAutocommit(true);
    test.assertTrue(conHandler.isAutocommit());
    conHandler.close();

    // the config file in this specifies autocommit as true
    conHandler = ConnectionHandlerWithConfig(MySQLConnection, "dbconfig_autoc_true.toml");
    test.assertTrue(conHandler.isAutocommit());
    // the following line is intentional
    conHandler.setAutocommit(true);
    test.assertTrue(conHandler.isAutocommit());
    conHandler.setAutocommit(false);
    test.assertFalse(conHandler.isAutocommit());
    conHandler.close();

    // config file in this specifies autocommit as false
    conHandler = ConnectionHandlerWithConfig(MySQLConnection, "dbconfig_autoc_false.toml");
    test.assertFalse(conHandler.isAutocommit());
    conHandler.setAutocommit(true);
    test.assertTrue(conHandler.isAutocommit());
    conHandler.close();

    // Tests Part B: Connection init using ConnectionHandler constructor
    
    conHandler = new ConnectionHandler(MySQLConnection, "localhost;testdb;root;password");
    test.assertTrue(conHandler.isAutocommit());
    // the following line is intentional
    conHandler.setAutocommit(true);
    test.assertTrue(conHandler.isAutocommit());
    conHandler.setAutocommit(false);
    test.assertFalse(conHandler.isAutocommit());
    conHandler.close();

    conHandler = new ConnectionHandler(MySQLConnection, "localhost;testdb;root;password", false);
    test.assertFalse(conHandler.isAutocommit());
    conHandler.setAutocommit(true);
    test.assertTrue(conHandler.isAutocommit());
    conHandler.close();
}

// Tests for other methods are located appropriately
// TODO: replace "appropriately" in above line with proper locations

UnitTest.main();