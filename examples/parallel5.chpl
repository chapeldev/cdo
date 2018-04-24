module Main{
use Cdo;
use Postgres;
use Time;
proc main(){

var pcon = new PgParallelConnection("localhost", "postgres", "test", "password");

    



    // Type for single datum
    type DataTuple = 2*string;

// Array of data
    var data:[{1..0}]DataTuple;
// Data to be stored
    
    var i=0;
    while(i<100000){
        writeln("Creating data I=",i);
        data.push_back(("Brian"+(i:string),"brian@email.co"+(i:string)));
        data.push_back(("Kerim"+(i:string),"kerim@email.co"+(i:string)));
    i+=1;
    }

    var t:Timer;

    t.start();

    //Columns names array
    var cols:[1..2]string=["name","email"];

    //Batch insert tuples array. parameters are table name, column's name array, data containing the tuples array
    pcon.insertTuples("public.contacts",cols,data);
    
    t.stop();

    writeln("Insert time ",t.elapsed());

    
  }



}