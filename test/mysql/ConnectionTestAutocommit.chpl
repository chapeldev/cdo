use DatabaseCommunicator;
use DatabaseCommunicator.DatabaseCommunicationObjects.ErrorTypes;
use DatabaseCommunicator.QueryBuilder;
use UnitTest;
use MySQL;

// Autocommit Tests Part A: Connection init using autcommit specified/not specified
// in config files
proc testAutocommitNoAutocommitInConfigFile(test: borrowed Test) throws {
    // the config file in this does not specify autocommit
    var conHandler = ConnectionHandler.ConnectionHandlerWithConfig(MySQLConnection, "dbconfig_noautoc.toml");
    test.assertTrue(conHandler.isAutocommit());
    conHandler.setAutocommit(false);
    test.assertFalse(conHandler.isAutocommit());
    conHandler.setAutocommit(true);
    test.assertTrue(conHandler.isAutocommit());
    conHandler.close();
}

proc testAutocommitTrueInConfigFile(test: borrowed Test) throws {
    var conHandler = ConnectionHandler.ConnectionHandlerWithConfig(MySQLConnection, "dbconfig_noautoc.toml");
    // the config file in this specifies autocommit as true
    conHandler = ConnectionHandler.ConnectionHandlerWithConfig(MySQLConnection, "dbconfig_autoc_true.toml");
    test.assertTrue(conHandler.isAutocommit());
    // the following line is intentional
    conHandler.setAutocommit(true);
    test.assertTrue(conHandler.isAutocommit());
    conHandler.setAutocommit(false);
    test.assertFalse(conHandler.isAutocommit());
    conHandler.close();
}

proc testAutocommitFalseInConfigFile(test: borrowed Test) throws {
    var conHandler = ConnectionHandler.ConnectionHandlerWithConfig(MySQLConnection, "dbconfig_noautoc.toml");
    // config file in this specifies autocommit as false
    conHandler = ConnectionHandler.ConnectionHandlerWithConfig(MySQLConnection, "dbconfig_autoc_false.toml");
    test.assertFalse(conHandler.isAutocommit());
    conHandler.setAutocommit(true);
    test.assertTrue(conHandler.isAutocommit());
    conHandler.close();
}

// Autocommit Tests Part B: Connection init using ConnectionHandler constructor
proc testAutocommitDefaultTrueUsingConnString(test: borrowed Test) throws {
    var conHandler = ConnectionHandler.ConnectionHandlerWithString(MySQLConnection, "localhost;testdb;root;password");
    test.assertTrue(conHandler.isAutocommit());
    // the following line is intentional
    conHandler.setAutocommit(true);
    test.assertTrue(conHandler.isAutocommit());
    conHandler.setAutocommit(false);
    test.assertFalse(conHandler.isAutocommit());
    conHandler.close();
}

proc testAutocommitFalseUsingConnString(test: borrowed Test) throws {
    var conHandler = ConnectionHandler.ConnectionHandlerWithConfig(MySQLConnection, "dbconfig_noautoc.toml");
    conHandler = ConnectionHandler.ConnectionHandlerWithString(MySQLConnection, "localhost;testdb;root;password", false);
    test.assertFalse(conHandler.isAutocommit());
    conHandler.setAutocommit(true);
    test.assertTrue(conHandler.isAutocommit());
    conHandler.close();
}

proc simpleConnectionTest(test: borrowed Test) throws {
    var conHandler = ConnectionHandler.ConnectionHandlerWithString(MySQLConnection, "localhost;testdb;root;password");
    conHandler.close();

    // Invalid connection string, should throw exception:
    conHandler = ConnectionHandler.ConnectionHandlerWithString(MySQLConnection, "localhost;");
}

UnitTest.main();