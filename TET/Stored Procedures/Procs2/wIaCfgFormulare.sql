--***
create procedure wIaCfgFormulare (@sesiune varchar(50), @parXML xml)
as
begin try
	declare 
		@denumire varchar(200), @fisier varchar(200), @procedura varchar(200),
		@fltDenumire bit, @fltFisier bit, @fltProcedura bit, @fltTipFormular bit, @fltCaleRaport bit,
		@tip_formular varchar(20), @cale_raport varchar(150), @utilizator varchar(20),
		@meniu_asociat varchar(200), @tip_asociat varchar(200)

	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

	select
		@denumire = @parXML.value('(row/@denFormular)[1]', 'varchar(200)'),
		@fisier = @parXML.value('(row/@fisier)[1]', 'varchar(200)'),
		@procedura = @parXML.value('(row/@procedura)[1]', 'varchar(200)'),
		@tip_formular = @parXML.value('(row/@filtru_tip)[1]', 'varchar(20)'),
		@cale_raport = @parXML.value('(row/@filtru_raport)[1]', 'varchar(150)'),
	--> filtrare pe meniu si/sau tip asociat
		@meniu_asociat = @parXML.value('(row/@meniu_asociat)[1]', 'varchar(150)'),
		@tip_asociat = @parXML.value('(row/@tip_asociat)[1]', 'varchar(150)')

	--> daca meniul si tipul nu sunt de gasit incerc sa le identific dupa denumire:
	if @meniu_asociat is not null and not exists (select 1 from webconfigtipuri t where t.meniu=@meniu_asociat)
		select @meniu_asociat=isnull((select top 1 m.Meniu from webconfigmeniu m where m.Nume like @meniu_asociat),@meniu_asociat)
	if @tip_asociat is not null and not exists (select 1 from webconfigtipuri t where t.Tip=@tip_asociat and (@meniu_asociat is null or t.meniu=@meniu_asociat))
		select @tip_asociat=isnull((select top 1 t.Tip from webconfigtipuri t where t.Nume like @tip_asociat and (@meniu_asociat is null or t.meniu=@meniu_asociat)),@tip_asociat)

	select
		@fltDenumire = (case when isnull(@denumire, '') = '' then 0 else 1 end),
		@fltFisier = (case when isnull(@fisier, '') = '' then 0 else 1 end),
		@fltProcedura = (case when isnull(@Procedura, '') = '' then 0 else 1 end),
		@fltTipFormular = (case when isnull(@tip_formular, '') = '' then 0 else 1 end),
		@fltCaleRaport = (case when isnull(@cale_raport, '') = '' then 0 else 1 end),
		@denumire = '%' + replace(@denumire, ' ', '%') + '%',
		@fisier = '%' + @fisier + '%',
		@procedura = '%' + replace(@procedura, ' ', '%') + '%',
		@tip_formular = isnull(@tip_formular, '') + '%',
		@cale_raport = '%' + isnull(@cale_raport, '') + '%'
	
	select *
	from (
		select
			rtrim(numar_formular) as formular, rtrim(denumire_formular) as denumire, 
			(case lower(CLFrom) when 'raport' then 'Raport' when 'procedura' then 'Procedura' else 'Altele' end) as tipformular,
			rtrim(case when lower(CLFrom) = 'procedura' then CLWhere end) as procedura,
			rtrim(case when lower(CLFrom) = 'raport' then CLWhere end) as cale_raport,
			rtrim(case when lower(CLFrom) = 'raport' then CLWhere end) as dencale_raport,
			Tip_formular as tip, exml, transformare as sablon,
			-- f_formular e pentru detalierea asocierilor, pentru a folosi aceleasi proceduri ca la macheta de asocieri formulare
			numar_formular as f_formular,
			-- raport (albastru), procedura (negru), altele (gri)
			(case CLFrom when 'procedura' then '#000000' when 'raport' then '#0000FF' else '#A0A0A0' end) as culoare,
			(case when CLFrom = 'procedura' then 0 else 1 end) as _nemodificabil
		from antform a
		where (@fltDenumire = 0 or a.Denumire_formular like @denumire) 
			and (@fltProcedura = 0 or CLFrom = 'procedura' and isnull(a.CLWhere, '') like @procedura) 
			and (@fltFisier = 0 or a.Transformare like @fisier) 
			and (@fltCaleRaport = 0 or a.clwhere like @cale_raport)
			and (@meniu_asociat is null and @tip_asociat is null
				or exists (select 1 from webconfigformulare f
								where (@meniu_asociat is null or f.meniu=@meniu_asociat) and (@tip_asociat is null or f.tip=@tip_asociat)
									and f.cod_formular=a.Numar_formular))
		) as x
	where tipformular like @tip_formular
	order by tipformular desc, formular
	for xml raw

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
