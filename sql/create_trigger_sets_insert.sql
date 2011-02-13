/* file: "create_trigger_sets_insert.sql" */

use relations
go

/*  
 *  tempdb..sets
 *
 *  tempdb..sets is used to accumulate records for output.
 *
 *  (this table is possibly not needed; but (1) useful during development and (2)
        will be needed if we can't write the big union :)
    We are currently inserting rows into output table as we come to them.
        could possibly just do one large union at end and not need a temp table?
        
 *
 */
     
drop table tempdb..sets
go

select 
    convert(char(14),"") "query_status", sets.* 
into tempdb..sets 
from sets where 0 = 1 
go

/* debug/quicklook view on tempdb..sets */

drop view temp_sets_quick_look
go
create view temp_sets_quick_look as
    select  a.query_status          "query_status_quick", 
            a.set_id, 
            convert(char(2), a.set_seq_no)      "seq", 
            a.set_super_id , 
            convert(char(64),a.set_name) "set_name_64"
    from tempdb..sets a
go

/*  
 *  trigger sets_insert
 *
 *  trigger sets_insert is...
 
 also:
 /*      set_seq_no has a default of 0.  this is (almost) immediately "re-sequenced" to be 
        one plus the current max set_seq_no for the set_id. */

 *
 */

create trigger sets_insert
on sets
for insert

as 

    /* truncate output table. */
    
    delete from tempdb..sets where 1 = 1


/*

    Expected action(s)/output(s):

 	set_id      set_seq_no   	set_name	            query_status
 	------      ----------      --------                ------------
    
    invalid     (ignored)       matches existing        "found"             return all matching existing records.
                     
    invalid     (ignored)       doesn't match           "created_set_id"    create new set_id.  undefined seq_no, insert name

    valid        null           valid                  N/A             create new seq_no, insert id+name

    valid        valid          valid                  N/A             updates name at set_id+set_seq_no
    
    
    set_seq_no takes part in *no* queries(?)  
    
    the value is entirely "pass-through" with regards to this trigger.

    will be passively inserted if specified, otherwise automatically "sequenced" within set_id.
    
    set_seq_no has a default of 0.  this is (almost) immediately "sequenced" to be 
        one plus the current max set_seq_no for the set_id.


*/


    /* "found"   (ie, matched on name)
     *  (1) set_id is invalid and (2) set_name is a match, return *all* matching records
     *  (possibly from different set_id's) 
     */
     
     /* this query uses the fact that existing set records have valid set_ids.
            only inserted records can have invalid set_ids. */
            
    /* will have to delete the record that formed the query.  no records should end up being inserted due
            to a query  */
    
    insert tempdb..sets
        select 
            "found" "query_status", sets.set_id	,	sets.set_seq_no, sets.set_name,	sets.set_super_id   
        from sets, inserted
        where   inserted.set_name = sets.set_name                              --  and set_name matches
        and     inserted.set_id not like "set[0-9][0-9][0-9][0-9][0-9]"     -- inserted set_id is invalid
        and     sets.set_id  like "set[0-9][0-9][0-9][0-9][0-9]"

 
    declare @max_set_id char(8)	-- set_id datatype?
    declare @max_set_id_index int

    /* 
     * find max of existing, valid set_id's.  exclude any badly formed ids which would have to be from the insertion. 
     */

    select 
        @max_set_id_index = isnull( convert( integer, right ( max( c.set_id ) , 5 ) ) + 1 , 1 )
    from sets c 
    where c.set_id like "set[0-9][0-9][0-9][0-9][0-9]"  

    select  @max_set_id =  "set" + right( "00000" +    ltrim( str( @max_set_id_index ) )   , char_length( "00000" ) ) 

    -- exec n2nid @max_set_id_index ,  "set", "00000",  @max_set_id output


     /* "created_set_id" 
     *  (1) set_id is not valid and 
     *  (2) set_name (a) does not match an entry with a valid set_id (ie, is an existing entry)
     */

   /* invalid set_ids */
    
    /* actions:
        (1) insert records into tempdb but with newly created set_ids
        (2) update inserted records via sequence-generating select.
       return:
        updated records
     */

    /* have to exclude matching records that were included above */
    
    insert tempdb..sets
        select 
            "created_set_id" "query_status",  
             
            "set" + right( "00000" +                    
               ltrim( str(	 
                        @max_set_id_index 
                        + (select count( c.set_name ) from sets c 
                        where (ins.set_id + ins.set_name) > ( c.set_id + c.set_name ) 
                        and c.set_id not like 'set[0-9][0-9][0-9][0-9][0-9]'
                        )
                    ))
                
                ,5 )  "set_id" ,                 
                           
            ins.set_seq_no, ins.set_name,	ins.set_super_id      
        from  inserted ins
        where   ins.set_id not like "set[0-9][0-9][0-9][0-9][0-9]"     -- inserted set_id is invalid
        and     not exists (select b.set_name from sets b where ins.set_name = b.set_name
                                    and b.set_id like "set[0-9][0-9][0-9][0-9][0-9]")



    /*  update the output table */
    
