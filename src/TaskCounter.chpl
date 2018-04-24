module TaskCounter {
  //Not tested and freindly donated by Dr. Brad from Chapel core dev.

  class sharedCounter { 
    var counter: atomic int; 
    proc init() { 
      this.complete(); 
      counter.write(0); // make -1 if you want zero-based tasks                
    } 
    proc get() { 
      return counter.fetchAdd(1); 
    } 
    proc done() { 
      counter.sub(1); 
      } 
    } 
    record taskID { 
      var id: int; 
      var ctr: sharedCounter; 
      proc init() { 
        id = 0; 
        ctr = new sharedCounter(); 
      } 
      proc init(parentTid: taskID) {
           this.id = parentTid.ctr.get(); 
           this.ctr = parentTid.ctr; 
      } 
      proc deinit() {   
        ctr.done(); 
        } 
      } 
}
/*
module Test {
  use TaskCounter;

  proc main() {
    var tid: taskID;

    forall i in 1..10 with (in tid) do
      writeln("iteration ", i, " is owned by, ", tid.id);

      writeln("-----");

    forall i in 1..10 with (in tid) do
      writeln("iteration ", i, " is owned by, ", tid.id);
  }
}
*/