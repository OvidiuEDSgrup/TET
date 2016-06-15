--***
create procedure rapJurnalTvaVanzari(@sesiune varchar(50), @DataJ datetime, @DataS datetime
	,@RecalcBaza int=0	--> Recalculare baza TVA
	,@nTVAex int=0	--> 0=Toate documentele, 1=Cu TVA exonerat, 2=Fara TVA exonerat,
					-->	3=Facturi casa de marcat, 8=Fara facturi UA, 9=Doar facturi UA
	,@Provenienta varchar(1)	-->	''=Toate, V=Vanzari, C=Cumparari
	,@OrdDataDoc int=0, @OrdDenTert int=1
	,@DifIgnor float=0.5		--> Diferenta ignorata
	,@TipTvaTert int=0	--> Tipul tertului/TVA:	0=nefiltrat, 1=platitor, 2=neplatitor, 3=TLI
	-- Filtre
	,@ContF varchar(40)=null
	,@LM varchar(40)=null, @LMExcep int=0				--> excepteaza locul de munca (LM)
	,@ContCor varchar(40)=null, @ContFExcep varchar(1)=0	--> excepteaza contul corespondent (=@ContCor)
	,@Tert varchar(40)=null, @Factura varchar(40)=null
	,@cotatvaptfiltr float=null
	--	parametri nefolositi (ascunsi in raport):
		,@Gest varchar(40)=null, @Jurnal varchar(40)=null
		,@FFFBTVA0 varchar(1)=0	--> apar si FB fara TVA 0=Nu, 2=Da
		,@SiFactAnul int=0		--> Si facturi anulate	0=Nu, 1=Da
		,@TVAAlteCont int=0		-->	TVA pe alte conturi	0=Nu, 1=Da
		,@DVITertExt int=0		-->	DVI pe tert extern	0=Nu, 1=Da
		,@DetalDoc int=0	-->	Detaliere pe documente	0=Nu, 1=Da
	-- par persistenti in BD:
		,@CtVenScDed varchar(40)=null		-->	"Cont(uri) venituri -> deducere"
		,@CtPIScDed varchar(40)=null		-->	"Cont(uri) antet PI -> deducere"
		,@CtCorespNeimpoz varchar(40)=null	-->	"Cont(uri) coresp -> neimpozabile"
		,@parXML xml='<row/>'
	)
as
set transaction isolation level read uncommitted
declare @TipCump int, @TipFact char(1), @TVAnx int, @TVAEronat int, @grupaTerti varchar(20), @TipTert int, @dinCGplus int, @CtTvaNeexIncasari varchar(40), @dincorelatii int
select @TipCump=isnull(@parXML.value('(/*/@tipcump)[1]', 'int'),1)
		,@TipFact=isnull(@parXML.value('(/*/@tipfact)[1]', 'char(1)'),'')
		,@TVAnx=isnull(@parXML.value('(/*/@tvanx)[1]', 'int'),0)
		,@TVAEronat=isnull(@parXML.value('(/*/@tvaeronat)[1]', 'int'),0)
		,@grupaTerti=@parXML.value('(/*/@grterti)[1]', 'varchar(20)')
		,@TipTert=@parXML.value('(/*/@tiptert)[1]', 'int')
		,@dinCGplus=isnull(@parXML.value('(/*/@dincgplus)[1]', 'int'),0)
		,@dincorelatii=isnull(@parXML.value('(/*/@dincorelatii)[1]', 'int'),0)

select @ContF=ISNULL(@ContF,''),@Gest=ISNULL(@Gest,''),@LM=ISNULL(@LM,'')
		,@Jurnal=isnull(@Jurnal,''), @ContCor=ISNULL(@ContCor,''),@Tert=ISNULL(@Tert,'')
		,@Factura=ISNULL(@Factura,'')
declare @q_cotatvaptfiltr float, @subunitate varchar(9), @faraReturnareDate int
set @q_cotatvaptfiltr=isnull(@cotatvaptfiltr,0)
select @subunitate=(case when parametru='SUBPRO' then val_alfanumerica else @subunitate end)
	,@CtTvaNeexIncasari=(case when parametru='CNTLIBEN' then val_alfanumerica else @CtTvaNeexIncasari end)
