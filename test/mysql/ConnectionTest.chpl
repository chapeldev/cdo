use DatabaseCommunicator;
use DatabaseCommunicator.DatabaseCommunicationObjects.ErrorTypes;
use DatabaseCommunicator.QueryBuilder;
use UnitTest;
use MySQL;

proc configConnectionTestNormal(test: borrowed Test) throws {
    var conHandler = ConnectionHandler.ConnectionHandlerWithConfig(MySQLConnection, "dbconfig.toml");
    conHandler.close();
}

proc configConnectionTestDifferentRootElem(test: borrowed Test) throws {
    // different root element name in TOML file
    var conHandler = ConnectionHandler.ConnectionHandlerWithConfig(MySQLConnection, "dbconfig2.toml", "dbconf");
    conHandler.close();
}

// TODO: Figure out a way to run all the follwing tests in one go
// Currently, the TOML library halts on an error so all of these can't run unless each
// function is isolated in a different file.

proc configConnectionTestWrongRootElem(test: borrowed Test) throws {
    // wrong root element in TOML file, should throw exception:
    var conHandler = ConnectionHandler.ConnectionHandlerWithConfig(MySQLConnection, "dbconfig.toml", "root");
    conHandler.close();
}

proc configConnectionTestInvalidFile(test: borrowed Test) throws {
    // Invalid file, should throw exception saying file not found
    var conHandler = ConnectionHandler.ConnectionHandlerWithConfig(MySQLConnection, "nofile");
}

proc configConnectionTestTomlParseError(test: borrowed Test) throws {
    // Invalid file (not TOML), should throw TOML parsing error
    var conHandler = ConnectionHandler.ConnectionHandlerWithConfig(MySQLConnection, "TransactionTest.chpl");
}

UnitTest.main();
