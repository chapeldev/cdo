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

use Reflection;
use Regexp;

use CDOutils;

pragma "no doc"


class ModelEngine{

    var __cdo_con:Connection;


    proc ModelEngine(con:Connection){
        this.__cdo_con = con;
    }

    proc setConnection(con:Connection){
        this.__cdo_con =con;
    }

    proc getConnection():Connection{
        return this.__cdo_con;
    }


    proc Find(type eltType,id:int):eltType{
        return this.Find(eltType,id:string);
    }
    proc Find(type eltType,id:string):eltType{
       var obj = new eltType;
       obj.setConnection(this.getConnection());
       obj.setQueryBuilder(this.getConnection().table(obj.getTable()));
     
       obj = obj.getQueryBuilder().Select()
        .From(obj.getTable())
        .Where(obj.getPK(),id:string).Limit(1)
        .Query()
        .getOneAsRecord(obj);

        return obj;
    }
    proc Find(ref obj:?eltType):eltType{
       //var obj = new eltType;
       obj.setConnection(this.getConnection());
       obj.setQueryBuilder(this.getConnection().table(obj.getTable()));
     
       obj = obj.getQueryBuilder().Select()
        .From(obj.getTable())
        .Where(obj.getPK(),this.__cdo_getFieldName(obj,obj.getPK()):string).Limit(1)
        .Query()
        .getOneAsRecord(obj);

        return obj;
    }

    iter All(type eltType){

       var obj = new eltType;
       obj.setConnection(this.getConnection());
       obj.setQueryBuilder(this.getConnection().table(obj.getTable()));
       
       var qb = obj.getQueryBuilder().Select()
        .From(obj.getTable()).Query();

        obj = qb.getOneAsRecord(obj);
        while(obj!=nil){
            yield obj;
            obj = new eltType;
            obj.setConnection(this.getConnection());
            obj.setQueryBuilder(this.getConnection().table(obj.getTable()));
            obj = qb.getOneAsRecord(obj);
            
        }
    }
    proc Insert(ref obj:?eltType){
       obj.setConnection(this.getConnection());
       obj.setQueryBuilder(this.getConnection().table(obj.getTable()));       
       var qb = obj.getQueryBuilder();
       qb.Insert(obj,obj.getPK());
    }
    proc Update(ref obj:?eltType){
       obj.setConnection(this.getConnection());
       obj.setQueryBuilder(this.getConnection().table(obj.getTable()));       
       var qb = obj.getQueryBuilder();
       qb.Update(obj, obj.getPK(), this.__cdo_getFieldName(obj,obj.getPK()));
    }
    proc Delete(ref obj:?eltType){
       obj.setConnection(this.getConnection());
       obj.setQueryBuilder(this.getConnection().table(obj.getTable()));       
       var qb = obj.getQueryBuilder();
       qb.Delete(obj.getPK(),this.__cdo_getFieldName(obj,obj.getPK()));
    }

    proc BelongsTo(ref obj:?eltType, type refType, local_key:string, foreign_key:string=""): refType{
       var robj = new refType();
       obj.setConnection(this.getConnection());
       obj.setQueryBuilder(this.getConnection().table(obj.getTable()));       
       robj.setConnection(this.getConnection());
       robj.setQueryBuilder(this.getConnection().table(robj.getTable())); 
       var fk = foreign_key; 
       var qb = robj.getQueryBuilder();

       writeln("Table =",robj.getTable());
       
       if(foreign_key == ""){
           fk = robj.getPK();
           
           var fval:string = this.__cdo_getFieldName(obj,local_key):string;
           writeln("fval =", fval);
           if((fval=="")){
               return nil;
           }
           writeln("FK =",fk);
        //var sqlstr = qb.Select().Where(fk,fval).Query().toSql();
          // writeln("SQL1 =" , sqlstr);
          qb.Select().Where(fk,fval).Query().getOneAsRecord(robj);
           return robj;
       }      
       //var sqlstr = qb.Select().Where(foreign_key,this.__cdo_getFieldName(robj,local_key))
       // .Query().toSql();
        
        //writeln("SQL2 =" , sqlstr);
       
        qb.Select().Where(foreign_key,this.__cdo_getFieldName(robj,local_key))
        .Query().getOneAsRecord(robj);
       
        return robj;
        //qb.Select().Where(local_key,this.__cdo_getFieldName(obj,local_key)).;
    }

