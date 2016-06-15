--***
/*
	-->	Exemplu apel:
	exec rapJurnalTvaCumparari @sesiune='', @dataj='2013-06-01',@datas='2013-06-30', @tert='1843'
*/
create procedure rapJurnalTvaCumparari (@sesiune varchar(50),
	@DataJ datetime,@DataS datetime
	,@nTVAex varchar(1)=0	-->	Tip tva (taxare inversa):	0=toate, 1=exonerat, 2=fara exonerat
	,@FFFBTVA0 varchar(1)=2	--> Facturi operate pe FF:	0=nu apar fara tva, 1=cu cota<>0, 2=apar fara tva
	,@SFTVA0 varchar(1)=2	--> Facturi operate pe SF:	0=nu apar fara tva, 1=cu cota<>0, 2=apar fara tva
	,@OrdDataDoc varchar(1)=0
	,@Provenienta varchar(1)=''	-->	''=<Toate>,I=Interne, E=Extracomunitar, U=Intracomunitar
									-->	,C=toate cumpararile, V=Vanzari
	,@DifIgnor float=0.5		--> diferenta ignorata
	,@UnifFact varchar(1)=0	-->	Unificare numere facturi (0/1)
	,@nTVAneded int=0		-->	Tip TVA (neded.)	0=fara, 1=cu
	--	Filtre:
	,@cotatvaptfiltr float=null
	,@ContF varchar(40)=null,@LM varchar(40)=null, @ContCor varchar(40)=null	--> cont corespondent
	,@Tert varchar(40)=null, @Factura varchar(40)=null, @marcaj int=0	-->	marcaj: 0=toate, 1=Marcate, 2=Nemarcate
	--	am activat cei 2 parametrii la cererea lui Ghita.
	,@DVITertExt varchar(1)=0	-->	DVI pe tert extern
	,@RPTVACompPeRM int=0	--> Receptii prestarii cu tip TVA compensat cumulate pe factura de pe RM
	--	parametri nefolositi (ascunsi in raport):
	,@Gest varchar(40)=null
	,@LMExcep varchar(1)=0,@Jurnal varchar(40)=null,@RecalcBaza varchar(1)=0
	,@TVAAlteCont varchar(1)=0	--> tva pe alte conturi
	,@OrdDenTert varchar(1)=0
	,@DetalDoc varchar(1)=0	-->	Detaliere pe documente (0/1)
	,@TipTvaTert int=0	--> Tipul tertului/TVA:	0=nefiltrat, 1=platitor, 2=neplatitor, 3=TLI
	,@parXML xml='<row/>'
	)
as
begin
set transaction isolation level read uncommitted
declare @TipCump int, @TipFact char(1), @TVAnx int, @IAFTVA0 int, @TVAEronat int, @CtNeimpoz varchar(200), @grupaTerti varchar(20), @TipTert int, @dinCGplus int, @dincorelatii int
	,@tipuridocument varchar(2000)
select @TipCump=isnull(@parXML.value('(/*/@tipcump)[1]', 'int'),1)
		,@TipFact=isnull(@parXML.value('(/*/@tipfact)[1]', 'char(1)'),'')
		,@TVAnx=isnull(@parXML.value('(/*/@tvanx)[1]', 'int'),0)
		,@IAFTVA0=isnull(@parXML.value('(/*/@IAFTVA0)[1]', 'int'),0)
		,@TVAEronat=isnull(@parXML.value('(/*/@tvaeronat)[1]', 'int'),0)
		,@CtNeimpoz=isnull(@parXML.value('(/*/@ctneimpoz)[1]', 'varchar(200)'),'')
		,@grupaTerti=@parXML.value('(/*/@grterti)[1]', 'varchar(20)')
		,@TipTert=@parXML.value('(/*/@tiptert)[1]', 'int')
		,@dinCGplus=isnull(@parXML.value('(/*/@dincgplus)[1]', 'int'),0)
		,@dincorelatii=isnull(@parXML.value('(/*/@dincorelatii)[1]', 'int'),0)
		,@tipuridocument=isnull(@parXML.value('(/*/@tipuridocument)[1]', 'varchar(2000)'),'')
		
select @ContF=ISNULL(@ContF,''),@Gest=ISNULL(@Gest,''), @LM=isnull(@LM,''), @Jurnal=isnull(@Jurnal,''), @ContCor=ISNULL(@ContCor,'')
declare @q_cotatvaptfiltr float, @q_tip_facturi varchar(1), @subunitate varchar(9), @bugetari int, @Ct4426 varchar(40), @CtTvaNeexPlati varchar(40), @faraReturnareDate int
select @q_cotatvaptfiltr=isnull(@cotatvaptfiltr,0), @q_tip_facturi='', @subunitate='1'
if (@Provenienta in('C','V'))
begin
	set @q_tip_facturi=@provenienta
	set @Provenienta=''
