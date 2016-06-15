create function dbo.rapTVAVanz
(@DataJ datetime,@DataS datetime,@ContF char(13),@ContFExcep int,@Gest char(9),@LM char(9),@LMExcep int,@Jurnal char(3),@ContCor char(13),@TVAnx int,@RecalcBaza int,@CtVenScDed char(200),@CtPIScDed char(200),@nTVAex int,@FFFBTVA0 char(1),@SiFactAnul int,@TipCump int,@TVAAlteCont int,@DVITertExt int,@OrdDataDoc int,@OrdDenTert int,@DifIgnor float,@Tert char(13),@Factura char(20),@DetalDoc int,@TipFact char(1),@TVAEronat int,@CtNeimpoz char(200))
returns @rtva table
(numar char(20), data datetime, beneficiar char(80), codfisc char(20), total float, baza_19 float, tva_19 float, baza_9 float, tva_9 float, baza_exon_vanz float, tva_exon_vanz float, baza_exon_cump float, tva_exon_cump float, scutite_extern_ded float, scutite_extern_fara float, scutite_intra_ded_1 float, scutite_intra_ded_2 float, scutite_ded_alte float, scutite_fara float, neimpozabile float, explicatii char(50), detal_doc int, care_jurnal int, tip_doc char(2), nr_doc char(10), data_doc datetime, valoare_doc float, cota_tva_doc int, suma_tva_doc float)
begin
declare @ttt table
(numar char(20), data datetime, beneficiar char(80), codfisc char(20), total float, baza_19 float, tva_19 float, baza_9 float, tva_9 float, baza_exon_vanz float, tva_exon_vanz float, baza_exon_cump float, tva_exon_cump float, scutite_extern_ded float, scutite_extern_fara float, scutite_intra_ded_1 float, scutite_intra_ded_2 float, scutite_ded_alte float, scutite_fara float, neimpozabile float, explicatii char(50), cod_tert char(13), data_IC datetime, detal_doc int, care_jurnal int, tip_doc char(2), nr_doc char(10), data_doc datetime, valoare_doc float, cota_tva_doc int, suma_tva_doc float)

if @Tert is null set @Tert=''
if @Factura is null set @Factura=''

declare @Serv86 int
set @Serv86=isnull((select max(convert(int,val_logica)) from par where tip_parametru='GE' and parametru='JTVAVS86'),0)

