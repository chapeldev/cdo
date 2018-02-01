module Main{
config const numTasks = here.maxTaskPar;
proc main(){

var X:[{1..10}]int=[1,2,3,4,5,6,7,8,9,10];
var Y:[{1..20}]int;

forall (x,y) in zip(X,Y){
    y=x;
}

writeln("Y=",Y);

    /*forall x in count(10){
        writeln("X = ",x);
    }*/

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