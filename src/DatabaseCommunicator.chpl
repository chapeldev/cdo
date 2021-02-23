module DatabaseCommunicator {
    include module DatabaseCommunicationObjects;
    use IO;
    use TOML;

    /*
    Initializes a connection handler for the given database management system.
    The configuration information (like username, etc.) are supplied as a TOML file.
    */
    proc ConnectionHandlerWithConfig(type className, configFile: string, tomlFileDbconfigRootElem: string = "dbconfig"): owned ConnectionHandler throws {
        if (!isSubtype(className, DatabaseCommunicationObjects.Implementables.IConnection)) {
            halt("[Error] The class specified in the constructor of ConnectionHandler should inherit IConnection.");
        }

        const DBCONF_ROOT_ELEM = tomlFileDbconfigRootElem;

        const tomlConfigFile = open(configFile, iomode.r);
        const configs = parseToml(tomlConfigFile);

        var connParams: string = className.getRequiredConnectionParameters();
        var connString: string = "";

        // build the connection string by taking vaues from the config file
        for (i, str) in zip(0.., connParams.split(';')) {
            var connParamValue = configs![DBCONF_ROOT_ELEM]![str]!.toString();
            connString = connString + connParamValue.strip("\"") + ";"; 
            
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

        var connection: owned ConnectionHandler = new ConnectionHandler(className, connString, autocommit);
        return connection;
    }

    class ConnectionHandler {
        var _connection;

        /*
        Initializes a connection handler for the given database management system.
        */
        proc init(type className, connectionString: string, autocommit: bool = true) {
            if (!isSubtype(className, DatabaseCommunicationObjects.Implementables.IConnection)) {
                halt("[Error] The class specified in the constructor of ConnectionHandler should inherit IConnection.");
            }

            _connection = new className();
            _connection.connect(connectionString, autocommit);
        }

        forwarding _connection except init;
    }
}