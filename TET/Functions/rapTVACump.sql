create function dbo.rapTVACump
(@DataJ datetime,@DataS datetime,@ContF char(13),@Gest char(9),@LM char(9),@LMExcep int,@Jurnal char(3),@ContCor char(13),@TVAnx int,@RecalcBaza int,@nTVAex int,@FFFBTVA0 char(1),@SFTVA0 char(1),@IAFTVA0 int,@TipCump int,@TVAAlteCont int,@DVITertExt int,@OrdDataDoc int,@OrdDenTert int,@Provenienta char(1),@DifIgnor float,@Tert char(13),@Factura char(20),@DetalDoc int,@TipFact char(1),@TVAEronat int,@UnifFact int)
returns @rtva table
(numar char(20),data datetime,furnizor char(80),codfisc char(20),total float,baza_capital_19 float,tva_capital_19 float,baza_revanz_19 float,tva_revanz_19 float,baza_alte_19 float,tva_alte_19 float,baza_revanz_9 float,tva_revanz_9 float,baza_alte_9 float,tva_alte_9 float,scutite float,baza_revanz_intra float,tva_revanz_intra float,scutite_revanz_intra float,neimpoz_revanz_intra float,baza_alte_intra float,tva_alte_intra float,scutite_alte_intra float,neimpoz_alte_intra float,baza_oblig_intra float,tva_oblig_intra float,explicatii char(50),cont_tva char(13),detal_doc int,care_jurnal int,tip_doc char(2),nr_doc char(10),data_doc datetime,valoare_doc float,cota_tva_doc int,suma_tva_doc float)
begin
declare @ttt table
(numar char(20),data datetime,furnizor char(80),codfisc char(20),total float,baza_capital_19 float,tva_capital_19 float,baza_revanz_19 float,tva_revanz_19 float,baza_alte_19 float,tva_alte_19 float,baza_revanz_9 float,tva_revanz_9 float,baza_alte_9 float,tva_alte_9 float,scutite float,baza_revanz_intra float,tva_revanz_intra float,scutite_revanz_intra float,neimpoz_revanz_intra float,baza_alte_intra float,tva_alte_intra float,scutite_alte_intra float,neimpoz_alte_intra float,baza_oblig_intra float,tva_oblig_intra float,explicatii char(50),cont_tva char(13),cod_tert char(13),data_PC datetime,detal_doc int,care_jurnal int,tip_doc char(2),nr_doc char(10),data_doc datetime,valoare_doc float,cota_tva_doc int,suma_tva_doc float)

if @Tert is null set @Tert=''
if @Factura is null set @Factura=''

insert @ttt
select d.factura,min(d.data),max(isnull(t.denumire,d.explicatii)),max(isnull(t.cod_fiscal,'')),sum(d.valoare_factura+d.tva_22),
sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)=1 then dbo.BazaTVA(d.valoare_factura,d.baza_22,@RecalcBaza,@DifIgnor) else 0 end)),
sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)=1 then d.tva_22 else 0 end)),
sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)=2 then dbo.BazaTVA(d.valoare_factura,d.baza_22,@RecalcBaza,@DifIgnor) else 0 end)),
sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)=2 then d.tva_22 else 0 end)),
sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)=3 then dbo.BazaTVA(d.valoare_factura,d.baza_22,@RecalcBaza,@DifIgnor) else 0 end)),
sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)=3 then d.tva_22 else 0 end)),
sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)=4 then dbo.BazaTVA(d.valoare_factura,d.baza_22,@RecalcBaza,@DifIgnor) else 0 end)),
sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)=4 then d.tva_22 else 0 end)),
sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)=5 then dbo.BazaTVA(d.valoare_factura,d.baza_22,@RecalcBaza,@DifIgnor) else 0 end)),
sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)=5 then d.tva_22 else 0 end)),

sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip) between 7 and 14 then 0 else dbo.ScutitTVA(d.valoare_factura,d.baza_22,d.cota_tva,@RecalcBaza,@DifIgnor) end)),

sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)=7 then dbo.BazaTVA(d.valoare_factura,d.baza_22,@RecalcBaza,@DifIgnor) else 0 end)),
sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)=7 then d.tva_22 else 0 end)),
sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip) in (7,8,9) then dbo.ScutitTVA(d.valoare_factura,d.baza_22,d.cota_tva,@RecalcBaza,@DifIgnor) else 0 end)),
sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip) in (7,8,9) and 1=0 then d.valoare_factura else 0 end)),

sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)=11 then dbo.BazaTVA(d.valoare_factura,d.baza_22,@RecalcBaza,@DifIgnor) else 0 end)),
sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)=11 then d.tva_22 else 0 end)),
sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip) in (11,12,13) then dbo.ScutitTVA(d.valoare_factura,d.baza_22,d.cota_tva,@RecalcBaza,@DifIgnor) else 0 end)),
sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip) in (11,12,13) and 1=0 then d.valoare_factura else 0 end)),

sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip) in (9,13,15) then dbo.BazaTVA(d.valoare_factura,d.baza_22,@RecalcBaza,@DifIgnor) else 0 end)),
sum((case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip) in (9,13,15) then d.tva_22 else 0 end)),
max(d.explicatii),max(d.cont_tva),d.tert,(case when d.tipDoc='PC' then d.data else '01/01/1901' end),
0,max(case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)<7 then 1 else 0 end)+max(case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)>=7 then 2 else 0 end),
'','','01/01/1901',0,0,0
from dbo.docTVACump(@DataJ,@DataS,@ContF,@Gest,@LM,@LMExcep,@Jurnal,@ContCor,@TVAnx,@RecalcBaza,@nTVAex,@FFFBTVA0,@SFTVA0,@IAFTVA0,@TipCump,@TVAAlteCont,@DVITertExt,@OrdDataDoc,@Tert,@Factura,@UnifFact,0,2) d
left outer join terti t on t.subunitate=d.subunitate and t.tert=d.tert
left outer join infotert it on it.subunitate=d.subunitate and it.tert=d.tert and it.identificator=''
left outer join nomencl n on n.cod=d.cod
left outer join pozdoc i on i.subunitate='INTRASTAT' and i.tip=d.tipdoc and i.numar=d.numar and i.data=d.data_doc and i.numar_pozitie=0
left outer join tari on cod_tara=i.cont_intermediar
where (@Provenienta='' or isnull(zile_inc,0)=(case when @Provenienta='E' then 2 else 0 end))
and (@TipFact='' or d.vanzcump=@TipFact)
group by d.subunitate,d.factura,d.tert,(case when d.tipDoc='PC' then d.data else '01/01/1901' end)
having (@TVAEronat=0 or sum(case when d.cota_tva<>0 and abs(d.tva_22-d.baza_22*d.cota_tva/100)>@DifIgnor then 1 else 0 end)>0)

update @ttt
set care_jurnal=0
where care_jurnal>=3

if @DetalDoc=1
 insert @ttt
 select d.factura,min(isnull(r.data,d.data)),max(isnull(r.furnizor,isnull(t.denumire,d.explicatii))),'',
 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
 '','',d.tert,(case when d.tipDoc='PC' then d.data else '01/01/1901' end),1,
 (case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)>=7 then 2 else 1 end),
 d.tipDoc,d.numar,d.data_doc,sum(d.valoare_factura),d.cota_tva,sum(d.tva_22)
 from dbo.docTVACump(@DataJ,@DataS,@ContF,@Gest,@LM,@LMExcep,@Jurnal,@ContCor,@TVAnx,@RecalcBaza,@nTVAex,@FFFBTVA0,@SFTVA0,@IAFTVA0,@TipCump,@TVAAlteCont,@DVITertExt,@OrdDataDoc,@Tert,@Factura,@UnifFact,0,2) d
 left outer join terti t on t.subunitate=d.subunitate and t.tert=d.tert
 left outer join infotert it on it.subunitate=d.subunitate and it.tert=d.tert and it.identificator=''
 left outer join @ttt r on d.factura=r.numar and d.tert=r.cod_tert and (case when d.tipDoc='PC' then d.data else '01/01/1901' end)=r.data_PC
 left outer join nomencl n on n.cod=d.cod
 left outer join pozdoc i on i.subunitate='INTRASTAT' and i.tip=d.tipdoc and i.numar=d.numar and i.data=d.data_doc and i.numar_pozitie=0
 left outer join tari on cod_tara=i.cont_intermediar
 where (@Provenienta='' or isnull(zile_inc,0)=(case when @Provenienta='E' then 2 else 0 end))
 and (@TipFact='' or d.vanzcump=@TipFact)
 and (@TVAEronat=0 or r.numar is not null)
 group by d.subunitate,d.factura,d.tert,(case when d.tipDoc='PC' then d.data else '01/01/1901' end),(case when dbo.colTVACump(zile_inc,teritoriu,d.cota_tva,exonerat,d.vanzcump,cont_coresp,n.tip)>=7 then 2 else 1 end),d.tipDoc,d.numar,d.data_doc,d.cota_tva,sign(d.valoare_factura),sign(d.tva_22)

insert @rtva
select numar,data,furnizor,codfisc,total,baza_capital_19,tva_capital_19,baza_revanz_19,tva_revanz_19,baza_alte_19,tva_alte_19,baza_revanz_9,tva_revanz_9,baza_alte_9,tva_alte_9,scutite,baza_revanz_intra,tva_revanz_intra,scutite_revanz_intra,neimpoz_revanz_intra,baza_alte_intra,tva_alte_intra,scutite_alte_intra,neimpoz_alte_intra,baza_oblig_intra,tva_oblig_intra,explicatii,cont_tva,detal_doc,care_jurnal,tip_doc,nr_doc,data_doc,valoare_doc,cota_tva_doc,suma_tva_doc
from @ttt
order by (case when @OrdDenTert=1 then furnizor+numar+convert(char(10),data,102) else convert(char(10),data,102)+numar end),detal_doc,data_doc,tip_doc,nr_doc

return
end
