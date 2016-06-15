create procedure creeazaGestiuniTransfer 
AS

select parametru,val_alfanumerica
into #pp
from par p
inner join gestiuni g on p.parametru=g.cod_gestiune
where tip_parametru='PG'

declare @gestiune varchar(20),@gesttransfer varchar(200)
set @gestiune=null
select top 1 @gestiune=parametru,@gesttransfer=val_alfanumerica from #pp
while @gestiune is not null
begin
	insert into #gesttransfer
	select @gestiune,s.string,s.id
	from dbo.fsplit(@gesttransfer,';') s
	
	delete from #pp where parametru=@gestiune
	set @gestiune=null
	select top 1 @gestiune=parametru,@gesttransfer=val_alfanumerica from #pp
end
