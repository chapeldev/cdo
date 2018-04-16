module Main{
use Cdo;
use Postgres;
use Time;
proc main(){

var pcon = new PgParallelConnection("localhost", "postgres", "test", "password");

    



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

    var t:Timer;

    t.start();

    pcon.execute("INSERT INTO public.contacts(\"name\",\"email\") VALUES ('%s','%s')",data);
    
    t.stop();

    writeln("Insert time ",t.elapsed());

    
  }


}