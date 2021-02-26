module DatabaseCommunicator {
    include module DatabaseCommunicationObjects;
    include module QueryBuilder;
    use IO;
    use TOML;

    class ConnectionHandler {
        var _connection;

        pragma "no doc"
        proc init(type className, connectionString: string, autocommit: bool) {
            if (!isSubtype(className, DatabaseCommunicationObjects.Implementables.IConnection)) {
                halt("[Error] The class specified in the constructor of ConnectionHandler should inherit IConnection.");
            }

            _connection = new className();
            _connection._connect(connectionString, autocommit);
        }

        pragma "no doc"
        proc type _getParsedTomlParams(connParams: string, configFile: string, tomlFileDbconfigRootElem: string) throws {
            const DBCONF_ROOT_ELEM = tomlFileDbconfigRootElem;

            const tomlConfigFile = open(configFile, iomode.r);
            const configs = parseToml(tomlConfigFile);
            
            var connString: string = "";

            // build the connection string by taking values from the config file
            for (i, paramName) in zip(0.., connParams.split(';')) {
                var connParamElem = configs![DBCONF_ROOT_ELEM];
                var connParamValue = connParamElem![paramName];
                var connParamValueString = connParamValue!.toString();
                connString = connString + connParamValueString.strip("\"") + ";"; 
                
                // "due to some reason, the TOML parser returns the string enclosed in quotes
                // hence the above line has to strip it
            }

            // eliminate the last ';'
            connString = connString.strip(";");

            var autocommit: bool;
            
            if (configs![DBCONF_ROOT_ELEM]!["autocommit"] != nil) {
                autocommit = (configs![DBCONF_ROOT_ELEM]!["autocommit"]!.toString()): bool;
            }
            else {
                autocommit = true;
            }

            return (connString, autocommit);
        }

        /*
        Initializes a connection handler for the given database management system using a configuration file.
        The configuration information (like username, etc.) is supplied in a TOML file.
        It should be noted that if the TOML file does not mention a value for the "autocommit" attribute, it is
        taken to be true by default.
        Arguments:

            :className: - The type name for the DBMS connection that you want to use (should inherit IConnection).
            :configFile: - Path to the TOML configuration file.
            :tomlDbconfigRootElem: - The root element in the TOML file that contains information about the DB configuration. (dbconfig) by default

        Returns: a DB connection with the specified parameters.
        */
        proc type ConnectionHandlerWithConfig(type className, configFile: string, tomlFileDbconfigRootElem: string = "dbconfig"): owned ConnectionHandler throws {
            if (!isSubtype(className, DatabaseCommunicationObjects.Implementables.IConnection)) {
                halt("[Error] The class specified in the constructor of ConnectionHandler should inherit IConnection.");
            }

            var connParams: string = className.getRequiredConnectionParameters();
            var connString: string;
            var autocommit: bool;
            (connString, autocommit) = ConnectionHandler._getParsedTomlParams(connParams, configFile, tomlFileDbconfigRootElem);

            var connection: owned ConnectionHandler = ConnectionHandler.ConnectionHandlerWithString(className, connString, autocommit);
            return connection;
        }

        /*
        Initializes a connection handler for the given database management system with the given connection string.
        For the connection string format (which differs based on the className), please check the documentation of 
        the className type.
        Arguments:

            :className: - The type name for the DBMS connection that you want to use (should inherit IConnection).
            :connectionString: - Connection string for connecting to the database.
            :autocommit: - Whether to set autocommit ON. (true by default)

        Returns: a DB connection with the given parameters.
        */
        proc type ConnectionHandlerWithString(type className, connectionString: string, autocommit: bool = true) {
            var connection: owned ConnectionHandler = new ConnectionHandler(className, connectionString, autocommit);
            return connection;
        }

        forwarding _connection except init;
    }
}
