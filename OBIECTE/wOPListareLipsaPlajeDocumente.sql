--/*
DROP procedure yso_wOPListareLipsaPlajeDocumente
GO
CREATE procedure yso_wOPListareLipsaPlajeDocumente --*/declare
@sesiune varchar(50), @parxml xml  
/*
declare @p2 xml
set @p2=convert(xml,N'<row tipdocument="AS" serie="TET CJ" numarinferior="9520001" numarsuperior="9529999" ultimulnumar="9520016" denumire="Avize servicii" denserieinnumar="Nu" serieinnumar="0" idPlaja="49" datajos="07/01/2013" datasus="08/08/2013" scotformulare="0" tip="PJ" tipMacheta="C" codMeniu="PJ" TipDetaliere="PJ" subtip="LL"/>')
--exec yso_wOPListareLipsaPlajeDocumente 
select @sesiune='BF7C1E1C77E43',@parXML=@p2
--*/as  
  
declare @tipdocument varchar(5), @numarinferior int, @numarsuperior int
	, @ultimulnumar int
	, @utilizator varchar(20), @hostid varchar(20)
	, @data date, @datajos date, @datasus date, @serie varchar(9), @scriuavnefac int
	, @idPlaja int, @numarcurent int, @totaldoclipsa int, @nrlinie int
	, @numarinferiorPerioada int, @numarsuperiorPerioada int
	, @nr varchar(8), @contractul varchar(8), @factura varchar(8), @codgestiune varchar(9)
	, @scotformulare bit
  
select @tipdocument = @parXML.value('(/row/@tipdocument)[1]','varchar(5)')
	,@numarinferior=@parXML.value('(/row/@numarinferior)[1]','int')
	,@numarsuperior=@parXML.value('(/row/@numarsuperior)[1]','int')
	,@ultimulnumar=@parXML.value('(/row/@ultimulnumar)[1]','int')
	,@data=@parXML.value('(/row/@data)[1]','date')
	,@datajos=isnull(@parXML.value('(/row/@datajos)[1]','date'),@data)
	,@datasus=isnull(@parXML.value('(/row/@datasus)[1]','date'),@data)
	,@serie=@parXML.value('(/row/@serie)[1]','varchar(13)')
	,@idPlaja=@parXML.value('(/row/@idPlaja)[1]','int')
	,@scotformulare=isnull(@parXML.value('(/row/@scotformulare)[1]','bit'),0)
	
--select top 1 @numarinferiorplaja=df.NumarInf from docfiscale df where df.Id=@idPlaja

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
set @hostid=LEFT(@utilizator,20)

declare @nrform varchar(50)  
set @nrform='FACTLIPSA'  
  
if @parXML.value('(/row/@nrform)[1]','varchar(50)') is null  
  set @parXML.modify ('insert attribute nrform {sql:variable("@nrform")} into (/row)[1]')  
 else   
  set @parXML.modify('replace value of (/row/@nrform)[1] with sql:variable("@nrform")')  

set @scriuavnefac=0
if @parXML.value('(/row/@scriuavnefac)[1]','int') is null  
  set @parXML.modify ('insert attribute scriuavnefac {sql:variable("@scriuavnefac")} into (/row)[1]')  
 else   
  set @parXML.modify('replace value of (/row/@scriuavnefac)[1] with sql:variable("@scriuavnefac")')  
  
set @parxml = replace(replace(CONVERT(varchar(max),@parXML), '<parametri ', '<row '), '</parametri>', '</row>')  

if OBJECT_ID('tempdb..factemise') is not null
	drop table tempdb..factemise

select distinct factura
	=isnull(case when p.Tip IN ('AP') then case tl.N when 1 then pa.Factura_stinga else p.Factura end
			when p.Tip='AC' then ab.Factura 
			else p.Factura end
	,p.factura) 
	,data_facturii=isnull(case when p.Tip IN ('AP') then case tl.N when 1 then pa.Data_fact else p.Data_facturii end
			when p.Tip='AC' then ab.Data_facturii 
			else p.Data_facturii end
	,p.Data_facturii)
	,tip=isnull(case p.Tip when 'AP' then pa.Tip when 'AC' then case when ab.Factura is not null then 'BC' else null end else p.tip end, p.tip)
