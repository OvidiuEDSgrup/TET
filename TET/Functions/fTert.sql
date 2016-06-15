--***
--select * from dbo.fTert('B', '1901-01-01','2011-12-31', null, null, null, 0,0,0, null)
create function  fTert(@cFurnBenef char(1), @dDataJos datetime, @dDataSus datetime, @cTert char(13), @cFact char(20), 
						@cContFact char(13), @nSoldMin float,@nSemnSold int,@nStrictPerioada int = 0, @locm varchar(20))
returns @docfac table
(furn_benef char(1),subunitate char(9),tert char(13),factura char(20),tip char(2),numar char(20),data datetime,valoare float,tva float,
achitat float,valuta char(3),curs float,total_valuta float,achitat_valuta float,loc_de_munca char(13),comanda char(40),
cont_de_tert char(20),fel int,cont_coresp char(20),explicatii char(50),numar_pozitie int,gestiune char(13),data_facturii datetime,
data_scadentei datetime,nr_dvi char(13),barcod char(30), contTVA char(13), cod char(20), cantitate float, contract char(20),pozitie int identity,
data_platii datetime,punct_livrare char(5))

begin

declare @cSub char(9), @dDImpl datetime, @nAnImpl int, @nLunaImpl int, @nAnInitFact int, @IstFactImpl int, @dDataIncDoc datetime, 
@nAnImplMF int,@nLunaImplMF int, @dDataIncDocMF datetime, 
@Ignor4428Avans int, @Ignor4428DocFF int, @DVI int, @AccImpDVI int, @CtFactVamaDVI int, @GenisaUnicarm int, @DocSchimburi int, @FactBil int, @LME int, @IFN int

if exists (select 1 from par where Tip_parametru='GE' and Parametru='FLTTRTLM' and Val_logica=1)
	set @locm='%'
	else set @locm=ISNULL(@locm,'')+'%'
if @dDataJos is null set @dDataJos='01/01/1901'
if @dDataJos is null OR YEAR(@dDataJos)<1921 set @dDataJos='01/01/1901'
if @dDataSus is null set @dDataSus='01/01/2999'

select @cSub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'),''),
	@nAnImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULIMPL'),0),
	@nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAIMPL'),0),
	@dDImpl=dateadd(day,-1,dateadd(month,@nLunaImpl,dateadd(year,@nAnImpl-1901,'01/01/1901'))),
	@nAnInitFact=(select max(val_numerica) from par where tip_parametru='GE' and parametru='ULT_AN_IN')

if isnull(@nAnInitFact,0)<1901
	set @nAnInitFact=@nAnImpl
-- cazuri de apelare functie fTert:
	-- "documente pana la data" (la fel la refacere facturi) se trimite @dDataJos='01/01/1921' => trebuie sa ia facturile de la ultimul an initializat, nu toata istoria 
	-- "toata istoria" se trimite @dDataJos='01/01/1901' => trebuie sa trimita incepand cu "factimpl"
--Cristy: SET @dDataJos=dateadd(year, @nAnInitFact-1901,'01/01/1901'), comentat de Ghita, 26.10.2011, vezi mai jos
IF YEAR(@dDataJos)=1921 -- este o conventie, vezi mai sus: pentru "la data" si refacere: sa se ia de la ultimul an initializat
	SET @dDataJos=dateadd(year, @nAnInitFact-1901,'01/01/1901') 
-- Ce facem cu documentele pe o perioada mai mica decat anul initializarii - Nu le vom optimiza momentan, se vor lua documente de la implementare pana la data superioara
if @nAnInitFact<=@nAnImpl or @dDataJos<dateadd(year, @nAnInitFact-1901,'01/01/1901')
	begin 	--Daca nu exista an initializat va fi egal cu 2 => ia din factimpl
			--Daca din greseala exista an initializt mai mic sau egal cu data implementarii se va lua tot 2
			--Sau daca datajos este mai mica decat ulimul an initializat
		set @IstFactImpl=2 -- factimpl
		set @dDataIncDoc=dateadd(day, 1, @dDImpl)
	end
else	--Daca este an initializat intotdeauna se va seta @istFactImpl cu 1 => ia din an initializat
	begin
		set @IstFactImpl=1 -- istfact
		set @dDataIncDoc=dateadd(year, @nAnInitFact-1901, '01/01/1901')
	end
-- daca se doreste returnarea documentelor dintr-o perioada, fara analiza soldului: nu mai conteaza data inc. doc.
if @nStrictPerioada=1 and @dDataIncDoc<=@dDataJos
begin
	set @IstFactImpl=0 -- nu se vor lua date initiale, se studiaza doar rulajul
	set @dDataIncDoc=@dDataJos
end
-- nu mai vrem sa calculam data inc. doc. MF, vom trimite totdeauna data inc. doc. generala:
-- daca pana la 05.08.2012 ramane comentat se poate sterge:
--set @nAnImplMF=isnull((select max(val_numerica) from par where tip_parametru='MF' and parametru='ANULI'),0)
--set @nLunaImplMF=isnull((select max(val_numerica) from par where tip_parametru='MF' and parametru='LUNAI'),0)
--if @nAnImplMF>1901
--	set @dDataIncDocMF=dateadd(month,@nLunaImplMF,dateadd(year,@nAnImplMF-1901,'01/01/1901'))
--else
--	set @dDataIncDocMF=@dDataIncDoc
--if @dDataIncDocMF<@dDataIncDoc 
set @dDataIncDocMF=@dDataIncDoc

