module Main{
use Cdo;
use Mysql;

proc main(){
    //Open connection with Postgres database. Parametrs are host,username, database, password
         var con = MysqlConnectionFactory("localhost", "root", "teste", "root");        //Open a cursor
        //Open a cursor
        var cursor = con.cursor();
      
    // Type for single datum
    type DataTuple = 2*string;

// Array of data
    var data:[{1..3}]DataTuple;
// Data to be stored
    data[1]=("John","john@email.co");
    data[2]=("Mary","marry@email.co");
    data[3]=("Paul","paul@email.co");

// Simple insert in Data
    for datum in data{
        cursor.execute("INSERT INTO contacts(name,email) VALUES ('%s','%s')",datum);
    }

// class holding the data 
    class MyContact{
      var name:string;
      var email:string;
      proc MyContact(name:string, email:string){
          this.name = name;
          this.email = email;
      }
    }

    var obj = new MyContact("Maria", "maria@marcos.com.br");
    // Insert object into database.
    writeln(cursor.insertRecord("contacts", obj));
//Select 
    cursor.query("SELECT * FROM contacts");
    //Get results
    for row in  cursor{
        writeln(row["id"],row["name"],"  ", row["email"]);
    }
    cursor.close();
    con.close();
    writeln("End");
  }
}