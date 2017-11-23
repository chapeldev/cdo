module Main{
    use Cdo;
    use Postgres;
    use Regexp;
    proc main(){
        var con = PgConnectionFactory("localhost", "postgres", "teste", "password");

        class MyModel{
           type selfType;
           proc print(){
               writeln("print model");
           }
           proc New(){
               var obj = new this.selfType;
                obj.model = this; 
               return obj;
           }
        }

        class Company:Model{
            var id:int;
            var name:string;

            proc Company(){
                this.setup(this);
            }
        }

        class ContactsCampony:Model{
            var id:int;
            var name:string;
            var email:string;
            
            proc ContactsCampony(){
                this.setTable("contacts");
                this.setup(this);
            }
            
        }

        var c = con.model().Find(ContactsCampony,2);
        
        if(c!=nil){
           writeln("* id = ",c.id, " name = ", c.name);    
        }

        var campony = con.model().Find(Company, 1);
        
        if(campony!=nil){
            writeln("# id = ",campony.id, " name = ", campony.name);
        }


        con.close();
        writeln("End");
    }
}