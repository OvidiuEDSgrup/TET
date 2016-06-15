--***
CREATE procedure wIaAdoc @sesiune varchar(50), @parXML xml
as
declare @userASiS varchar(10), @lista_lm bit, @Sub char(9), @iDoc int

--select @userASiS=id from utilizatori where observatii=SUSER_NAME()
/*Modificare pentru login utilizator sa */
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
select @lista_lm=dbo.f_arelmfiltru(@userASiS)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output

exec sp_xml_preparedocument @iDoc output, @parXML

select top 100 rtrim(d.subunitate) as subunitate, rtrim(d.tip) as tip, rtrim(d.numar_document) as numar, 
convert(char(10),d.data,101) as data, rtrim(max(d.tert)) as tert, 
rtrim(max(isnull(t.denumire,''))) as dentert, rtrim(max(p.factura_stinga)) as factura,
rtrim(max(p.Tert_beneficiar)) as tertbenef, rtrim(max(isnull(tb.denumire,''))) as dentertbenef, 
isnull(convert(decimal(15,2),sum(p.suma)),0) as valoare, 
isnull(convert(decimal(15,2),sum(p.suma+p.TVA22)),0) as valoarecutva, 
isnull(convert(decimal(15,2),sum(p.TVA22)),0) as tva22,
isnull(convert(decimal(15,2),sum(p.suma_valuta)),0) as valoarevaluta, 
RTRIM(max(d.Jurnal))as jurnal, convert(char(10),max(p.Data_scad),101) as datascadentei,
RTRIM(max(p.Loc_munca)) as lm, RTRIM(max(isnull(lm.denumire, ''))) as denlm, 
max(d.numar_pozitii) as numarpozitii, max(d.stare) as stare, 
case when max(d.numar_pozitii)=0 then '#FF0000' else '#000000' end as culoare,
--pt tabul de inregistrari contabile
d.tip tipdocument, d.Numar_document nrdocument
from adoc d
cross join OPENXML(@iDoc, '/row')
	WITH
	(
		tip varchar(2) '@tip',
		numar varchar(20) '@numar',
		data_jos datetime '@datajos',
		data_sus datetime '@datasus',
		data datetime '@data', 
		tert varchar(13) '@f_tert',
		denumire_tert varchar(80) '@f_dentert',
		lm varchar(9) '@f_lm',
		denumire_lm varchar(30) '@f_denlm',
		factura_stinga varchar(10) '@facturastinga',
		fnumar varchar(80) '@f_numar',
		valoare_minima float '@f_valoarejos',
		valoare_maxima float '@f_valoaresus'
	) as fx
left outer join pozadoc p on p.Subunitate=d.Subunitate and p.Tip=d.Tip and p.Numar_document=d.Numar_document and p.Data=d.Data
left outer join terti t on t.subunitate = d.subunitate and t.tert = d.tert 
left outer join terti tb on tb.subunitate = d.subunitate and tb.tert = (p.Tert_beneficiar)
left outer join lm on lm.cod = p.Loc_munca
where	d.subunitate=@Sub and d.tip = fx.tip and 
		d.Numar_document like isnull(fx.fnumar, '')+ '%' 
		and (d.Numar_document=fx.numar or isnull(fx.numar,'')='')
		and isnull(p.factura_stinga,'') like isnull(fx.factura_stinga,'')+'%' 
		and d.data between isnull(fx.data_jos, '01/01/1901') and (case when isnull(fx.data_sus, '01/01/1901')<='01/01/1901' then '12/31/2999' else fx.data_sus end)
		and (fx.data is null or d.data=fx.data)
		and d.tert like isnull(fx.tert, '') + '%'
		and isnull(t.denumire, '') like '%' + isnull(fx.denumire_tert, '') + '%'
		and (isnull(fx.lm,'')='' or p.Loc_munca like isnull(fx.lm, '') + '%')
		and (isnull(fx.denumire_lm,'')='' or isnull(lm.denumire, '') like '%' + isnull(fx.denumire_lm, '') + '%')
		and (@lista_lm=0 OR p.Loc_munca IS null or p.Loc_munca is not null and exists (
			select 1 from lmfiltrare lu where lu.utilizator=@userASiS and lu.cod=p.loc_munca))
group by d.Subunitate, d.Tip, d.Numar_document, d.Data
having isnull(convert(decimal(15,2),sum(p.suma)),0) between max(isnull(fx.valoare_minima, -99999999999)) and max(isnull(fx.valoare_maxima, 99999999999))
order by d.Data desc  
for xml raw
exec sp_xml_removedocument @iDoc 
