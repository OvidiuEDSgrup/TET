--***
create procedure dbo.yso_pjurnalTVACumparari 
	(@DataJ datetime, @DataS datetime, @ContF char(200), @Gest char(9), @LM char(9), @LMExcep int, @Jurnal char(3), @ContCor char(13), @TVAnx int, @RecalcBaza int, @nTVAex int, 
	@FFFBTVA0 char(1), @SFTVA0 char(1), @IAFTVA0 int, @TipCump int, @TVAAlteCont int, @DVITertExt int, @OrdDataDoc int, @OrdDenTert int, @Provenienta char(1), @DifIgnor float, 
	@Tert char(13), @Factura char(20), @DetalDoc int, @TipFact char(1), @TVAEronat int, @UnifFact int, @CtNeimpoz char(200),@nTVAned int,@cotatvaptfiltr float, @parXML xml)
as
declare @rtva table
	(numar char(20), data datetime, cod_tert char(13), furnizor varchar(80), codfisc varchar(20)
	,total float, baza_19 float, tva_19 float, baza_9 float, tva_9 float, scutite float
	,baza_intra float, tva_intra float, scutite_intra float, neimpoz_intra float
	,baza_oblig_1 float,tva_oblig_1 float, baza_oblig_2 float, tva_oblig_2 float, explicatii char(50), cont_tva char(13)
	,detal_doc int, care_jurnal int, tip_doc char(2), nr_doc char(10), data_doc datetime
	,valoare_doc float, cota_tva_doc int, suma_tva_doc float, baza_intra_serv float, tva_intra_serv float, scutite_intra_serv float
	,baza_oblig_1_serv float,tva_oblig_1_serv float)
begin
declare @vert table
(	sub char(9), factura char(20), dataf datetime, tert char(13), valoareDoc float, bazaDoc float, tvaDoc float, cota_tva float, total float, baza float, 
	tva float, scutit float, coloana int, colscutit int, exonerat int, vanzcump char(1), cont_TVA char(13), cont_coresp char(13), explicatii char(50), 
	tipDoc char(2), nrDoc char(10), dataDoc datetime, nrpozitie int, contPI char(13), tipPI char(2), cod char(20), TipTert int, Teritoriu char(1), TipNom char(1))

if @Tert is null set @Tert=''
if @Factura is null set @Factura=''

insert @vert
select d.subunitate sub, d.factura factura, d.data dataf, d.tert tert,
	valoare_factura valoareDoc, (case when d.cota_tva=0 and abs(baza_22)<0.01 then valoare_factura else baza_22 end) bazaDoc, tva_22 tvaDoc, d.cota_tva cota_tva,
	valoare_factura+tva_22 total, 0 baza, 0 tva, 0 scutit, 0 coloana, 0 colscutit, exonerat, vanzcump, cont_TVA, cont_coresp, d.explicatii, 
	(case when d.tipD='RM' then d.tipDoc else d.tipD end) tipDoc, d.numar nrDoc, d.data_doc dataDoc, d.numar_pozitie nrpozitie, d.numarD contPI, d.tipDoc tipPI, d.cod,
	isnull(it.zile_inc, 0) tipTert, tari.teritoriu, isnull(n.tip, '') TipNom
from dbo.docTVACump (@DataJ, @DataS, @ContF, @Gest, @LM, @LMExcep, @Jurnal, @ContCor, @TVAnx, @RecalcBaza, @nTVAex, @FFFBTVA0, @SFTVA0, @IAFTVA0, @TipCump,
					@TVAAlteCont, @DVITertExt, @OrdDataDoc, @Tert, @Factura, @UnifFact, 0, @nTVAned, @parXML) d
	left outer join terti t on t.subunitate=d.subunitate and t.tert=d.tert
	left outer join infotert it on it.subunitate=d.subunitate and it.tert=d.tert and it.identificator=''
	left outer join nomencl n on n.cod=d.cod
	left outer join pozdoc i on i.subunitate='INTRASTAT' and i.tip=d.tipdoc and i.numar=d.numar and i.data=d.data_doc and i.numar_pozitie=0
	left outer join tari on cod_tara=i.cont_intermediar
where (@Provenienta='' or isnull(zile_inc, 0)=(case @Provenienta when 'E' then 2 when 'I' then 0 else 1 end))
and (@TipFact='' or d.vanzcump=@TipFact) and (@cotatvaptfiltr=0 or d.cota_tva=@cotatvaptfiltr)

update @vert
set coloana=dbo.coloanaTVACumparari (cota_tva, exonerat, vanzcump, cont_coresp, @CtNeimpoz, TipTert, Teritoriu, TipNom, tert, factura, tipDoc, nrDoc, dataDoc, nrpozitie, contPI, tipPI, cod)

if exists (select 1 from sysobjects where type in ('FN', 'IF') and name='funcColTVACump')
	update @vert
	set coloana=dbo.funcColTVACump (coloana, cota_tva, exonerat, vanzcump, cont_coresp, @CtNeimpoz, TipTert, Teritoriu, TipNom, tert, factura, tipDoc, nrDoc, dataDoc, nrpozitie, contPI, tipPI, cod)