insert @ttt
select d.factura as numar, min(d.data) as data, max(isnull(t.denumire,d.explicatii)) as beneficiar, max(isnull(t.cod_fiscal,(case when d.tipD='FA' then d.cont_TVA else '' end))) as codfisc, 
sum(d.valoare_factura+d.tva_22) as total,
sum((case when d.cota_tva=19 and d.exonerat=0 then dbo.BazaTVA(d.valoare_factura,d.baza_22,@RecalcBaza,@DifIgnor) else 0 end)) as baza_19,
sum((case when d.cota_tva=19 and d.exonerat=0 then d.tva_22 else 0 end)) as tva_19,
sum((case when d.cota_tva=9 and d.exonerat=0 then dbo.BazaTVA(d.valoare_factura,d.baza_22,@RecalcBaza,@DifIgnor) else 0 end)) as baza_9,
sum((case when d.cota_tva=9 and d.exonerat=0 then d.tva_22 else 0 end)) as tva_9,
sum((case when d.exonerat>0 and d.vanzcump='V' then dbo.BazaTVA(d.valoare_factura,d.baza_22,@RecalcBaza,@DifIgnor) else 0 end)) as baza_exon_vanz,
sum((case when d.exonerat>0 and d.vanzcump='V' then d.tva_22 else 0 end)) as tva_exon_vanz,
sum((case when d.exonerat>0 and d.vanzcump='C' then dbo.BazaTVA(d.valoare_factura,d.baza_22,@RecalcBaza,@DifIgnor) else 0 end)) as baza_exon_cump,
sum((case when d.exonerat>0 and d.vanzcump='C' then d.tva_22 else 0 end)) as tva_exon_cump,
sum((case when d.cota_TVA=0 and charindex(d.cont_coresp,@CtNeimpoz)=0 and (isnull(it.zile_inc,0)=1 and isnull(teritoriu,'U')='U' or isnull(it.zile_inc,0)=2 and isnull(teritoriu,'')='U') and @Serv86=1 and isnull(n.tip,'') in ('R','S') then d.valoare_factura else 0 end)) as scutite_extern_ded,
0 as scutite_extern_fara,
sum((case when d.cota_TVA=0 and charindex(d.cont_coresp,@CtNeimpoz)=0 and (isnull(it.zile_inc,0)=1 and isnull(teritoriu,'U')='U' or isnull(it.zile_inc,0)=2 and isnull(teritoriu,'')='U') and isnull(n.tip,'') not in ('R','S') then d.valoare_factura else 0 end)) as scutite_intra_ded_1,
0 as scutite_intra_ded_2,
sum((case when d.drept_ded<>'C' and (isnull(it.zile_inc,0)=0 or isnull(it.zile_inc,0)=1 and isnull(teritoriu,'U')='U' or isnull(it.zile_inc,0)=2 and isnull(teritoriu,'')='U') and not (d.cota_TVA=0 and (isnull(it.zile_inc,0)=1 and isnull(teritoriu,'U')='U' or isnull(it.zile_inc,0)=2 and isnull(teritoriu,'')='U') and @Serv86=0 and isnull(n.tip,'') in ('R','S')) or d.cota_TVA=0 and charindex(d.cont_coresp,@CtNeimpoz)>0 then 0 when @RecalcBaza=1 then (case when abs(d.valoare_factura-d.baza_22)>@DifIgnor then d.valoare_factura-d.baza_22 else 0 end) when d.cota_TVA=0 and (isnull(it.zile_inc,0)<>1 or isnull(it.zile_inc,0)=1 and @Serv86=0 and isnull(n.tip,'') in ('R','S')) then d.valoare_factura else 0 end)) as scutite_ded_alte,
sum((case when d.drept_ded='C' or isnull(it.zile_inc,0)>0 or d.cota_TVA=0 and charindex(d.cont_coresp,@CtNeimpoz)>0 then 0 when @RecalcBaza=1 then (case when abs(d.valoare_factura-d.baza_22)>@DifIgnor then d.valoare_factura-d.baza_22 else 0 end) when d.cota_TVA=0 then d.valoare_factura else 0 end)) as scutite_fara,
sum((case when d.cota_TVA=0 and charindex(d.cont_coresp,@CtNeimpoz)>0 then d.valoare_factura else 0 end)) as neimpozabile,
max(d.explicatii) as explicatii, d.tert as cod_tert, (case when d.tipDoc='IC' then d.data else '01/01/1901' end) as data_IC,
0 as detal_doc, 
max(case when d.numar_pozitie>=0 and d.cota_TVA=0 then 2 else 0 end)+max(case when d.numar_pozitie<0 or d.cota_TVA=0 or @RecalcBaza=1 and abs(d.valoare_factura-d.baza_22)>@DifIgnor then 0 else 1 end)+max(case when d.cota_TVA<>0 and @RecalcBaza=1 and abs(d.valoare_factura-d.baza_22)>@DifIgnor then 3 else 0 end) as care_jurnal, 
'' as tip_doc, '' as nr_doc, '01/01/1901' as data_doc, 0 as valoare_doc, 0 as cota_tva_doc, 0 as suma_tva_doc

from dbo.docTVAVanz(@DataJ,@DataS,@ContF,@ContFExcep,@Gest,@LM,@LMExcep,@Jurnal,@ContCor,@TVAnx,@RecalcBaza,@CtVenScDed,@CtPIScDed,@nTVAex,@FFFBTVA0,@SiFactAnul,@TipCump,@TVAAlteCont,@DVITertExt,@OrdDataDoc,@OrdDenTert,@Tert,@Factura,0,0) d
left outer join terti t on t.subunitate=d.subunitate and t.tert=d.tert and d.tipD<>'FA'
left outer join infotert it on it.subunitate=t.subunitate and it.tert=t.tert and it.identificator=''
left outer join nomencl n on n.cod=d.cod
left outer join pozdoc i on i.subunitate='INTRASTAT' and i.tip=d.tipdoc and i.numar=d.numar and i.data=d.data_doc and i.numar_pozitie=0
left outer join tari on cod_tara=i.cont_intermediar
where (@TipFact='' or d.vanzcump=@TipFact)
group by d.subunitate, d.factura, d.tert, (case when d.tipDoc='IC' then d.data else '01/01/1901' end)
having (@TVAEronat=0 or sum(case when d.cota_tva<>0 and abs(d.tva_22-d.baza_22*d.cota_tva/100)>@DifIgnor then 1 else 0 end)>0)

