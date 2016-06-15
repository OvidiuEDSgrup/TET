--***
/* procedura pentru populare macheta de generare D300 - decont de TVA */
create procedure wOPGenerareRapIntrastat_p @sesiune varchar(50), @parXML xml 
as  

--declare @p2 xml
--set @p2=convert(xml,N'<row tip="YS" datalunii="06/30/2014" numeluna="Iunie 2014" luna="6" an="2014" dentipdecl="" flux="I" denflux="Introducere" utilizator="" dataop="" data_ord="2014-06-30T00:00:00" data="" ora=""/>')

select @parXML.value('(row/@flux)[1]','varchar(1)') flux,
	--@p2.value('(row/@datalunii)[1]','varchar(20)'),
	convert(varchar(20),dbo.bom(@parXML.value('(row/@datalunii)[1]','varchar(20)')),101) datajos,
	convert(varchar(20),dbo.eom(@parXML.value('(row/@datalunii)[1]','varchar(20)')),101) datasus
for xml raw, root('Date')
--exec wOPGenerareRapIntrastat_p @sesiune='1D14F872B88B7',@parXML=@p2

--select 
