declare @cont nvarchar(4000),@tert nvarchar(4000),@data1 datetime,@data2 datetime
select @cont=NULL,@tert=NULL,@data1='2014-01-01 00:00:00',@data2='2014-03-12 00:00:00'

declare @contOK char(20)
if(@cont='401.4') set @contOK=null
else set @contOK=@cont
if(@cont='401.4')
begin
select * from 
(
select max(t.Denumire) as tert, 
p.Factura,
max(p.data_facturii) as data,
p.numar as nrNiv,
max(p.Data) as dataNir,
SUM(p.cantitate*p.Pret_valuta) as valoareValuta ,
'' as curs,
SUM(p.cantitate*p.pret_de_stoc) as valoare ,
--(case when @contOK='401.4' then isnull((select max(pret_valuta) from pozdoc where tip='RP' and numar=p.numar and Cont_factura='401.4'),0) else isnull((select max(pret_valuta) from pozdoc where tip='RP' and numar=p.numar),0)end) as transport,
isnull((select max(pret_valuta) from pozdoc where tip='RP' and numar=p.numar and Cont_factura='401.4'),0) as transport,
SUM(p.cantitate*p.Pret_valuta) as totalValoare,
--'' as TVA1,
--'' as valMarfa,
'' as Numar_DVI,
'' as taxevamale,
'' as s327,
'' as s3711,
--'' as s3712,
--'' as s3713,
--'' as s3715,
--'' as s3718,
SUM(p.TVA_deductibil) as TVA,
'' as s4427,
'' as s4428,
''as s609,
'' as s667
from pozdoc p 
inner join terti t on t.tert=p.tert
where p.tip in ('RP') /*and YEAR(p.data)=2012*/
and p.Data>=@data1 and p.Data<=@data2
and (isnull(@contOK, '') = '' OR  p.Cont_factura= rtrim(rtrim(@contOK)))
and (isnull(@tert, '') = '' OR  p.Tert= rtrim(rtrim(@tert)))
group by p.factura,p.numar,p.Cont_venituri,t.Tert,t.Denumire,p.Tert
)r
where   r.transport>0
order by r.nrNiv
end 
else 
select * from 
(
select max(t.Denumire) as tert, 
p.Factura,
max(p.data_facturii) as data,
p.numar as nrNiv,
max(p.Data) as dataNir,
SUM(p.cantitate*p.Pret_valuta) as valoareValuta ,
MAX(p.Curs) as curs,
SUM(p.cantitate*p.pret_de_stoc) as valoare ,
--(case when @contOK='401.4' then isnull((select max(pret_valuta) from pozdoc where tip='RP' and numar=p.numar and Cont_factura='401.4'),0) else isnull((select max(pret_valuta) from pozdoc where tip='RP' and numar=p.numar),0)end) as transport,
isnull((select max(pret_valuta) from pozdoc where tip='RP' and numar=p.numar and Cont_factura='401.4'),0) as transport,
isnull(SUM(p.cantitate*p.pret_de_stoc),0)+isnull((select sum(suma) from pozincon where Tip_document in ('RM','RS')  and Numar_document=p.Numar and data=p.Data  and Cont_debitor='4426'),0) as totalValoare,
--(select sum(suma) from pozincon where Tip_document in ('RM','RS')  and Numar_document=p.Numar  and Cont_debitor='4426')  as TVA1,
--isnull(SUM(p.cantitate*p.pret_de_stoc),0) as valMarfa,
max(d.Numar_DVI) as Numar_DVI,
isnull(max(d.Suma_vama),0) as taxevamale,
isnull((select sum(suma) from pozincon where Tip_document in ('RM','RS')  and Numar_document=p.Numar and data=p.Data  and  Cont_debitor='327' and (isnull(@contOK, '') = '' OR  Cont_creditor= rtrim(rtrim(@contOK)))),0) as s327,
isnull((select sum(suma) from pozincon where Tip_document in ('RM','RS')  and Numar_document=p.Numar and data=p.Data  and  Cont_debitor='371.1' and (isnull(@contOK, '') = '' OR  Cont_creditor= rtrim(rtrim(@contOK)))),0) as s3711,
--isnull((select sum(suma) from pozincon where Tip_document in ('RM','RS')  and Numar_document=p.Numar  and  Cont_debitor='371.2' and (isnull(@contOK, '') = '' OR  Cont_creditor= rtrim(rtrim(@contOK)))),0) as s3712,
--isnull((select sum(suma) from pozincon where Tip_document in ('RM','RS')  and Numar_document=p.Numar  and  Cont_debitor='371.3' and (isnull(@contOK, '') = '' OR  Cont_creditor= rtrim(rtrim(@contOK)))),0) as s3713,
--isnull((select sum(suma) from pozincon where Tip_document in ('RM','RS')  and Numar_document=p.Numar  and  Cont_debitor='371.5' and (isnull(@contOK, '') = '' OR  Cont_creditor= rtrim(rtrim(@contOK)))),0) as s3715,
--isnull((select sum(suma) from pozincon where Tip_document in ('RM','RS')  and Numar_document=p.Numar  and  Cont_debitor='371.8' and (isnull(@contOK, '') = '' OR  Cont_creditor= rtrim(rtrim(@contOK)))),0) as s3718,
isnull((case when @contOK is null then  (select sum(suma) from pozincon where Tip_document in ('RM','RS')  and Numar_document=p.Numar and data=p.Data  and Cont_debitor='4426')
when @contOK is not null and (select sum(suma) from pozincon where Tip_document in ('RM','RS')  and Numar_document=p.Numar and data=p.Data and Cont_debitor='4426' and (isnull(@contOK, '') = '' OR  Cont_creditor= rtrim(rtrim(@contOK)))) is null
then (select sum(suma) from pozincon where Tip_document in ('RM','RS')  and Numar_document=p.Numar and data=p.Data  and Cont_debitor='4426' and  Cont_creditor='4427')
else (select sum(suma) from pozincon where Tip_document in ('RM','RS')  and Numar_document=p.Numar and data=p.Data  and Cont_debitor='4426' and (isnull(@contOK, '') = '' OR  Cont_creditor= rtrim(rtrim(@contOK)))) end),0) as TVA,
isnull((select sum(suma) from pozincon where Tip_document in ('RM','RS')  and Numar_document=p.Numar and data=p.Data  and Cont_creditor='4427'),0) as s4427,
isnull((select sum(suma) from pozincon where Tip_document in ('RM','RS')  and Numar_document=p.Numar and data=p.Data  and Cont_debitor like '4428%'),0) as s4428,
isnull((select sum(suma) from pozincon where Tip_document in ('RM','RS')  and Numar_document=p.Numar and data=p.Data  and cont_debitor='609'),0) as s609,
isnull((select sum(suma) from pozincon where Tip_document in ('RM','RS')  and Numar_document=p.Numar and data=p.Data  and cont_debitor='667'),0) as s667
from pozdoc p left join dvi d on  p.factura=d.Factura_CIF
inner join terti t on t.tert=p.tert
where p.tip in ('RM','RS') /*and YEAR(p.data)=2012*/
and p.Data>=@data1 and p.Data<=@data2
and (isnull(@contOK, '') = '' OR  p.Cont_factura= rtrim(rtrim(@contOK)))
and (isnull(@tert, '') = '' OR  p.Tert= rtrim(rtrim(@tert)))
group by p.factura,p.numar,p.Data,p.Cont_venituri,t.Tert,t.Denumire,p.Tert
)r