end
select @subunitate=(case when parametru='SUBPRO' then val_alfanumerica else @subunitate end)
	,@bugetari=(case when parametru='BUGETARI' then Val_logica else @bugetari end)
	,@Ct4426=isnull((case when parametru='CDTVA' then val_alfanumerica else @Ct4426 end),'4426')
	,@CtTvaNeexPlati=(case when parametru='CNTLIFURN' then val_alfanumerica else @CtTvaNeexPlati end)
from par where tip_parametru='GE' and parametru in ('SUBPRO','BUGETARI','CDTVA','CNTLIFURN')

select @parXML=(select isnull(@marcaj,0) as marcaj, isnull(@RPTVACompPeRM,0) as RPTVACompPeRM, @TipTvaTert as tiptvatert,@sesiune as sesiune
	,@tipuridocument tipuridocument for xml raw)

if @Tert is null set @Tert=''
if @Factura is null set @Factura=''

--	creez tabela intermediara pt. prelucrare date
if object_id('tempdb..#vert') is not null drop table #vert
create table #vert 
	(sub char(9), factura char(20), dataf datetime, tert char(13), valoareDoc float, bazaDoc float, tvaDoc float, cota_tva float, total float, baza float, 
	tva float, scutit float, coloana int, colscutit int, exonerat int, vanzcump char(1), cont_TVA varchar(40), cont_coresp varchar(40), explicatii char(50), 
	tipDoc char(2), nrDoc char(20), dataDoc datetime, nrpozitie int, contPI varchar(40), tipPI char(2), cod char(20), TipTert int, Teritoriu char(1), TipNom char(1), 
	PCF int, tip_tva int, datafact datetime, contf varchar(40))

--	creez tabela intermediara in care se va insera rezultatul procedurii TVACumparari
if object_id('tempdb..#tvacump') is not null drop table #tvacump
create table #tvacump (subunitate char(9))
exec CreazaDiezTVA @numeTabela='#tvacump'

-- creare tabela ce va returna datele, se creeaza tabela cu un singur camp si se adauga celelalte coloana prin procedura CreazaDiezTVA
-- in cazul in care tabela exista la momentul apelului procedurii, se populeaza doar tabela existenta, fara ca procedura sa returneze date
set @faraReturnareDate=0
if object_id('tempdb..#jtvacump') is not null 
	set @faraReturnareDate=1
if object_id('tempdb..#jtvacump') is null 
begin
	create table #jtvacump (numar char(20))
	exec CreazaDiezTVA '#jtvacump'
end

--	populare tabela #tvacump prin apelul procedurii TVACumparari
exec dbo.TVACumparari @DataJ, @DataS, @ContF, @Gest, @LM, @LMExcep, @Jurnal, @ContCor, @TVAnx, @RecalcBaza, @nTVAex, @FFFBTVA0, @SFTVA0, @IAFTVA0, @TipCump,
					0, @DVITertExt, @OrdDataDoc, @Tert, @Factura, @UnifFact, 0, @nTVAneded, @parXML

insert #vert
select d.subunitate sub, d.factura factura, d.data dataf, d.tert tert,
	valoare_factura valoareDoc, (case when d.cota_tva=0 and abs(baza_22)<0.01 then valoare_factura else baza_22 end) bazaDoc, d.tva_22 tvaDoc, d.cota_tva cota_tva,
	valoare_factura+d.tva_22 total, 0 baza, 0 tva, 0 scutit, 0 coloana, 0 colscutit, exonerat, vanzcump, cont_TVA, cont_coresp, d.explicatii, 
	(case when d.tipD='RM' then d.tipDoc else d.tipD end) tipDoc, d.numar nrDoc, d.data_doc dataDoc, d.numar_pozitie nrpozitie, d.numarD contPI, d.tipDoc tipPI, d.cod,
	isnull(it.zile_inc, 0) tipTert, tari.teritoriu, isnull(n.tip, '') TipNom, 
	(case when tipDoc='PC' and f.data is not null then 1 else 0 end) PCF, -- daca PC-ul se leaga de o factura
	d.tip_tva, d.dataf as datafact, d.contf
from #tvacump d
	left outer join terti t on t.subunitate=d.subunitate and t.tert=d.tert
	left outer join facturi f on f.subunitate=d.subunitate and f.tert=d.tert and f.factura=d.factura and f.tip=0x54 and d.tipDoc='PC' and d.contf like '442%'
	left outer join infotert it on it.subunitate=d.subunitate and it.tert=d.tert and it.identificator=''
	left outer join nomencl n on n.cod=d.cod
	left outer join pozdoc i on i.subunitate='INTRASTAT' and i.tip=d.tipdoc and i.numar=d.numar and i.data=d.data_doc and i.numar_pozitie=0
	left outer join tari on cod_tara=i.cont_intermediar
