/* file "test_insert_relations_4.sql" */

use relations
go

drop view rel_view
go

create view rel_view
    as
select relations.rel_id   , 
    convert(char(24), relations.rel_name) "relations_rel_name", 
    relations.set_id1, convert(char(2), set1.set_seq_no) "sq1",  convert(char(32), set1.set_name) "set_name_1", 
    relations.set_id2, convert(char(2), set2.set_seq_no) "sq2",  convert(char(32), set2.set_name) "set_name_2" 
from relations, sets set1, sets set2
where relations.set_id1 = set1.set_id
and relations.set_id2 = set2.set_id
and set1.set_seq_no = (select min(a.set_seq_no) from sets a)
and set2.set_seq_no = (select min(b.set_seq_no) from sets b)



truncate table relations
go

INSERT INTO relations (rel_id, set_id1, set_id2)
select "" , 'set00001', 'set00002'
go

select * from rel_view
go
INSERT INTO relations (rel_id, set_id1, set_id2)
select "" , 'set00002', 'set00004'
go

select * from rel_view
go

INSERT INTO relations (rel_id, set_id1, set_id2)
select "" , 'set00002', 'set00003' union
select "" , 'set00003', 'set00004'
go


select * from rel_view
go


gronk

 

/*
Thu Jan 20 15:41:14 PST 2011
 max rel id max_rel_id_index 
 ---------- ---------------- 
 r0000001                  1 

(1 row affected)
(1 row affected)
 rel_id   relations_rel_name       set_id1  sq1 set_name_1                       set_id2  sq2 set_name_2                       
 -------- ------------------------ -------- --- -------------------------------- -------- --- -------------------------------- 
 r0000001 NULL                     set00001 1   Edward R. Murrow (updated)       set00002 1   Joe                              

(1 row affected)
Msg 2601, Level 14, State 2:
Server 'manny_ASE', Line 2:
Attempt to insert duplicate key row in object 'relations' with unique index 'rel_id'
Command has been aborted.
(0 rows affected)
 rel_id   relations_rel_name       set_id1  sq1 set_name_1                       set_id2  sq2 set_name_2                       
 -------- ------------------------ -------- --- -------------------------------- -------- --- -------------------------------- 
 r0000001 NULL                     set00001 1   Edward R. Murrow (updated)       set00002 1   Joe                              

(1 row affected)
Msg 207, Level 16, State 1:
Server 'manny_ASE', Line 9:
Invalid column name 'set_id'.
Msg 207, Level 16, State 1:
Server 'manny_ASE', Line 3:
Invalid column name 'set_id'.
Msg 207, Level 16, State 4:
Server 'manny_ASE', Line 5:
Invalid column name 'set_seq_no'.
Msg 207, Level 16, State 4:
Server 'manny_ASE', Line 5:
Invalid column name 'set_id'.
Msg 207, Level 16, State 4:
Server 'manny_ASE', Line 5:
Invalid column name 'set_name'.
Msg 207, Level 16, State 1:
Server 'manny_ASE', Line 16:
Invalid column name 'set_id'.
Msg 207, Level 16, State 4:
Server 'manny_ASE', Line 2:
Invalid column name 'set_seq_no'.
Msg 207, Level 16, State 4:
Server 'manny_ASE', Line 2:
Invalid column name 'set_id'.
*/

 
gronk

INSERT INTO relations (set_id, set_id1, set_id2)
select "" , 'set00001', 'set00002' union
select "" , 'The Republic of Desire'  union
select "" , 'Joe' union
select "" , 'Joe 2'

go


INSERT INTO relations (set_id, set_name)
select "set00001" , 'Edward R. Murrow2' union
select "" , 'The Republic of Desire'  union
select "" , 'Joe' union
select "" , 'Joe 2'

go

declare @temp_set_id char(8)
declare @temp_set_seq_no int

select @temp_set_id = set_id , @temp_set_seq_no = set_seq_no from relations where set_name = 'Edward R. Murrow'

-- select @temp_set_id "temp_set_id",    @temp_set_seq_no "temp_set_seq_no"


/* this insert is really an update of an existing record.  will
    fail with 'insert duplicate key' if we don't:
    (1) allow for this kind of duplicate at the *table* constraint level
    (2) handle this kind of duplicate inside of the insert trigger.
    */
    
INSERT INTO relations (set_id, set_seq_no, set_name)
select @temp_set_id , @temp_set_seq_no , 'Edward R. Murrow (updated)'
go

select * from relations
    order by set_id, set_seq_no
go




/*
Thu Jan 20 08:39:42 PST 2011
 query status set_id   set_seq_no  set_name                                                                                                                             set_super_id 
 ------------ -------- ----------- ------------------------------------------------------------------------------------------------------------------------------------ ------------ 
 created      set00002           1 Joe                                                                                                                                  NULL         
 created      set00003           1 Joe 2                                                                                                                                NULL         
 created      set00001           1 Edward R. Murrow                                                                                                                     NULL         
 created      set00004           1 The Republic of Desire                                                                                                               NULL         

(4 rows affected)
(4 rows affected)
 query status set_id   set_seq_no  set_name                                                                                                                             set_super_id 
 ------------ -------- ----------- ------------------------------------------------------------------------------------------------------------------------------------ ------------ 
 created      set00005           1 Joe                                                                                                                                  NULL         
 created      set00006           1 Joe 2                                                                                                                                NULL         
 created      set00007           1 The Republic of Desire                                                                                                               NULL         

(3 rows affected)
(4 rows affected)
(1 row affected)
 query status set_id   set_seq_no  set_name                                                                                                                             set_super_id 
 ------------ -------- ----------- ------------------------------------------------------------------------------------------------------------------------------------ ------------ 
 inserted     set00001           1 Edward R. Murrow (updated)                                                                                                           NULL         

(1 row affected)
insert trigger:      record(s) being deleted:    1.
(1 row affected)
 set_id   set_seq_no  set_name                                                                                                                             set_super_id 
 -------- ----------- ------------------------------------------------------------------------------------------------------------------------------------ ------------ 
 set00001           1 Edward R. Murrow (updated)                                                                                                           NULL         
 set00001           2 Edward R. Murrow2                                                                                                                    NULL         
 set00002           1 Joe                                                                                                                                  NULL         
 set00003           1 Joe 2                                                                                                                                NULL         
 set00004           1 The Republic of Desire                                                                                                               NULL         
 set00005           1 Joe                                                                                                                                  NULL         
 set00006           1 Joe 2                                                                                                                                NULL         
 set00007           1 The Republic of Desire                                                                                                               NULL         

(8 rows affected)
*/
