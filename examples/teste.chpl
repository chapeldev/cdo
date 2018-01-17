module Main{
use Types;
    proc main(){


        foo("select %s from table",("name"));

    }
    proc foo(str:string, params){
        try{


            writeln(str.format((...params)));
        }catch{
            writeln("Error");
        }

    }
}