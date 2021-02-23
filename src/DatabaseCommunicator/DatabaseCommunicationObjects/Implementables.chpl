module Implementables {
    use super.QueryBuilder;
    /*
    The `IConnection` class provides an interface that needs to be
    implemented by all database connector classes.
    */
    class IConnection {
        proc connect(connectionString: string, autocommit: bool = true) throws {}
        proc type getRequiredConnectionParameters(): string {return nil;}
        proc cursor(): ICursor {return nil;}
        proc close() {}
        proc setAutocommit(autocommit: bool) {}
        proc isAutocommit(): bool {return nil;}
        proc rollback(): bool {return nil;}

        proc getNativeConnection(): opaque {
            // TODO: ref intent instead of opaque?
            return nil;
        }

        proc beginTransaction() {}
        proc commit() {}
        proc rollback() {}
    }

    /*
    The `ICursor` class provides an interface that needs to be
    implemented by all database cursor classes.
    */
    class ICursor {
        proc execute(statement: Statement) throws {}
        proc executeBatch(statements: [] owned Statement) {}
        proc query(statement: Statement) {}
        proc fetchone() {}
        iter fetchsome(howManyRows: int(32)) {}
        iter fetchall() {}
        proc close() {}

        proc __resetFields() {}
        proc __addField() {}
        iter getFieldsInfo() {}
    }

    /*
    The base class for a field of the returned result.
    This class needs to be implemented by all field info classes.
    */
    class IField {
        proc getFieldType() {} // returns an enum type specific to the implementation
        proc getFieldIdx(): int(32) {} // TODO: rename to getFieldIndex() ?
        proc getFieldName(): string {}
    }

    /*
    The base class for a row  of the returned result.
    This class needs to be implemented by all row classes.
    */
    class IRow {
        // A single function can't return different types of values
        // hence the first two methods
        
        proc getValAsType(fieldNumber: int(32), type t) {}
        proc getValAsType(fieldName: string, type t) {}

        proc getVal(fieldNumber: int(32)): string {}
        proc getVal(fieldName: string): string {}
    }
}