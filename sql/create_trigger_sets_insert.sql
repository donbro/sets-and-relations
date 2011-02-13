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

    new         (auto)          (new value)             "inserted"          inserted set_id, set_name as entered.

    existing     new            (any)                   "inserted"          inserted synonym.

    existing     existing       (updated value)         "updated"           updates name at set_id+set_seq_no
    
    
*/

/*
    set_seq_no 
        
    set_seq_no takes part in *no* queries(?)  
    
    set_seq_no is entirely "pass-through" with regards to this trigger.

    set_seq_no will be inserted if entered, otherwise automatically "sequenced" within set_id.
    
    set_seq_no has a default of 0.  this is (almost) immediately "sequenced" to be 
        one plus the current max set_seq_no for the set_id.


*/


    /* 
     *  "found"   (a query: a match on name returns matching records.)
     *
     *  (1) set_id is invalid and 
     *  (2) set_name is a match.
     *
     *  Return *all* matching records (possibly from different set_id's) .
     *
     *  Delete the record(s) that formed the query(s).  
     *  No records should end up being inserted due to a query.
     *
     */
     
     /* this query uses the fact that existing set records have valid set_ids.
            only inserted records can have invalid set_ids. */
            
    
    insert tempdb..sets
        select 
            "found" "query_status", sets.set_id	,	sets.set_seq_no, sets.set_name,	sets.set_super_id   
        from sets, inserted
        where   inserted.set_name = sets.set_name                              --  and set_name matches
        and     inserted.set_id not like "set[0-9][0-9][0-9][0-9][0-9]"     -- inserted set_id is invalid
        and     sets.set_id  like "set[0-9][0-9][0-9][0-9][0-9]"


    /* 
     *  "inserted"      (valid and new (not pre-existing) set_id)
     *
     *  (1) set_id is valid and 
     *  (2) set_id is not a match for any existing *before* insert.
     *
     *  nothing needs be done.  we're just doing the simple, basic SQL insert here.  oh and then we auto-seq :-)
     
     *  return inserted records that match this section: valid set_id and no previously existing set_id.  
     *
     *  later: could return "inserted" for no previously existing and "updated" for same but did previously exist.
     *  
     *  use fact that at this point there will only be *one* record in all of sets
     *      with this set_id?  All updates will have two, all queries dont have a valid set_id.
     *
     *  auto-seq routine at end will
     *      update all null set_seq_no's at once.
     *
     */

     /* this won't return an insert of a synonym where the set_id matches but the seq_no is new (or zero at this point)
            Use match on set_id and set_seq_no to ensure that we find 
            newly inserted records that are new seq_no's but for an existing set_id.
            */

    insert tempdb..sets
        select 
            "inserted" "query_status", ins.set_id	,	ins.set_seq_no, ins.set_name,	ins.set_super_id   
        from inserted ins
        where       ins.set_id like "set[0-9][0-9][0-9][0-9][0-9]"     -- inserted set_id is valid
        and     (select count(*) from sets b where ins.set_id = b.set_id 
                        and ins.set_seq_no = b.set_seq_no ) = 1  -- no other record with this set_id and seq_no

    /* 
     *  "inserted"      (valid and new (not pre-existing) set_id)
     *
     *  (1) set_id is valid and 
     *  (2) set_id is a match for one existing record from before insert, so exactly two currently.
     *
     *  nothing needs be done here; have to delete the existing record at delete time.
     *
     */
     

    insert tempdb..sets
        select 
            "updated(1)" "query_status", ins.set_id	,	ins.set_seq_no, ins.set_name,	ins.set_super_id   
        from inserted ins
        where       ins.set_id like "set[0-9][0-9][0-9][0-9][0-9]"     -- inserted set_id is valid
        and     (select count(*) from sets b where ins.set_id = b.set_id 
                        and ins.set_seq_no = b.set_seq_no ) = 2  -- just one other record with this set_id and seq_no

    /* this second approach is based not on the appearance of two records but 
            more on the fact that there is an inserted name that doesn't match a record
            with set_id, seq_no but a different set_name. */
    
    insert tempdb..sets
        select 
            "updated(2)" "query_status", ins.set_id	,	ins.set_seq_no, ins.set_name,	ins.set_super_id   
        from sets, inserted ins
        where   sets.set_id     = ins.set_id
        and     sets.set_seq_no = ins.set_seq_no
        and     sets.set_name  != ins.set_name      -- add any other fields which might be part of any possible update.
        and     ins.set_id like "set[0-9][0-9][0-9][0-9][0-9]"     -- inserted set_id is valid
     
     
    /* 
     *  "created_set_id"   (invalid set_id)
     *
     *  (1) set_id is invalid and 
     *  (2) set_name does not match (is not one of) those that already exist (ie, that has a valid set_id)
     
     */
     
     
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
     *  auto-seq
     *
     * 
     *  Update node sequence numbers based on count/ranking within each set_id.
     *
     *
     *  the field set_seq_no has a default of 0.  this is the clue to "sequence" the record
     *  which is to update the seq_no to one plus the current max set_seq_no for the set_id. 
     *
     *
     * update tempdb first because we are using values from sets to do this calc. 
     *
     */

     
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




    /* 
     *  "updated"   (valid and existing set_id)
     *
     *
*/

/*
    There is a unique index on sets ( set_id, set_seq_no, set_name )
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
    and     sets.set_name  != inserted.set_name      -- add any other fields which might be part of any possible update.

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
        