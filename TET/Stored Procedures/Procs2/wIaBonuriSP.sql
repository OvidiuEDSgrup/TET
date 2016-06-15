create procedure wIaBonuriSP --*/ declare 
@sesiune varchar(50), @parXML xml
/*
select @parxml=convert(xml,N'<row tip="BC" numar="2" data="05/23/2014" dengestiune="SB BON FISCAL SIBIU" gestiune="210.SB" dentert="FLOREA ADRIAN" tert="1770924323918" factura="SB940136" data_facturii="05/23/2014" valoare="393.92" tva="76.25" valtotala="393.92" numarpozitii="2" vanzator="FILIALA_SB" casam="5" ora="14:53" idantetbon="5271" culoare="#0000EE" _nemodificabil="1" contract="SB980486" nrdoc="SB50002" tipdoc="AC" datadoc="2014-05-23T00:00:00" _refresh="1"/>')
	,@sesiune=''
--*/as

begin
set transaction isolation level read uncommitted


declare @Sub char(9), @userASiS varchar(10),@iDoc int, 
@filtreazaGestiuni bit, @filtreazaClienti bit, @filtreazaLM bit, @top int

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @top = 100
/* citesc diverse filtre configurate pe utilizatori */
select @filtreazaGestiuni=0, @filtreazaClienti=0, @filtreazaLM=0
select @filtreazaGestiuni=(case when cod_proprietate='GESTIUNE' and Valoare<>''  then 1 else @filtreazaGestiuni end), 
	@filtreazaClienti=(case when cod_proprietate='CLIENT' and Valoare<>'' then 1 else @filtreazaClienti end), 
	@filtreazaLM=(case when cod_proprietate='LOCMUNCA' and Valoare<>'' then 1 else @filtreazaLM end),
	@top=(case when Cod_proprietate='LINIIAFISATE' and Valoare<>'' and isnumeric(valoare)=1 then CONVERT(int, valoare) else @top end)
from proprietati 
where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('GESTIUNE', 'CLIENT', 'LOCMUNCA','LINIIAFISATE')

exec sp_xml_preparedocument @iDoc output, @parXML

declare @f_tip int,@c_numar varchar(8),@f_numar varchar(8),@f_datajos datetime,@f_datasus datetime,@f_data datetime,@f_gestiune varchar(9)
declare @f_dengestiune varchar(30),@f_tert varchar(13),@f_dentert varchar(80),@f_vanzator varchar(10),@f_casam int,@f_factura varchar(20)
	,@idAntetBon int

if @parXML.value('(/row/@tip)[1]', 'varchar(50)')='BC'
	set @f_tip=1
else
	set @f_tip=0

select @idAntetBon=isnull(@parXML.value('(/row/@idantetbon)[1]', 'varchar(8)'), 0),
	@f_numar=isnull(@parXML.value('(/row/@numar)[1]', 'varchar(8)'),''),
	@f_datajos=isnull(@parXML.value('(/row/@datajos)[1]', 'datetime'),'01/01/1901'),
	@f_datasus=isnull(@parXML.value('(/row/@datasus)[1]', 'datetime'),'12/31/2999'),
	@f_data=@parXML.value('(/row/@data)[1]', 'datetime'),
	@f_gestiune=isnull(@parXML.value('(/row/@f_gestiune)[1]', 'varchar(9)'),''),
	@f_dengestiune=isnull(@parXML.value('(/row/@f_dengestiune)[1]', 'varchar(30)'),''),
	@f_tert=isnull(@parXML.value('(/row/@f_tert)[1]', 'varchar(13)'),''),
	@f_dentert=isnull(@parXML.value('(/row/@f_dentert)[1]', 'varchar(80)'),''),
	@f_vanzator=isnull(@parXML.value('(/row/@f_vanzator)[1]', 'varchar(10)'),''),
	@f_casam=isnull(@parXML.value('(/row/@f_casam)[1]', 'int'),-1),
	@f_factura=isnull(@parXML.value('(/row/@f_factura)[1]', 'varchar(20)'),'')

select a.casa_de_marcat,a.Chitanta,a.Numar_bon,a.Data_bon,a.Vinzator,a.tert,gPred.Cod_gestiune,
rtrim(left(rtrim(gPred.denumire_gestiune),30)) as denumire_gestiune,a.IdAntetBon,
rtrim(a.gestiune) as gestiune,a.Data_facturii,
rtrim(a.factura) as factura --/*SP
,t.Denumire as dentert 
,comanda=rtrim(a.Comanda)
,[contract]=rtrim(a.Contract)
,IdAntetBonFactura=b.IdAntetBon
,numar_in_pozdoc= rtrim(a.bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)'))
--SP*/
into #bonurifiltrate
from antetBonuri a
left outer join terti t on t.subunitate = @Sub and t.tert = a.tert
left outer join gestiuni gPred on gPred.subunitate = @Sub and gPred.cod_gestiune = a.Gestiune
left outer join proprietati gu on gu.valoare=a.Gestiune and gu.tip='UTILIZATOR' and gu.cod=@userASiS and gu.cod_proprietate='GESTIUNE'--/*SP
left outer join antetBonuri b on b.Casa_de_marcat=a.Casa_de_marcat and b.Vinzator=a.Vinzator and b.Data_bon=a.Data_bon 
	and convert(varchar(20),a.Numar_bon)=b.Factura
--SP*/
where (@idAntetBon=0 or a.idAntetBon=@idAntetBon)
and a.Data_bon between @f_datajos and @f_datasus
and a.chitanta=@f_tip
and (@f_numar='' or convert(char(20),a.Numar_bon) like @f_numar + '%' )
and (@f_data is null or a.data_bon=@f_data)
and (@f_vanzator='' or a.Vinzator like @f_vanzator+ '%')
and (@f_casam=-1 or a.Casa_de_marcat=@f_casam)
and (@f_gestiune='' or a.Gestiune like @f_gestiune+ '%')
and (@f_dengestiune='' or left(gPred.denumire_gestiune, 30) like '%' + @f_dengestiune + '%')
and (@f_tert='' or a.tert like @f_tert + '%')
and (@f_dentert='' or isnull(t.denumire, '') like '%' + @f_dentert + '%')
and (@filtreazaGestiuni=0 or gu.valoare is not null)
and (@f_factura='' or a.Factura like @f_factura+ '%')--SP*/
and (isnull(@parXML.value('(/row/@f_contract)[1]', 'varchar(20)'),'')='' or a.[Contract] like @parXML.value('(/row/@f_contract)[1]', 'varchar(20)')+ '%') 
--SP*/