/*
    update  tempdb..sets 
        set a.set_id = (
            select "set" + right( "00000" +
                ltrim( str(	 
                    @max_set_id_index 
                    + (select count( b.set_name ) from sets b 
                       where (a.set_id + a.set_name) > ( b.set_id + b.set_name ) 
                       and b.set_id not like 'set[0-9][0-9][0-9][0-9][0-9]')
                   ))
               ,5)
        )
    from tempdb..sets a, inserted
    where   a.set_name = inserted.set_name	-- if ids are the same in inserted table, then distinguish via name.  unique index on id,name will prevent dups here.
    and     a.set_id   = inserted.set_id	
    and     inserted.set_id not like "set[0-9][0-9][0-9][0-9][0-9]"

*/
        
    update  sets 
        set a.set_id = (
            select "set" + right( "00000" +
                ltrim( str(	 
                isnull( convert( integer, right ( max( c.set_id ) , 5 ) ) + 1 , 1 )
                    + (select count( b.set_name ) from sets b 
                       where (a.set_id + a.set_name) > ( b.set_id + b.set_name ) 
                       and b.set_id not like 'set[0-9][0-9][0-9][0-9][0-9]')
                   ))
               ,5)
            from sets c where c.set_id like "set[0-9][0-9][0-9][0-9][0-9]"  -- have to confine to well-formed set_ids in order to exclude the incoming, badly-formed, set_id!
        )
    from sets a, inserted ins
    where   a.set_name = ins.set_name	-- if ids are the same in inserted table, then distinguish via name.  unique index on id,name will prevent dups here.
    and     a.set_id   = ins.set_id	
    and     ins.set_id not like "set[0-9][0-9][0-9][0-9][0-9]"
    and     not exists (select * from sets b where ins.set_name = b.set_name
                                    and b.set_id like "set[0-9][0-9][0-9][0-9][0-9]")



    
    /* 
     * Update node sequence numbers based on count/ranking within each set_id.
     *
     */
/*      set_seq_no has a default of 0.  this is (almost) immediately "re-sequenced" to be 
        one plus the current max set_seq_no for the set_id. */
     
     /* update tempdb first because we are using values from sets to do this calc. */
     
    update tempdb..sets
    set a.set_seq_no = 
            (select  max(set_seq_no) from sets b where a.set_id = b.set_id ) +
            (select count(*) from sets c 
                    where a.set_id = c.set_id and a.set_name >= c.set_name and c.set_seq_no = 0)
    from tempdb..sets  a 
    where set_seq_no = 0

    update sets
    set a.set_seq_no = 
            (select  max(set_seq_no) from sets b where a.set_id = b.set_id ) +
            (select count(*) from sets c 
                    where a.set_id = c.set_id and a.set_name >= c.set_name and c.set_seq_no = 0)
    from sets  a 
    where set_seq_no = 0





        
--    select "created"  "query status (temp)", set_id   , 
--        set_seq_no  , set_super_id , 
--        convert(char(64),set_name) "set_name"
--    from tempdb..sets 
     
    /* create feedback to calling routine based on whether or not we created any new set_ids */
    /* TODO: there's no way to remember/retain which records are actually being updated
        with either new ids or new seq_no's.  Really, there's no way, once we update either
        set_id or set_seq_no to remember even which records were inserted.  A hack is to
        look for set_id's larger than any when we first began but this fails if there
        are already larger set_id's present when we insert. */

    /* temp tables to retain those records updated? */

/*

    if @updated_rowcount > 0 
        -- convert char(80) just for testing convenience.  remove before wrapping :-)
        
        select "created"  "query status (sets)", sets.set_id   , sets.set_seq_no  , sets.set_super_id , convert(char(80),sets.set_name) "set_name"
            from sets , inserted
            where sets.set_name = inserted.set_name	
            and sets.set_id >= @max_set_id -- = ( select max(set_id) from sets )
    else  
        select "inserted" "query status", sets.* 
            from sets , inserted
            where sets.set_name = inserted.set_name	
            and sets.set_id = inserted.set_id	

*/

   /* 
    *   Update set name.
    *   An insertion is actually an update of set name if inserted row matches on set_id and set_seq_no.
    *   We handle this by simply deleting the previously existing record?
    *
    *   Probably should actually update the existing record: some details of the row
    *     might want to stay the same :-)
    
     * If an insertion matches an existing (node_id, node_seq_no) 
     * then we have an update of the record.
     * At this (or any) point inside this trigger there will be two records in the nodes table: 
     * the previously existing and the newly inserted; matching on node_id, node_seq_no
     * but differing (hopefully) on node_name (and/or any other fields (?) )
            (this is why we cna't ahve anythong like a unique on ndoe_id, seq, it would prevent this update mechanism)
     *
     * Delete the record from nodes that matches node_id, node_seq_no but doesn't match node_name (...)
     *
     */

    delete sets
            from sets, inserted 
    where   sets.set_id     = inserted.set_id
    and     sets.set_seq_no = inserted.set_seq_no
    and     sets.set_name  != inserted.set_name      -- have to add any other fields which might be different ?!

    /* if we delete any rows, tell the caller about it. */
    
    declare @deleted_row_count int
    select  @deleted_row_count = @@rowcount  
    /* some output message format strings */

    declare @msg_prefix varchar(40)
    select @msg_prefix = 'insert trigger:      ' 

    declare @msg            varchar(240)  
