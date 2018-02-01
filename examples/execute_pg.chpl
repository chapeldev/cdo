module Main{
use Cdo;
use Postgres;

proc main(){
    //Open connection with Postgres database. Parametrs are host,username, database, password
        var con = PgConnectionFactory("localhost", "postgres", "test", "password");
        //Open a cursor
        var cursor = con.cursor();
      
// Array of tuple
    type MyTuple =(string,string); 
    var data:[{1..0}]MyTuple;
// Data to be stored

    data.push_back(("John","john@email.co"));
    data.push_back(("Mary","marry@email.co"));
    data.push_back(("Paul","paul@email.co"));
    
    cursor.execute("INSERT INTO public.contacts(\"name\",\"email\") VALUES ('%s','%s')",data);
 
    cursor.close();
    con.close();
    writeln("End");
  }
}