if @sesiune='' select 
sum((1-b.chitanta)*convert(decimal(15,2),d.tva)
	+convert(decimal(15,2), d.Total*case when b.chitanta=1 then 1 else (100-Discount)/100 end)) as valtotala 
from bp d
inner join #bonurifiltrate b on d.casa_de_marcat=b.casa_de_marcat and d.Data=b.data_bon and d.Vinzator=b.Vinzator
	and d.Numar_bon=b.Numar_bon or d.IdAntetBon=b.IdAntetBonFactura
left outer join terti t on t.subunitate = @Sub and t.tert = d.Client
left outer join comenzi c on c.Subunitate=@Sub and c.Comanda=b.comanda
left outer join gestiuni gPred on gPred.subunitate = @Sub and gPred.cod_gestiune = d.Loc_de_munca 
left outer join proprietati gu on gu.valoare=d.Loc_de_munca and gu.tip='UTILIZATOR' and gu.cod=@userASiS and gu.cod_proprietate='GESTIUNE'

select (case when b.chitanta=1 then 'BC' else 'BY' end) as tip, 
max(LTRIM(str(d.Numar_bon))) as numar, 
convert(char(10),d.data,101) as data, 
b.denumire_gestiune as dengestiune, 
rtrim(max(b.gestiune)) as gestiune, rtrim(t.denumire) as dentert, 
b.Tert as tert, 
b.Factura  as factura, 
max(convert(char(10),b.Data_facturii,101)) as data_facturii,
--sum(convert(decimal(15,2), d.Total*case when b.chitanta=1 then 1 else (100-Discount)/100 end)) as valoare
--, sum(convert(decimal(15,2),d.tva)) as tva, 
--sum((1-b.chitanta)*convert(decimal(15,2),d.tva)
--	+convert(decimal(15,2), d.Total*case when b.chitanta=1 then 1 else (100-Discount)/100 end)) as valtotala, 
sum(convert(decimal(15,2), d.Total-d.Tva)) as valoare, sum(convert(decimal(15,2),d.tva)) as tva, 
sum(convert(decimal(15,2), d.Total)) as valtotala,
sum(1) as numarpozitii, rtrim(max(d.Vinzator)) as vanzator, max(convert(int,d.Casa_de_marcat)) as casam,
max(left(d.ora,2)+':'+substring(d.Ora,3,2)) as ora, 
max(b.idAntetBon) as idantetbon,(case	when sum(total) <= 0 then'#FF0000' 
		when isnull(max(b.factura),'')<>'' and  max(cast(chitanta as int)) = 1 then '#0000EE' 
		when isnull(max(b.factura),'')<>''  and max(cast(chitanta as int)) = 0 then '#2A8E82' else '#000000' end)  as culoare, 
1 as _nemodificabil 
, comanda=MAX(b.comanda), dencomanda=RTRIM(max(c.Descriere))
, [contract]=MAX(b.[Contract])
, nrdoc=MAX(b.numar_in_pozdoc)
, tipdoc=max((case when b.Chitanta=1 then 'AC' else 'AP' end))
, datadoc=max((b.Data_bon))
from bp d
inner join #bonurifiltrate b on d.casa_de_marcat=b.casa_de_marcat and d.Data=b.data_bon and d.Vinzator=b.Vinzator
	and d.Numar_bon=b.Numar_bon or d.IdAntetBon=b.IdAntetBonFactura
left outer join terti t on t.subunitate = @Sub and t.tert = d.Client
left outer join comenzi c on c.Subunitate=@Sub and c.Comanda=b.comanda
left outer join gestiuni gPred on gPred.subunitate = @Sub and gPred.cod_gestiune = d.Loc_de_munca 
left outer join proprietati gu on gu.valoare=d.Loc_de_munca and gu.tip='UTILIZATOR' and gu.cod=@userASiS and gu.cod_proprietate='GESTIUNE'
where d.tip='21'
group by d.Data,d.Casa_de_marcat, d.Numar_bon, d.vinzator,b.idAntetBon,b.chitanta,b.tert,t.denumire,b.denumire_gestiune,b.factura,b.data_facturii
order by d.data desc, d.Casa_de_marcat, d.Numar_bon desc 
for xml raw

drop table #bonurifiltrate
end
