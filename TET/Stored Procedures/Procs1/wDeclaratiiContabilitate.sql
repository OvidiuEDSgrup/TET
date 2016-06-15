--***
Create procedure wDeclaratiiContabilitate @sesiune varchar(50), @parXML xml
as

declare @tip char(2), @datajos datetime, @datasus datetime, @lunaalfa varchar(15), @luna int, @an int, @userASiS varchar(10),
	@dataDecl datetime, @flux varchar(10)

exec wIaUtilizator @sesiune = @sesiune, @utilizator = @userASiS output

set @tip = ISNULL(@parXML.value('(/row/@tip)[1]', 'char(2)'), '')
set @datajos = ISNULL(@parXML.value('(/row/@datajos)[1]', 'datetime'), '')
set @datasus = ISNULL(@parXML.value('(/row/@datasus)[1]', 'datetime'), 0)
set @dataDecl = ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), @parXML.value('(/row/@datalunii)[1]', 'datetime'))
set @flux = @parXML.value('(/row/@flux)[1]', 'varchar(10)')

if @dataDecl is not null -- daca avem in antet aceste campuri, facem refresh la date din macheta de tip pozitii document
begin
	select @datajos = dbo.bom(@dataDecl), @datasus = dbo.eom(@dataDecl)
end

begin try  
	select @tip as tip, convert(char(10),d.Data,101) as datalunii, rtrim(dbo.fDenumireLuna(d.data)) + ' ' + convert(char(4),year(d.data)) as numeluna, month(d.data) as luna, convert(char(4),year(d.data)) as an, 
		(case when d.tip='N' then 'Noua' when d.tip='' then 'Initiala' when d.tip='R' then 'Rectificativa' when d.tip='U' then 'Nula' else '' end) as dentipdecl, 
		(case when @tip='YS' then isnull(d.detalii.value('/row[1]/@flux', 'varchar(1)'),'') else '' end) as flux, 
		(case when isnull(d.detalii.value('/row[1]/@flux', 'varchar(1)'),'')='I' then 'Introducere' 
			when isnull(d.detalii.value('/row[1]/@flux', 'varchar(1)'),'')='E' then 'Expediere' else '' end) as denflux, 
		d.utilizator as utilizator, convert(varchar(10),d.data_operarii,103)+' '+convert(varchar(10),d.data_operarii,108) as dataop, d.data as data_ord, 
		convert(varchar(20),j.data,101) data, convert(varchar(10),j.data,108) ora, d.detalii, d.idDeclaratie iddeclaratie
	from declaratii d
		outer apply (select top 1 wj.data from webJurnalOperatii wj where wj.data<=d.Data_operarii and wj.obiectSql like '%'+rtrim(d.cod)+'%' order by data desc) j
	where d.data between @datajos and @datasus and (@tip='YM' and d.Cod='394' or @tip='YL' and d.Cod='390' or @tip='YO' and d.Cod='300' or @tip='YS' and d.Cod like 'Intrastat_%')
		and (@flux is null or @flux = d.detalii.value('/row[1]/@flux', 'varchar(1)'))
	union all
	select distinct @tip as tip, convert(char(10),Data_lunii,101) as datalunii, rtrim(LunaAlfa) + ' ' + convert(char(4), an) as numeluna, Luna as luna, convert(char(4),an) as an,
		'' as dentipdecl, (case when @tip='YS' then 'I' else '' end) as flux, (case when @tip='YS' then 'Introducere' else '' end) as denflux, 
		'' as utilizator, '' as dataop, data as data_ord, '', '', null, null
	from fCalendar(@datajos,@datasus) c
	where data=Data_lunii
		and not exists (select 1 from declaratii d where d.Data=c.Data 
			and (@tip='YM' and d.Cod='394' or @tip='YL' and d.Cod='390' or @tip='YO' and d.Cod='300' or @tip='YS' and d.Cod='Intrastat_I' and detalii.value('/row[1]/@flux', 'varchar(1)')='I'))
	union all 
	select distinct @tip as tip, convert(char(10),Data_lunii,101) as datalunii, rtrim(LunaAlfa) + ' ' + convert(char(4), an) as numeluna, Luna as luna, convert(char(4),an) as an,
		'' as dentipdecl, 'E' as flux, 'Expediere' as denflux, '' as utilizator, '' as dataop, data as data_ord, '', '', null, null
	from fCalendar(@datajos,@datasus) c
	where data=Data_lunii and @tip='YS'
		and not exists (select 1 from declaratii d where d.Data=c.Data and @tip='YS' and d.Cod='Intrastat_E' and detalii.value('/row[1]/@flux', 'varchar(1)')='E')
	order by data_ord desc, flux desc
	for XML raw

	select 1 areDetaliiXml for xml raw, root('Mesaje')
end try  

begin catch
	declare @eroare varchar(254)
	set @eroare='Procedura wDeclaratiiContabilitate (linia '+convert(varchar(20),ERROR_LINE())+'): '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1)
end catch
