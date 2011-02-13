/* file "test_insert_relations_4.sql" */

use relations
go

truncate table relations
go

INSERT INTO relations (rel_id, set_id)
select "" , 'set00001' union
select "" ,  'set00002'
go

select * from relations -- rel_view
go


INSERT INTO relations (rel_id, set_id)
select "" , 'set00001' union
select "" ,  'set00002'
go

select * from relations -- rel_view
go

-- Attempt to insert duplicate key row:

INSERT INTO relations (rel_id, set_id)
select "r0000001" , 'set00001'
go

INSERT INTO relations (rel_id, set_id)
select "" , 'set00003' union
select "" , 'set00004' union
select "A" , 'set00005' union
select "A" ,  'set00006'
go

select * from relations -- rel_view
go

print "done"

go





/*
Fri Jan 21 16:29:39 PST 2011
(2 rows affected)
 rel_id   set_id   
 -------- -------- 
 r0000001 set00001 
 r0000001 set00002 

(2 rows affected)
(2 rows affected)
 rel_id   set_id   
 -------- -------- 
 r0000001 set00001 
 r0000001 set00002 
 r0000002 set00001 
 r0000002 set00002 

(4 rows affected)
Msg 2601, Level 14, State 1:
Server 'manny_ASE', Line 4:
Attempt to insert duplicate key row in object 'relations' with unique index 'relations_rel_id_set_id'
Command has been aborted.
(0 rows affected)
(4 rows affected)
 rel_id   set_id   
 -------- -------- 
 r0000001 set00001 
 r0000001 set00002 
 r0000002 set00001 
 r0000002 set00002 
 r0000003 set00003 
 r0000003 set00004 
 r0000004 set00005 
 r0000004 set00006 

(8 rows affected)
done
*/
