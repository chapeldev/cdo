module ErrorTypes {
    /*** Errors ***/

    /*
    Thrown when user tries to perform an operation on a
    connection that is not connected.
    */
    class NotConnectedError : Error {
        proc init() {}
    }

    /*
    Class for wrong connection string format or parameters.
    */
    class ConnectionStringFormatError : Error {
        proc init() {}
    }

    /*
    Class for connection errors.
    */
    class DBConnectionFailedError : Error {
        proc init() {}
    }

    /*
    Class for failure of SQL statement execution.
    */
    class QueryExecutionError : Error {
        proc init() {}
    }

    /*
    This is the base class for al SQL statement errors.
    */
    class SQLStatementError : Error {
        proc init() {}
    }

    /*
    This error is thrown when a `Statement` still contains atleast one
    unsubstituted placeholder and the user attempts to retrieve the final
    SQL statement or query, or tries to use it somewhere else.
    */
    class IncompleteStatementError : SQLStatementError {
        proc init() {}
    }

    /*
    Thrown when methods are called on an invalid row.
    */
    class InvalidRowError : Error {
        proc init() {}
    }
}