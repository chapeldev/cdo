module MySQL {
    use DatabaseCommunicator.DatabaseCommunicationObjects.Implementables;
    use DatabaseCommunicator.DatabaseCommunicationObjects.ErrorTypes;
    use DatabaseCommunicator.DatabaseCommunicationObjects.QueryBuilder;
    use CPtr;
    use SysCTypes;
    use MySQLNative;
    require "mysql.h";
    require "stdio.h";
    require "helpers/mysql_helper.h", "helpers/mysql_helper.c";

    /*
    Enum that describes the data type held by a field in MySQL.
    Note: MySQL uses TINYINT(1) internally for the BOOLEAN
    data type, so BOOLEAN fields are depicted as MYSQL_TYPE_TINY.
    The field value 1 depicts true and 0 depicts false internally.
    */
    enum MySQLFieldType {MYSQL_TYPE_TINY = 0,
                MYSQL_TYPE_SHORT = 1,
                MYSQL_TYPE_LONG = 2,
                MYSQL_TYPE_INT24 = 3,
                MYSQL_TYPE_LONGLONG = 4,
                MYSQL_TYPE_DECIMAL = 5,
                MYSQL_TYPE_NEWDECIMAL = 6,
                MYSQL_TYPE_FLOAT = 7,
                MYSQL_TYPE_DOUBLE = 8,
                MYSQL_TYPE_BIT = 9,
                MYSQL_TYPE_TIMESTAMP = 10,
                MYSQL_TYPE_DATE = 11,
                MYSQL_TYPE_TIME = 12,
                MYSQL_TYPE_DATETIME = 13,
                MYSQL_TYPE_YEAR = 14,
                MYSQL_TYPE_STRING = 15,
                MYSQL_TYPE_VAR_STRING = 16,
                MYSQL_TYPE_TYPE_BLOB = 17,
                MYSQL_TYPE_SET = 18,
                MYSQL_TYPE_ENUM = 19,
                MYSQL_TYPE_GEOMETRY = 20,
                MYSQL_TYPE_NULL = 21,
                UNKNOWN_TYPE = 22}

    /*
    Class for a MySQL server connection. 
    Used to keep track of a MySQL server connection.
    */
    class MySQLConnection : IConnection {
        
        var _cptr_mysqlconn: c_ptr(MYSQL);
        var _autocommit: bool;
        var _prev_autocommit_state: bool;
        var _connected: bool;

        /*
        This procedure returns the required parameters for the connection
        as a ;-separated string.
        This information is required to parse the TOML config file provided for
        database connection and find the required parameters in it (the ;-separated
        parameters will be taken as the 'keys' to be found in the config file).
        Please ensure that this string is in the same format as the expected connection string.

            :return: the required parameters for the database connection separated by ';', as a string
            :rtype: string
        */
        override proc type getRequiredConnectionParameters(): string {
            return "host;dbname;username;password";
        }

        /*
        Explicitly connects to a database.
        Connection string format:
        <host>;<database name>;<username>;<password>
        Note that the port number can be specified in the host part itself, for example:
        localhost:5223;testdb;testuser;pwd

            :arg connectionString: the connection string to be used for connection
            :type connectionString: string

            :arg autocommit: whether to turn on autocommit
            :type autocommit: bool
        */
        override proc connect(connectionString: string, autocommit: bool = true) throws {
            // TODO: check the connection string properly

            var host: string;
            var database: string;
            var username: string;
            var password: string;

            // let's extract the relevant info from the connection string
            for (i, str) in zip(0.., connectionString.split(';')) {
                select i {
                    when 0 do host = str;
                    when 1 do database = str;
                    when 2 do username = str;
                    when 3 do password = str;
                    when 4 do throw new ConnectionStringFormatError();
                }
            }

            // Throw errors if anything wrong: (TODO: can be improved)
            if (host == '' || database == '') {
                throw new ConnectionStringFormatError();
            }

            this._autocommit = autocommit;
            this._prev_autocommit_state = autocommit;
            this._cptr_mysqlconn = mysql_init(this._cptr_mysqlconn);

            var conn_res: c_ptr(MYSQL) = mysql_real_connect(this._cptr_mysqlconn, 
                                                            host.localize().c_str(), 
                                                            username.localize().c_str(), 
                                                            password.localize().c_str(), 
                                                            database.localize().c_str(), 0, 
                                                            c_nil: c_string, 0);

            if (conn_res == c_nil) {
                writeln("[Error] Unable to connect to database!");
                writeln(createStringWithNewBuffer(mysql_error(this._cptr_mysqlconn)));
                mysql_close(this._cptr_mysqlconn);
                throw new DBConnectionFailedError();
            }

            this.setAutocommit(autocommit);
            this._connected = true;
        } 

        /*
        Constructor for the class that initializes default values.
        Note that this constructor does NOT connect to any database.
        */
        proc init() {
            this._cptr_mysqlconn = nil;
            this._autocommit = true;
            this._prev_autocommit_state = true;
            this._connected = false;
        }

        /*
        Initialize a MySQL database connection.
            :arg host: Host name/address
            :type host: string

            :arg username: username
            :type username: string

            :arg database: database name
            :type database: string

            :arg password: password
            :type password: string

            :arg autocommit: whether to enable autocommit (optional, true by default)
            :type autocommit: bool
        */
        proc init(host: string, username: string, database: string, password: string, autocommit: bool = true) {
            this._cptr_mysqlconn = nil;
            this._autocommit = autocommit;
            this._prev_autocommit_state = autocommit;

            this._cptr_mysqlconn = mysql_init(this._cptr_mysqlconn);

            var conn_res: c_ptr(MYSQL) = mysql_real_connect(this._cptr_mysqlconn, 
                                                            host.localize().c_str(), 
                                                            username.localize().c_str(), 
                                                            password.localize().c_str(), 
                                                            database.localize().c_str(), 0, 
                                                            c_nil: c_string, 0);

            if (conn_res == c_nil) {
                writeln("[Error] Unable to connect to database!");
                mysql_close(this._cptr_mysqlconn);
                // throw new DBConnectionFailedError();
            }

            this._connected = true;
            this.complete();
            this.setAutocommit(true);
        }

        /*
        Returns true if connected to a database.
        */
        proc isConnected(): bool {
            return this._connected;
        }

        pragma "no doc"
        // TODO: Use this function at the beginning of each appropriate function
        proc checkConnected() {
            if (!this._connected) {
                throw new NotConnectedError();
            }
        }

        /*
        Sets autocommit.
            :arg autocommit: whether autocommit should be enabled or not
            :type autocommit: bool
        */
        override proc setAutocommit(autocommit: bool) {
            this._prev_autocommit_state = this._autocommit;
            this._autocommit = autocommit;

            if (autocommit) {
                mysql_autocommit(this._cptr_mysqlconn, 1);
                mysql_query(this._cptr_mysqlconn, "SET autocommit = 1;");
            }
            else {
                mysql_autocommit(this._cptr_mysqlconn, 0);
                mysql_query(this._cptr_mysqlconn, "SET autocommit = 0;");
            }
        }

        /*
        Returns whether autocommit is enabled or not, for this connection.
            :return: true if autocommit is enabled, else false.
            :rtype: bool
        */
        override proc isAutocommit(): bool {
            return this._autocommit;
        }

        /*
        Returns a C pointer to the native SQL connection.
        In case of MySQL, it is a c_ptr(MYSQL).
            :return: C pointer to the native SQL connection.
            :rtype: c_ptr(MYSQL)
        */
        override proc getNativeConnection(): c_ptr(MYSQL) {
            return this._cptr_mysqlconn;
        }

        /*
        Closes the database connection.
        */
        override proc close() {
            mysql_close(this._cptr_mysqlconn);
        }

        /*
        Returns a :class:`MySQLCursor` object.
            :return: a MySQL cursor
            :rtype: MySQLCursor
        */
        override proc cursor(): owned MySQLCursor {
            return new MySQLCursor(this, this._cptr_mysqlconn);
        }

        /*
        Starts a transaction. 
        Note that after calling this method, autocommit is disabled until you call
        `commit()` or `rollback()`, so you must call `commit()` manually after
        statements that modify tables or data in them.
        After calling `commit()`, the current transaction is committed and autocommit is
        enabled again if it was previously enabled.
        */
        override proc beginTransaction() {
            this.setAutocommit(false);
            mysql_query(this._cptr_mysqlconn, "START TRANSACTION;");
        }

        /*
        Commits the current transaction.
        This method should be called to manually commit, if autocommit is disabled,
        and after `beginTransaction()` to commit the changes.
        After calling `commit()`, the current transaction is committed and autocommit is
        enabled again if it was enabled previously (that is, before the last call
        to `beginTransaction()`).
        */
        override proc commit() {
            mysql_commit(this._cptr_mysqlconn);

            // If autocommit was enabled previously and is now disabled, enable it
            // TODO: Check if it causes unintended consequences
            if (!this.isAutocommit() && (this._prev_autocommit_state == true)) {
                this.setAutocommit(true);
            }
        }

        /*
        Rolls back the current transaction.
        After calling `rollback()`, the current transaction is committed and autocommit is
        enabled again if it was enabled previously (that is, before the last call
        to `beginTransaction()`).
        */
        override proc rollback() {
            mysql_rollback(this._cptr_mysqlconn);

            // If autocommit was enabled previously and is now disabled, enable it
            // TODO: Check if it causes unintended consequences
            if (!this.isAutocommit() && (this._prev_autocommit_state == true)) {
                this.setAutocommit(true);
            }
        }
    }

    /*
    Class for a MySQL result field.
    */
    class MySQLField : IField {
        pragma "no doc"
        var _fieldIdx: int(32);

        pragma "no doc"
        var _fieldName: string;

        pragma "no doc"
        var _fieldType: MySQLFieldType;

        proc init(fieldIdx: int(32), fieldName: string, fieldType: MySQLFieldType) {
            this._fieldIdx = fieldIdx;
            this._fieldName = fieldName;
            this._fieldType = fieldType;
        }

        override proc getFieldName(): string {
            return this._fieldName;
        }

        override proc getFieldIdx(): int(32) {
            return this._fieldIdx;
        }

        override proc getFieldType(): MySQLFieldType {
            return this._fieldType;
        }
    }

    /*
    Class representing a row of result.
    */
    class MySQLRow : IRow {

        // Note: the problem here is that we can't use one single function
        // to return values of different types
        // Because of this, even if we know the field type, we cannot really
        // convert the value to that type and return it
        // because that would mean returning different types from the same function

        pragma "no doc"
        var _cptr_row: MYSQL_ROW;
        var _cptr_fields: c_ptr(MYSQL_FIELD);
        var _fieldTypes: string;
        var valid: bool;

        pragma "no doc"
        proc init(valid: bool) {
            this._cptr_fields = nil;
            this.valid = false;
        }

        pragma "no doc"
        proc init(mysqlrow: MYSQL_ROW, cfields: c_ptr(MYSQL_FIELD), valid: bool = true) {
            this._cptr_row = mysqlrow;
            this._cptr_fields = cfields;

            this.valid = valid;
            // TODO: init _fieldTypes here
        }

        proc isValid() {
            return this.valid;
        }

        /*
        Returns the value at the field number (index) specified by fieldNumber as
        the specified type. The first field is the zeroth field.
        Note that this function and its overload is valid only for those types
        that can be converted from string to that type.
        To handle the conversion yourself, use `getVal()` instead, which returns a string.
            :arg fieldNumber: the nth field whose value is required in the row (n starts from 0)
            :type fieldNumber: int(32)
            :arg t: The type to which the field value should be converted to while returning the value.
            :type t: type
            :return: the value of the fieldNumber-th field converted to type t
            :rtype: t
        */
        override proc getValAsType(fieldNumber: int(32), type t) {
            if (!this.isValid()) {
                throw new InvalidRowError();
            }
            var fieldVal: string = createStringWithNewBuffer(__get_mysql_field_val_by_number(this._cptr_row, fieldNumber));
            return fieldVal: t;
        }

        /*
        Returns the value for the field name specified by fieldName as
        the specified type.
        Note that this function and its overload is valid only for those types
        that can be converted from string to that type.
        To handle the conversion yourself, use `getVal()` instead, which returns a string.
            :arg fieldName: the name of the field whose value is required in the row (n starts from 0)
            :type fieldName: string
            :arg t: The type to which the field value should be converted to while returning the value.
            :type t: type
            :return: the value of the field with name fieldName converted to type t
            :rtype: t
        */
        override proc getValAsType(fieldName: string, type t) {
            if (!this.isValid()) {
                throw new InvalidRowError();
            }
            var fieldVal: string = createStringWithNewBuffer(__get_mysql_field_val_by_name(this._cptr_row, 
                                                                                           this._cptr_fields, 
                                                                                           fieldName.localize().c_str()));
            return fieldVal: t;
        }

        /*
        Returns the value at the specified field as a string.

            :arg fieldNumber: the value at the fieldNumber-th field will be returned (starts from 0)
            :type fieldNumber: int(32)
        */
        override proc getVal(fieldNumber: int(32)): string throws {
            if (!this.isValid()) {
                throw new InvalidRowError();
            }
            return createStringWithNewBuffer(__get_mysql_field_val_by_number(this._cptr_row, fieldNumber));
        }

        /*
        Returns the value at the specified field (with field name given) as a string.

            :arg fieldName: the value for the field fieldName wil be returned
            :type fieldName: string
        */
        override proc getVal(fieldName: string): string {
            if (!this.isValid()) {
                throw new InvalidRowError();
            }
            return createStringWithNewBuffer(__get_mysql_field_val_by_name(this._cptr_row, 
                                                                           this._cptr_fields, 
                                                                           fieldName.localize().c_str()));
        }

        proc this(fieldNumber: int(32)): string throws {
            if (!this.isValid()) {
                throw new InvalidRowError();
            }
            return this.getVal(fieldNumber);
        }

        proc this(fieldName: string): string throws {
            if (!this.isValid()) {
                throw new InvalidRowError();
            }
            return this.getVal(fieldName);
        }
    }

    /*
    Class for a MySQL cursor object.
    Implements ICursor.
    */
    class MySQLCursor : ICursor {

        var _connection: MySQLConnection;
        var _cptr_mysqlconn: c_ptr(MYSQL);
        var _cptr_result: c_ptr(MYSQL_RES);
        var _cptr_fields: c_ptr(MYSQL_FIELD);
        var _curRow: int(32) = 0;
        var _nRows: int(64);
        var _nFields: int(32);

        pragma "no doc"
        proc init(connctn: MySQLConnection, mysqlconn: c_ptr(MYSQL)) {
            this._connection = connctn;
            this._cptr_mysqlconn = mysqlconn;
            this._cptr_result = nil;
            this._cptr_fields = nil;
            this._curRow = 0;
            this._nRows = 0;
            this._nFields = 0;

            this.complete();
        }

        // Returns the last error message as a string
        proc getLastError(): string throws {
            return createStringWithNewBuffer(mysql_error(this._cptr_mysqlconn));
        }

        /*
        Returns the number of rows retrieved for SELECT statements and
        the number of rows affected for DML statements like INSERT and UPDATE.

            :return: number of rows retrieved/affected
            :rtype: int(32)
        */

        proc getRowCount(): int(32) {
            this._nRows;
        }

        /*
        Closes the cursor: resets all results and frees memory allocated for results.
        */
        override proc close() {
            mysql_free_result(this._cptr_result);
        }

        /*
        Executes an SQL statement.
            :arg statement: the SQL statement to execute, an instance of Statement
            :type statement: instance of :class:`Statement` class
        */
        override proc execute(statement: Statement) throws {
            var sqlStatement: string = statement.getSubstitutedStatement();

            if (mysql_query(this._cptr_mysqlconn, sqlStatement.localize().c_str())) {
                writeln("[Error] Query execution error.");
                writeln(createStringWithNewBuffer(mysql_error(this._cptr_mysqlconn)));
                throw new QueryExecutionError();
            }

            // TODO: store result or use result?
            this._cptr_result = mysql_store_result(this._cptr_mysqlconn);

            if ((this._cptr_result == c_nil) && (mysql_errno(this._cptr_mysqlconn) != 0)) {
                writeln("[Error] Error while storing result of query: ");
                writeln(createStringWithNewBuffer(mysql_error(this._cptr_mysqlconn)));
                throw new QueryExecutionError();
            }

            else if ((this._cptr_result == c_nil) && (mysql_errno(this._cptr_mysqlconn) == 0)) {
                // Result is nil. Should it be? Check using mysql_field_count (as per example in API docs)
                if (mysql_field_count(this._cptr_mysqlconn) == 0) {
                    this._nFields = 0;
                }
                else {
                    writeln(createStringWithNewBuffer(mysql_error(this._cptr_mysqlconn)));
                    throw new QueryExecutionError();
                }
            }

            // If all is fine and there is some result:
            else if ((this._cptr_result != c_nil) && (mysql_errno(this._cptr_mysqlconn) == 0)) {
                this._nFields = mysql_num_fields(this._cptr_result): int(32);
                this._cptr_fields = mysql_fetch_fields(this._cptr_result);
                
                this._nRows = mysql_num_rows(this._cptr_result);
            }

            else {
                writeln("[Error] Error occurred while storing result.");
                throw new QueryExecutionError();
                writeln(createStringWithNewBuffer(mysql_error(this._cptr_mysqlconn)));
            }
        }

        /*
        Execute a batch of SQL statements in a single transaction.
        Commits after their execution, or rolls back if there was an error.
            :arg statements: an array of :class:`Statement` objects to be executed
            :type statements: array of :class:`Statement` objects
        */
        override proc executeBatch(statements: [] owned Statement) throws {
            this._connection.beginTransaction();
            var hasError: bool = false;

            // TODO: memory management
            for stmt in statements {
                try {
                    this.execute(stmt);
                }
                catch err: QueryExecutionError {
                    hasError = true;
                    this._connection.rollback();

                    // re-throw the query execution error
                    throw new QueryExecutionError();
                }
            }

            if (!hasError) {
                this._connection.commit();
            }
        }

        /*
        Fetches the next row of the result set.
        Returns a row whcih gives false on calling isValid() on it.
        */
        override proc fetchone(): owned MySQLRow? {
            if (this._curRow >= this._nRows) {
                return nil;
            }

            var nextRow: MYSQL_ROW = mysql_fetch_row(this._cptr_result);
            // TODO: is there any way to check if nextRow is NULL here?
            // using nextRow == nil or nextRow == c_nil don't work

            this._curRow += 1;

            // init the row:
            var _row = new MySQLRow(nextRow, this._cptr_fields, true);
            
            return _row;
        }

        /*
        Fetches the next given number of rows in the result one by one,
        returning an iterator.
        Throws Error if howManyRows is negative.

            :args howManyRows: how many rows to return
            :type howManyRows: int(32)
        */
        override iter fetchsome(howManyRows: int(32)): owned MySQLRow? {
            if (howManyRows < 0) {
                writeln("[Error] MySQLCursor.fetchsome(howManyRows) called with howManyRows < 0");
                throw new Error();
            }

            else {
                var counter = 0;
                var _row = this.fetchone();

                while (_row != nil && counter < this._nRows && counter < howManyRows) {
                    yield _row;
                    _row = this.fetchone();
                    counter += 1;
                }
            }
        }

        /*
        Fetches all the (remaining) rows in the result, returning an iterator.
        */
        override iter fetchall(): owned MySQLRow? {
            var _row = this.fetchone();
            while (_row != nil) {
                yield _row;
                _row = this.fetchone();
            }
        }

        /*
        Fetches the nth row in the result set. Sets the seek at that row as well.
            :arg rowIdx: the row to fetch (starts from 0)
            :type rowIdx: int(32)
        */
        proc fetchrow(rowIdx: int(32)): owned MySQLRow? {
            if (rowIdx >= this._nRows) {
                return nil;
            }

            this._curRow = rowIdx;
            mysql_data_seek(this._cptr_result, rowIdx: c_int);

            var row = this.fetchone();

            return row;
        }

        /*
        Returns information about the fields, iterating over the fields.
        */
        override iter getFieldsInfo() throws {
            for i in 0..(this._nFields - 1) {
                var fieldName = createStringWithNewBuffer(__get_mysql_field_name_by_number(this._cptr_fields, i));
                var fieldType = __get_mysql_field_type_by_idx(this._cptr_fields, i);
                var fieldIdx = i;

                var mysqlFieldType: MySQLFieldType;
                try {
                    mysqlFieldType = fieldType: MySQLFieldType;
                }
                catch e: IllegalArgumentError {
                    mysqlFieldType = MySQLFieldType.UNKNOWN_TYPE;
                }
                yield new MySQLField(fieldIdx, fieldName, mysqlFieldType);
            }
        }
    }
}