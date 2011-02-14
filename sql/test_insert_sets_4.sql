use relations
go

truncate table sets
go

------------------------------------------------------------------------
--
-- 
--      test001:    Name and no set_id ==> Create a new set_id.
--
-- 
INSERT INTO sets (set_name) values ("Albert Einstein")
go
-- 
--      Expect: 
--          create a new set_id ("set00001")
-- 
--          created_set_id     set00001 1   NULL         Albert Einstein                                                  
-- 
-- 
------------------------------------------------------------------------
--
-- 
--      test002:    Matching name and no set_id ==> Find and return existing set_id.
--
-- 
INSERT INTO sets (set_name) values ("Albert Einstein")
go
-- 
--      Expect: 
--          find and return an existing set_id ("set00001").
--  
--          found              set00001 1   NULL         Albert Einstein                                                  
--    
--
------------------------------------------------------------------------
--
-- 
--      test003:    insert another 'Albert Einstein' but with a different set_id.  
--
--     
INSERT INTO sets (set_id, set_name) values ( "set00002" , 'Albert Einstein' )
go
-- 
--      Expect: 
--
--      returned value matching inserted set_id and name, possibly with new set_seq_no.
-- 
--      inserted           set00002 1   NULL         Albert Einstein                                                  
--
-- 
------------------------------------------------------------------------
--
-- 
--      test004:        find all (both) records returned
--
-- 
INSERT INTO sets (set_name) values ("Albert Einstein")
go
-- 
--      Expect: 
--
--      found              set00001 1   NULL         Albert Einstein                                                  
--      found              set00002 1   NULL         Albert Einstein                                                  
-- 
------------------------------------------------------------------------

------------------------------------------------------------------------
-- 
--      test005:        insert synonym:  existing set_id and no seq_no
-- 
--
INSERT INTO sets (set_id, set_name) values ( "set00001" , 'Albert Einstein 2' )
go
-- 
--      Expect: 
--
--      ==> new record with new sequence number and existing set_id
--
--      inserted           set00001 2   NULL         Albert Einstein 2                                                
-- 
------------------------------------------------------------------------



------------------------------------------------------------------------
-- 
--      test006:    update:   matching set_id and seq_no.
--
--
INSERT INTO sets (set_id, set_seq_no, set_name) values ( "set00001" , 1,  'Albert Einstein (updated)' )
--
--      Expect:
--
--      Report the deletion that is associated with an update:
--      
--      insert trigger:      record(s) being deleted:    1.
--
--      Update the record.
--
--      updated(1)         set00001 1   NULL         Albert Einstein (updated)                                        
--      updated(2)         set00001 1   NULL         Albert Einstein (updated)                                        
--
--
------------------------------------------------------------------------ 




--      quick/debug look at entire sets table
--      set_id   seq set_super_id set_name                                                         
--      -------- --- ------------ ---------------------------------------------------------------- 
--      set00001 1   NULL         Albert Einstein (updated)                                        
--      set00001 2   NULL         Albert Einstein 2                                                
--      set00002 1   NULL         Albert Einstein                                                  
-- 
-- 