from par where tip_parametru='GE' and parametru in ('SUBPRO','CNTLIBEN')
select @nTVAex=@nTVAex+10*@TipTvaTert
--	tratat filtrare dupa tip facturi (dinspre Ria=Provenienta)
if (@Provenienta in ('C','V')) and @TipFact=''
	set @TipFact=@provenienta

-- nu e logic sa scriu aici in par
--update par set val_alfanumerica=@CtVenScDed where tip_parametru='GE' and parametru='CSCDED'
--update par set val_alfanumerica=@CtPIScDed where tip_parametru='GE' and parametru='CASCDED'
--update par set val_alfanumerica=@CtCorespNeimpoz where tip_parametru='GE' and parametru='CCNEIMPOZ'

if @Tert is null set @Tert=''
if @Factura is null set @Factura=''

if object_id('tempdb..#vert') is not null drop table #vert
create table #vert 
	(sub char(9), factura char(20), dataf datetime, tert char(13), valoareDoc float, bazaDoc float, tvaDoc float, cota_tva float, 
	total float, baza float, tva float, scutit float, coloana int, colscutit int, drept_ded char(1), exonerat int, vanzcump char(1),
	cont_TVA varchar(40), cont_coresp varchar(40), explicatii char(50), tipDoc char(2), nrDoc char(20), dataDoc datetime, nrpozitie int,
	contPI varchar(40), tipPI char(2), cod char(20), 
	TipTert int, -- intern, UE, extern
	Teritoriu char(1), TipNom char(1), tip_tva int, datafact datetime, contf varchar(40))

--	creez tabela intermediara in care se va insera rezultatul procedurii TVAVanzari
if object_id('tempdb..#tvavanz') is not null drop table #tvavanz
create table #tvavanz (subunitate char(9))
exec CreazaDiezTVA @numeTabela='#tvavanz'

-- creare tabela ce va returna datele, se creeaza tabela cu un singur camp si se adauga celelalte coloana prin procedura CreazaDiezTVA
-- in cazul in care tabela exista la momentul apelului procedurii, se populeaza doar tabela existenta, fara ca procedura sa returneze date
set @faraReturnareDate=0
if object_id('tempdb..#jtvavanz') is not null 
	set @faraReturnareDate=1
if object_id('tempdb..#jtvavanz') is null 
begin
	create table #jtvavanz (numar char(20))
	exec CreazaDiezTVA '#jtvavanz'
end

--@nTVAex int=0	-->ordinul unitatilor 0=Toate documentele, 1=Cu TVA exonerat, 2=Fara TVA exonerat,3=Facturi casa de marcat, 8=Fara facturi UA, 9=Doar facturi UA
--				   ordinul zecilor 0-toti 1-platitor tva, 2-neplatitor tva
declare @o_nTVAex int,@TLI int
set @o_nTVAex=@nTVAex
set @TipTvaTert=@o_nTVAex/10

select top 1 @TLI=(case when tip_tva='I' then 1 else 0 end)
	from TvaPeTerti
	where TvaPeTerti.tipf='B' and tert is null and tip_tva='I' and @DataJ>=dateadd(day,-90,dela)
	order by dela desc
if @TLI is null
	set @TLI=0

--	populare tabela #tvavanz prin apelul procedurii TVAVanzari
declare @pxml xml
set @pxml=(select @sesiune as sesiune for xml raw)
exec dbo.TVAVanzari @DataJ,@DataS,@ContF,@ContFExcep,@Gest,@LM,@LMExcep,@Jurnal,@ContCor,@TVAnx,@RecalcBaza,@CtVenScDed,
	@CtPIScDed,@o_nTVAex,@FFFBTVA0,@SiFactAnul,@TipCump,@TVAAlteCont,@DVITertExt,@OrdDataDoc,@OrdDenTert,@Tert,@Factura,0,0, @pxml--'<row />'

insert #vert
select d.subunitate, d.factura, d.data, d.tert, 
	valoare_factura, (case when d.cota_tva=0 and abs(baza_22)<0.01 then valoare_factura else baza_22 end), tva_22, d.cota_tva, 
	valoare_factura+tva_22 total, 0 baza, 0 tva, 0 scutit, 0 coloana, 0 colscutit, 
	drept_ded, exonerat, vanzcump, cont_TVA, cont_coresp, d.explicatii, d.tipD tipDoc, d.numar nrDoc,
	d.data_doc dataDoc, d.numar_pozitie nrpozitie, d.numarD contPI, d.tipDoc tipPI, d.cod, 
	isnull(it.zile_inc, 0) TipTert, tari.teritoriu, isnull(n.tip, '') TipNom, d.tip_tva, d.dataf as datafact, d.contf
