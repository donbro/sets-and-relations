/* file "create_trigger_abbr_insert.sql" */

use relations
go

drop table abbr_calc
go


create table abbr_calc (
	set_name	    varchar(132)		            null,
	cp  	        int	       default 1     null,
	set_name_abbr	    varchar(24)		            null

)
go

/*
 *    Trigger self-recursion 
 *
 *    By default, a trigger does not call itself recursively. That is, an update 
 *    trigger does not call itself in response to a second update to the same table 
 *    within the trigger. If an update trigger on one column of a table results in 
 *    an update to another column, the update trigger fires only once. However, 
 *    you can turn on the self_recursion option of the set command to allow 
 *    triggers to call themselves recursively. The allow nested triggers 
 *    configuration variable must also be enabled for self-recursion to occur. 
 *
 *    The self_recursion setting remains in effect only for the duration of a 
 *    current client session. If the option is set as part of a trigger, its effect is 
 *    limited by the scope of the trigger that sets it. If the trigger that sets 
 *    self_recursion on returns or causes another trigger to fire, this option 
 *    reverts to off. Once a trigger turns on the self_recursion option, it can 
 *    repeatedly loop, if its own actions cause it to fire again, but it cannot 
 *    exceed the limit of 16 nesting levels. 
 
 nested triggers
 
 Triggers can nest to a depth of 16 levels. The current nesting level is stored 
in the @@nestlevel global variable. Nesting is enabled at installation. A 
System Administrator can turn trigger nesting on and off with the allow 
nested triggers configuration parameter. 

Msg 217, Level 16, State 1:
Server 'manny_ASE', Procedure 'abbr_insert', Line 58:
Maximum stored procedure nesting level exceeded (limit 16).


 *
 */

create trigger abbr_insert 
on abbr_calc 
for insert , update

as 

     print "before if update (cp)"

if update (cp) 
begin

    print "inside if update (cp)"
  set self_recursion on

    declare @name_part varchar(132)
    
    -- substring (expression, start, length) 
    
    select  @name_part =  substring (a.set_name, a.cp, char_length(a.set_name) - a.cp +1 )  
        from abbr_calc a, inserted
            where a.set_name = inserted.set_name



    update abbr_calc
        set a.set_name_abbr = a.set_name_abbr  + substring( @name_part, 1 , 1) 

            
        from abbr_calc a, inserted
            where a.set_name = inserted.set_name
     -- charindex (expression1, expression2) Searches expression2 for the first occurrence of expression1


    select @@nestlevel "nestlevel (before)", convert(char(48),a.set_name) "set_name_48", str(a.cp,2) "cp", 
        convert(char(24),@name_part) "@name_part", a.set_name_abbr 
        from abbr_calc a, inserted    
            where a.set_name = inserted.set_name

    if charindex (" " , @name_part) != 0 and @@nestlevel < 8  -- 8 reps total, counting the one taht is about to happen
    begin

        -- updating a.cp is what fires off the recursive trigger 
        
        update abbr_calc
            set a.cp = charindex (" " , @name_part) + a.cp --  + 1-- cp is relative to field a.set_name, not @name_part

            
            from abbr_calc a, inserted
                where a.set_name = inserted.set_name
    end
end    
    -- select @@nestlevel "nestlevel (after)", convert(char(48),a.set_name) "set_name_48", a.set_name_abbr 
    --     from abbr_calc a, inserted
    -- 
    --         where a.set_name = inserted.set_name

go

   

/*
charindex (expression1, expression2) Searches expression2 for the first occurrence of expression1 and 
returns an integer representing its starting position. If expression1 
is not found, it returns 0. If expression1 contains wildcard 
characters, charindex treats them as literals.

substring (expression, start, length) Returns part of a character or binary string. start  specifies the 
character position at which the substring begins. length specifies 
the number of characters in the substring. 

*/

INSERT INTO abbr_calc (set_name, cp) values ("Albert Einstein", 1)
select  convert(char(48),a.set_name) "set_name_48", a.set_name_abbr 
    from abbr_calc a
            where a.set_name = "Albert Einstein"
go

truncate table abbr_calc
go

INSERT INTO abbr_calc (set_name ) values ("Albert Einstein" )
select  convert(char(48),a.set_name) "set_name_48", a.set_name_abbr 
    from abbr_calc a
            where a.set_name = "Albert Einstein"
go

truncate table abbr_calc
go

INSERT INTO abbr_calc (set_name, cp) values ("Alan M. Turing", 1)
select  convert(char(48),a.set_name) "set_name_48", a.set_name_abbr 
    from abbr_calc a
            where a.set_name = "Alan M. Turing"
go




/*  =========   */




/*
Thu Feb 17 16:40:12 PST 2011
before if update (cp)
inside if update (cp)
before if update (cp)
 nestlevel (before) set_name_48                                      cp @name_part               set_name_abbr            
 ------------------ ------------------------------------------------ -- ------------------------ ------------------------ 
                  1 Albert Einstein                                   1 Albert Einstein          A                        

(1 row affected)
before if update (cp)
inside if update (cp)
before if update (cp)
 nestlevel (before) set_name_48                                      cp @name_part               set_name_abbr            
 ------------------ ------------------------------------------------ -- ------------------------ ------------------------ 
                  2 Albert Einstein                                   8 Einstein                 AE                       

(1 row affected)
(1 row affected)
 set_name_48                                      set_name_abbr            
 ------------------------------------------------ ------------------------ 
 Albert Einstein                                  AE                       

(1 row affected)
before if update (cp)
inside if update (cp)
before if update (cp)
 nestlevel (before) set_name_48                                      cp @name_part               set_name_abbr            
 ------------------ ------------------------------------------------ -- ------------------------ ------------------------ 
                  1 Albert Einstein                                   1 Albert Einstein          A                        

(1 row affected)
before if update (cp)
inside if update (cp)
before if update (cp)
 nestlevel (before) set_name_48                                      cp @name_part               set_name_abbr            
 ------------------ ------------------------------------------------ -- ------------------------ ------------------------ 
                  2 Albert Einstein                                   8 Einstein                 AE                       

(1 row affected)
(1 row affected)
 set_name_48                                      set_name_abbr            
 ------------------------------------------------ ------------------------ 
 Albert Einstein                                  AE                       

(1 row affected)
before if update (cp)
inside if update (cp)
before if update (cp)
 nestlevel (before) set_name_48                                      cp @name_part               set_name_abbr            
 ------------------ ------------------------------------------------ -- ------------------------ ------------------------ 
                  1 Alan M. Turing                                    1 Alan M. Turing           A                        

(1 row affected)
before if update (cp)
inside if update (cp)
before if update (cp)
 nestlevel (before) set_name_48                                      cp @name_part               set_name_abbr            
 ------------------ ------------------------------------------------ -- ------------------------ ------------------------ 
                  2 Alan M. Turing                                    6 M. Turing                AM                       

(1 row affected)
before if update (cp)
inside if update (cp)
before if update (cp)
 nestlevel (before) set_name_48                                      cp @name_part               set_name_abbr            
 ------------------ ------------------------------------------------ -- ------------------------ ------------------------ 
                  3 Alan M. Turing                                    9 Turing                   AMT                      

(1 row affected)
(1 row affected)
 set_name_48                                      set_name_abbr            
 ------------------------------------------------ ------------------------ 
 Alan M. Turing                                   AMT                      

(1 row affected)
*/