------------------------------------------------------------------------
-- 
--      test106:    mix of updates and insertions
--
--
INSERT INTO sets (set_id, set_name)
select "set00001" , 'Albert Einstein (third)' union
select "" , 'Alonso Church' union
select "" , 'Kurt Gödel'
--
--
--      Expect:
--
--      Return a list of all records with additonal field describing action(s) performed 
--        (eg, "found, created, updated: or "inserted")
--
--        inserted           set00001 3   NULL         Albert Einstein (third)                                          
--        created_set_id     set00003 1   NULL         Alonso Church                                                    
--        created_set_id     set00004 1   NULL         Kurt Gödel                                                      
--
--
------------------------------------------------------------------------ 
    

------------------------------------------------------------------------
-- 
--      test107:    create name, then query for set_id and add synonym
--
--
INSERT INTO sets (set_name) values ('Alan Turing')
--
--      Expect:
--
--       created_set_id     set00005 1   NULL         Alan Turing                                                      


declare @temp_set_id char(8)
 
select @temp_set_id = set_id 
from sets 
    where set_name = 'Alan Turing'
    
/* add synomym for existing node_id */    

INSERT INTO sets (set_id,   set_name)
select @temp_set_id ,   'A. M. Turing'
go
--
--      Expect:
--

--  inserted           set00005 2   NULL         A. M. Turing                                                     

------------------------------------------------------------------------
-- 
--      test109:    query for set_id and seq_no, then update value for name
-- 
-- 
--
declare @temp_set_id char(8)
declare @temp_set_seq_no int

select @temp_set_id = set_id , 
       @temp_set_seq_no = set_seq_no 
from sets 
    where set_name = 'Alan Turing'

INSERT INTO sets (set_id, set_seq_no, set_name)
select @temp_set_id , @temp_set_seq_no , 'Alan Turing (updated)'
go
--
--      Expect:
--
--      updated name for and existing node_id+seq_no combination
--      report from trigger about original record being deleted.
--
--
-- insert trigger:      record(s) being deleted:    1.
--
--  updated(1)         set00005 1   NULL         Alan Turing (updated)                                            
--  updated(2)         set00005 1   NULL         Alan Turing (updated)                                            
--
------------------------------------------------------------------------


------------------------------------------------------------------------
-- 
--      test110:    query for set_id and seq_no, then update value for name

/* mix of updates, insertions and queries. */

-- The column set_seq_no in table sets does not allow null values.

INSERT INTO sets (set_id,   set_name)
select "" ,  'Albert Einstein 2' union
select "" ,  'Alfred Tarski' 

 -- found              set00001 2   NULL         Albert Einstein 2                                                
 -- created_set_id     set00007 1   NULL         Alfred Tarski              
 
--  ==>  auto-seq for created set_id creates one more than necessary
--          due to presence of the "query" record at the time of auto-seq.
--      delete "found" before auto-seq?                                      


INSERT INTO sets (set_id, set_seq_no, set_name)
select "set00002" , 2,  "Second record second synonym" union
select "" , 0,  'Kurt Gödel'

go

 -- inserted           set00002 2   NULL         Second record second synonym                                     
 -- found              set00004 1   NULL         Kurt Gödel                                                      

------------------------------------------------------------------------
-- 
--      test111:    sql UPDATE statement test 1
--
--      base update on retrieved set_id and set_seq_no
-- 
-- 
--
declare @temp_set_id char(8)
declare @temp_set_seq_no int

select @temp_set_id = set_id , 
       @temp_set_seq_no = set_seq_no 
from sets 
    where set_name = 'Alan Turing (updated)'

UPDATE sets
    set set_name = 'Alan M. Turing (update3)'
    where   set_id =  @temp_set_id
    and     set_seq_no = @temp_set_seq_no

go
--
--      Expect:
--
--      updated name for and existing node_id+seq_no combination
--      report from trigger about original record being deleted.
--
--
-- insert trigger:      record(s) being deleted:    1.
--
--  updated(1)         set00005 1   NULL         Alan Turing (updated)                                            
--  updated(2)         set00005 1   NULL         Alan Turing (updated)                                            
--
--
--      Currently:
-- 
--      no result set returned?

--      (1 row affected)

------------------------------------------------------------------------


------------------------------------------------------------------------
-- 
--      test111:    sql UPDATE statement test 1
--
--      base update on original name
-- 
-- 
--

UPDATE sets
    set set_name = 'Alan M. Turing (update4)'
    where   set_name = 'Alan M. Turing (update3)'

go
--
--      Expect:
--
--      updated name for and existing node_id+seq_no combination
--      report from trigger about original record being deleted?
--
--      have to write logic to consider that the delete of an update-type insert has already happened.?
--
--
-- insert trigger:      record(s) being deleted:    1.
--
--  updated(1)         set00005 1   NULL         Alan Turing (updated)                                            
--  updated(2)         set00005 1   NULL         Alan Turing (updated)                                            
--
------------------------------------------------------------------------

------------------------------------------------------------------------
--
--          final output
--
print "quick/debug look at entire sets table"
select * from sets_short_view    
    order by set_id, seq
go
--
--
--         set_id   seq set_super_id set_name                                                         
--         -------- --- ------------ ---------------------------------------------------------------- 
--         set00001 1   NULL         Albert Einstein (updated)                                        
--         set00001 2   NULL         Albert Einstein 2                                                
--         set00001 3   NULL         Albert Einstein (third)                                          
--         set00002 1   NULL         Albert Einstein                                                  
--         set00002 2   NULL         Second record second synonym                                     
--         set00003 1   NULL         Alonso Church                                                    
--         set00004 1   NULL         Kurt Gödel                                                      
--         set00005 1   NULL         Alan M. Turing (update4)                                         
--         set00005 2   NULL         A. M. Turing                                                     
--         set00007 1   NULL         Alfred Tarski                                                    
--
--
------------------------------------------------------------------------
 


/* ======== */




/*
Mon Feb 14 07:27:03 PST 2011
 query_status_quick set_id   seq set_super_id set_name_64                                                      
 ------------------ -------- --- ------------ ---------------------------------------------------------------- 
 created_set_id     set00001 1   NULL         Albert Einstein                                                  

(1 row affected)
(1 row affected)
insert trigger:      record(s) being deleted:    1.
 query_status_quick set_id   seq set_super_id set_name_64                                                      
 ------------------ -------- --- ------------ ---------------------------------------------------------------- 
 found              set00001 1   NULL         Albert Einstein                                                  

(1 row affected)
(1 row affected)
 query_status_quick set_id   seq set_super_id set_name_64                                                      
 ------------------ -------- --- ------------ ---------------------------------------------------------------- 
 inserted           set00002 1   NULL         Albert Einstein                                                  

(1 row affected)
(1 row affected)
insert trigger:      record(s) being deleted:    1.
 query_status_quick set_id   seq set_super_id set_name_64                                                      
 ------------------ -------- --- ------------ ---------------------------------------------------------------- 
 found              set00001 1   NULL         Albert Einstein                                                  
 found              set00002 1   NULL         Albert Einstein                                                  

(2 rows affected)
(1 row affected)
 query_status_quick set_id   seq set_super_id set_name_64                                                      
 ------------------ -------- --- ------------ ---------------------------------------------------------------- 
 inserted           set00001 2   NULL         Albert Einstein 2                                                

(1 row affected)
(1 row affected)
insert trigger:      record(s) being deleted:    1.
 query_status_quick set_id   seq set_super_id set_name_64                                                      
 ------------------ -------- --- ------------ ---------------------------------------------------------------- 
 updated(1)         set00001 1   NULL         Albert Einstein (updated)                                        
 updated(2)         set00001 1   NULL         Albert Einstein (updated)                                        

(2 rows affected)
(1 row affected)
 query_status_quick set_id   seq set_super_id set_name_64                                                      
 ------------------ -------- --- ------------ ---------------------------------------------------------------- 
 inserted           set00001 3   NULL         Albert Einstein (third)                                          
 created_set_id     set00003 1   NULL         Alonso Church                                                    
 created_set_id     set00004 1   NULL         Kurt Gödel                                                      

(3 rows affected)
(3 rows affected)
 query_status_quick set_id   seq set_super_id set_name_64                                                      
 ------------------ -------- --- ------------ ---------------------------------------------------------------- 
 created_set_id     set00005 1   NULL         Alan Turing                                                      

(1 row affected)
(1 row affected)
(1 row affected)
 query_status_quick set_id   seq set_super_id set_name_64                                                      
 ------------------ -------- --- ------------ ---------------------------------------------------------------- 
 inserted           set00005 2   NULL         A. M. Turing                                                     

(1 row affected)
(1 row affected)
(1 row affected)
insert trigger:      record(s) being deleted:    1.
 query_status_quick set_id   seq set_super_id set_name_64                                                      
 ------------------ -------- --- ------------ ---------------------------------------------------------------- 
 updated(1)         set00005 1   NULL         Alan Turing (updated)                                            
 updated(2)         set00005 1   NULL         Alan Turing (updated)                                            

(2 rows affected)
(1 row affected)
insert trigger:      record(s) being deleted:    1.
 query_status_quick set_id   seq set_super_id set_name_64                                                      
 ------------------ -------- --- ------------ ---------------------------------------------------------------- 
 found              set00001 2   NULL         Albert Einstein 2                                                
 created_set_id     set00007 1   NULL         Alfred Tarski                                                    

(2 rows affected)
(2 rows affected)
insert trigger:      record(s) being deleted:    1.
 query_status_quick set_id   seq set_super_id set_name_64                                                      
 ------------------ -------- --- ------------ ---------------------------------------------------------------- 
 inserted           set00002 2   NULL         Second record second synonym                                     
 found              set00004 1   NULL         Kurt Gödel                                                      

(2 rows affected)
(2 rows affected)
(1 row affected)
(1 row affected)
(1 row affected)
quick/debug look at entire sets table
 set_id   seq set_super_id set_name                                                         
 -------- --- ------------ ---------------------------------------------------------------- 
 set00001 1   NULL         Albert Einstein (updated)                                        
 set00001 2   NULL         Albert Einstein 2                                                
 set00001 3   NULL         Albert Einstein (third)                                          
 set00002 1   NULL         Albert Einstein                                                  
 set00002 2   NULL         Second record second synonym                                     
 set00003 1   NULL         Alonso Church                                                    
 set00004 1   NULL         Kurt Gödel                                                      
 set00005 1   NULL         Alan M. Turing (update4)                                         
 set00005 2   NULL         A. M. Turing                                                     
 set00007 1   NULL         Alfred Tarski                                                    

(10 rows affected)
*/