into tempdb..factemise
from pozdoc p  
  left outer join nomencl n on p.cod=n.cod  
  left outer join anexaFac a on a.subunitate=p.subunitate and a.numar_factura=p.factura   
  left outer join antetBonuri b on --isnull(nullif(b.bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)'),''),
	left(rtrim(convert(varchar(4),b.Casa_de_marcat))+right(replace(str(b.Numar_bon),' ','0'),4),8)=p.numar
	and b.Data_bon=p.Data and b.Chitanta=1 
  left outer join antetBonuri ab on ab.Chitanta=0 and ab.Factura=b.Factura and ab.Data_facturii=b.Data_facturii
  left outer join par on par.Tip_parametru='GE' and par.Parametru='CTCLAVRT' 
  left outer join pozadoc pa on pa.Subunitate=p.Subunitate and pa.Tip='IF' and pa.Factura_dreapta=p.Factura
  left outer join Tally tl on pa.Factura_stinga is not null and tl.N between 1 and 2
where p.subunitate='1' and p.tip in ('AC','AP','AS')
	and (p.tip<>'AC' or ab.Factura is not null)
	--and isnull(case when p.Tip IN ('AP') then case tl.N when 1 then pa.Data_fact else p.Data_facturii end
	--		when p.Tip='AC' then ab.Data_facturii 
	--		else p.Data_facturii end
	--	,p.Data_facturii) between dateadd(day,-1,@datajos) and dateadd(day,1,@datasus)
	
	/*and (not(p.Tip in ('AP','AS') and p.Cont_factura =isnull(par.Val_alfanumerica,'418.0')) 
		or pa.Factura_stinga is not null)*/
order by 1,2

if OBJECT_ID('tempdb..factemiseint') is not null
	drop table tempdb..factemiseint

select f.* 
into tempdb..factemiseint			
from
	(select factura=convert(int,convert(decimal(8,0),e.factura)), data_facturii
		--,perioada=case when e.data_facturii between @datajos and @datasus then 0 
		--		when e.data_facturii<@datajos then -1
		--		else 1 end
	from tempdb..factemise e
	where ISNUMERIC(e.factura)=1) f 
where f.factura between @numarinferior and @numarsuperior

create nonclustered index fact on tempdb..factemiseint (factura,data_facturii)

if OBJECT_ID('tempdb..docfisclipsa') is not null
	drop table tempdb..docfisclipsa

set @numarinferiorPerioada=(select MAX(e.factura) from tempdb..factemiseint e 
		where e.data_facturii<@datajos)
set @numarsuperiorPerioada=(select MIN(e.factura) from tempdb..factemiseint e 
		where e.data_facturii>=@datasus)

select NrLinie=IDENTITY(int,1,1),d.TipDoc,d.Serie,d.NumarInf,d.UltimulNr,NumarCurent=t.N 
	--,fact_anterioara=(select top 1 e.factura from tempdb..factemiseint e where e.factura<t.N order by e.factura desc)
	,data_facturii_anterioare=convert(date,ant.data_facturii)
	,data_facturii_urmatoare=convert(date,urm.data_facturii)
into tempdb..docfisclipsa
from Tally t 
	inner join docfiscale d on ID=@idPlaja and t.n between d.NumarInf and d.UltimulNr
	outer apply (select top 1 * from tempdb..factemiseint e 
		where e.factura between d.NumarInf and d.UltimulNr and e.factura<t.N order by e.factura desc) ant
	outer apply (select top 1 * from tempdb..factemiseint e 
		where e.factura between d.NumarInf and d.UltimulNr and e.factura>t.N order by e.factura asc) urm
	left join tempdb..factemiseint f on f.Factura=t.N
where f.factura is null 
	and t.N>isnull(@numarinferiorPerioada,@numarinferior)
	and t.N<isnull(@numarsuperiorPerioada,@numarsuperior)
order by t.N

select @totaldoclipsa=max(NrLinie), @nrlinie=1 from tempdb..docfisclipsa

if @scotformulare=0 
	return

while @nrlinie<=@totaldoclipsa
begin 
	select
	@tipdocument=df.TipDoc, --Tip	char	2
	@nr=df.NumarCurent--df.NumarInf, --Numar	char	20
	,@codgestiune=df.Serie, --Cod_gestiune	char	9
	@data=coalesce(df.data_facturii_anterioare,df.data_facturii_urmatoare,getdate()), --Data	datetime	8
	@factura=df.NumarCurent--df.UltimulNr, --Factura	char	20
	,@contractul=df.NumarCurent --Contractul	char	20,
	from tempdb..docfisclipsa df where df.NrLinie=@nrlinie

	delete avnefac where Terminal=@hostid
	insert avnefac
	select
	@hostid, --Terminal	char	25
	'1', --Subunitate	char	9
	@tipdocument, --Tip	char	2
	@nr, --Numar	char	20
	@codgestiune, --Cod_gestiune	char	9
	@data, --Data	datetime	8
	'', --Cod_tert	char	13
	@factura, --Factura	char	20
	@contractul, --Contractul	char	20
	'', --Data_facturii	datetime	8
	'', --Loc_munca	char	9
	'', --Comanda	char	13
	'', --Gestiune_primitoare	char	9
	'', --Valuta	char	3
	'', --Curs	float	8
	'', --Valoare	float	8
	'', --Valoare_valuta	float	8
	'', --Tva_11	float	8
	'', --Tva_22	float	8
	'', --Cont_beneficiar	char	13
	'' --Discount	real	4
	
	if @parXML.value('(/row/@tip)[1]','varchar(2)') is null  
	  set @parXML.modify ('insert attribute tip {sql:variable("@tipdocument")} into (/row)[1]')  
	else   
	  set @parXML.modify('replace value of (/row/@tip)[1] with sql:variable("@tipdocument")')  

	if @parXML.value('(/row/@numar)[1]','varchar(20)') is null  
	  set @parXML.modify ('insert attribute numar {sql:variable("@contractul")} into (/row)[1]')  
	else   
	  set @parXML.modify('replace value of (/row/@numar)[1] with sql:variable("@contractul")')
	
	exec wTipFormular @sesiune=@sesiune, @parXML=@parxml
	set @nrlinie=@nrlinie+1
end
go
/*
declare @p2 xml
set @p2=convert(xml,N'<row tipdocument="AP" serie="TET" numarinferior="9430000" numarsuperior="9439999" ultimulnumar="9430010" denumire="Avize produse" denserieinnumar="Nu" serieinnumar="0" idPlaja="1" tip="PJ" tipMacheta="C" codMeniu="PJ" TipDetaliere="PJ" subtip="LL"/>')
exec yso_wOPListareLipsaPlajeDocumente @sesiune='',@parXML=@p2
*/