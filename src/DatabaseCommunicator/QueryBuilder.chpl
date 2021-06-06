module QueryBuilder {
  use DatabaseCommunicator.DatabaseCommunicationObjects.ErrorTypes;
  use List;

  /*** Query Building ***/

  /* 
  This record helps in the creation of SQL queries and statements,
  something like `PreparedStatement` used by the JDBC in Java.
  Useful for ensuring proper data types and prevention of SQL injection.

  Note that the placeholder indices should start from 1 in the statement.

  For example: `SELECT id FROM USERS WHERE name = ?1 and address = ?2`
  The `?1` and `?2` placeholders can be replaced with setValue.
  Note that there must be atleast one space before
  the placeholder to be recognized as one.
  Hence, for `SELECT id FROM USERS WHERE name =?1 and address = ?2`,
  `?1` will not be recognized as a placeholder and `?2` will be.
  */
  class Statement {
    var _statementUnformatted: string;
    var _toSubstitute: bool;
    var _finalStatement: string;
    var _placeholderRemains: bool;
    var _placeholderIndices: list(int);

    pragma "no doc"
    
    proc _findPlaceholderIndices(statement: string) {
      // extract the placeholder indices
      // search for the pattern <space>?<int> in the statement for this
      for (i, char) in zip(0.., statement) {
        if (char == "?" && i > 0 && statement[i - 1].isSpace()) {
          if (i < statement.size - 1 && statement[i + 1].isDigit()) {
            try {
              _placeholderIndices.append(statement[i + 1]: int);
            } catch {
              writeln("[Internal Error] conversion of value from string to int failed when finding placeholder indices.");
            }
          }
        }
      }
    }

    /*
    Initialize an SQL statement.
      :arg statement: The SQL statement
      :type statement: string
      :arg toSubstitue: True if the arg `statement` contains placeholder question marks to be substituted
      :type toSubstitue: bool
    */
    
    proc init(statement: string, toSubstitute: bool = false) {
      this._statementUnformatted = statement;
      this._toSubstitute = toSubstitute;
      this._finalStatement = statement;
      this._placeholderRemains = toSubstitute;
      
      this.complete();
      this._findPlaceholderIndices(statement);
    }
    
    /*
    Initialize an SQL statement.
    The replacement values (wrgs) should be in natural order (i.e, not in the order that the placeholders appear in the statement).
      :arg statement: The SQL statement
      :type statement: string
      :arg toSubstitue: True if the arg `statement` contains placeholder question marks to be substituted
      :type toSubstitue: bool
      
      :arg args: Replacement values for the placeholders in the statement
    */

    proc init(statement: string, toSubstitute: bool, args...?n) {
      this._statementUnformatted = statement;
      this._toSubstitute = toSubstitute;
      this._finalStatement = statement;
      this._placeholderRemains = toSubstitute;

      this.complete();

      this._findPlaceholderIndices(statement);
      // since we have the replacement values in natural order
      for param at in 0..<n {
        this.setValue(at + 1, args(at));
      }
    }

    /*
    Set the value of a placeholder.
      :arg at: The placeholder index to substitute the value at (e.g.: for `?2`, the value of `at` is 2)
      :type at: int
      :arg value: The value to substitute at the placeholder index `at`
    */

    proc setValue(at: int, value: ?t) {
      if (!this._toSubstitute) {
        return;
      }

      if (this._placeholderIndices.size == 0) {
        writeln("Error: setValue() called on a statement with no placeholders. This call will not affect the statement.");
        halt();
      }

      if (this._placeholderIndices.count(at) == 0) {
        writeln("Error: setValue() called on a statement with a placeholder index not present in the statement. This call will not affect the statement.");
        halt();
      }

      var toBeReplacedWith: string;
      // TODO: add tests for SQL injection
      if (t == int(64) || t == int(32) || t == int) {
        toBeReplacedWith = value: string;
      }
      else if (t == bool) {
        toBeReplacedWith = value: string;
      }
      else {
        toBeReplacedWith = "'" + value: string + "'";
      }
      // TODO add more types like date

      // conserve the space
      this._finalStatement = this._finalStatement.replace(" ?" + at: string, " " + toBeReplacedWith);
      // TODO: add escapes for symbols
    }

    pragma "no doc"
    /*
    Checks if any placeholder remains to be substituted in the SQL statement.
      :return: if any placeholders are yet to be substituted
      :rtype: bool
    */

    proc _isPlaceholderRemaining(): bool {
      // TODO: There's a way to further optimize this placeholder checking
      // by counting the number of placeholders in init and decrementing
      // the count everytime a value is substituted.
      // This will allow _isPlaceholderRemaining() to execute in O(1)
      // instead of O(n) each time this function is called.

      // Skip the check if we've previously checked that there's none left
      if (!this._placeholderRemains) {
        return false;
      }

      // Checks if there is any pattern like: "<space>?<digit>" left in the string
      for (i, char) in zip(0.., this._finalStatement) {
        if (char == "?" && i > 0 && this._finalStatement[i - 1].isSpace()) {
          if (i < this._finalStatement.size - 1 && this._finalStatement[i + 1].isDigit()) {
            return true;
          }
        }
      }
      this._placeholderRemains = false;
      return false;
    }

    /*
    Returns the substituted, final SQL statement/query.
      :arg checkPlaceholders: whether to check if there are any placeholders 
                  left to be substituted (true by default)
      :type checkPlaceholders: bool

      :return: final substituted SQL statement/query
      :rtype: string
    */
    proc getSubstitutedStatement(checkPlaceholders: bool = true): string throws {
      // If checkPlaceholders is false, the function does not check
      // if any placeholders are yet to be substituted.
      // This has been added for flexibility on the user's end.
      if (!checkPlaceholders) {
        return this._finalStatement;
      }
      if (!this._toSubstitute) {
        return this._finalStatement;
      }

      if (this._isPlaceholderRemaining()) {
        throw new IncompleteStatementError();
      }
      return this._finalStatement;
    }
  }
}
