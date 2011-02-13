/* file:  "create_table_relations.sql" */

use relations
go

drop table relations
go


 
/*
    The default takes effect only if the user does not add an entry to the 
    advance column of the titles table. Not making an entry is different than 
    entering a null value. A default can connect to a particular column, to a 
    number of columns, or to all columns in the database that have a given 
    user-defined datatype.  [sqlug 456]
*/

/* some debate: allowing NULL in rel_id allows some simpler inserts (insert relations (rel_name) values ("first relation")
	but generally is too permissive: we don't want NULLS particularly when "" isn't NULL. (?)

	also: could create constraint primary key but I seem to prefer NOT NULL in the create table and an explicit clustered unique index 
	  since these two together are the same as a primary key constraint?
	  
        r0000001, etc. (yes, six places.  Ten Million Relations!

 */

create table relations (
	rel_id		    char(8)		    not null, 
	set_id	        char(8)		    not null
	                                            -- do we have a name for the role/participation of the domain
	                                            --    No.  The set_id is a sub-domain: the name of the sub-domain is the name of the role.
--	set_id1	        char(8)		    not null,
--	set_id2         char(8)	        not null,
--	rel_name	    varchar(132)	null            -- possibly in another table?
)
go

/*
You can create that unique index using either the unique or primary key constraint or the create index 
statement. [Sybase 12.5 sqlug]
*/

/* unique constraint on rel_id precludes inserting a list of ("","relation one")("", "relation two"), etc.  which we seem to want to be able to do. */

-- can't have unique on rel_id and still insert a list of undefined rel_id's at once :-(
    
--create unique  index rel_id  -- not clustered.  why??
--on relations.dbo.relations ( rel_id )
--go

create unique clustered index relations_rel_id_set_id 
on relations.dbo.relations ( rel_id, set_id )
go



/*
Fri Jan 21 13:30:35 PST 2011
*/

sp_help relations
go




/*
Fri Jan 21 16:25:51 PST 2011
 Name                           Owner                          Object_type                      
 ------------------------------ ------------------------------ -------------------------------- 
 relations                      dbo                            user table                       

(1 row affected)
 Data_located_on_segment        When_created               
 ------------------------------ -------------------------- 
 default                               Jan 21 2011  4:25PM 
 Column_name     Type            Length      Prec Scale Nulls Default_name    Rule_name       Access_Rule_name               Identity 
 --------------- --------------- ----------- ---- ----- ----- --------------- --------------- ------------------------------ -------- 
 rel_id          char                      8 NULL  NULL     0 NULL            NULL            NULL                                  0 
 set_id          char                      8 NULL  NULL     0 NULL            NULL            NULL                                  0 
 index_name                     index_description                                                   
	 index_keys                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
	 index_max_rows_per_page index_fillfactor index_reservepagegap index_created       
 ------------------------------ --------------------------------------------------------------------
	 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	 ----------------------- ---------------- -------------------- ------------------- 
 relations_rel_id_set_id        clustered, unique located on default                                
	  rel_id, set_id                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
	                       0                0                    0 Jan 21 2011  4:25PM 

(1 row affected)
No defined keys for this object.
Object is not partitioned.
Lock scheme Allpages
The attribute 'exp_row_size' is not applicable to tables with allpages lock scheme.
The attribute 'concurrency_opt_threshold' is not applicable to tables with allpages lock scheme.
 
 exp_row_size reservepagegap fillfactor max_rows_per_page identity_gap 
 ------------ -------------- ---------- ----------------- ------------ 
            1              0          0                 0            0 

(1 row affected)
 concurrency_opt_threshold optimistic_index_lock dealloc_first_txtpg 
 ------------------------- --------------------- ------------------- 
                         0                     0                   0 
(return status = 0)
*/
