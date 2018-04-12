module Main{
use Cdo;
use Postgres;
use Time;
proc main(){
    //Open connection with Postgres database. Parametrs are host,username, database, password
        var con = PgConnectionFactory("localhost", "postgres", "test", "password");
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

    var i=0;

    while(i<100000){
        writeln("Inserting I=",i);
        
        data.push_back(("Brian"+(i:string),"brian@email.co"+(i:string)));
        data.push_back(("Kerim"+(i:string),"kerim@email.co"+(i:string)));
    i+=1;
    }

    var t: Timer; 
            t.start(); 
                cursor.execute("INSERT INTO public.contacts(\"name\",\"email\") VALUES ('%s','%s')",data);
            t.stop();

//Select 

    var t2: Timer; 
            t2.start();
    cursor.query("SELECT * FROM public.contacts");
    //Get results
    for row in  cursor{
        writeln(row["name"],"  ", row["email"]);
    }

    t2.stop();

    writeln("Insert time", t.elapsed());
    writeln("query time", t2.elapsed());

    cursor.close();
    con.close();
    writeln("End");
  }
}