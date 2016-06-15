--***
create procedure  [wIaCheltuieli] @sesiune varchar(50), @parXML xml
as
--set @parXML=convert(xml,N'<row tip="CH" datajos="03/01/2010" datasus="03/31/2010"/>')
declare @iDoc int
--
exec sp_xml_preparedocument @iDoc output, @parXML
--
select  
'CH' as tip, 
rtrim(d.tip_document)+':'+rtrim(d.Numar_document) as doc,
rtrim(d.tip_document) as tipDoc, 
rtrim(d.Numar_document) as numar, 
convert(char(10),d.data,101) as data, 
rtrim(d.cont_debitor) as cont,
--rtrim(d.Cont_creditor) as contcor,
convert(decimal(15,2), d.Suma) as suma,
rtrim(d.Explicatii) as explicatii,
rtrim(d.Loc_de_munca) as lm,
RTRIM(lm.Denumire) as denlm,
rtrim(d.Comanda) as comanda,
RTRIM(comenzi.Descriere) as dencomanda,
--rtrim(c.Articol_de_calculatie) as articol
(case 
when d.Tip_document='PI' then isnull((select max(factura) from pozplin where subunitate=d.subunitate and plata_incasare='PD' and cont=d.numar_document and data=d.data and Factura<>''),rtrim(c.Articol_de_calculatie)) 
when d.Tip_document in ('AI','CM','RS') then isnull((select max(barcod) from pozdoc where subunitate=d.subunitate and tip=d.Tip_document and numar=d.numar_document and data=d.data and Barcod<>''),rtrim(c.Articol_de_calculatie) ) 
when d.Tip_document in ('NC') then isnull( (select max(tert) from pozncon where subunitate=d.subunitate and tip=d.Tip_document and numar=d.numar_document and data=d.data and tert<>''),rtrim(c.Articol_de_calculatie) ) 
when d.Tip_document in ('FF') then isnull( (select max(factura_stinga) from pozadoc where subunitate=d.subunitate and tip=d.Tip_document and Numar_document=d.numar_document and data=d.data and Factura_stinga<>''),rtrim(c.Articol_de_calculatie) ) 
else rtrim(c.Articol_de_calculatie) end) 
as articol
from pozincon d
cross join OPENXML(@iDoc, '/row')
	WITH
	(
		numar varchar(20) '@f_numar',
		data_jos datetime '@datajos',
		data_sus datetime '@datasus',
		tipDoc varchar(2) '@tipDoc',
		cont varchar(20) '@f_cont',
		suma float '@f_suma',
		val_min float '@f_valmin',
		val_max float '@f_valmax',
		lm varchar(9) '@f_lm',
		comanda varchar(20) '@f_comanda',
		articol varchar(9) '@f_articol'
	) as fx

left outer join conturi c on c.cont=d.cont_debitor 
left outer join lm on lm.Cod=d.Loc_de_munca
left outer join comenzi on comenzi.Comanda=d.Comanda
where d.cont_debitor like '6%' and c.logic=1 
and d.Tip_document like isnull(fx.tipDoc, '')+'%'
and d.numar_document like isnull(fx.numar, '') + '%'
and d.data between fx.data_jos and fx.data_sus 
and d.Cont_debitor like isnull(fx.cont, '') + '%'
and d.suma between isnull(fx.val_min, -99999999999) and isnull(fx.val_max, 99999999999)
and d.loc_de_munca like isnull(fx.lm, '') + '%' 
and d.comanda like isnull(fx.comanda, '') + '%'
and (case 
when d.Tip_document='PI' then isnull((select max(factura) from pozplin where subunitate=d.subunitate and plata_incasare='PD' and cont=d.numar_document and data=d.data and Factura<>''),rtrim(c.Articol_de_calculatie)) 
when d.Tip_document in ('AI','CM','RS') then isnull((select max(barcod) from pozdoc where subunitate=d.subunitate and tip=d.Tip_document and numar=d.numar_document and data=d.data and Barcod<>''),rtrim(c.Articol_de_calculatie) ) 
when d.Tip_document in ('NC') then isnull( (select max(tert) from pozncon where subunitate=d.subunitate and tip=d.Tip_document and numar=d.numar_document and data=d.data and tert<>''),rtrim(c.Articol_de_calculatie) ) 
when d.Tip_document in ('FF') then isnull( (select max(factura_stinga) from pozadoc where subunitate=d.subunitate and tip=d.Tip_document and Numar_document=d.numar_document and data=d.data and Factura_stinga<>''),rtrim(c.Articol_de_calculatie) ) 
else rtrim(c.Articol_de_calculatie) end)  like isnull(fx.articol, '') + '%'
order by d.data, d.tip_document,d.numar_document 
for xml raw

exec sp_xml_removedocument @iDoc


