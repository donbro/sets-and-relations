use relations
go

truncate table sets
go

/*
 *  first test:
 *      Name and no set_id ==> Create a new set_id.
 *
 */

INSERT INTO sets (set_name) values ("Albert Einstein")
go

/*
 *  first result:
 *      Created a new set_id ("set00001")
 *
 *  query_status_quick set_id   seq set_super_id set_name_64                                                      
 *  ------------------ -------- --- ------------ ---------------------------------------------------------------- 
 *  created_set_id     set00001 1   NULL         Albert Einstein                                                  
 *
 */
 

/*
 *  second test:
 *      Matching name and no set_id ==> Find and return existing set_id.
 *
 */

INSERT INTO sets (set_name) values ("Albert Einstein")
go

/* 
 *  second result:
 *      Found and returned an existing set_id ("set00001").
 *
 *   query_status_quick set_id   seq set_super_id set_name_64                                                      
 *    ------------------ -------- --- ------------ ---------------------------------------------------------------- 
 *    found              set00001 1   NULL         Albert Einstein                                                  
 *   
 */

-- Any name, no seq_no and existing set_id ==> New sequence number at existing set_id:

INSERT INTO sets (set_id, set_name) values ( "set00001" , 'Albert Einstein 2' )

/*
 set_id   seq set_super_id set_name                                                         
 -------- --- ------------ ---------------------------------------------------------------- 
 set00001 2   NULL         Albert Einstein 2                                                

*/

 -- Any name and matching seq_no and existing set_id ==> Update the record.
 
INSERT INTO sets (set_id, set_seq_no, set_name) values ( "set00001" , 1,  'Albert Einstein (updated)' )

/*
 set_id   seq set_super_id set_name                                                         
 -------- --- ------------ ---------------------------------------------------------------- 
 set00001 1   NULL         Albert Einstein 3                                                
*/

/* mix of updates and insertions */

INSERT INTO sets (set_id, set_name)
select "set00001" , 'Albert Einstein (third)' union
select "" , 'Alonso Church' union
select "" , 'Kurt Gödel'

/*
    Return a list of all records with additonal field describing action(s) performed 
        (eg, "found, created, updated: or "inserted")
    */
    

INSERT INTO sets (set_name) values ('Alan Turing')


declare @temp_set_id char(8)
 
select @temp_set_id = set_id 
from sets 
    where set_name = 'Alan Turing'
    
/* add synomym for existing node_id */    

INSERT INTO sets (set_id,   set_name)
select @temp_set_id ,   'A. M. Turing'
go

/* update name for existing node_id+seq_no */    

declare @temp_set_id char(8)
declare @temp_set_seq_no int

select @temp_set_id = set_id , 
       @temp_set_seq_no = set_seq_no 
from sets 
    where set_name = 'Alan Turing'

INSERT INTO sets (set_id, set_seq_no, set_name)
select @temp_set_id , @temp_set_seq_no , 'Alan Turing (updated)'
go

/* mix of updates and insertions */

-- The column set_seq_no in table sets does not allow null values.

INSERT INTO sets (set_id,   set_name)
select "" ,  'Albert Einstein 2' union
select "" ,  'Alfred Tarski' 


INSERT INTO sets (set_id, set_seq_no, set_name)
select "set00002" , 2,  "Second record second synonym" union
select "" , 0,  'Kurt Gödel'

go


print "select * from sets:"
select * from sets
    order by set_id, set_seq_no
go


 
--  column "set_id" in table sets has a default of "" which circumvents table constraint to not allow null values.


/* ======== */

