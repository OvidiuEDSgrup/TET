--***
create procedure wIaCoduriClasif @sesiune varchar(50), @parXML xml
as
begin try
	declare @mesajeroare varchar(500), @filtru_codcl varchar(20), @filtru_dencodcl varchar(100), @filtru_durmin int, @filtru_durmax int

	select	
		@filtru_codcl = ISNULL(@parXML.value('(/row/@f_codcl)[1]', 'varchar(20)'),''),
		@filtru_dencodcl = ISNULL(@parXML.value('(/row/@f_dencodcl)[1]', 'varchar(100)'),''),
		@filtru_durmin = @parXML.value('(/row/@f_durmin)[1]', 'int'),
		@filtru_durmax = @parXML.value('(/row/@f_durmax)[1]', 'int')

	select rtrim(Cod_de_clasificare) as cod, rtrim(Denumire) as denumire, 
		(case when Este_grup=1 then 'Da' else 'Nu' end) as estegrup, convert(decimal(12,0),DUR) as dur, 
		convert(decimal(12,0),dur_min) as durmin, convert(decimal(12,0),DUR_max) as durmax, 
		Este_grup as grup
	from Codclasif --select * from Codclasif
	where (@filtru_codcl='' or Cod_de_clasificare like rtrim(@filtru_codcl)+'%')
		and (@filtru_dencodcl='' or Denumire like +'%'+rtrim(@filtru_dencodcl)+'%')
		and (@filtru_durmin is null or Dur_min=@filtru_durmin)
		and (@filtru_durmax is null or Dur_max=@filtru_durmax)
	order by Cod_de_clasificare
	for xml raw
end try

begin catch
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare,11,1)
end catch	
