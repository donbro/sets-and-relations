/* file: "create_trigger_sets_insert.sql" */

use relations
go

/* Some node_id related utility procedures and a tempdb table to hold a copy of rows to be returned
    to the calling procedure as feedback.  */

drop procedure n2nid 
go

create procedure n2nid         -- yields the conversion: 5 ==> "set00005"         
    @index_in int ,  
    @nid_prefix varchar(8) ,
    @nid_filler varchar(8) ,
    @nid_out char(8) output 
as 
 select  @nid_out =  @nid_prefix + right( @nid_filler +    ltrim( str( @index_in ) )   , char_length( @nid_filler ) ) 
go

/* CREATE PROCEDURE must be the first command in a query batch. */

drop procedure nid2n 
go

create procedure nid2n          -- does not add one to result (although we gererally *want* to add one.)
    @max_set_id     char(8),
    @nid_prefix varchar(8) ,
    @nid_filler varchar(8) ,
    @index_out      int         output
as
    select @index_out =
		isnull( convert( integer, right( @max_set_id, char_length( @nid_filler ) ) ) + 0 , 0 )

    
go

if  1 = 1 -- testing  
begin

    declare @set_id char(8)    
    exec n2nid   5,         "set",   "00000",  @set_id output    -- yields the conversion: 5 ==> "set00005"         
     
    declare @set_id_index int
    exec nid2n   @set_id,   "set",  "00000",  @set_id_index output     --    yields the conversion: "set00005" ==> 5 

    
    declare @max_set_id char(8)
    
    select 
        @max_set_id = max( c.set_id )  
    from sets c 
        where c.set_id like "set[0-9][0-9][0-9][0-9][0-9]" 

    /* find max of existing, valid set_id's.  exclude any badly formed ids which would have to be from the insertion. */

    exec nid2n @max_set_id,  "set",  "00000",  @set_id_index output
  
end
go

/*
Sat Jan 22 01:13:04 PST 2011
*/


/*
Sat Jan 22 01:13:17 PST 2011
(return status = 0)

Return parameters:

          
 -------- 
 set00005 


(1 row affected)
(return status = 0)

Return parameters:

             
 ----------- 
           5 


(1 row affected)
(1 row affected)
(return status = 0)

Return parameters:

             
 ----------- 
           9 


(1 row affected)
*/