select @Ignor4428Avans=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='NEEXAV'),0),
	@Ignor4428Avans=(case when isnull(@Ignor4428Avans, 0)=0 then 1 else 0 end),
	@Ignor4428DocFF=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='NEEXDOCFF'),0),
	@Ignor4428DocFF=(case when isnull(@Ignor4428DocFF, 0)=0 then 1 else 0 end),
	@DVI=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='DVI'),0),
	@AccImpDVI=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='ACCIMP'),0),
	@CtFactVamaDVI=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='CONTFV'),0),
	@GenisaUnicarm=(case when exists (select 1 from par where tip_parametru='SP' and parametru in ('GENISA','UNICARM') and val_logica=1) then 1 else 0 end),
	@DocSchimburi=isnull((select max(case when val_logica=1 and val_numerica=0 then 1 else 0 end) from par where tip_parametru='GE' and parametru='DOCPESCH'),0),
	@FactBil=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='FACTBIL'),0),
	@LME=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='COMPPRET'),0),
	@IFN=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='IFN'),0)

select @cFurnBenef=isnull(@cFurnBenef,''),
	@cTert=isnull(@cTert,'%'),
	@cFact=isnull(@cFact,'%'),
	@cContFact=isnull(@cContFact,''),
	@nSoldMin=isnull(@nSoldMin,0),
	@nSemnSold=isnull(@nSemnSold,0)

if (@cFurnBenef='' or @cFurnBenef='F')
	insert @docfac  
	select 'F', f.*,f.data, ''		/**	data platii se ia din fBenef pentru IB-uri, in rest data_platii=data */
		from dbo.fFurn(@cSub, @IstFactImpl, @dDataIncDoc, @dDataSus, @cTert, @cFact, @cContFact, @Ignor4428Avans, @Ignor4428DocFF, 
			@DVI, @AccImpDVI, @CtFactVamaDVI, @FactBil, @dDataIncDocMF, @locm) f
if (@cFurnBenef='' or @cFurnBenef='B')
begin
	declare @LFact int
	set @LFact=isnull((select c.length from sysobjects o, syscolumns c where o.name='facturi' and o.id=c.id and c.name='factura'), 0)
	declare @contTvaDeductibil varchar(20), @userASiS varchar(30), @filtrareUser bit
		
	select	@userASiS=dbo.fIaUtilizator(null)
		,@contTvaDeductibil=rtrim(isnull((select val_alfanumerica from par where tip_parametru='GE' and parametru='CCTVA'),'4427'))
	select @filtrareUser=dbo.f_areLMFiltru(@userASiS)
		
	insert @docfac
	select 'B', subunitate, tert, factura, tip, numar, data, valoare, tva, achitat, valuta, curs, total_valuta, achitat_valuta,
		loc_de_munca, comanda, cont_de_tert, fel, cont_coresp, explicatii, numar_pozitie, gestiune, data_facturii, data_scadentei, punct_livrare, barcod,
		contTVA, cod, cantitate, contract, data_platii, punct_livrare
		from dbo.fBenef(@cSub, @IstFactImpl, @dDataIncDoc, @dDataSus, @cTert, @cFact, @cContFact, @Ignor4428Avans, @Ignor4428DocFF, 
				@GenisaUnicarm, @DocSchimburi, @LME, @FactBil, @dDataIncDocMF, @locm, @contTvaDeductibil, @userASiS, @filtrareUser) f	

	if exists (select 1 from sysobjects o where o.type='TF' and o.name='fBenefUA')
	insert @docfac
		select 'B', f.*, '','',0,'',f.data,'' from dbo.fBenefUA(@cSub,@dDataIncDoc,@dDataSus,@cTert,@cFact,@cContFact,@LFact) f	--*/
end
if @nSoldMin <> 0 
	delete @docfac 
	from (select furn_benef as ffurn_benef, tert as ttert, factura as ffactura from @docfac 
		group by furn_benef, tert, factura 
		having abs(sum(round(convert(decimal(17,5), valoare), 2) + round(convert(decimal(17,5), tva), 2) - round(convert(decimal(17,5), achitat), 2))) < @nSoldMin 
			or sign(sum(round(convert(decimal(17,5), valoare), 2) + round(convert(decimal(17,5), tva), 2) - round(convert(decimal(17,5), achitat), 2)))*@nSemnSold < 0
		) a 
	where furn_benef=a.ffurn_benef and tert=a.ttert and factura=a.ffactura

update @docfac
set valuta='', curs=0, total_valuta=0, achitat_valuta=0
from @docfac d 
where not exists (select 1 from terti t where t.subunitate=@csub and d.tert=t.tert and t.tert_extern=1)
	or @IFN=1 and d.furn_benef='B' and abs(d.total_valuta)<0.01 and abs(d.achitat_valuta)<0.01
--*/--*/--*/--*/--*/
return
end