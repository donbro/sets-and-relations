/* file:  "test_relation_text_1.sql" */

use relations
go

drop table relation_text
go


create table relation_text (
	rt_id	         char(8)		  default ""  not null, 
	rel_text		    varchar(240)    null
)
go

create unique clustered index relation_text_rt_id
    on relations.dbo.relation_text ( rt_id , rel_text )
go

drop view rel_text_view
go

create view rel_text_view as
    select rt_id, convert(char(80), rel_text) "rel_text" from relation_text
go

--sp_help relation_text
--go


/* create a temp table, updated as with existing, then returned as feedback to calling routine. */

drop table tempdb..relation_text
go

create table tempdb..relation_text (
    rt_id	         char(8)		  default ""  not null, 
    rel_text		    varchar(240)    null
)
go

drop procedure index_to_node_id 
go

create procedure index_to_node_id 
    @node_id_index int ,  
    @node_id_prefix varchar(8) ,
    @node_id_filler varchar(8) ,
    @node_id_out char(8) output 
as 

 select  @node_id_out =  -- convert(char(8), 
                @node_id_prefix + right( "000000" +    ltrim( str( @node_id_index ) )   , 6 ) 
--            )  
  
go

  
 
  
create trigger relation_text_insert
on relation_text
for insert

as 

    /* create auto-increment style index on table relation_text  "rt000001" */
    
    declare @max_rt_id char(8)	-- node id datatype
    declare @max_rt_id_index int

    /* We consider only existing (which includes recently inserted) well-formed rt_ids.
        There may be badly-formed rt_ids in inserted that just happen to be more max()
        than what is already in the table. */

    select @max_rt_id_index  =  
    
			isnull( convert( integer, right ( max( c.rt_id ) , 6 ) ) + 1 , 1 )
			
    from relation_text c where c.rt_id like "rt[0-9][0-9][0-9][0-9][0-9][0-9]"  
    

    --  select @max_rt_id = "rt" + right( "000000" +    ltrim( str(	    @max_rt_id_index	   ))    , 6 )

    exec index_to_node_id @max_rt_id_index ,  "rt", "000000",  @max_rt_id output
    
    /* 
     * Truncate temp table then make a copy of the inserted table.
     *  update temp table to match current "created" IDs
     *  return as feedback to calling routine with "created" query_status.
     *
     */

    delete from tempdb..relation_text where 1 = 1
    
    insert tempdb..relation_text
    select * 
    from inserted 
    
 
    /* debugging display */
    
-- select @max_rt_id "max rel id" , @max_rt_id_index  "max_rt_id_index"

    update  relation_text 
        set a.rt_id = (
            select "rt" + right( "000000" +  ltrim( str(	 

                    @max_rt_id_index +

                    (select count(  b.rt_id+b.rel_text  ) from relation_text b 

                       where (a.rt_id+a.rel_text) > ( b.rt_id+b.rel_text )

                       and b.rt_id not like 'rt[0-9]0-9][0-9][0-9][0-9][0-9]')

                   ))   ,6)


        )
    from relation_text a, inserted
    where   a.rt_id  = inserted.rt_id	
    and     a.rel_text  = inserted.rel_text	
    and     inserted.rt_id not like "rt[0-9][0-9][0-9][0-9][0-9][0-9]"


    /* update same for the temp table, this is just for feedback to calling routine. */
    
    update  tempdb..relation_text 
        set a.rt_id = (
            select "rt" + right( "000000" +  ltrim( str(	 

                    @max_rt_id_index +

                    (select count(  b.rt_id+b.rel_text  ) from relation_text b 

                       where (a.rt_id+a.rel_text) > ( b.rt_id+b.rel_text )

                       and b.rt_id not like 'rt[0-9]0-9][0-9][0-9][0-9][0-9]')

                   ))   ,6)


        )
    from tempdb..relation_text a, inserted
    where   a.rt_id  = inserted.rt_id	
    and     a.rel_text  = inserted.rel_text	
    and     inserted.rt_id not like "rt[0-9][0-9][0-9][0-9][0-9][0-9]"

    /* debugging display */

    select "created" "query_status", * from tempdb..relation_text 

/*
patindex (“%pattern%”, 
char_expr [using {bytes | 
chars | characters}]) 
Returns an integer representing the starting position of the first 
occurrence of pattern in the specified character expression; 
returns 0 if pattern is not found. By default, patindex returns the 
offset in characters. 

substring (expression, start, length) Returns part of a character or binary string. start  specifies the 
character position at which the substring begins. length specifies 
the number of characters in the substring. 


*/

--    declare @offset1    int
--    select @offset1 = patindex (" is a " , a.rel_text )

  
    select  substring (a.rel_text, 1, patindex ("% is a %" , a.rel_text )), 
        substring (a.rel_text, patindex ("% is a %" , a.rel_text ), char_length(a.rel_text)), 
        patindex ("% is a %" , a.rel_text )
    from tempdb..relation_text a




-- end create trigger insertxxxx

go


insert into relation_text(rel_text) values ("Albert Einstein is a physicist")
go

select * from rel_text_view
    order by rt_id

go



/*
Fri Jan 21 19:02:29 PST 2011
 query_status rt_id   
	 rel_text                                                                                                                                                                                                                                         
 ------------ --------
	 ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ 
 created      rt000001
	 Albert Einstein is a physicist                                                                                                                                                                                                                   

(1 row affected)
                                                                                                                                                                                                                                                 
	                                                                                                                                                                                                                                                 
	             
 ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	 ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	 ----------- 
 Albert Einstein                                                                                                                                                                                                                                 
	  is a physicist                                                                                                                                                                                                                                 
	          16 

(1 row affected)
(1 row affected)
 rt_id    rel_text                                                                         
 -------- -------------------------------------------------------------------------------- 
 rt000001 Albert Einstein is a physicist                                                   

(1 row affected)
*/

-- 
-- insert into relation_text(rel_text) values ("Alan Turing is a computer scientist")
-- go
-- 
-- select * from rel_text_view
--     order by rt_id
-- 
-- go
-- 
-- 
-- INSERT INTO relation_text(rel_text)
-- select "George Harrison is a musician"   union
-- select "Ringo Starr is a musician."  
-- go
-- 
-- 
-- select * from rel_text_view
--     order by rt_id
-- 
-- go
-- 


