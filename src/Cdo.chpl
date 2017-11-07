/*
 * Copyright (C) 2017 Marcos Cleison Silva Santana
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
Cdo - Chapel Data Object is a library that helps to access RDBMS databases like Postgres, Mysql or Sqlite.

One of the objectives of this library is to provide to Chapel developers a common API to access relational databases. 

Some features found in this library is inspired by PHP PDO, Python DB API and Go SQL API.

This module is focused on providing interfaces, base classes, and helpers that allows hiding complexity of different database connection libraries. 

 -  Database Connection Class
    + :chpl:class `Conection`
    + :chpl:class `ConectionBase`
 -  Database Cursor Class
    + :chpl:class `Cursor`
    + :chpl:class `CursorBase`
 -  Data Row Class
    + :chpl:class `Row`
-  Data ColumnInfo Class
    + :chpl:class `ColumnInfo`

*/

module Cdo{

pragma "no doc"
enum CdoType{
    DATE,
    TIME,
    TIMESTAMP,
    TIMESTAMP_FROM_TICKS,
    TIME_FROM_TICKS,
    DATE_FROM_TICKS,
    BINARY,
    STRING, 
    NUMBER, 
    DATETIME, 
    ROWID 
}

/*
The  `Row` class stores information from result set send by the database server.


*/
class Row{
    pragma "no doc"
    var rowColDomain:domain(string);
    pragma "no doc"
    var data:[rowColDomain]string;
    pragma "no doc"
    var num:int(32);
/*
`addData` adds in an associative array the column and its correspondent data.
        :arg colname: `string` name of the column.
        :type colname: `string`

        :arg datum: `string` data returned.
        :type datum: `string`
       
*/

    proc addData(colname:string, datum:string){
        this.data[colname] = datum;
    }
/*
    `get` gets the data from column name.
        :arg colname: `string` name of the column.
        :type colname: `string`

     :return: data value of the column `colname`.
     :rtype: `string`
       
*/
    
    proc get(colname:string):string{
        if(this.rowColDomain.member(colname)){
            return this.data[colname];
        }else{
            return nil;
        }
    }
/*
    `this[colname]` gets the data from column name.
        :arg colname: `string` name of the column.
        :type colname: `string`

     :return: data value of the column `colname`.
     :rtype: `string`
       
*/


    proc this(colname:string):string{
        return this.get(colname);
    }
/*
    `this[colnum]` gets the data from column number.
        :arg colnum: `int` number of the column.
        :type colnum: `int`

     :return: data value of the column `colnum`.
     :rtype: `string`
       
*/

    proc this(colnum:int):string{
        var i=1;
        for idx in this.rowColDomain{
            if(i == colnum){
                return this.data[idx];
            }
            i+=1;
        }
        return nil;
    }
    pragma "no doc"
    proc writeThis(f){
        try{
            for col in this.rowColDomain{
                f.write(col,"=",this.data[col]," ");
            }
            f.writeln(" ");

        }catch{
            writeln("Cannot Write Row");//todo: improves messages with log
        }
    }

}

/*
The `ColumnInfo` class holds infomration about returned columns.
*/
class ColumnInfo{
    pragma "no doc"
    var coltype:string;
    pragma "no doc"
    var colnum:int(32);
    pragma "no doc"
    var name:string;
}
/*
The `ConnectionBase` class is provides an interface-like for the database Driver developers for Cto  
All database drivers/connectors need to inherit this class and override non-helper methods.
*/
class ConnectionBase{

/*
    The method `cursor` creates a cursor to query and retrieve results from database. 
    
    :return: result cursor .
    :rtype: `Cursor`
*/

