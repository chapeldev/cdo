/*
 * Copyright (C) 2018 Marcos Cleison Silva Santana
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
module CDOModelEngine{
use Cdo;
use CDOQueryBuilder;

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




}//model