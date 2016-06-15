--***
create function fDenumiriRapMM(@sesiune varchar(50), @parXML xml)
returns @denumiri table (parametru varchar(50), valoare varchar(2000))
as 
begin

--	MM:
declare @element varchar(50), @masina varchar(50), @GrupaMasina varchar(50), @tipMasina varchar(50)

--	MM
select	@element=@parXML.value('(row/@element)[1]','varchar(50)'),
		@masina=@parXML.value('(row/@masina)[1]','varchar(50)'),
		@grupaMasina=@parXML.value('(row/@grupaMasina)[1]','varchar(50)'),
		@tipMasina=@parXML.value('(row/@tipMasina)[1]','varchar(50)')
	
	--	MM
	insert into @denumiri(parametru,valoare)
	select '@element', rtrim(isnull((select max(e.Denumire) from elemente e where e.Cod=@element),'<nu exista>'))
		where @element is not null union all
	select '@masina', rtrim(isnull((select max(m.denumire) from masini m where m.cod_masina=@masina),'<nu exista>'))
		where @masina is not null union all
	select '@tipMasina', rtrim(isnull((select max(t.Denumire) from tipmasini t where t.Cod=@tipMasina),'<nu exista>'))
		where @tipMasina is not null
		
	if (@grupaMasina is not null)	--> aici e altfel pt ca s-ar putea ca tabela sa nu existe (grupemasini)
	insert into @denumiri(parametru,valoare)	
	select '@grupaMasina', rtrim(isnull((case when @grupaMasina is not null then (select max(g.Denumire) from grupemasini g where g.Grupa=@grupaMasina) else '' end),'<nu exista>'))
		where @grupaMasina is not null

return
end