union 
select max(t.Denumire)as tert, 
p.Factura_dreapta,
max(p.data) as data,
p.Numar_document as nrNiv,
max(p.Data) as dataNir,
SUM(p.Suma_valuta) as valoareValuta ,
MAX(p.Curs) as curs,
SUM(suma) as valoare ,
--(case when @contOK='401.4' then isnull((select max(pret_valuta) from pozdoc where tip='RP' and numar=p.numar and Cont_factura='401.4'),0) else isnull((select max(pret_valuta) from pozdoc where tip='RP' and numar=p.numar),0)end) as transport,
isnull((select max(pret_valuta) from pozdoc where tip='RP' and numar=p.Numar_document and Cont_factura='401.4'),0) as transport,
isnull(SUM(p.suma),0)+isnull((select sum(suma) from pozincon where Tip_document in ('FF')  and Numar_document=p.Numar_document and data=p.Data and Cont_debitor='4426'),0) as totalValoare,
--(select sum(suma) from pozincon where Tip_document in ('FF')  and Numar_document=p.Numar_document  and Cont_debitor='4426')  as TVA1,
--isnull(SUM(p.suma_dif),0) as valMarfa,
max(d.Numar_DVI) as Numar_DVI,
isnull(max(d.Suma_vama),0) as taxevamale,
isnull((select sum(suma) from pozincon where Tip_document in ('FF')  and Numar_document=p.Numar_document and data=p.Data and  Cont_debitor='327' and (isnull(@contOK, '') = '' OR  Cont_creditor= rtrim(rtrim(@contOK)))),0) as s327,
isnull((select sum(suma) from pozincon where Tip_document in ('FF')  and Numar_document=p.Numar_document and data=p.Data and  Cont_debitor='371.1' and (isnull(@contOK, '') = '' OR  Cont_creditor= rtrim(rtrim(@contOK)))),0) as s3711,
--isnull((select sum(suma) from pozincon where Tip_document in ('FF')  and Numar_document=p.Numar_document  and  Cont_debitor='371.2' and (isnull(@contOK, '') = '' OR  Cont_creditor= rtrim(rtrim(@contOK)))),0) as s3712,
--isnull((select sum(suma) from pozincon where Tip_document in ('FF')  and Numar_document=p.Numar_document  and  Cont_debitor='371.3' and (isnull(@contOK, '') = '' OR  Cont_creditor= rtrim(rtrim(@contOK)))),0) as s3713,
--isnull((select sum(suma) from pozincon where Tip_document in ('FF')  and Numar_document=p.Numar_document  and  Cont_debitor='371.5' and (isnull(@contOK, '') = '' OR  Cont_creditor= rtrim(rtrim(@contOK)))),0) as s3715,
--isnull((select sum(suma) from pozincon where Tip_document in ('FF')  and Numar_document=p.Numar_document  and  Cont_debitor='371.8' and (isnull(@contOK, '') = '' OR  Cont_creditor= rtrim(rtrim(@contOK)))),0) as s3718,
isnull((case when @contOK is null then  (select sum(suma) from pozincon where Tip_document in ('FF')  and Numar_document=p.Numar_document and data=p.Data and Cont_debitor='4426')
when @contOK is not null and (select sum(suma) from pozincon where Tip_document in ('FF')  and Numar_document=p.Numar_document and data=p.Data and Cont_debitor='4426' and (isnull(@contOK, '') = '' OR  Cont_creditor= rtrim(rtrim(@contOK)))) is null
then (select sum(suma) from pozincon where Tip_document in ('FF')  and Numar_document=p.Numar_document and data=p.Data and Cont_debitor='4426' and  Cont_creditor='4427')
else (select sum(suma) from pozincon where Tip_document in ('FF')  and Numar_document=p.Numar_document and data=p.Data and Cont_debitor='4426' and (isnull(@contOK, '') = '' OR  Cont_creditor= rtrim(rtrim(@contOK)))) end),0) as TVA,
isnull((select sum(suma) from pozincon where Tip_document in ('FF')  and Numar_document=p.Numar_document and data=p.Data and Cont_creditor='4427'),0) as s4427,
isnull((select sum(suma) from pozincon where Tip_document in ('FF')  and Numar_document=p.Numar_document and data=p.Data and Cont_debitor like '4428%'),0) as s4428,
isnull((select sum(suma) from pozincon where Tip_document in ('FF')  and Numar_document=p.Numar_document and data=p.Data and cont_debitor='609'),0) as s609,
isnull((select sum(suma) from pozincon where Tip_document in ('FF')  and Numar_document=p.Numar_document and data=p.Data and cont_debitor='667'),0) as s667
from pozadoc p left join dvi d on  p.Factura_dreapta=d.Factura_CIF
inner join terti t on t.tert=p.tert
where p.tip in ('FF') /*and YEAR(p.data)=2012*/
and p.Data>=@data1 and p.Data<=@data2
and (isnull(@contOK, '') = '' OR  p.Cont_cred= rtrim(rtrim(@contOK)))
and (isnull(@tert, '') = '' OR  p.Tert= rtrim(rtrim(@tert)))
group by p.Factura_dreapta,p.Numar_document,p.Data,t.Tert,t.Denumire,p.Tert
order by r.nrNiv