    iter HasMany(ref obj:?eltType, type refType, foreign_key:string, local_key:string=""): refType{
       var robj = new refType();
       obj.setConnection(this.getConnection());
       obj.setQueryBuilder(this.getConnection().table(obj.getTable()));       
       robj.setConnection(this.getConnection());
       robj.setQueryBuilder(this.getConnection().table(robj.getTable())); 
       var fk = foreign_key; 
       var lk = local_key;
       var qb = robj.getQueryBuilder();
        
       if(local_key ==""){
        lk = obj.getPK();
        
       }

       var qr =  qb.Select().Where(foreign_key,this.__cdo_getFieldName(obj,lk)).Query();
        robj = qr.getOneAsRecord(robj);
        while(robj!=nil){
            yield robj;
            robj = new refType();
            robj.setConnection(this.getConnection());
            robj.setQueryBuilder(this.getConnection().table(robj.getTable()));
            robj = qb.getOneAsRecord(robj);    
        }
       //qb.Select().Where(foreign_key,this.__cdo_getFieldName(obj,lk));
    }

    proc HasOne(ref obj:?eltType, type refType, foreign_key:string, local_key:string=""): refType{
       var robj = new refType();
       obj.setConnection(this.getConnection());
       obj.setQueryBuilder(this.getConnection().table(obj.getTable()));       
       robj.setConnection(this.getConnection());
       robj.setQueryBuilder(this.getConnection().table(robj.getTable())); 
       var fk = foreign_key; 
       var lk = local_key;
       var qb = robj.getQueryBuilder();
        
       if(local_key ==""){
        lk = obj.getPK();
       }
       var qr =  qb.Select().Where(foreign_key,this.__cdo_getFieldName(obj,lk)).Limit(1).Query();
        robj = qr.getOneAsRecord(robj);
        return robj;
    }

    iter BelongsToMany(ref obj:?eltType, type refType, intermediate_table:string, local_key:string, foreign_key:string, remote_key :string= "id"){
       var robj = new refType();
       obj.setConnection(this.getConnection());
       obj.setQueryBuilder(this.getConnection().table(obj.getTable()));       
       robj.setConnection(this.getConnection());
       robj.setQueryBuilder(this.getConnection().table(robj.getTable()));
       var qb = robj.getQueryBuilder();
       var rk = remote_key;
     
       var qr = qb.Select([robj.getTable()+".*"])
      .Join(intermediate_table,robj.getTable()+"."+robj.getPK(),intermediate_table+"."+foreign_key)
      .Join(obj.getTable(),obj.getTable()+"."+obj.getPK(),intermediate_table+"."+local_key)
      .Where(obj.getTable()+"."+obj.getPK(),this.__cdo_getFieldName(obj,obj.getPK()))
      .Query();

      // writeln(qr.toSql());

       robj = qr.getOneAsRecord(robj);
        while(robj!=nil){
            yield robj;
            robj = new refType();
            robj.setConnection(this.getConnection());
            robj.setQueryBuilder(this.getConnection().table(robj.getTable()));
            robj = qb.getOneAsRecord(robj);    
        }
    }

    proc __cdo_getFieldName(ref obj:?eltType, fieldname:string):string{
        for param i in 1..numFields(eltType) {
            var fname = getFieldName(eltType,i);
            if(fieldname == fname){
                return getFieldRef(obj, i):string; 
            }
        }
        return "";
    }

