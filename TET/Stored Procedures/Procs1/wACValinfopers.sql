--***
Create procedure wACValinfopers @sesiune varchar(50), @parXML XML
as

declare @Cod_inf varchar(13), @searchText varchar(100)
set @Cod_inf=isnull(@parXML.value('(/row/@cod)[1]','varchar(13)'),'')
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

if @Cod_inf='DATAMFCT'
	exec wACFunctii @sesiune, @parXML
if @Cod_inf='CONDITIIM' 
	select 'N' as cod, 'Conditii normale' as denumire, '' as info
	union all
	select 'D' as cod, 'Conditii deosebite' as denumire, '' as info
	union all
	select 'S' as cod, 'Conditii speciale' as denumire, '' as info
	union all
	select 'C' as cod, 'Contract timp partial' as denumire, '' as info
	for xml raw
else 
	select top 100 rtrim(Valoare) as cod, (case when rtrim(Descriere)='' then Valoare else rtrim(Descriere) end) as denumire, '' as info
	from valinfopers a
	where Cod_inf=@Cod_inf and (Valoare like @searchText+'%' or Descriere like '%'+@searchText+'%') and @Cod_inf<>'DATAMFCT'
	order by Valoare
	for xml raw