from #tvavanz d
	left outer join terti t on t.subunitate=d.subunitate and t.tert=d.tert and d.tipD<>'FA'
	left outer join infotert it on it.subunitate=t.subunitate and it.tert=t.tert and it.identificator=''
	left outer join nomencl n on n.cod=d.cod
	left outer join pozdoc i on i.subunitate='INTRASTAT' and i.tip=d.tipdoc and i.numar=d.numar and i.data=d.data_doc and i.numar_pozitie=0
	left outer join tari on cod_tara=i.cont_intermediar
where (@TipFact='' or d.vanzcump=@TipFact) and (@q_cotatvaptfiltr=0 or d.cota_tva=@q_cotatvaptfiltr)
	and (@TipTvaTert=0
		or (((@TipTvaTert=1) and isnull((select top 1 tt.tip_tva from tvapeterti tt where tt.tert=d.tert and tt.tipf='F' and tt.dela<=@DataS and isnull(tt.factura,'')='' order by tt.dela desc),'P')='P' 
				/*isnull(it.Grupa13,0)<>1*/ and (t.tert is not null /*or d.tert='<Dim BF>'*/)
		or (@TipTvaTert=3 and @tli=1 or @TipTvaTert=1 and @tli=0) and isnull((select top 1 tt.tip_tva from tvapeterti tt where tt.tert=d.tert and tt.tipf='F' and tt.dela<=@DataS and isnull(tt.factura,'')='' order by tt.dela desc),'P')='I' 
				and (t.tert is not null /*or d.tert='<Dim BF>'*/)
		or @TipTvaTert=2 and (isnull((select top 1 tt.tip_tva from tvapeterti tt where tt.tert=d.tert and tt.tipf='F' and tt.dela<=@DataS and isnull(tt.factura,'')='' order by tt.dela desc),'P')='N' 
				/*isnull(it.Grupa13,0)=1*/ or t.tert is null)) and d.tipD<>'FA') 
		or d.tipD='FA')

--	Lucian: utilizam procedura tipTVAFacturi care stabileste tipul de TVA al facturii
if object_id ('tempdb..#facturi_cu_TLI') is not null drop table #facturi_cu_TLI
select 
	'' as tip, 'B' tipf, ft.tert, ft.factura, max(ft.datafact) as data, max(ft.contf) as cont, '' as tip_tva
into #facturi_cu_TLI
from #vert ft 
group by ft.tert, ft.factura
exec tipTVAFacturi @dataJos=@dataJ, @dataSus=@dataS, @TLI=null

-- Ghita: Facturile aferente bonurilor sunt platite, nu pot avea tip I
update f
set tip_tva='P'
from #facturi_cu_TLI f 
inner join #vert d on f.tipf='B' and f.tert=d.tert and f.factura=d.factura
where d.tipDoc='BP'

--	Lucian: pastram in tabela doar pozitiile cu tip TVA diferit de I si precum documentele generate prin inchidere TLI.
delete d
	from #vert d
	left outer join #facturi_cu_TLI f on f.tipf='B' and f.tert=d.tert and f.factura=d.factura
	where f.tip_tva='I' and not (d.tipDoc='PI' and tipPI='IC' and d.contPI=@CtTvaNeexIncasari and d.nrDoc like 'IT%') 
		and not (d.tipDoc='PI' and tipPI='IC')	--	nu stergem iC-urile inregistrate manual care sunt cu TLI (BD cu TLI sau terti cu TLI) - trebuie sa apara in jurnal
		and d.tip_tva=0 and d.cota_tva>0
		and d.tipdoc<>'FA' -- sa nu stearga documentele de UA

