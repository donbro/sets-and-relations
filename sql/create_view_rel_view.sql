
drop view rel_view
go



/*

create view rel_view
    as
select relations.rel_id   , 
--    convert(char(24), relations.rel_name) "relations_rel_name", 
    relations.set_id, convert(char(2), sets.set_seq_no) "seq",  convert(char(32), sets.set_name) "set_name", 
from relations, sets  
where relations.set_id  = sets.set_id
and sets.set_seq_no = (select min(a.set_seq_no) from sets a)
 
go
*/

