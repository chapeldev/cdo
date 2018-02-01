module Main{
    use Cdo;
    use Postgres;
    use Time;
    
config const numTasks = here.maxTaskPar;
proc main(){

//Open connection with Postgres database. Parametrs are host,username, database, password
        var con = PgConnectionFactory("localhost", "postgres", "test", "password");
        //Open a cursor
        var cursor = con.cursor();
/*
// Array of tuple
    type MyTuple =(string,string); 
    var data:[{1..0}]MyTuple;
// Data to be stored

    for i in {1..1000} {
        data.push_back(("John"+i:string,"john"+i:string+"@email.co"));
        data.push_back(("Mary"+i:string,"marry"+i:string+"@email.co"));
        data.push_back(("Paul"+i:string,"paul"+i:string+"@email.co"));    
    }

    
    
    cursor.execute("INSERT INTO public.contacts(\"name\",\"email\") VALUES ('%s','%s')",data);
*/
    cursor.query("SELECT * FROM public.contacts");


    var t1= getCurrentTime(TimeUnits.milliseconds);

    for row in cursor{
        writeln("name = ", row["name"]+" email = "+row["email"] );
    }
    var t2= getCurrentTime(TimeUnits.milliseconds);
 
    var tserial =t2-t1;
    
   


    var t3= getCurrentTime(TimeUnits.milliseconds);

    for row in cursor{
        writeln("name = ", row["name"]+" email = "+row["email"] );
    }
    var t4= getCurrentTime(TimeUnits.milliseconds);
 
    var tserial_cached =t4-t3;
    
    var t5= getCurrentTime(TimeUnits.milliseconds);

    forall row in cursor{
         writeln("name = ", row["name"]+" email = "+row["email"] );
    }
    var t6= getCurrentTime(TimeUnits.milliseconds);

    var tparallel = t6-t5;
   
    writeln("Serial time  ",tserial );
    writeln("Serial time  Cached ",tserial_cached );
    writeln("Parallel time   ",tparallel );


    cursor.close();
    con.close();
    writeln("End");




}






iter count(n:int){
    var i=0;
    while (i<n) {
         yield i;
         i+=1;
    }
}


iter count(param tag: iterKind, n: int)
       where tag == iterKind.standalone {
  //if (verbose) then
    writeln("In count() standalone, creating ", numTasks, " tasks");
  coforall tid in 0..#numTasks {
    const myIters = computeChunk(0..#n, tid, numTasks);
    //if (verbose) then
      writeln("task ", tid, " owns ", myIters);
    for i in myIters do
      yield i;
  }
}

proc computeChunk(r: range, myChunk, numChunks) where r.stridable == false {
  const numElems = r.length;
  const elemsPerChunk = numElems/numChunks;
  const mylow = r.low + elemsPerChunk*myChunk;
  if (myChunk != numChunks - 1) {
    return mylow..#elemsPerChunk;
  } else {
    return mylow..r.high;
  }
}


}