if (exists (select 1 from sysobjects o where o.type='U' and o.name='factposleg') OR exists (select 1 from sysobjects o where o.type='U' and o.name='antetBonuri') )
begin
	insert #vert
	select sub, /*convert(char(10),dataf,103)*/'', dataf, '<Dim BF>', -1*sum(valoaredoc), -1*sum(bazadoc), -1*sum(tvaDoc), cota_TVA, 
		-1*sum(valoaredoc+tvaDoc), 0, 0, 0, 0, 0, 
		max(drept_ded), exonerat, vanzcump, max(cont_TVA), max(cont_coresp), 'Diminuare bonuri fiscale ',  'BP', '', dataf, 0, '', '', '', 
		0, '', '', 0, null, null
	from #vert 
	where tipDoc='BP'
	group by sub, dataf, cota_TVA, exonerat, vanzcump
end

-- apel functie care incadreaza sumele pe coloane
update #vert
set coloana=dbo.coloanaTVAVanzari(cota_tva, drept_ded, exonerat, vanzcump, cont_coresp, @CtCorespNeimpoz, TipTert, Teritoriu, TipNom, tert, factura, tipDoc, nrDoc, dataDoc, nrpozitie, contPI, tipPI, cod)

-- apel functie specifica care permite mutarea sumelor pe alte coloane fata de cele standard
if exists (select 1 from sysobjects where type in ('FN', 'IF') and name='funcColTVAVanz')
	update #vert
	set coloana=dbo.funcColTVAVanz(coloana, cota_tva, drept_ded, exonerat, vanzcump, cont_coresp, @CtCorespNeimpoz, TipTert, Teritoriu, TipNom, tert, factura, tipDoc, nrDoc, dataDoc, nrpozitie, contPI, tipPI, cod)

declare @UARIA bit
if exists (select 1 from sysobjects o where o.type='U' and o.name='antetfactAbon')
	set @UARIA=1
else 
	set @UARIA=0

update #vert
set 
baza=(case when LEFT(explicatii,2)='UA' and exonerat=0 and tvaDoc=0 then 0 else (case when coloana in (6, 8, 19, 21) then dbo.BazaTVA(valoareDoc, bazaDoc, @RecalcBaza, @DifIgnor) else valoareDoc end) end),
tva=(case when coloana in (6, 8, 19, 21) then tvaDoc else 0 end), 
--Norbert 25.01.2012
scutit=(case when LEFT(explicatii,2)='UA' and exonerat=0 and tvaDoc=0 then valoareDoc 
	else (case when (coloana in (6, 8, 19, 21) and @RecalcBaza=1 and abs(valoareDoc-bazaDoc)>@DifIgnor) 
		or LEFT(explicatii,2)='UA'  and exonerat=0 then valoareDoc-bazaDoc-(case when LEFT(explicatii,2)='UA' and @UARIA=0 then 0 else tvaDoc end) else 0 end) end)
--scutit=(case when LEFT(explicatii,2)='UA' and exonerat=0 and tvaDoc=0 then valoareDoc else (case when (coloana in (6, 8, 19) and @RecalcBaza=1 and abs(valoareDoc-bazaDoc)>@DifIgnor) or LEFT(explicatii,2)='UA'  and exonerat=0 then valoareDoc-bazaDoc-tvadoc else 0 end) end)
declare @penneimp int
set @penneimp=isnull((select val_numerica from par where tip_parametru='UA' and parametru='PENNEIMP'),0)

update #vert
set colscutit=17
where abs(scutit)>=0.01

insert #jtvavanz
	(numar, data, cod_tert, beneficiar, codfisc, total, baza_19, tva_19, baza_9, tva_9, baza_5, tva_5
	,baza_txinv, tva_txinv, regim_spec, afara_ded, afara_fara, scutite_intra_ded_1
	,scutite_intra_ded_2, scutite_ded_alte, scutite_fara, neimpozabile, explicatii, detal_doc
	,care_jurnal, tip_doc, nr_doc, data_doc, valoare_doc, cota_tva_doc, suma_tva_doc, afara_ded_serv, baza_txinv_cump, tva_txinv_cump, baza_txinv_cump_9, tva_txinv_cump_9)
