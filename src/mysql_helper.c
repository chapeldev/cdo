#include"mysql_helper.h"

const char* __get_mysql_row_by_number(MYSQL_ROW row,int i){
    return (const char*)row[i];
}

const char* __get_mysql_field_name_by_number(MYSQL_FIELD *fields,int i){

    return (const char*)fields[i].name;
}