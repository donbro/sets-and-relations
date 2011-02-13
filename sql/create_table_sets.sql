/* file:  "create_table_sets.sql" */

use relations
go

drop table sets
go

/*         set_ids are: set00001, etc. Yes, five places.  100,000 sets!       */


create table sets (
	set_id		    char(8)		    default ""      not null, 
	set_seq_no      int             default 0       not null,   
	set_name	    varchar(132)		            null,
	set_super_id	char(8)		                    null
)
go


create unique index sets_set_id_seq_no_name -- create unique clustered index
    on relations.dbo.sets ( set_id, set_seq_no, set_name )
go


drop view sets_short_view
go

create view sets_short_view as
    select 
        set_id, 
        convert(char(2), set_seq_no) "seq" ,
        set_super_id ,
        convert(char(64), set_name) "set_name"
    from sets
go


  
/* ============ */ 

/*
    The default takes effect only if the user does not add an entry to the 
    advance column of the titles table. Not making an entry is different than 
    entering a null value. A default can connect to a particular column, to a 
    number of columns, or to all columns in the database that have a given 
    user-defined datatype.  [sqlug 456]
*/



/* some debate: allowing NULL in set_id allows some simpler inserts (insert sets (set_name) values ("first set")
	but generally is too permissive: we don't want NULLS expecially when "" is *not* a NULL?

	also: could create constraint primary key but I seem to prefer NOT NULL in the create table and an explicit clustered unique index 
	  since these two together are the same as a primary key constraint?
	  
  -- (nulls allow cleaner insert syntax?) -- not null, -- primary key,		/* set00001, etc. (yes, five places.  100,000 sets! )  */	  

 */
 
 
 /* The default takes effect only if the user does not add an entry to the 
    advance column of the titles table. Not making an entry is different than 
    entering a null value.[sqlug 456]

    create default default_zero    as 0 

        You can create that unique index using either the unique or primary key constraint or the create index 
        statement. [Sybase 12.5 sqlug]
*/



/* unique constraint on set_id precludes inserting a list of ("","set one")("", "set two"), etc.  which we seem to want to be able to do. */

-- create unique clustered index set_id 
-- on relations.dbo.sets ( set_id )
-- go
