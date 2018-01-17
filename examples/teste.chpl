module Main{


    proc main(){
        foo("select %s,%s from table",("name","email"));
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