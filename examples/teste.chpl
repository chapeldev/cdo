module Main{
use Types;
    proc main(){



    proc main(){
        foo("select %s,%s from table",("name","email"));
        foo("select %s from table",("name"));

    }
    proc foo(str:string, params){
        try{


            writeln(str.format((...params)));
        }catch{
            writeln("Error");
        }


    }

    proc foo(str,params){
        try{
            var ist =false;
            for p in params{
                if(isTuple(p)){
                    foo(str,p);
                    ist=true;
                }
                    
                
                
                
            }
            if(!ist){
                writeln( str.format((...params)) );
            }

        }catch{
            writeln("Error");
        }
        
    }

}