select factura numar, min(dataf) data, (case when tipDoc<>'FA' then v.tert else '' end) cod_tert
	,max(isnull(t.denumire, case when LEFT(explicatii,2)='UA' then substring(v.explicatii,3,48) else v.explicatii end)) beneficiar
	,max(isnull(t.cod_fiscal, (case when tipDoc in ('FA','BP') then cont_TVA else '' end))) codfisc
	,sum(total) total
	,sum(case when coloana=6 then baza else 0 end) baza_19, sum(case when coloana=6 then tva else 0 end) tva_19
	,sum(case when coloana=8 then baza else 0 end) baza_9, sum(case when coloana=8 then tva else 0 end) tva_9
	,sum(case when coloana=19 then baza else 0 end) baza_5, sum(case when coloana=19 then tva else 0 end) tva_5
	,sum(case when coloana=10 then baza else 0 end) baza_txinv, 0 tva_txinv
	,sum(case when coloana=11 then baza else 0 end)+sum(case when colscutit=11 then scutit else 0 end) regim_spec
	,sum(case when coloana=12 or coloana=22 then baza else 0 end)+sum(case when colscutit=12 or colscutit=22 then scutit else 0 end) afara_ded
	,sum(case when coloana=13 then baza else 0 end)+sum(case when colscutit=13 then scutit else 0 end) afara_fara
	,sum(case when coloana=14 then baza else 0 end)+sum(case when colscutit=14 then scutit else 0 end) scutite_intra_ded_1
	,sum(case when coloana=15 then baza else 0 end)+sum(case when colscutit=15 then scutit else 0 end) scutite_intra_ded_2
	,(case when @penneimp=1 then sum(case when coloana=16 then baza else 0 end)+sum(case when colscutit=16 then scutit else 0 end) 
	else sum(case when LEFT(explicatii,2)='UA' and exonerat=0 then scutit else (case when coloana=16 then baza else 0 end) end)
	+sum(case when LEFT(explicatii,2)='UA' and exonerat=0 then 0 else (case when colscutit=16 then scutit else 0 end) end) end) scutite_ded_alte
	,sum(case when LEFT(explicatii,2)='UA' and exonerat=0 then 0 else (case when coloana=17 then baza else 0 end) end)
		+sum(case when LEFT(explicatii,2)='UA' and exonerat=0 then 0 else (case when colscutit=17 then scutit else 0 end) end) scutite_fara
	,(case when @penneimp=1 then sum(case when LEFT(explicatii,2)='UA' and exonerat=0 then scutit else (case when coloana=18 then baza else 0 end) end)
	+sum(case when LEFT(explicatii,2)='UA' and exonerat=0 then 0 else (case when colscutit=18 then scutit else 0 end) end) else
	sum(case when coloana=18 then baza else 0 end)+sum(case when colscutit=18 then scutit else 0 end) end) neimpozabile	
	,max(case when LEFT(explicatii,2)='UA' and exonerat=0 then substring(explicatii,3,28) else explicatii end) explicatii
	,0 detal_doc,(case when max(coloana)<=11 and max(colscutit)<=11 then 1 when min(coloana)>=12 and (max(colscutit)=0 or min(colscutit)>=12) then 2 else 0 end) care_jurnal
	,'' tip_doc, '' nr_doc, '01/01/1901' data_doc, 0 valoare_doc, 0 cota_tva_doc, 0 suma_tva_doc
	,sum(case when coloana=22 then baza else 0 end)+sum(case when colscutit=22 then scutit else 0 end) afara_ded_serv
	,sum(case when coloana=21 and v.cota_tva!=9 then baza else 0 end) baza_txinv_cump, sum(case when coloana=21 and v.cota_tva!=9 then tva else 0 end) tva_txinv_cump
	,sum(case when coloana=21 and v.cota_tva=9 then baza else 0 end) baza_txinv_cump_9, sum(case when coloana=21 and v.cota_tva=9 then tva else 0 end) tva_txinv_cump_9
from #vert v
left outer join terti t on v.tipDoc<>'FA' and v.sub=t.subunitate and v.tert=t.tert
group by factura, (case when tipDoc<>'FA' then v.tert else '' end), (case when v.tipPI='IC' then dataf else '01/01/1901' end)
having (@TVAEronat=0 or sum(case when v.cota_tva<>0 and abs(v.tvaDoc-v.bazaDoc*v.cota_tva/100)>@DifIgnor then 1 else 0 end)>0)

if exists (select 1 from sysobjects where name='rapJurnalTvaVanzariSP')
	exec rapJurnalTvaVanzariSP @sesiune=@sesiune, @parXML=@parXML