    proc __cdo_MapDataToModelObject(row:Row, ref obj:?eltType):bool{
    
    // Todo
        return false;
/*
        if(row == nil){
            return false;
        }
        
        if(obj == nil){
            return false;
        }
        

        for param i in 1..numFields(eltType) {
            var fname = getFieldName(eltType,i);
            if(row.hasColumn(fname)){
              if(getFieldRef(obj, i).type == string){
                type ftype = getFieldRef(obj, i).type;
                var s=row[fname];
                getFieldRef(obj, i)=s:ftype;
              }
             
            }else if(isClass(obj)&&(obj.__cdo_hasRelationMap(fname))){
                
                type ftype = getFieldRef(obj, i).type;
                
                var s = row[fname];
                var mri = obj.__cdo_getRelationMap(fname);
                
                if(mri.relType == "belogsTo"){

                    ref relObj = getFieldRef(obj, i);
        
                    relObj.setConnection(this.getConnection());
                    getFieldRef(obj, i).setQueryBuilder(this.getConnection().table(getFieldRef(obj, i).getTable()));
                    var relObjQB = getFieldRef(obj, i).getQueryBuilder();
                    var row = relObjQB.Select().Where(getFieldRef(obj, i).getPK(), this.__cdo_getFieldName(obj,mri.localKey))
                    .Get();
                    if(row != nil){
                       return  this.__cdo_MapDataToModelObject(row,getFieldRef(obj, i));
                    }
                }
            }
            return true;
            */
        
    }

}

class ModelRelationInfo{
    
var relType:string;
var localKey:string;
var remoteKey:string;
var remoteTable:string;
var pivotTable:string;

proc __CDO_ModelRelationInfo(relType:string){
        this.relType = relType;
}


};

class Model{
    
    var __cdo_table:string;
    var __cdo_pk:string;
    var __cdo_configDom:domain(string);
    var __cdo_cofig:[__cdo_configDom]string;
    var __cdo_con:Connection;
    var __cdo_qb:QueryBuilder;

    var __cdo_rel_mappingDom:domain(string);
    var __cdo_rel_mapping:[__cdo_rel_mappingDom]ModelRelationInfo;

    proc __cdo_mapRelation(relationType:string, 
    fieldName:string,
    localKey:string,
    remoteKey:string="id",
    pivotTable:string=""
    ){
        if(this.__cdo_rel_mappingDom.member(fieldName)){

            this.__cdo_rel_mapping[fieldName].localKey = localKey;
            this.__cdo_rel_mapping[fieldName].remoteKey = remoteKey;
            this.__cdo_rel_mapping[fieldName].relType = relationType;
            this.__cdo_rel_mapping[fieldName].pivotTable = pivotTable;

        }else{

            this.__cdo_rel_mapping[fieldName] = new __CDO_ModelRelationInfo(relationType);
            this.__cdo_rel_mapping[fieldName].localKey = localKey;
            this.__cdo_rel_mapping[fieldName].remoteKey = remoteKey;
            this.__cdo_rel_mapping[fieldName].pivotTable = pivotTable;

        }
    }

    proc __cdo_hasRelationMap(fieldname:string):bool{
        return this.__cdo_rel_mappingDom.member(fieldname);
    }
    proc __cdo_getRelationMap(fieldName):ModelRelationInfo{
        return this.__cdo_rel_mapping[fieldName];
    }

    proc mapBelongsTo(fieldName:string, localKey:string,remoteKey:string="id"){
        this.__cdo_mapRelation("belongsTo",fieldName,localKey,remoteKey);
    }

    proc setTable(table:string){
        this.__cdo_table = table;
    }
    proc getTable():string{
        return this.__cdo_table;
    }

    proc setConnection(con:Connection){
        this.__cdo_con =con;
    }
    proc getConnection():Connection{
        return this.__cdo_con;
    }
    proc setQueryBuilder(qb:QueryBuilder){
        this.__cdo_qb = qb;
    }
    proc getQueryBuilder():QueryBuilder{
        return this.__cdo_qb;
    }
    proc setPK(pkname:string){
        this.__cdo_pk = pkname;
    }
    proc getPK():string{
        return this.__cdo_pk;
    }
    
    /*proc Config(key:string){
        if(__cdo_configDom.member(key)){
            return this.__cdo_cofig[key];
        }
        return "";
    }
    proc Config(key:string, value:string){
        this.__cdo_cofig[key]=value;
    }
*/

