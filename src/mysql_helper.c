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
#include"mysql_helper.h"

const char* __get_mysql_row_by_number(MYSQL_ROW row,int i){
    return (const char*)row[i];
}

const char* __get_mysql_field_name_by_number(MYSQL_FIELD *fields,int i){

    return (const char*)fields[i].name;
}
/*const char* __get_mysql_field_type_by_number(MYSQL_FIELD *fields,int i){

    return (const char*)fields[i].name;
}*/