update @ttt
set care_jurnal=0
where care_jurnal>=3

if @DetalDoc=1
 insert @ttt
 select d.factura,min(isnull(r.data,d.data)),max(isnull(r.beneficiar,isnull(t.denumire,d.explicatii))),'',
 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
 '', d.tert, (case when d.tipDoc='IC' then d.data else '01/01/1901' end), 1, (case when d.numar_pozitie>=0 and d.cota_TVA=0 then 2 when @RecalcBaza=1 and abs(d.valoare_factura-d.baza_22)>@DifIgnor then 0 else 1 end), 
 d.tipDoc, d.numar, d.data_doc, sum(d.valoare_factura), d.cota_tva, sum(d.tva_22)
 from dbo.docTVAVanz(@DataJ,@DataS,@ContF,@ContFExcep,@Gest,@LM,@LMExcep,@Jurnal,@ContCor,@TVAnx,@RecalcBaza,@CtVenScDed,@CtPIScDed,@nTVAex,@FFFBTVA0,@SiFactAnul,@TipCump,@TVAAlteCont,@DVITertExt,@OrdDataDoc,@OrdDenTert,@Tert,@Factura,0,0) d
 left outer join terti t on t.subunitate=d.subunitate and t.tert=d.tert and d.tipD<>'FA'
 left outer join infotert it on it.subunitate=t.subunitate and it.tert=t.tert and it.identificator=''
 left outer join @ttt r on d.factura=r.numar and d.tert=r.cod_tert and (case when d.tipDoc='IC' then d.data else '01/01/1901' end)=r.data_IC
 where d.valoare_factura<>0 and (@TipFact='' or d.vanzcump=@TipFact)
 and (@TVAEronat=0 or r.numar is not null)
 group by d.subunitate, d.factura, d.tert, (case when d.tipDoc='IC' then d.data else '01/01/1901' end), 
 (case when d.numar_pozitie>=0 and d.cota_TVA=0 then 2 when @RecalcBaza=1 and abs(d.valoare_factura-d.baza_22)>@DifIgnor then 0 else 1 end), 
 d.tipDoc, d.numar, d.data_doc, d.cota_tva, sign(d.valoare_factura), sign(d.tva_22)

insert @rtva
select numar, data, beneficiar, codfisc, total, baza_19, tva_19, baza_9, tva_9, baza_exon_vanz, tva_exon_vanz, baza_exon_cump, tva_exon_cump, scutite_extern_ded, scutite_extern_fara, scutite_intra_ded_1, scutite_intra_ded_2, scutite_ded_alte, scutite_fara, neimpozabile, explicatii, detal_doc, care_jurnal, tip_doc, nr_doc, data_doc, valoare_doc, cota_tva_doc, suma_tva_doc
from @ttt
order by data, numar, beneficiar, detal_doc, data_doc, tip_doc, nr_doc

if 1=0 and @DetalDoc=1 begin
 update @rtva
 set care_jurnal=1 
 from @rtva r, @ttt t 
 where r.detal_doc=0 and t.detal_doc=1 and t.care_jurnal=1 and r.numar=t.numar and r.data=t.data and r.beneficiar=t.beneficiar
 update @rtva
 set care_jurnal=(case when r.care_jurnal=0 then 2 else 0 end) 
 from @rtva r, @ttt t 
 where r.detal_doc=0 and t.detal_doc=1 and t.care_jurnal=2 and r.numar=t.numar and r.data=t.data and r.beneficiar=t.beneficiar
 update @rtva
 set care_jurnal=0
 from @rtva r, @ttt t 
 where r.detal_doc=0 and t.detal_doc=1 and t.care_jurnal=0 and r.numar=t.numar and r.data=t.data and r.beneficiar=t.beneficiar
end

return
end