    proc cursor():Cursor{

        return nil;
    }
pragma "no doc"
    proc getNativeConection():opaque{

        //todo:

    }

pragma "no doc"
    proc commit(){

    }
    pragma "no doc"
    proc rollback(){

    }
    pragma "no doc"
    proc close(){

    }

pragma "no doc"
    proc helloWorld(){
        writeln("Hello from ConnectionBase");
    }

}
/*
The `CursorBase` is the interface-like base class that treats queries and returned result from database. 
All database driver cursors should implement its methods inheriting from this class 
*/
class CursorBase{
pragma "no doc"
    var colDomain:domain(int(32));
pragma "no doc"    
    var columns:[colDomain]ColumnInfo;
/*
`__addColumn` is a helper method that adds column infomrations to column result list.
        :arg colnum: `int` number of the column.
        :type colnum: `int`
        
        :arg colname: `string` name of the column.
        :type colname: `string`

        :arg coltype: `string` type of the column.
        :type coltype: `string`

   

*/
    proc __addColumn(colnum:int(32),colname:string,coltype:string=""){
        this.columns[colnum] = new ColumnInfo(name=colname,colnum=colnum,coltype=coltype);  
    }
/*
`__removeColumns` is a helper method that clears column infomation list.
*/
    proc __removeColumns(){

        //if(this.columns[colnum]!=nil){
            for colnum in this.colDomain{
                this.colDomain -= colnum;
            }
            
        //}

    }
pragma "no doc"
    proc getColumnInfo(colnum:int(32)):ColumnInfo{
        return this.columns[colnum];
    }

pragma "no doc"
    proc printColumns(){
        for col in this.columns{
            writeln(col,"\t");
        }
        writeln("\n++++++++++++++++++++++++++++++++++++++++++++");
    }
/*
    `rowcount` gets the number of rows in result set.
     :return: Number of rows in the result set.
     :rtype: `int(32)`
*/
    proc rowcount():int(32){
        return 0;
    }
/*
*/
pragma "no doc"
    proc callproc(){

    }
/*
    `close` frees the result result set resources.
     :return: Number of rows in the result set.
     :rtype: `int(32)`
*/   
    proc close(){

    }
    /*
    `execute` executes SQL commands.

    :arg query: `string` SQL command.
    :type query: `string`

    :arg params: `tuple` tuple of parameters.
    :type params: `tuple`

*/  
    proc execute(query:string, params){

    }
/*
    `execute` executes SQL commands.

    :arg query: `string` SQL command.
    :type query: `string`
*/
   proc execute(query:string){
       
   }

/*
    `query` sends SQL queries.

    :arg query: `string` SQL command.
    :type query: `string`

*/ 
   proc query(query:string){
      
   }

   /*
    `query` sends SQL queries.

    :arg query: `string` SQL command.
    :type query: `string`
    :arg params: `tuple` tuple of parameters.
    :type params: `tuple`

    */ 

   proc query(query:string,params){

      
   }

   pragma "no doc"
   proc dump(){

   }

 pragma "no doc"
    proc executemany(str:string, pr){
      //writeln(pr[1][1]);
    }

   /*
    `fetchone` gets one row from result set.

    
    :return: Row data.
    :rtype: `Row`
    */ 

    proc fetchone():Row{
        return nil;
    }

   /*
    `fetchmany` iterates on `count` rows.

    :arg count: `int` Number of rows that wants to interate on.
    :type count: `int`
    
    :return: Row data.
    :rtype: `Row`
    */ 

    iter fetchmany(count:int=0):Row{
        
    }
    /*
    `fetchall` iterates on all rows.
    
    :return: Row data.
    :rtype: `Row`
    */ 

    iter fetchall():Row{
       
    }
    /*
    `this[idx]` accesses the idx-th row.
    :return: Row data.
    :rtype: `Row`
    */
    proc this(idx:int):Row{
        return nil;
    }

    /*
    `these` iterates on all rows.
    
    :return: Row data.
    :rtype: `Row`
    */ 
    iter these()ref:Row{

    }

    /*
    `next` increses the cursor position.
    
    :return: Row data.
    :rtype: `Row`
    */
    proc next(){
        
    }
    pragma "no doc"
    proc messages(){

    }

}
/*

`Connection` forwarding contract interface-like class.

*/
class Connection{
    forwarding var driver: ConnectionBase;
}
/*
`Connection` forwarding contract interface-like class.
*/
class Cursor{
    forwarding var cursor_drv: CursorBase;
}

}//end module