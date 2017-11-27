module Main{
    use Cdo;
    use Postgres;
    use Regexp;
    proc main(){
        var con = PgConnectionFactory("localhost", "postgres", "teste", "password");


        class Company:Model{
            var id:int;
            var name:string;

            proc Company(){
                this.setup(this);
            }
        }

        class ContactsCompany:Model{
            var id:int;
            var name:string;
            var email:string;
            var company_id:int;
            proc ContactsCompany(){
                this.setTable("contacts");
                this.setup(this);
            }
            
        }

        var c = con.model().Find(ContactsCompany,16);
        
        if(c!=nil){
           writeln("* id = ",c.id, " name = ", c.name," email = ", c.email);    
        }

        c.name="Josefina";
        c.email="j@j.com";
        con.model().Update(c);

        c = con.model().Find(ContactsCompany,16);
        
        if(c!=nil){
           writeln("# id = ",c.id, " name = ", c.name," email = ", c.email);    
        }

        /*var new_contact = new ContactsCompany();

        new_contact.name="Neo";
        new_contact.email="neo@matrix.com";
        con.model().Insert(new_contact);
*/
        for contact in con.model().All(ContactsCompany){
            writeln("@ id = ",contact.id, " name = ", contact.name,contact.company_id);
        }

        var contact = con.model().Find(ContactsCompany,1);

        if(contact!=nil){

           var company:Company = con.model().BelongsTo(contact,Company,"company_id");

            writeln();
            writeln("% id = ",contact.id, " name = ", contact.name, "Company name = ",company.name);

            //con.model().Delete(contact);
        }

        for contact in con.model().All(ContactsCompany){
           // writeln("# id = ",contact.id, " name = ", contact.name);
        }
        var comp = con.model().Find(Company,2);
        if(comp!=nil){
           //var company:Company = con.model().BelongsTo(contact,Company,"company_id");

            writeln("company id = ",comp.id, " name = ", comp.name);

            for cont in con.model().HasMany(comp,ContactsCompany,"company_id"){
               begin writeln("Contact ", cont.name, " company id ",cont.company_id);
            }

            //con.model().Delete(contact);
        }


        con.close();
        writeln("End");
    }
}