module ErrorTypes {
  /*** Errors ***/

  /*
  Thrown when user tries to perform an operation on a
  connection that is not connected.
  */
  class NotConnectedError : Error {}

  /*
  Class for wrong connection string format or parameters.
  */
  class ConnectionStringFormatError : Error {}

  /*
  Class for connection errors.
  */
  class DBConnectionFailedError : Error {}

  /*
  Class for failure of SQL statement execution.
  */
  class QueryExecutionError : Error {}

  /*
  This is the base class for al SQL statement errors.
  */
  class SQLStatementError : Error {}

  /*
  This error is thrown when a `Statement` still contains atleast one
  unsubstituted placeholder and the user attempts to retrieve the final
  SQL statement or query, or tries to use it somewhere else.
  */
  class IncompleteStatementError : SQLStatementError {}

  /*
  Thrown when methods are called on an invalid row.
  */
  class InvalidRowError : Error {}
}
