	--***
Create procedure wIaCatProprietati @sesiune varchar(50)=null, @parxml xml=null
as

declare @eroare varchar(max)
begin try  
	declare @utilizator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	declare @f_descriere varchar(500), @flk_descriere varchar(500), @f_cod_proprietate varchar(500),
			@f_catalog varchar(500), @flk_catalog varchar(500)
	select	@f_cod_proprietate=replace(@parxml.value('(row/@f_cod_proprietate)[1]','varchar(100)'),' ','%'),
			@f_descriere=@parxml.value('(row/@f_descriere)[1]','varchar(100)'),
			@f_catalog=@parxml.value('(row/@f_catalog)[1]','varchar(500)')
	select	@flk_descriere='%'+replace(isnull(@f_descriere,''),' ','%')+'%',
			@flk_catalog='%'+replace(@f_catalog,' ','%')+'%'
	
	create table #corespondente(cod varchar(1), catalog varchar(500))
	
	insert into #corespondente (cod, catalog)
	select 'N','Nomenclator' union all
	select 'G', 'Gestiuni' union all
	select 'T', 'Terti' union all
	select 'L', 'Locuri de munca' union all
	select 'C', 'Comenzi' union all
	select 'V', 'Valute' union all
	select 'U', 'UM' union all
	select 'R', 'Grupe nomenclator' union all
	select 'M', 'Masini' union all
	select 'O', 'Conturi' union all
	select 'E', 'Operatii' union all
	select 'B', 'Subunitati' union all
	select 'P', 'Grupe comenzi' union all
	select 'S', 'Salariati' union all
	select 'I', 'Localitati'
	
	select	top 100
			rtrim(Cod_proprietate) cod_proprietate, rtrim(Descriere) descriere,
			rtrim(Validare) validare, rtrim(c.Catalog) catalog,
			rtrim(Proprietate_parinte) proprietate_parinte,
			convert(varchar(1),validare)+' - '+(case validare	when 0 then 'Fara validare'
							when 1 then 'Lista'
							when 2 then 'Catalog'
							when 3 then 'Compusa' end) as etvalidare,
			rtrim(c.catalog)+' - '+o.catalog as etcatalog
	from catproprietati c left join #corespondente o on c.catalog=o.cod
	where (@f_descriere is null or c.Descriere like @flk_descriere)
		and (@f_cod_proprietate is null or c.Cod_proprietate like @f_cod_proprietate)
		and (@f_catalog is null or c.catalog like @f_catalog
			or len(@f_catalog)>1 and o.catalog like @flk_catalog)
	for xml raw

end try
begin catch
	set @eroare=ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
end catch

if len(@eroare)>0 raiserror(@eroare, 16,1)
