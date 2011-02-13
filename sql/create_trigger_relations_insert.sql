/* file: "create_trigger_relations_insert.sql" */

use relations
go

create trigger relations_insert
on relations
for insert

as 

	/* 
     * A relation (	rel_id	, 	set_id  ) can be inserted singly or in a batch
     *  without a valid rel id (rel_id). Both the single or the entire batch
     *  will have a valid rel_id created, and will have correct value returned to the application.
        
        rel_id's are like:  r0000001, etc.   Yes, seven places.  Ten Million Relations!
	 
	 *
	 * There is a unique index ( rel_id	, 	set_id) on table relations
     *
     *  This trigger returns the inserted record(s) preceded by a "query status" which can have the values:
	 *  "created", "inserted", "queried", "updated".  a record can be queried and updated, the
	 *	    status returned is updated.
	 *
	 */

    declare @max_rel_id char(8)	-- node id datatype
    declare @max_rel_id_index int

    /* This query is confined to just well-formed rel_ids 
       so as to exclude any possible badly-formed (but more maximum) rel_ids 
       inserted but prior to being updated. */

    select @max_rel_id_index  =  
    
			isnull( convert( integer, right ( max( c.rel_id ) , 7 ) ) + 1 , 1 )
			
    from relations c where c.rel_id like "r[0-9][0-9][0-9][0-9][0-9][0-9][0-9]"  
    

    select @max_rel_id = "r" + right( "0000000" +    ltrim( str(	    @max_rel_id_index	   ))    , 7 )
    

    /* debugging display */
    
--     select @max_rel_id "max rel id" , @max_rel_id_index  "max_rel_id_index"
     

    /* Create sequential rel_ids by counting (ranking)
        the incoming (inserted) records based on a field (or combination) that
        distinguishes *each* incoming record (within the grouping that you want them to be ranked)
        eg, one combination is a.rel_id + a.set_id (string concatenation creates a single field for comparison.  
            (doesn't always work to do the ranking on a=a anb b>b but don't alwyas see why?  NULLS?)).  
        rel_ids are possibly all the same at this point; 
        but the combination of rel_ids and rel_names will be different
        because of the unique index). */
        
    /* relations are ranked only on the incoming "rel_id" so that a set of sets being added
        end up in the same relation.  insert ("A", xx)("A", yy)("B", xx) creates two relations. */

    /* We really are only looking at records inserted.  But we are *updating* the records in the existing table.
        thus we join on the IDs: rel_id and set_id. */
        
    /* count distinct rel_id prevents rel_id from being increased by count of all occurances of row_id 
        (ie all rows) present in that row_id's group of rows being inserted. */
    
    update  relations 
        set a.rel_id = (
            select "r" + right( "0000000" +  ltrim( str(	 

                    @max_rel_id_index +

                    (select count( distinct rel_id ) from relations b 

                       where (a.rel_id) > ( b.rel_id )

                       and b.rel_id not like 'r[0-9][0-9]0-9][0-9][0-9][0-9][0-9]')

                   ))   ,7)


        )
    from relations a, inserted
    where   a.rel_id  = inserted.rel_id	
    and     a.set_id  = inserted.set_id	
    and     inserted.rel_id not like "r[0-9][0-9][0-9][0-9][0-9][0-9][0-9]"


  /* each row in this relations table represents the occurance of a set/domain in a relation.
       Only secondary detail about the specific appearance of a set in a relation can be updated.
       (rel_id, set_id) pairs can only be inserted or deleted.  */

  /*
      update  relations 
        set a.rel_id = (
            select "r" + right( "0000000" +
                ltrim( str(	 
                isnull( convert( integer, right ( max( c.rel_id ) , 7 ) ) + 1 , 1 )
                    + (select count( * ) from relations b 
                       where (a.set_id1 + a.set_id2) > ( b.set_id1 + b.set_id2 ) 
                       and b.rel_id not like 'r[0-9][0-9]0-9][0-9][0-9][0-9][0-9]')
                   ))
               ,7)
            from relations c where c.rel_id like "r[0-9][0-9][0-9][0-9][0-9][0-9][0-9]"  -- have to confine to well-formed rel_ids in order to exclude the incoming, badly-formed, rel_id!
        )
    from relations a, inserted
    where   a.set_id1  = inserted.set_id1	-- if ids are the same in inserted table, then distinguish via name.  unique index on id,name will prevent dups here.
    and     a.set_id2  = inserted.set_id2	
    and     inserted.rel_id not like "r[0-9][0-9][0-9][0-9][0-9][0-9][0-9]"
  
    declare @updated_rowcount int
    select @updated_rowcount  = @@rowcount


  */
    


    /* 
     * Update node sequence numbers based on count/ranking within each rel_id.
     */
     
     /*
    update relations
    set a.rel_seq_no = 
            (select  max(rel_seq_no) from relations b where a.rel_id = b.rel_id ) +
            (select count(*) from relations c 
                    where a.rel_id = c.rel_id and a.rel_name >= c.rel_name and c.rel_seq_no = 0)
    from relations  a 
    where rel_seq_no = 0
     */
     
    /* create feedback to calling routine based on whether or not we created any new rel_ids */
    
    /* TODO: there's no way to remember/retain which records are actually being updated
        with either new ids or new seq_no's.  Really, there's no way, once we update either
        rel_id or rel_seq_no to remember even which records were inserted.  A hack is to
        look for rel_id's larger than any when we first began but this fails if there
        are already larger rel_id's present when we insert. */

    /* temp tables to retain those records updated? */

/*
    if @updated_rowcount > 0 
        select "created"  "query status", relations.* 
            from relations , inserted
            where relations.rel_name = inserted.rel_name	
            and relations.rel_id >= @max_rel_id -- = ( select max(rel_id) from relations )
    else  
        select "inserted" "query status", relations.* 
            from relations , inserted
            where relations.rel_name = inserted.rel_name	
            and relations.rel_id = inserted.rel_id	
*/

   /* 
    *   Update relation name.
    *   An insertion is actually an update of rel name if inserted row matches on rel_id and rel_seq_no.
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

   

go

 
/* 
        Sybase insert triggers are AFTER triggers.  

        The  logical table "inserted" is a copy of rows that have *already* been inserted. 

        "During an insert or an update, new rows are added 
        to the inserted and trigger tables at the same time. The rows in inserted 
        are copies of the new rows in the trigger table." [sqlug557]

        Constraints such as unique index, checks, happen BEFORE the trigger
        and can prevent the sequence from even getting this far.  So: don't
        plan on    correcting* an integrity violation inside of the trigger. ;-)

        "A trigger "fires" only after the data modification statement has completed 
        and Adaptive Server has checked for any datatype, rule, or integrity constraint violation. [sqlug552]    

*/





/*
Fri Jan 21 14:28:54 PST 2011
*/


/*
Fri Jan 21 15:03:09 PST 2011
*/


/*
Fri Jan 21 16:29:02 PST 2011
*/
