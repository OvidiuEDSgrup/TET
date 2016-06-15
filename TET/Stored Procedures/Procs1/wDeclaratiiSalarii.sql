--***
Create procedure wDeclaratiiSalarii @sesiune varchar(50), @parXML xml
as

declare @tip char(2), @datajos datetime, @datasus datetime, @datalunii datetime, @userASiS varchar(10)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @tip = ISNULL(@parXML.value('(/row/@tip)[1]', 'char(2)'), '')
set @datajos = @parXML.value('(/row/@datajos)[1]', 'datetime')
set @datasus = @parXML.value('(/row/@datasus)[1]', 'datetime')
set @datalunii = @parXML.value('(/row/@datalunii)[1]', 'datetime')
if @datajos is null
begin
	set @datajos=dbo.BOM(@datalunii)
	set @datasus=dbo.EOM(@datalunii)
end

begin try  
	select @tip as tip, convert(char(10),d.Data,101) as datalunii, convert(char(10),d.Data,101) as data, 
		rtrim(dbo.fDenumireLuna(d.data)) as numeluna, month(d.data) as luna, convert(char(4),year(d.data)) as an, 
		(case when d.tip='' then 'Initiala' when d.tip='R' then 'Rectificativa' else '' end) as dentipdecl, 
		d.utilizator as utilizator, convert(varchar(10),d.data_operarii,103)+' '+convert(varchar(10),d.data_operarii,108) as dataop, d.data as data_ord, 
		convert(varchar(20),j.data,101) datajurn, convert(varchar(10),j.data,108) orajurn
	from declaratii d
		outer apply (select top 1 wj.data from webJurnalOperatii wj where wj.data<=d.Data_operarii and wj.obiectSql like '%'+rtrim(d.cod)+'%' order by data desc) j
	where (@tip='DU' and d.data between @datajos and @datasus and d.Cod='112' or @tip='D2' and d.data between @datajos and dbo.EOY(@datasus) and d.Cod='205'
			or @tip='RE' and d.data between @datajos and dbo.EOY(@datasus) and d.Cod='REVISAL')
			and (@datalunii is null or d.data=@datalunii)
	union all
	select distinct @tip as tip, convert(char(10),Data_lunii,101) as datalunii, convert(char(10),Data_lunii,101) as data, 
		rtrim(LunaAlfa) as numeluna, Luna as luna, convert(char(4),an) as an, 
		'' as dentipdecl, '' as utilizator, '' as dataop, data as data_ord, '' as datajurn, '' as orajurn
	from fCalendar(@datajos,(case when @tip='D2' then dbo.eoy(@datasus) else @datasus end)) c
	where (@tip='DU' and data=Data_lunii or @tip='D2' and data=dbo.EOY(Data_lunii) or @tip='RE' and data=Data_lunii)
		and (@datalunii is not null and c.data_lunii=@datalunii 
			or not exists (select 1 from declaratii d where d.Data=c.Data and (@tip='DU' and Cod='112' or @tip='D2' and Cod='205' or @tip='RE' and Cod='REVISAL')))
	order by data_ord desc
	for XML raw
end try  

begin catch
	declare @eroare varchar(254)
	set @eroare='Procedura wDeclaratiiSalarii (linia '+convert(varchar(20),ERROR_LINE())+'): '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1)
end catch
