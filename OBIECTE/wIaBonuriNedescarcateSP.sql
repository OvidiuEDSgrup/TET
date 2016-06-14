--***
if exists (select * from sysobjects where name ='wIaBonuriNedescarcateSP')
drop procedure wIaBonuriNedescarcateSP
go
--***
create procedure wIaBonuriNedescarcateSP @sesiune varchar(50), @parXML xml
as
begin
declare @Sub char(9), @userASiS varchar(10),@iDoc int, 
		@filtreazaGestiuni bit, @filtreazaClienti bit, @filtreazaLM bit, @top int

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
if @userASiS is null
	return -1
exec sp_xml_preparedocument @iDoc output, @parXML

select top (100) max(LTRIM(str(d.Numar_bon))) as numar, 
convert(char(10),d.data,101) as data, 
max(rtrim(d.Loc_de_munca)) as gestiune, max(rtrim(isnull(t.denumire,''))) as dentert, 
max(rtrim(antet.Tert)) as tert, max(rtrim(antet.UID)) as [UID],
max(rtrim(antet.Factura)) as factura, 
sum(convert(decimal(15,2), d.Total*case when Factura_chitanta=1 then 1 else (100-Discount)/100 end)) as valoare, sum(convert(decimal(15,2),d.tva)) as tva, 
sum((1-Factura_chitanta)*convert(decimal(15,2),d.tva)+convert(decimal(15,2), d.Total*case when Factura_chitanta=1 then 1 else (100-Discount)/100 end)) as valtotala, 
sum(1) as numarpozitii, rtrim(max(d.Vinzator)) as vanzator, max(convert(int,d.Casa_de_marcat)) as casam,
max(left(d.ora,2)+':'+substring(d.Ora,3,2)) as ora,
max(antet.idAntetBon) as idantetbon
from bt d
cross join OPENXML(@iDoc, '/row')
	WITH
	(
		tip varchar(2) '@tip',
		numar varchar(8) '@numar',
		data_jos datetime '@datajos',
		data_sus datetime '@datasus',
		data datetime '@data', 
		gestiune varchar(9) '@f_gestiune',
		denumire_gestiune varchar(30) '@f_dengestiune',
		tert varchar(13) '@f_tert',
		denumire_tert varchar(80) '@f_dentert',
		vanzator varchar(10) '@f_vanzator',
		casam int '@f_casam',
		valoare_minima float '@valoarejos',
		valoare_maxima float '@valoaresus', 
		factura varchar(20) '@f_factura' 
	) as fx
join antetBonuri antet on antet.casa_de_marcat=d.casa_de_marcat and 
				antet.Numar_bon=d.Numar_bon and antet.Data_bon=d.data and 
				antet.Vinzator=d.Vinzator
left outer join terti t on t.subunitate = @Sub and t.tert = d.Client
where d.tip='21' --and Factura_chitanta=0
and convert(char(20),d.Numar_bon) like isnull(fx.numar, '') + '%'
and d.data between isnull(fx.data_jos, '01/01/1901') and (case when isnull(fx.data_sus, '01/01/1901')<='01/01/1901' then '12/31/2999' else fx.data_sus end)
and (fx.data is null or d.data=fx.data)
and d.Vinzator like isnull(fx.vanzator, '') + '%' 
and (fx.casam is null or d.Casa_de_marcat=fx.casam)
and d.Loc_de_munca like isnull(fx.gestiune, '') + '%' 
and isnull(t.denumire, '') like '%' + isnull(fx.denumire_tert, '') + '%'
group by d.Data, d.Numar_bon, d.Casa_de_marcat, d.vinzator
order by d.data desc, d.Casa_de_marcat, d.Numar_bon desc 
for xml raw
exec sp_xml_removedocument @iDoc 
end
