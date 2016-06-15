--***
create procedure proceduraCuJobModel @sesiune varchar(50)=null, @parXML xml=null, @idRulare int=0
as

if @idRulare=0 -- procedura e apelata din frame
begin
	declare @numeProcedura varchar(500)
	set @numeProcedura = object_name(@@procid)
	exec wOperatieLunga @sesiune=@sesiune, @parXML=@parXML, @procedura=@numeProcedura
	return
end

select @sesiune=p.sesiune, @parXML=p.parXML
from asisria..ProceduriDeRulat p
where idRulare=@idrulare  

declare @i int
set @i = 0
while @i < 101
begin
	update asisria..ProceduriDeRulat 
		set procent_finalizat=@i, statusText=case when @i<25 then 'incep lucrul' when @i<51 then 'Lucrez...' else 'Finalizare procese' end 
	where idRulare=@idrulare 

	waitfor delay '00:00:01'

	set @i=@i+5
end

-- select * from asisria..proceduriderulat order by idrulare desc