where (@Provenienta='' or isnull(zile_inc, 0)=(case @Provenienta when 'E' then 2 when 'I' then 0 else 1 end))
	and (@TipFact='' or d.vanzcump=@TipFact) and (@q_cotatvaptfiltr=0 or d.cota_tva=@q_cotatvaptfiltr)
	and (isnull((select max(cast(val_logica as int)) from par where tip_parametru='SP' and parametru='AROBS'),0)=0 or not (left(d.contf,3) in ('473','462','446') and d.tva_22=0))

--	Lucian: utilizam procedura tipTVAFacturi care stabileste tipul de TVA al facturii
if object_id ('tempdb..#facturi_cu_TLI') is not null drop table #facturi_cu_TLI
select 
	'' as tip, 'F' tipf, ft.tert, ft.factura, max(ft.datafact) as data, max(ft.contf) as cont, '' as tip_tva
into #facturi_cu_TLI
from #vert ft 
group by ft.tert, ft.factura
exec tipTVAFacturi @dataJos=@dataJ, @dataSus=@dataS, @TLI=null

if @TVAAlteCont=1 -- facturile care nu au 4426...
	delete d
		from #vert d
		left outer join #facturi_cu_TLI f on f.tipf='F' and f.tert=d.tert and f.factura=d.factura
		where not (f.tip_tva='I' and not (d.tipDoc='PI' and tipPI='PC' and d.contPI=@CtTvaNeexPlati and d.nrDoc like 'IT%') and d.tip_tva=0 and cota_tva>0 and not (d.tipDoc='PI' and tipPI='PC')
			or d.tipDoc in ('RM','RS','RC') and d.cont_tva<>'')
else --	Lucian: pastram in tabela doar pozitiile cu tip TVA diferit de I, precum documentele generate prin inchidere TLI.
	delete d
		from #vert d
		left outer join #facturi_cu_TLI f on f.tipf='F' and f.tert=d.tert and f.factura=d.factura
		where f.tip_tva='I' and not (d.tipDoc='PI' and tipPI='PC' and d.contPI=@CtTvaNeexPlati and d.nrDoc like 'IT%') and d.tip_tva=0 and cota_tva>0 
			and not (d.tipDoc='PI' and tipPI='PC')	--	nu stergem PC-urile inregistrate manual de la terti cu TLI  - trebuie sa apara in jurnal
			or d.tipDoc in ('RM','RS','RC') and d.cont_tva<>''

-- apel functie care incadreaza sumele pe coloane
update #vert
set coloana=dbo.coloanaTVACumparari (cota_tva, exonerat, vanzcump, cont_coresp, @CtNeimpoz, TipTert, Teritoriu, TipNom, tert, factura, tipDoc, nrDoc, dataDoc, nrpozitie, contPI, tipPI, cod)

-- apel functie specifica care permite mutarea sumelor pe alte coloane fata de cele standard
if exists (select 1 from sysobjects where type in ('FN', 'IF') and name='funcColTVACump')
	update #vert
	set coloana=dbo.funcColTVACump (coloana, cota_tva, exonerat, vanzcump, cont_coresp, @CtNeimpoz, TipTert, Teritoriu, TipNom, tert, factura, tipDoc, nrDoc, dataDoc, nrpozitie, contPI, tipPI, cod)

update #vert
set 
baza=(case when coloana in (6, 8, 11, 15, 17, 21, 25) then dbo.BazaTVA(valoareDoc, bazaDoc, @RecalcBaza, @DifIgnor) else valoareDoc end), 
tva=(case when coloana in (6, 8, 11, 15, 17, 21, 25) then tvaDoc else 0 end), 
scutit=(case when coloana in (6, 8, 11, 15, 17, 21, 25) and @RecalcBaza=1 and abs(valoareDoc-bazaDoc)>@DifIgnor then valoareDoc-bazaDoc else 0 end)

update #vert
set colscutit=(case when coloana in (11,21) then 13 else 10 end)
where abs(scutit)>=0.01

insert #jtvacump(numar, data, cod_tert, furnizor, codfisc
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
	,(case when @faraReturnareDate=1 and @dincorelatii=0 then min(v.tipDoc) else '' end), '', (case when @faraReturnareDate=1 and @dincorelatii=0 then max(v.dataDoc) else '01/01/1901' end) as data_doc
	,0, 0, 0 suma_tva_doc
	,sum(case when coloana=21 then baza else 0 end), sum(case when coloana=21 then tva else 0 end) tva_intra_serv
	,sum(case when coloana=23 then baza else 0 end) scutite_intra_serv
	,sum(case when coloana=25 then baza else 0 end) baza_oblig_1_serv, sum(case when coloana=25 then tva else 0 end) tva_oblig_1_serv