    proc setup(self:?eltType){
        
        var tablename:string = cdoTitleToSneak(eltType:string);

        if(this.getTable().length == 0){
            this.setTable(tablename);
        }
        if(this.getPK().length == 0){
            this.setPK("id");
        }



    }

    proc belongsTo(obj:?eltType, local_key:string, foreign_key:string){

    }

    proc printType(){
        writeln(this.type:string);
    }
    
    
}

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


    proc hasColumn(colname:string):bool{
        return this.rowColDomain.member(colname);
    }
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
            return "";
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
        var i = 1;
        for idx in this.rowColDomain{
            if(i == colnum){
                return this.data[idx];
            }
            i+=1;
        }
        return "";
    }
    /*pragma "no doc"
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
*/

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
        return nil;

    }

pragma "no doc"

proc Begin(){

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

    proc setAutocommit(commit:bool){

    }


    pragma "no doc"
    proc helloWorld(){
        writeln("Hello from ConnectionBase");
    }

    proc table(table:string):QueryBuilder{
        return nil;
    } 
    
    
    proc model():ModelEngine{
        return nil;
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

    proc hasColumn(name:string):bool{
        for col in this.columns{
            if(name == col.name){
                return true;
            }
        }
        return false;
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

    proc fetchAsRecord(ref el:?eltType):eltType{
        //var el2: eltType = new eltType;
        var row:Row = this.fetchone();

        if(row==nil){
            return nil;
        }
        for param i in 1..numFields(eltType) {
            var fname = getFieldName(eltType,i);
            if(hasColumn(fname)){
              //if(getFieldRef(el, i).type == string){
                type ftype = getFieldRef(el, i).type;
                var s=row[fname];
                 if(isNumericType(ftype)&&(s=="")){
                     getFieldRef(el, i)= 0:ftype;
                 }else{
                     getFieldRef(el, i)=s:ftype;
                 }
                
              //}
             // =  row[fname];
            }
        }

        return el;
    }

    proc fetchAsObj(ref el:?eltType):eltType{
        //var el2: eltType = new eltType;
        var row:Row = this.fetchone();
        if(row==nil){
            return nil;
        }
        for param i in 1..numFields(eltType) {
            var fname = getFieldName(eltType,i);
            if(hasColumn(fname)){
              if(getFieldRef(el, i).type == string){
                
                type ftype = getFieldRef(el, i).type;
                var s=row[fname];
                getFieldRef(el, i)=s:ftype;
              
              }else if(isClass(getFieldRef(el, i))){
                  //type ftype = getFieldRef(el, i).type;
              }
            }
        }

        return el;
    }






    pragma "no doc"
    
    proc __objToArray(ref el:?eltType){

        var cols_dim:domain(string);
        var cols:[cols_dim]string;

        for param i in 1..numFields(eltType) {
            var fname = getFieldName(eltType,i);
            var value = getFieldRef(el, i);// =  row[fname];
            cols[fname:string] = value:string;
        }

        return cols;
    }
    /*
    `insertRecord` inserts data from (object) record/class  fields into database  table.
        :arg table: `string` name of the datbase table.
        :type el: `?eltType` Object containing the data in class/record fields. 
        :return: Insert sql generted to do the insert operation.
        :rtype: `string`
    */
    proc insertRecord(table:string, ref el:?eltType):string{
        
        return "";
    }


/*
    `insert` inserts associative array into database  table.
        :arg table: `string` name of the database table.
        :type data: `[?D]string` Associative array with columns name as index. 
        :return: Insert sql generted to do the insert operation.
        :rtype: `string`
    */
    proc insert(table:string, data:[?D]string):string{
        return "";
    }

    proc update(table:string, whereCond:string, data:[?D]string):string{
        return "";
    }

    proc updateRecord(table:string, whereCond:string, data:[?D]string):string{
        return "";
    }

    proc Delete(table:string, whereCond:string):string{
        return "";
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

type whereType = 6*string;

class StatementData{
    var op:string;
    var data_dim:domain(1);
    var data:[data_dim]string;

    var where_data_dim:domain(1);
    var where_data:[where_data_dim]whereType;

    proc StatementData(op, data){
        this.op = op;
        this.data.push_back(data);
    }

    proc StatementData(op:string, data:whereType){
        this.where_data.push_back(data);
        this.op=op;
    }
    
    proc this(i:int):string{
        try{
            if(this.op=="where"){
                return this.where_data[i];
            }else{
                return this.data[i];
            }
        }catch{
            writeln("Error Statement Data");
        }
    }

    iter these()ref:string{
        try{
            if(this.op=="where"){
                for obj in this.where_data{
                    yield obj;
                }
            }else{
                for obj in this.data{
                    yield obj;
                }
            }
        }catch{
            writeln("Error Statement Data");
        }
    }

    proc append(data:string){
        this.data.push_back(data);
    }
    proc append(data:[?D]string){
        this.data.push_back(data);
    }
    proc append(data:whereType){
        this.where_data.push_back(data);
    }

    proc setData(data){
        this.data=data;
    }
    proc getData(){
        return this.data;
    }
    proc getWhereData(){
        return this.where_data;
    }
    
    proc writeThis(f){
        try{
            if(this.op=="where"){
                for c in this.where_data{
                    f.writeln("Op:",this.op," *data=",c);
                }
            }else{
                for c in this.data{
                    f.writeln("Op:",this.op," data=",c);
                }
            }
        }catch{
            writeln("Error on write");
        }
    }
}




class QueryBuilderBase{

    var _where_cond_dim:domain(1);
    var _where_cond:[_where_cond_dim]whereType;

    var _column_names_dom: domain(1);
    var _column_names: [_column_names_dom]string;

    var table:string = "";
    var con:Connection;

    var _optype_dim:domain(1);
    var _optype:[_optype_dim]string;

    var _statements_dim:domain(string);
    var _statements:[_statements_dim]StatementData;

    var sql="";


    proc QueryBuilderBase(){

    }


    proc _addStatement(key,value){
        this._statements[key] = value;
    }

    proc Select(){

        if(this._statements_dim.member("select")){
            var stdata = this._statements["select"];
            stdata.append("*");
        }else{
            this._statements["select"] = new StatementData("select",["*"]);
        }
        return this;
    }
    proc Select(columns:[?D]string){
        if(this._statements_dim.member("select")){
            var stdata = this._statements["select"];
            stdata.append(columns);
        }else{
            this._statements["select"] = new StatementData("select",columns);
        }
        return this;
    }


    proc From(table){
        if(this._statements_dim.member("from")){
            var stdata = this._statements["from"];
            stdata.append(table);
        }else{
            this._statements["table"] = new StatementData("table",[table]);
        }
        return this;
    }

    proc Where(column:string, value){
        return this.Where(column,"=",value,"AND");
    }

    proc Where(column:string, op:string, value, concat_op="AND"){

        var ops:whereType = (column ,op, value,concat_op,"","");
       
        if(this._statements_dim.member("where")){
            var stdata = this._statements["where"];
            stdata.append(ops);
        }else{
            this._statements["where"] = new StatementData("where",ops);
        }
        return this;
    }
    proc WhereIn(column:string, values:[?D]string ,concat_op="AND"){ 
        var value = "("+(" ,".join(values))+")";
        return this.Where(column,"IN",value,concat_op);
    }
    proc WhereNotIn( column:string, values:[?D]string, value,concat_op="AND"){
        var value = "("+(" ,".join(values))+")";

        return this.Where(column,"NOT IN",value,concat_op);
    }

    proc WhereNotNull( column:string,concat_op="AND"){
        return this.Where(column,"IS NOT NULL"," ",concat_op);
    }

    proc WhereBetween( column:string, low_bound:string, upper_bound:string, concat_op="AND"){
        var value = low_bound+" AND "+upper_bound;
        return this.Where(column,"BETWEEN",value,concat_op);
    }

    proc WhereNotBetween( column:string, low_bound:string, upper_bound:string, concat_op="AND"){
        var value = low_bound+" AND "+upper_bound;
        return this.Where(column,"NOT BETWEEN",value,concat_op);
    }

    proc orWhere( column:string, value){
        return this.Where( column, "=", value, "OR");
    }

    
    proc orWhere( column:string, op:string, value){
        return this.Where( column, op, value, "OR");
    }
    
    proc orWhereIn(column:string, values:[?D]string){
        return this.WhereIn(column,values,"OR");
    }
    
    proc orWhereNotIn(column:string, values:[?D]string ){
        return this.WhereNotIn(column,values,"OR");
    }

    proc orWhereBetween( column:string, low_bound:string, upper_bound:string){
        return this.WhereBetween(column,low_bound, upper_bound,"OR");
    }
    proc orWhereNotBetween(column:string, low_bound:string, upper_bound:string){
        return this.WhereNotBetween(column,low_bound, upper_bound,"OR");
    }

    proc Join(table:string, column1:string, op:string, column2:string, join_type:string="INNER" ,concat_op="AND"){
        
        var ops:whereType = (table, column1 , op, column2, join_type,concat_op);
       
        if(this._statements_dim.member("join")){
            var stdata = this._statements["join"];
            stdata.append(ops);
        }else{
            this._statements["join"] = new StatementData("join",ops);
        }

        return this;
    }

    proc Join(table:string, column1:string,op:string, column2:string){
        return this.Join(table, column1, op, column2, "INNER", "AND");
    }

    proc Join(table:string, column1:string, column2:string){
        return this.Join(table, column1, "=", column2, "INNER", "AND");
    }

    proc innerJoin(table:string, column1:string, op:string, column2:string){
        return this.Join(table, column1, op, column2, "INNER", "AND");
    }

    proc innerJoin(table:string, column1:string, column2:string){
        return this.Join(table, column1, "=", column2, "INNER", "AND");
    }

    proc leftJoin(table:string, column1:string,op:string, column2:string){
        return this.Join(table, column1, op, column2, "LEFT", "AND");
    }

    proc leftJoin(table:string, column1:string, column2:string){
        return this.Join(table, column1, "=", column2, "LEFT", "AND");
    }

    proc rightJoin(table:string, column1:string,op:string, column2:string){
        return this.Join(table, column1, op, column2, "RIGHT", "AND");
    }
    proc rightJoin(table:string, column1:string, column2:string){
        return this.Join(table, column1, "=", column2, "RIGHT", "AND");
    }
    proc fullJoin(table:string, column1:string,op:string, column2:string){
        return this.Join(table, column1, op, column2, "RIGHT", "AND");
    }
    proc fullJoin(table:string, column1:string, column2:string){
        return this.Join(table, column1, "=", column2, "RIGHT", "AND");
    }
    proc Insert(data:[?D]string, exclude_column:string="id"){
        return this;
    }
    proc Insert(ref data:?eltType, exclude_column:string="id"){
        return this;
    }

    proc Update( data:[?D]string, cond_column:string, id:string){
        return this;
    }

    proc Update(ref data:?eltType, cond_column:string, id:string){
        return this;
    }

    proc Delete(){
        
        if(this._statements_dim.member("delete")){
            var stdata = this._statements["delete"];
            stdata.append("*");
        }else{
            this._statements["delete"] = new StatementData("delete",["*"]);
        }
        
        return this;
    }
    proc Delete(column:string,value:string){
        this.Delete().Where(column,value).Exec();
    }
   /* proc BelongsTo(data:[?D]string, table:string, local_key:string, foreign_key:string = "id"){
        return nil;
    }
    proc BelongsTo(obj:?altType, table:string, local_key:string, foreign_key:string = "id"){
        return nil;
    }*/




    proc OrderBy(column){
        if(this._statements_dim.member("orderByAsc")){
            var stdata = this._statements["orderByAsc"];
            stdata.append(column);
        }else{
            this._statements["orderByAsc"] = new StatementData("orderByAsc",column);
        }
        return this;
    }
    proc OrderBy(columns:[?D]string){
        if(this._statements_dim.member("orderByAsc")){
            var stdata = this._statements["orderByAsc"];
            stdata.append(columns);
        }else{
            this._statements["orderByAsc"] = new StatementData("orderByAsc",columns);
        }
        return this;
    }

    proc OrderByDesc(column){
        if(this._statements_dim.member("orderByDesc")){
            var stdata = this._statements["orderByDesc"];
            stdata.append(column);
        }else{
            this._statements["orderByDesc"] = new StatementData("orderByDesc",column);
        }
        
        return this;
    }

    proc OrderByDesc(columns:[?D]string){
        if(this._statements_dim.member("orderByDesc")){
            var stdata = this._statements["orderByDesc"];
            stdata.append(columns);
        }else{
            this._statements["orderByDesc"] = new StatementData("orderByDesc",columns);
        }
        return this;
    }
    proc GroupBy(column){
        if(this._statements_dim.member("groupBy")){
            var stdata = this._statements["groupBy"];
            stdata.append(column);
        }else{
            this._statements["groupBy"] = new StatementData("groupBy",column);
        }

        return this;
    }

    proc GroupBy(columns:[?D]string){
        if(this._statements_dim.member("groupBy")){
            var stdata = this._statements["groupBy"];
            stdata.append(columns);
        }else{
            this._statements["groupBy"] = new StatementData("groupBy",columns);
        }
        return this;
    }
    proc Limit(i:int){
        if(this._statements_dim.member("limit")){
            var stdata = this._statements["limit"];
            stdata.setData([i:string]);
        }else{
            this._statements["limit"] = new StatementData("limit",[i:string]);
        }   
        return this;
    }
    proc Offset(i:int){
        if(this._statements_dim.member("offset")){
            var stdata = this._statements["offset"];
            stdata.setData([i:string]);
        }else{
            this._statements["offset"] = new StatementData("offset",[i:string]);
        }
        return this;
    }

    proc toSql():string{
        return "";
    }

    proc Count():int{ 
         return 0;
    }
    proc Count(colname:string):int{ 
         return 0;
    }
    proc Max(colname:string):real{ 
         return 0;
    }
    proc Min(colname:string):real{ 
         return 0;
    }

    proc Avg(colname:string):real{ 
         return 0;
    }

    iter Get():Row{
        
    }
    proc getOneAsRecord(ref obj:?eltType):eltType{
       return nil;
    }
    
   proc Query(){
    return this;
   }

    proc Exec(){
        
    }
    proc QueryAndGetCursor():Cursor{
       return nil;
   }


    proc clear(){
        this.sql="";
        this._statements_dim.clear();
    }
    

    proc writeThis(f){
        try{
            for c in this._statements{
                f.writeln(c);
            }
        }catch{
            writeln("Error on write");
        }
    }

    proc _has(opname:string):bool{
        return this._statements_dim.member(opname);
    }

    proc _get(opname):StatementData{
        return this._statements[opname];
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

class QueryBuilder{
    forwarding var query_driver: QueryBuilderBase;

    /*proc writeThis(f){
        this.query_driver.writeThis(f);
    }*/
}


module CDOutils{

    proc cdoTitleToSneak(str:string):string{
       
        try{
            var myRegexp = compile("([A-Z])");
            var tb:string;
            var i:int=0;
            var prfx:string="";
            for s in str.split(myRegexp){
                if((s.length!=0)&&(s.isUpper())){
               // var ss:string;
                    if(i>0){
                        prfx="_";
                    }
                    tb += (prfx+s.toLower());
                    i+=1;
                }else if(s.length!=0){
                    tb += s.toLower();
                    i+=1;
            }
            //writeln("* ",s, " id upper ", s.isUpper():string, "len = ", s.length);
        }
        
        return tb;

        }catch{
            writeln("Cannot convert String to Sneak case:  ",str:string);
            
        }

        return str;
    
    }

    proc cdoObjToArray(ref el:?eltType){

        var cols_dim:domain(string);
        var cols:[cols_dim]string;

        for param i in 1..numFields(eltType) {
            var fname = getFieldName(eltType,i);
            var value = getFieldRef(el, i);// =  row[fname];
            cols[fname:string] = value:string;
        }

        return cols;
    }




}



}//end module