if @DetalDoc=1
	insert #jtvavanz (numar, data, cod_tert, beneficiar, codfisc, total, baza_19, tva_19, baza_9, tva_9, baza_5, tva_5
		,baza_txinv, tva_txinv, regim_spec, afara_ded, afara_fara, scutite_intra_ded_1
		,scutite_intra_ded_2, scutite_ded_alte, scutite_fara, neimpozabile, explicatii, detal_doc
		,care_jurnal, tip_doc, nr_doc, data_doc, valoare_doc, cota_tva_doc, suma_tva_doc, afara_ded_serv, baza_txinv_cump, tva_txinv_cump, baza_txinv_cump_9, tva_txinv_cump_9)
	select (case when @dincorelatii=1 and tipDoc='PI' then contPI else factura end), min(dataf), (case when tipDoc<>'FA' then v.tert else '' end) cod_tert,
			max(isnull(t.denumire, v.explicatii)), max(isnull(t.cod_fiscal, (case when tipDoc='FA' then cont_TVA else '' end))) cod_fisc,
	0 total, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ,
	'' explicatii, 1 detal_doc, 
	(case when max(coloana)<=11 and max(colscutit)<=11 then 1 when min(coloana)>=12 and (max(colscutit)=0 or min(colscutit)>=12) then 2 else 0 end) care_jurnal,
	(case when tipDoc<>'PI' or @dincorelatii=1 then tipDoc else tipPI end) tip_doc, (case when @dincorelatii=1 and tipDoc='PI' then contPI else nrDoc end) nr_doc, dataDoc data_doc, 
	sum(valoareDoc) valoare_doc, cota_tva cota_tva_doc, sum(tvaDoc) suma_tva_doc, 0, 0, 0, 0, 0
	from #vert v
	left outer join terti t on v.tipDoc<>'FA' and v.sub=t.subunitate and v.tert=t.tert
	group by (case when @dincorelatii=1 and tipDoc='PI' then contPI else factura end), (case when tipDoc<>'FA' then v.tert else '' end), (case when v.tipPI='IC' then dataf else '01/01/1901' end), 
		coloana, (case when tipDoc<>'PI' or @dincorelatii=1 then tipDoc else tipPI end), (case when @dincorelatii=1 and tipDoc='PI' then contPI else nrDoc end), dataDoc, cota_TVA
	having (@TVAEronat=0 or sum(case when v.cota_tva<>0 and abs(v.tvaDoc-v.bazaDoc*v.cota_tva/100)>@DifIgnor then 1 else 0 end)>0)

--	selectul final
if @faraReturnareDate=0
select rtrim(numar) numar, data, rtrim(r.cod_tert) cod_tert, rtrim(beneficiar) beneficiar, rtrim(codfisc) codfisc
	,total, baza_19+(case when @dinCGplus=1 then baza_txinv_cump else 0 end) baza_19, tva_19+(case when @dinCGplus=1 then tva_txinv_cump else 0 end) tva_19, 
	(case when @Provenienta='1' then baza_5 else baza_9+baza_5+(case when @dinCGplus=1 then baza_txinv_cump_9 else 0 end) end) baza_9, 
	(case when @Provenienta='1' then tva_5 else tva_9+tva_5+(case when @dinCGplus=1 then tva_txinv_cump_9 else 0 end) end) tva_9, baza_5, tva_5
	,baza_txinv, tva_txinv, regim_spec, afara_ded, afara_fara, scutite_intra_ded_1
	,scutite_intra_ded_2, scutite_ded_alte, scutite_fara, neimpozabile, explicatii, detal_doc
	,care_jurnal, tip_doc, nr_doc, data_doc, valoare_doc, cota_tva_doc, suma_tva_doc, afara_ded_serv, baza_txinv_cump+baza_txinv_cump_9 as baza_txinv_cump, tva_txinv_cump+tva_txinv_cump_9 as tva_txinv_cump
from #jtvavanz r
	left outer join terti t on t.subunitate=@subunitate and t.tert=r.cod_tert
	left outer join infotert it on it.subunitate=@subunitate and it.tert=r.cod_tert and it.identificator=''
where (@grupaTerti is null or isnull(t.grupa, '')=@grupaTerti)
	and (@TipTert is null or isnull(it.zile_inc, (case when r.cod_tert='<Dim BF>' then 0 else -1 end))=@TipTert)
order by data, numar, beneficiar, detal_doc, data_doc, tip_doc, nr_doc