from #vert v
left outer join terti t on v.sub=t.subunitate and v.tert=t.tert
group by factura, v.tert, (case when v.tipPI='PC' and PCF=0 then dataf else '01/01/1901' end)
having (@TVAEronat=0 or sum(case when v.cota_tva<>0 and abs(v.tvaDoc-v.bazaDoc*v.cota_tva/100)>@DifIgnor then 1 else 0 end)>0)

if @DetalDoc=1
	insert #jtvacump
	select (case when @dincorelatii=1 and tipDoc='PI' then contPI else factura end), min(dataf), v.tert, rtrim(max(isnull(t.denumire, v.explicatii))), rtrim(max(isnull(t.cod_fiscal, ''))), 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	'', '', 1, 
	(case when max(coloana)<=10 and max(colscutit)<=10 then 1 when min(coloana)>=11 and (max(colscutit)=0 or min(colscutit)>=11) then 2 else 0 end), 
	(case when tipDoc='RP' and @dincorelatii=1 then 'RM' when tipDoc<>'PI' or @dincorelatii=1 then tipDoc else tipPI end), (case when @dincorelatii=1 and tipDoc='PI' then contPI else nrDoc end) as nr_doc, dataDoc, 
	sum(valoareDoc), cota_tva, sum(tvaDoc), 0, 0, 0, 0, 0
	from #vert v
	left outer join terti t on v.sub=t.subunitate and v.tert=t.tert
	group by (case when @dincorelatii=1 and tipDoc='PI' then contPI else factura end), v.tert, (case when v.tipPI='PC' and PCF=0 then dataf else '01/01/1901' end), 
		coloana, (case when tipDoc='RP' and @dincorelatii=1 then 'RM' when tipDoc<>'PI' or @dincorelatii=1 then tipDoc else tipPI end), (case when @dincorelatii=1 and tipDoc='PI' then contPI else nrDoc end), dataDoc, cota_TVA
	having (@TVAEronat=0 or sum(case when v.cota_tva<>0 and abs(v.tvaDoc-v.bazaDoc*v.cota_tva/100)>@DifIgnor then 1 else 0 end)>0)

if @faraReturnareDate=0
select rtrim(numar) numar, data, rtrim(cod_tert) cod_tert, rtrim(furnizor) furnizor, codfisc
	,total, baza_19, tva_19, baza_9, tva_9, scutite 
	,baza_intra, tva_intra, scutite_intra, neimpoz_intra 
	,baza_oblig_1, tva_oblig_1, baza_oblig_2, tva_oblig_2, explicatii
	,(case when @dinCGplus=1 and @bugetari=0 then right(replace(convert(char(10), data, 104),'.',' '),7) else cont_tva end) cont_tva
	,detal_doc, care_jurnal, tip_doc, nr_doc, data_doc, valoare_doc, cota_tva_doc, suma_tva_doc
	,baza_intra_serv, tva_intra_serv, scutite_intra_serv
	,baza_oblig_1_serv, tva_oblig_1_serv
	,(case when @dinCGplus=1 and @bugetari=1 then cont_tva else '' end) ord_cont_tva
from #jtvacump d
	left outer join terti t on t.subunitate=@subunitate and t.tert=d.cod_tert
	left outer join infotert it on it.subunitate=@subunitate and it.tert=d.cod_tert and it.identificator=''
where --total<>0 or --> "total" nu este folosit, doar incurca
	(@grupaTerti is null or isnull(t.grupa, '')=@grupaTerti) and (@TipTert is null or isnull(it.zile_inc, -1)=@TipTert)
	and (@TipTvaTert=0 or isnull((select top 1 tt.tip_tva from tvapeterti tt where tt.tert=d.cod_tert and tt.tipf='F' and tt.dela<=@DataS and isnull(tt.factura,'')='' order by tt.dela desc),'P')=
		(case @TipTvaTert when 1 then 'P' when 2 then 'N' else 'I' end))
	and (baza_19<>0 or tva_19<>0 or baza_9<>0 or tva_9<>0 or scutite<>0
		or baza_intra<>0 or tva_intra<>0 or scutite_intra<>0 or neimpoz_intra<>0
		or baza_oblig_1<>0 or tva_oblig_1<>0 or baza_oblig_2<>0 or tva_oblig_2<>0
		or @DetalDoc=1 and (valoare_doc<>0 or suma_tva_doc<>0))
order by ord_cont_tva, (case when @OrdDenTert=1 then furnizor+numar+convert(char(10),data,102) else convert(char(10),data,102)+numar end), detal_doc, data_doc, tip_doc, nr_doc
end
