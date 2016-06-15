--***
create procedure wIaButoane @sesiune varchar(50), @parXML XML
as
set transaction isolation level read uncommitted

declare @returnValue int
if exists(select * from sysobjects where name='wIaButoaneSP' and type='P')      
begin
	exec @returnValue = wIaButoaneSP @sesiune=@sesiune,@parXML=@parXML
	return @returnValue 
end

begin try

declare @utilizator varchar(50), @eroare varchar(2000)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

declare @grupeUtiliz table(grupe varchar(50))
insert into @grupeUtiliz
select grupa
from dbo.fIaGrupeUtilizator(@utilizator)

select b.*
from butoanePv b
where activ=1
and isnull(utilizator,'')='' or exists(select * from @grupeUtiliz g where b.utilizator=g.grupe)
order by ordine desc
for xml raw

end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wIaButoane)'
	raiserror(@eroare, 16, 1)
end catch
