--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori ) */

create procedure [dbo].[wIaZileEvolutieStocuri] @sesiune varchar(50), @parXML xml                 
as
set transaction isolation level read uncommitted
declare @userASiS varchar(255)
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

declare @dataJos datetime,@dataSus datetime,@dinFiltre bit, @searchText varchar(100),@element varchar(100)
declare @areFiltreGestiuni int,@areFiltreGrupe int,@areFiltreProduse int,@areFiltre int
select 
	@dataJos =convert(datetime,isnull(@parXML.value('(/row/@dataJos)[1]', 'char(10)'), '01/01/2012'),103),
	@datasus =convert(datetime,isnull(@parXML.value('(/row/@dataSus)[1]', 'char(10)'), '12/31/2012'),103),	
	@searchText='%'+replace(rtrim(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'')), ' ','%')+'%',
	@element=@parXML.value('(/row/@element)[1]','varchar(100)'), 
	@dinFiltre=isnull(@parXML.value('(/row/@dinFiltre)[1]','bit'),0)

if OBJECT_ID('tempdb..#filtre') is not null
	drop table #filtre
else -- tabela cu filtre decodificate din XML;
	create table #filtre (denElement varchar(50), filtru varchar(200), nivel int, primary key(nivel, filtru, denElement) )

insert #filtre(denElement, filtru, nivel)
select x.element, x.valoare, c.Numar
from
	dbo.wfIaFiltreDinXml(@parXML) x
	inner join colind c on c.Cod_indicator='ES' and c.Denumire= x.element


set @areFiltreGestiuni=ISNULL((select top 1 1 from #filtre where denElement='GESTIUNE'),0)
set @areFiltreGrupe=ISNULL((select top 1 1 from #filtre where denElement='GRUPA'),0)
set @areFiltreProduse=ISNULL((select top 1 1 from #filtre where denElement='PRODUSE'),0)

if @areFiltreGestiuni=1 or @areFiltreGrupe=1 or @areFiltreProduse=1
	set @areFiltre=1
else
	set @areFiltre=0

if @dinFiltre=1 --doar aratam primul nivel de filtrare = gestiune
begin
	if @element='GESTIUNE'
		select rtrim(left(Denumire_gestiune,20)) as  data
		from gestiuni
		where Denumire_gestiune like @searchText
		for xml raw,root('Date')
	else if @element='GRUPA'
		select rtrim(Denumire) as data
		from grupe
		where Denumire like @searchText
		for xml raw,root('Date')
	else if @element='PRODUS'
		select rtrim(n.Denumire) as data
		from nomencl n
		left outer join #filtre fg on fg.denElement='GRUPA' 
		left outer join grupe g on g.Grupa=n.Grupa and fg.filtru=g.Denumire
		where n.Denumire like @searchText
		and @areFiltreGrupe=0 or g.Grupa is not null
		for xml raw,root('Date')
	return
end

if @areFiltre=0
begin
	--Trebuie sa facem stocurile din contabilitate
	declare @conturist varchar(4000)
	set @conturist=dbo.fConturiStocuri()
	select convert(char(10),data,103) data,convert(decimal(12,2),suma) as valoare
	from rulaj_sold_tb(@conturist,'','1',@dataJos,@dataSus,'',0)
	for xml raw,root('Date')
	return
end
--Facem calculul stocurilor din tabele de documente fStocuri

declare @StocInitial float  
declare @data char(10),@nF int,@stoc float,@ziJos datetime,@ziSus datetime,@lGestiune varchar(20)
  
/*
select gestiune,data,cantitate*pret,tip_miscare
into #cursorStocuri  
from dbo.fStocuri(@dataJos,@dataSus,@Cod,null,null,null,null,null,0,null,null,null,null,null,null) fs
left outer join gestiuni g on fs.cod_gestiune=g.Cod_gestiune
left outer join #filtre fg on fg.filtru='GESTIUNE' and fg.denElement=g.Denumire_gestiune
where @areFiltreGestiune=0 or fg.filtru not null
order by gestiune,data*/
