#ifndef __MYSQL_HELPER_H
    #define __MYSQL_HELPER_H
#endif // !__MYSQL_HELPER_H
#include<my_global.h>
#include<mysql.h>

const char* __get_mysql_row_by_number(MYSQL_ROW row,int i);
const char* __get_mysql_field_name_by_number(MYSQL_FIELD *fields,int i);