--    select @msg = @msg_prefix + 'rows in inserted:                    '+ convert(varchar(4), @total_rows_inserted) + "."


    if @deleted_row_count != 0 
    begin

            select @msg = @msg_prefix + 'record(s) being deleted:    '+ convert(varchar(4), @deleted_row_count) + "."
            print @msg -- insert trigger:      invalid set id(s) being updated:    2.
            
    end
 
    /* "found"   (ie, matched on name)
            
        delete the record that formed the query.  no records should end up being inserted due
            to a query
   
        delete those inserted rows from sets which are actually queries
            (but not until the end when we have already processed the other cases.)
            
        delete the one(s) which is *not* the existing, matching, one(s).
            
    */

 
   delete sets
       from sets, inserted
   where   inserted.set_name = sets.set_name                              --  and set_name matches
   and      inserted.set_id not like "set[0-9][0-9][0-9][0-9][0-9]"     -- inserted set_id is invalid
   and     sets.set_id  = inserted.set_id             -- delete the one which is *not* the existing, matching, one.


   /* output (returned select set) table */

   select * from temp_sets_quick_look
    order by set_id, seq -- column name of view is not "set_seq_no" because we convert to char(3) for output.


   -- /* quick/debug look at entire sets table */
   -- 
   --  select * from sets_short_view    
   --  order by set_id, seq
    
    -- print "end trigger sets_insert"

    return -- all we need to do for volume inserts and queries

go

/* ========== */





/* ============ */
 


	/* 
	 * A set (set_id, set_name) being inserted without a valid set id (set_id)
	 *  will have one created, and will have correct value returned to the application.
	 *  The form of "well-formed" set IDs are like: "set00001"
	 
	 *
	 * A unique index (set_id) as well as (set_id, set_name)
 	 *  prevents duplicates from reaching this trigger. 
	 *	note that duplicated set anmes are possible, they may exist in different contexts.
     *
     *  This trigger returns the record preceded by a "query status" which can have the values:
	 *  "created", "inserted", "queried", "updated".  a record can be queried and updated, the
	 *	    status returned is updated.
	 *
	 */


	/* hoped for a single select statement: update sets set sets.set_id to (big calculation)
   	    and could've had it if not for the need to also reflect back to the caller
		a select set of the changed rows. 
	  So have to create a temp vaiable of the least max node id prior to updating to
	   use to do the select that goes back to the user.  sigh. 
	   */
	   
	   
	   
/* 
 *              Sybase insert triggers are AFTER triggers.  
 *
 *              The  logical table "inserted" is a copy of rows that have *already* been inserted. 
 *
 *              "During an insert or an update, new rows are added 
 *               to the inserted and trigger tables at the same time. The rows in inserted 
 *               are copies of the new rows in the trigger table." [sqlug557]
 *
 *              Constraints such as unique index, checks, happen BEFORE the trigger
 *                and can prevent the sequence from even getting this far.  So: don't
 *                plan on *correcting* an integrity violation inside of the trigger. ;-)
 *      
 *              "A trigger "fires" only after the data modification statement has completed 
 *               and Adaptive Server has checked for any datatype, rule, or integrity constraint violation. [sqlug552]
 *
 */	   
 
 
 
 
     /* debugging display */
   -- select @max_set_id "max set id" , @max_set_id_index  "max_set_id_index"


    /*  
     *    Sybase insert triggers are AFTER triggers. The logical table "inserted" is a  copy of rows that have *already* been inserted.   
     */

    
    /* created (updated) set_ids are for when there is no match on set_name.
        If match on set name then we have a found (and this case is excluded from the create/update select.) */
        
    /* do found case(s) */
    
    

    /* first do a match on, eg, "Albert Einstein" already appearing.  If the insert didn't
        specify a superset then return any existing.  If superset then try match on name, superset,
        return matching or creating new.  return feedback. */

    /* if match on set_name and no superset, then delete inserted set_name, superset_id 
          and return existing set.  If match on name but superset is different, then insert and return inserted. */

          /* a subsequent insert of an identical name should "find" the first:  "found", "set00001", etc., not "created", "set00002", etc. 
          */

        
--    delete sets where a.set_name = "Albert Einstein" and a.set_id = ""
--    from sets a, inserted
--    where   a.set_name = inserted.set_name	-- if ids are the same in inserted table, then distinguish via name.  unique index on id,name will prevent dups here.
--   and     a.set_id   = inserted.set_id	
--    and     inserted.set_id not like "set[0-9][0-9][0-9][0-9][0-9]"


    /* Create sequential set_ids by counting (ranking)
        the incoming (inserted) records based on a.set_id + a.set_name.  
        Set_ids are possibly all the same at this point; 
        but the combination of Set_ids and set_names will be different
        because of the unique index). */