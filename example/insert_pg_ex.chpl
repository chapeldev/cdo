module Main{
use Cdo;
use Postgres;
use List;

proc main(){
    //Open connection with Postgres database. Parametrs are host,username, database, password
    var con = PgConnectionFactory("localhost", "krishna", "teste", "krishna");
    //Open a cursor
    var cursor = con.cursor();
        
    // Type for single datum
    type DataTuple = 2*string;

    // Array of data
    var data:list(DataTuple);
    // Data to be stored
    data.append(("John","john@email.co"));
    data.append(("Mary","marry@email.co"));
    data.append(("Paul","paul@email.co"));

    // Simple insert in Data
    for datum in data {
        cursor.execute("INSERT INTO public.contacts(\"name\",\"email\") VALUES ('%s','%s')",datum);
    }

    // class holding the data 
    class MyContact{
        var name: string;
        var email: string;
        proc init(name: string, email: string){
            this.name = name;
            this.email = email;
        }
    }

    var obj = new unmanaged MyContact("Maria", "maria@marcos.com.br");
    // Insert object into database.
    writeln(cursor.insertRecord("public.contacts", obj));
    //Select 
    cursor.query("SELECT * FROM public.contacts");
    //Get results
    for row in  cursor{
        writeln(row["name"],"  ", row["email"]);
    }

    cursor.close();
    con.close();
    writeln("End");
}
}