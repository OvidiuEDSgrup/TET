select 'alter table '+o.name+' drop column This_Is_My_Ident_Col_Name' 
from sys.columns c join sys.objects o on o.object_id=c.object_id
where c.name like 'This_Is_My_Ident_Col_Name%'

select * -- delete t
from webConfigTipuri t where meniu  is null or tip is null or subtip is null or ordine is null 