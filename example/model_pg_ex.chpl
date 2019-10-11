module Main{
    use Cdo;
    use Postgres;
    use Regexp;
    proc main(){
        var con = PgConnectionFactory("localhost", "postgres", "teste", "password");


        class Company: Model{
            var id:int;
            var name:string;

            proc init(){
                this.setup(this);
            }
        }

        class ContactsCampony: Model{
            var id:int;
            var name:string;
            var email:string;
            
            proc init() {
                this.setTable("contacts");
                this.setup(this);
            }
            
        }

        var c = con.model().Find(ContactsCampony,2);
        
        if(c!=nil){
           writeln("* id = ",c.id, " name = ", c.name);    
        }

        for contact in con.model().All(ContactsCampony){

            writeln("@ id = ",contact.id, " name = ", contact.name);

        }


        var company = con.model().Find(Company, 1);
        
        if(company!=nil){
            writeln("# id = ",company.id, " name = ", company.name);
        }

        for comp in con.model().All(Company){

            writeln("@ id = ",comp.id, " name = ", comp.name);

        }

        con.close();
        writeln("End");
    }
}