update @vert
set 
baza=(case when coloana in (6, 8, 11, 15, 17, 21, 25) then dbo.BazaTVA(valoareDoc, bazaDoc, @RecalcBaza, @DifIgnor) else valoareDoc end), 
tva=(case when coloana in (6, 8, 11, 15, 17, 21, 25) then tvaDoc else 0 end), 
scutit=(case when coloana in (6, 8, 11, 15, 17, 21, 25) and @RecalcBaza=1 and abs(valoareDoc-bazaDoc)>@DifIgnor then valoareDoc-bazaDoc else 0 end)

update @vert
set colscutit=(case when coloana in (11,21) then 13 else 10 end)
where abs(scutit)>=0.01

insert @rtva(numar, data, cod_tert, furnizor, codfisc
	,total, baza_19, tva_19, baza_9, tva_9, scutite
	,baza_intra, tva_intra, scutite_intra, neimpoz_intra, baza_oblig_1
	,tva_oblig_1, baza_oblig_2, tva_oblig_2, explicatii, cont_tva
	,detal_doc, care_jurnal, tip_doc, nr_doc, data_doc
	,valoare_doc, cota_tva_doc, suma_tva_doc, baza_intra_serv, tva_intra_serv, scutite_intra_serv
	,baza_oblig_1_serv, tva_oblig_1_serv)
select factura, min(dataf), v.tert, rtrim(max(isnull(t.denumire, v.explicatii))) explicatii
	,rtrim(max(isnull(t.cod_fiscal, ''))), sum(total) total
	,sum(case when coloana=6 then baza else 0 end), sum(case when coloana=6 then tva else 0 end) tva_19
	,sum(case when coloana=8 then baza else 0 end), sum(case when coloana=8 then tva else 0 end) tva_9
	,sum(case when coloana=10 then baza else 0 end)+sum(case when colscutit=10 then scutit else 0 end) scutite
	,sum(case when coloana in (11,21) then baza else 0 end), sum(case when coloana in (11,21) then tva else 0 end) tva_intra
	,sum(case when coloana in (13,23) then baza else 0 end)+sum(case when colscutit in (13,23) then scutit else 0 end) scutite_intra
	,sum(case when coloana=14 then baza else 0 end)+sum(case when colscutit=14 then scutit else 0 end) neimpoz_intra
	,sum(case when coloana in (15,25) then baza else 0 end), sum(case when coloana in (15,25) then tva else 0 end) tva_oblig_1
	,sum(case when coloana=17 then baza else 0 end), sum(case when coloana=17 then tva else 0 end) tva_oblig_2 
	,max(explicatii), max(v.cont_TVA), 0 detal_doc
	,(case when max(coloana)<=10 and max(colscutit)<=10 then 1 
		when min(coloana)>=11 and (max(colscutit)=0 or min(colscutit)>=11) then 2 else 0 end) care_jurnal
	,'', '', '01/01/1901', 0, 0, 0 suma_tva_doc
	,sum(case when coloana=21 then baza else 0 end), sum(case when coloana=21 then tva else 0 end) tva_intra_serv
	,sum(case when coloana=23 then baza else 0 end) scutite_intra_serv
	,sum(case when coloana=25 then baza else 0 end) baza_oblig_1_serv, sum(case when coloana=25 then tva else 0 end) tva_oblig_1_serv
from @vert v
left outer join terti t on v.sub=t.subunitate and v.tert=t.tert
group by factura, v.tert, (case when v.tipPI='PC' then dataf else '01/01/1901' end)
having (@TVAEronat=0 or sum(case when v.cota_tva<>0 and abs(v.tvaDoc-v.bazaDoc*v.cota_tva/100)>@DifIgnor then 1 else 0 end)>0)

if @DetalDoc=1
	insert @rtva
	select factura, min(dataf), v.tert, rtrim(max(isnull(t.denumire, v.explicatii))), rtrim(max(isnull(t.cod_fiscal, ''))), 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	'', '', 1, 
	(case when max(coloana)<=10 and max(colscutit)<=10 then 1 when min(coloana)>=11 and (max(colscutit)=0 or min(colscutit)>=11) then 2 else 0 end), 
	(case when tipDoc<>'PI' then tipDoc else tipPI end), nrDoc, dataDoc, 
	sum(valoareDoc), cota_tva, sum(tvaDoc), 0, 0, 0, 0, 0
	from @vert v
	left outer join terti t on v.sub=t.subunitate and v.tert=t.tert
	group by factura, v.tert, (case when v.tipPI='PC' then dataf else '01/01/1901' end), 
		coloana, (case when tipDoc<>'PI' then tipDoc else tipPI end), nrDoc, dataDoc, cota_TVA
	having (@TVAEronat=0 or sum(case when v.cota_tva<>0 and abs(v.tvaDoc-v.bazaDoc*v.cota_tva/100)>@DifIgnor then 1 else 0 end)>0)
	
select * from @rtva
end
