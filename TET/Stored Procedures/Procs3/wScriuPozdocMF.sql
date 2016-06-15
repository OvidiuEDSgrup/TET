--***
create procedure [dbo].[wScriuPozdocMF] @sesiune varchar(50), @parXML xml 
as
--inloc. right(@tip,1)+@subtip cu @subtip unde se poate
declare @sub char(9),@datal datetime, @tip char(2),@subtip char(2),@numar char(8),@data datetime,
	@nrinv char(13),@denmf char(80),
	@seriemf char(20), @tipam char(1),@codcl char(13),@categmf int,@datapf datetime, 
	@tert char(13), @fact char(20), @datafact datetime, @datascad datetime, @valuta char(3), 
	@curs float, @pretvaluta float, @difvalinv float, @o_difvalinv float, @ajust float, 
	@pret float, @o_pret float, @cotatva float, @sumatva float, @o_sumatva float, @tiptva int, 
	@gest char(9), @lm char(9), @com char(20), @indbug char(30), @indbugprim char(30), 
	--@lmprim char(9),@comprim char(20), @gestprim char(9),
	@valinv float, @valam DECIMAL(18,2), @valamcls8 float, @valamneded float, @valamist float, 
	@rezreev float, @amlun float, --@amluncls8 float, @amlunneded float, 
	@tipmf int, @subtipmf char(1), @durata int, @o_durata int, @nrluni int, 
	@contmf varchar(20),@contcor varchar(20),@contam char(20),@contamcomprim char(20),@contcham varchar(20), --@contamcomprimold varchar(20),
	@contgestprim varchar(20), @contlmprim varchar(20), @conttva varchar(20), --@difam float, @difamcls8 float, 
	@cod char(20), @procinch float, @nrpozitie int, @codmfpublic char(20), @denmfpublic varchar(2000), @contpatrimiesire varchar(20), @contpatrimintrare varchar(20), 
	@patrim char(1), @denalternmf char(80), @prodmf char(80), @modelmf char(20), @nrinmatrmf char(13), 
	@durfunct char(20), @staremf char(13), @datafabr datetime, 
	@stare int, @jurnal char(3), @felop char(1), @tipdocCG char(2), --@tipdocMF char(3), 
	@tipGrp char(2), @numarGrp char(8), @dataGrp datetime, 
	@docXMLIaPozdocMF xml, @userASiS varchar(10), @eroare xml, @mesaj varchar(254), 
	@gestpropr varchar(20), @lmpropr varchar(20), --@clientpropr varchar(13), 
	/*@rulajepelm int, */@bugetari int, @Elcond int, @cttvaded varchar(20), @cttvacol varchar(20), 
	@modimpl int, @lunaimpl int, @anulimpl int, @dataimpl datetime, @cont8045 varchar(20), @contrezrep varchar(20), @ctchamcorp varchar(20), @anctmfchamcorp int, 
	@anlmchamcorp int,@ctchamnecorp varchar(20),@anctmfchamnecorp int,@anlmchamnecorp int,@doccuIC int,
	@AEnestdESU int, @ESUnoi int, @evidmfiesite int, @urmvalist int, @urmrezreev int, @reevcontab int, 
	@binar varbinary(128),@nrpozitiem int,@ctamm varchar(20),@tipm char(2),@subtipm char(2),
	@pretm float,@sumatvam float,@tiptvam int, @fetchstatus int, @farapozdoc int, 
	@xmlconttva varchar(20), @xmldatafact datetime, @xmltert char(13), @xmltiptva int, @xmlsubtip char(2), 
	@Ct4428TLIFurn varchar(20), @Ct4428TLIBenef varchar(20), @TipPlataTVA char(1), @xmlTVATert xml, @ptupdate int, @detaliiMfix xml, @detaliiPozdoc xml

--exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
--exec luare_date_par 'GE','RULAJELM', @rulajepelm output, 0, ''
exec luare_date_par 'GE','BUGETARI', @bugetari output, 0, ''
exec luare_date_par 'SP','ELCOND', @Elcond output, 0, ''
exec luare_date_par 'GE', 'CDTVA', 0, 0, @cttvaded output
exec luare_date_par 'GE', 'CCTVA', 0, 0, @cttvacol output
exec luare_date_par 'MF', 'IMPLEMENT', @modimpl output, 0, ''
exec luare_date_par 'MF', 'LUNAI', 0, @lunaimpl output, ''
exec luare_date_par 'MF', 'ANULI', 0, @anulimpl output, ''
set @dataimpl=CAST(CAST(@anulimpl AS varchar) + '-' + CAST(@lunaimpl AS varchar) + '-' + CAST('01' AS varchar) AS DATETIME)
set @dataimpl=dbo.EOM(@dataimpl)
exec luare_date_par 'MF', 'CTAMGRNU', 0, 0, @cont8045 output
if @cont8045='' set @cont8045='8045'
exec luare_date_par 'MF', 'CTREZREP', 0, 0, @contrezrep output
exec luare_date_par 'MF', 'CA681', 0, @anlmchamcorp output, @ctchamcorp output
if @ctchamcorp='' set @ctchamcorp='6811'
--exec luare_date_par 'MF','CA681', 0, @anctmfchamcorp output, ''
if @anlmchamcorp=2 set @anctmfchamcorp=1 else set @anctmfchamcorp=0
--exec luare_date_par 'MF','CA681', 0, @anlmchamcorp output, ''
if @anlmchamcorp=3 set @anlmchamcorp=1 else set @anlmchamcorp=0
exec luare_date_par 'MF', '681NECORP', 0, @anlmchamnecorp output, @ctchamnecorp output
if @ctchamnecorp='' set @ctchamnecorp=@ctchamcorp
--exec luare_date_par 'MF','681NECORP', 0, @anctmfchamnecorp output, ''
if @anlmchamnecorp=0 set @anctmfchamnecorp=@anctmfchamcorp
if @anlmchamnecorp=2 set @anctmfchamnecorp=1 else set @anctmfchamnecorp=0
--exec luare_date_par 'MF','681NECORP', 0, @anlmchamnecorp output, ''
if @anlmchamnecorp=0 set @anlmchamnecorp=@anlmchamcorp
if @anlmchamnecorp=3 set @anlmchamnecorp=1 else set @anlmchamnecorp=0
exec luare_date_par 'MF','INCONM', @doccuIC output, 0, ''
exec luare_date_par 'MF','AENSTDESU', @AEnestdESU output, 0, ''
exec luare_date_par 'MF','ESUNOI', @ESUnoi output, 0, ''
if @AEnestdESU=1 set @ESUnoi=0
exec luare_date_par 'MF','EVMFDCAS', @evidmfiesite output, 0, ''
exec luare_date_par 'MF','URMVALIST', @urmvalist output, 0, ''
exec luare_date_par 'MF','REZREEV', @urmrezreev output, 0, ''
exec luare_date_par 'MF','MRECONTAB', @reevcontab output, 0, ''
--exec luare_date_par 'MF','RIA', @MFria output, 0, ''
exec luare_date_par 'GE','CNTLIFURN',0,0,@Ct4428TLIFurn output
exec luare_date_par 'GE','CNTLIBEN',0,0,@Ct4428TLIBenef output

begin try
	--BEGIN TRAN
	set @binar=cast('modificaredocdefinitivMF' as varbinary(128))
	set CONTEXT_INFO @binar

	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozdocMFSP')
		exec wScriuPozdocMFSP @sesiune, @parXML output
 
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	
	select @gestpropr='', @lmpropr='' --, @clientpropr=''
	select @gestpropr=(case when Cod_proprietate='GESTIUNE' then valoare else @gestpropr end), 
		--@clientpropr=(case when Cod_proprietate='CLIENT' then valoare else @clientpropr end), 
		@lmpropr=(case when Cod_proprietate='LOCMUNCA' then isnull(valoare,'') else @lmpropr end)
	from proprietati where tip='UTILIZATOR' and cod=@userASiS 
		and Cod_proprietate in ('GESTIUNE', 'CLIENT', 'LOCMUNCA') and valoare<>''
	select @stare=2/*7*/, @jurnal='MFX' /*nu schimba jurnalul!!!!!*/
	if @parXML.value('(/row/row/@lm)[1]','varchar(9)') is null and 1=0	--n-ar trebui inserat in @parXML proprietatea LOCMUNCA.
	begin
		set @parXML.modify('insert attribute lm {sql:variable("@lmpropr")} into (/row/row)[1]') 
	end
--	stabilire cont TVA
	select @xmldatafact=@parXML.value('(/row/row/@datafact)[1]','datetime'), 
		@xmltert=@parXML.value('(/row/row/@tert)[1]','char(13)'),
		@xmltiptva=@parXML.value('(/row/row/@tiptva)[1]','int'),
		@xmlsubtip=@parXML.value('(/row/row/@subtip)[1]','char(2)'),
		@farapozdoc=isnull(@parXML.value('(/row/row/@farapozdoc)[1]','int'),0)
	
	if @xmlsubtip in ('AF','FF','VI')
	begin
		if @xmlsubtip in ('AF','FF') 
			set @xmlconttva=@cttvaded
		else
			set @xmlconttva=@cttvacol

		if @parXML.value('(/row/row/@conttva)[1]','varchar(20)') is null
			set @parXML.modify('insert attribute conttva {sql:variable("@xmlconttva")} into (/row/row)[1]') 

		if @parXML.value('(/row/row/@conttva)[1]','varchar(20)')=''
			set @parXML.modify('replace value of (/row/row/@conttva)[1] with sql:variable("@xmlconttva")')
	end

	exec wValidarePozdocMF @sesiune, @parXML --wValidarePozdocMF(@parXML)
	/*if isnull(@eroare.value('(error/@coderoare)[1]', 'int'), 0)>0
		begin
		set @mesaj = @eroare.value('(/error/@msgeroare)[1]', 'varchar(255)')
		raiserror(@mesaj, 11, 1)
		end*/

	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	declare crspozdocMF cursor for
	select isnull(sub, (case when data<(SELECT mm.Data_miscarii FROM misMF mm WHERE /*mm.subunitate=sub and */mm.Numar_de_inventar=nrinv and LEFT(mm.tip_miscare,1)='I') 
	/*daca se face impl. ca in MF, tb. si data<=data impl.!!!*/ then 'DENS' else (select rtrim(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO') end)) as sub,
	isnull(datal, dbo.eom(isnull(data, '01/01/1901'))) as datal, 
	tip, subtip, isnull(numar,'IMPL') as numar, data, nrinv, isnull(denmf, '') as denmf, 
	isnull(seriemf, '') as seriemf, isnull(tipam, '2') as tipam, isnull(codcl, '') as codcl, 
	isnull(categmf, 0) as categmf, 
	isnull(datapf, isnull(data, '01/01/1901')) as datapf, 
	(case when isnull(tert, '')<>'' then tert /*when subtip='VI' then @clientpropr */ when tip='ME' and subtip='SU' and @AEnestdESU=0 then 'AE' else '' end) as tert, 
	(case when tip='MM' and subtip='RE' and isnull(fact, '')='' then '0.00' else isnull(fact, '') end) as fact, 
	isnull(datafact, isnull(data, '01/01/1901')) as datafact, 
	isnull(datascad, isnull(datafact, isnull(data, '01/01/1901'))) as datascad, 
	isnull(valuta, '') as valuta, (case when isnull(valuta, '')='' then 0 else isnull(curs, 0) end) as curs, 
--	Lucian: la documente cu pret in valuta tratat sa recalculeze pret functie de pret valuta*curs (si la modificare pozitie)	
	(case when subtip in ('AF','FF','VI') and isnull(pretvaluta, 0)=0 then isnull(pret, isnull(valinv, 0)) else isnull(pretvaluta, 0) end) as pretvaluta, 
	(case when subtip in ('AF','FF','VI') and (isnull(pret,0)=0 or isnull(pretvaluta,0)<>0)
		then (case when isnull(pretvaluta,0)<>0 then round(isnull(pretvaluta, 0)*(case when isnull(valuta, '')='' then 1 else isnull(curs, 0) end),2) else isnull(valinv, 0) end) 
		else isnull(pret, 0) end) as pret, 
	isnull(cotatva, 0) as cotatva, 
--	Lucian: la documente cu pret in valuta tratat sa recalculeze valoarea TVA functie de pret valuta*curs (si la modificare pozitie)
--	La reevaluari sumatva contine Dif.am.cls.8. Sa ramina cea introdusa in macheta. Tratat si pentru alte subtipuri unde sumatva este dif. am. clasa 8.
	(case when isnull(sumatva,0)=0 or isnull(pretvaluta,0)<>0 and isnull(pretvaluta,0)<>isnull(o_pretvaluta,0) and subtip<>'VI' and subtip not in ('RE','EP','AL','MA')
		then (case when isnull(cotatva, 0)<>0 
			then round((case when subtip in ('AF','FF','VI') and isnull(pretvaluta,0)<>0 then round(isnull(pretvaluta, 0)*(case when isnull(valuta, '')='' then 1 else isnull(curs, 0) end),2)
					--when subtip='AF' and isnull(pret,0)=0 then isnull(valinv,0) 
					--when subtip='FF' then isnull(difvalinv,0) 
					else isnull(pret, 0) end)*isnull(cotatva, 0)/100,2) 
			else 0 end) 
		else sumatva end) as sumatva, 
	isnull(tiptva, 0) as tiptva, 
	isnull(ajust, 0) as ajust, 
	(case when isnull(gest, '')<>'' then gest else ''/*@gestpropr*/ end) as gest, 
	isnull(lm, '') as lm,	--(case when isnull(lm, '')<>'' then lm else @lmpropr end) as lm, N-ar fi nevoie de sa se preia ca loc de munca, proprietatea LOCMUNCA.
	/*isnull(com, '') as*/ com, /*replace(isnull(indbug, ''),'.','') as*/ indbug, indbugprim, 
--	Lucian: la documente cu pret in valuta tratat sa recalculeze valoarea de inventar functie de pret valuta*curs si la modificare pozitie
	isnull(valinv, 0) as valinv, isnull(difvalinv, 0) as difvalinv, isnull(valam, 0) as valam, isnull(valamcls8, 0) as valamcls8, 
	isnull(valamneded, 0) as valamneded, isnull(valamist, 0) as valamist, isnull(rezreev, 0) as rezreev, isnull(amlun, 0) as amlun, 
	isnull(tipmf, (case when isnull(valinv,isnull(pret,0))<isnull((select val_numerica from par where tip_parametru='MF' and parametru='VALOBINV'),1800) then 1 else 0 end)) as tipmf, 
	isnull(subtipmf, '') as subtipmf, durata, isnull(o_durata, 0) as o_durata, nrluni, 
	contmf, isnull(contcor, '') as contcor, contamcomprim, contcham, contgestprim, contlmprim as contlmprim, isnull(conttva, '') as conttva, contpatrimiesire, contpatrimintrare, 
	(case when isnull(cod, '')='' then 'MIJLOC_FIX_MF' else cod end) as cod, 
	(case when @modimpl=1 and data<=@dataimpl --or tip not in ('MB','MC') and @doccuIC=0 or tip='MM' and (subtip='TP' or data<(SELECT mm.Data_miscarii FROM misMF mm WHERE /*mm.subunitate=sub and */mm.Numar_de_inventar=nrinv and LEFT(mm.tip_miscare,1)='I') /*daca se face impl. ca-n MF, tb. si data<=data impl.!!!*/) 
		then 9 
		when 1=1 or isnull(procinch,0)=0 and (tip in ('MI','MM','ME') or tip='MT' and subtip='SE' and isnull(contcor,'')<>'' /*@rulajepelm=1*/) 
		then 6 
		else isnull(procinch, 0) end) as procinch, 
	isnull(nrpozitie, 0) as nrpozitie, 
	isnull(patrim, (case when left(contamcomprim,1)='8' then '1' else '' end)) as patrim, 
	isnull(denalternmf, '') as denalternmf, isnull(prodmf, '') as prodmf,
	isnull(modelmf, '') as modelmf, isnull(nrinmatrmf, '') as nrinmatrmf,
	isnull(durfunct, '') as durfunct, isnull(staremf, '') as staremf,
	isnull(datafabr, '01/01/1901') as datafabr, 
	isnull(o_difvalinv, 0) as o_difvalinv, isnull(o_pret, 0) as o_pret, 
	isnull(o_sumatva, 0) as o_sumatva, isnull(ptupdate,0) as ptupdate
	
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		sub char(9) '@sub', 
		datal datetime '../@datal',
		tip char(2) '../@tip', 
		subtip char(2) '@subtip', 
		numar char(8) '@numar',
		data datetime '@data',
		nrinv char(13) '@nrinv',
		denmf char(80) '@denmf',
		seriemf char(20) '@seriemf',
		tipam char(1) '@tipam',
		codcl char(13) '@codcl',
		categmf int '@categmf',
		datapf datetime '@datapf',
		tert char(13) '@tert',
		fact char(20) '@fact',
		datafact datetime '@datafact',
		datascad datetime '@datascad',
		valuta char(3) '@valuta', 
		curs float '@curs', 
		pretvaluta decimal(14, 6) '@pretvaluta', 
		difvalinv float '@difvalinv', 
		ajust float '@ajust', 
		pret decimal(12, 2) '@pret', 
		cotatva decimal(5, 2) '@cotatva', 
		sumatva decimal(15, 2) '@sumatva', 
		tiptva int '@tiptva', 
		gest char(9) '@gest', 
		lm char(9) '@lm', 
		com char(20) '@com', 
		indbug char(30) '@indbug',
		indbugprim char(30) '@indbugprim',
		valinv float '@valinv', 
		valam decimal(18,2) '@valam',
		valamcls8 float '@valamcls8', 
		valamneded float '@valamneded', 
		valamist float '@valamist', 
		rezreev float '@rezreev', 
		amlun float '@amlun', 
		tipmf int '@tipmf',
		subtipmf char(1) '@subtipmf',
		durata int '@durata',
		o_durata int '@o_durata',
		nrluni int '@nrluni',
		contmf varchar(20) '@contmf', 
		contcor varchar(20) '@contcor', 
		contamcomprim varchar(20) '@contamcomprim', 
		contcham varchar(20) '@contcham', 
		contgestprim varchar(20) '@contgestprim', 
		contlmprim varchar(20) '@contlmprim', 
		conttva varchar(20) '@conttva',
		contpatrimiesire varchar(20) '@contpatrimiesire', 
		contpatrimintrare varchar(20) '@contpatrimintrare', 
		cod char(20) '@cod',
		procinch float '@procinch',
		nrpozitie int '@nrpozitie',
		patrim char(1) '@patrim',
		denalternmf char(80) '@denalternmf',
		prodmf char(80) '@prodmf',
		modelmf char(20) '@modelmf',
		nrinmatrmf char(13) '@nrinmatrmf',
		durfunct char(20) '@durfunct',
		staremf char(13) '@staremf',
		datafabr datetime '@datafabr', 
		o_pretvaluta decimal(14, 6) '@o_pretvaluta', 
		o_difvalinv float '@o_difvalinv',
		o_pret float '@o_pret',
		o_sumatva float '@o_sumatva',
		ptupdate int '@update'
	)

	open crspozdocMF
	fetch next from crspozdocMF into @sub, @datal,@tip,@subtip,@numar,@data,@nrinv,@denmf,@seriemf, @tipam,@codcl,@categmf,@datapf, 
			@tert, @fact, @datafact, @datascad, @valuta, @curs, @pretvaluta, @pret, @cotatva, @sumatva, @tiptva, @ajust, 
			@gest, @lm, @com, @indbug, @indbugprim, --@lmprim,@comprim, @gestprim,
			@valinv, @difvalinv, @valam, @valamcls8, @valamneded, @valamist, @rezreev, @amlun, --@amluncls8, @amlunneded, 
			@tipmf, @subtipmf, @durata, @o_durata, @nrluni, @contmf,@contcor,@contamcomprim, @contcham, @contgestprim, @contlmprim, @conttva, @contpatrimiesire, @contpatrimintrare, --@difam, @difamcls8, 
			@cod, @procinch, @nrpozitie, @patrim, @denalternmf, @prodmf, @modelmf, @nrinmatrmf, @durfunct, @staremf, @datafabr, @o_difvalinv, @o_pret, @o_sumatva, @ptupdate
	set @fetchstatus=@@FETCH_STATUS
	while @fetchstatus = 0
	begin
		set @sumatvam=(case when @tip='ME' and @subtip='VI' and @tiptva=2 then 0 when @tiptva in (4,5) then @sumatva-round(@sumatva/2,2) else @sumatva end)
		if isnull(@valinv, 0)=0 or @tip='MI' and @subtip='AF'	--pentru intrari (Achizitii de la furnizori), sa recalculam tot timpul valoarea de inventar functie de pret.
			set @valinv=(case when isnull(@pret, 0)=0 or isnull(@pretvaluta,0)<>0 
				then round(isnull(@pretvaluta, 0)*(case when isnull(@valuta, '')='' then 1 else isnull(@curs, 0) end),2) else isnull(@pret, 0) end)
				+(case when @tip='MI' and @subtip='AF' and @tiptva=5 then @sumatvam else 0 end)
		if isnull(@difvalinv, 0)=0 
				and not (@tip='ME')	--	in MFplus la iesiri, diferenta de valoare (=Valoare recuperata) nu se initializeaza decat cu ea insusi la ECS-uri, altfel este 0. 
				and not (@tip='MM')	--	in MFplus la modificari, diferenta de valoare nu se initializeaza decat cu ea insusi.  Cred ca trebuie ca @difvalinv sa fie egal cu @pret, doar daca @pret are semnificatie de pret
			set @difvalinv=(case when isnull(@pret, 0)=0 or isnull(@pretvaluta,0)<>0 then round(isnull(@pretvaluta, 0)*(case when isnull(@valuta, '')='' then 1 else isnull(@curs, 0) end),2) else isnull(@pret, 0) end) 
		IF @tip='MM' and @subtip='FF'
			set @pret=0 -- daca nu este explicit diferenta de amortizare...
		if isnull(@categmf, 0)=0 or @tip='MI'	--	la intrari se determina din nou categoria (daca s-a modificat codul de clasificare)
			set @categmf=(case when @codcl='2.5.' then 21 when left(@codcl,1)='2' then convert(float,left(@codcl,3))*10 else convert(float,left(@codcl,1)) end)
		/*if @lm=''
			set @lm=isnull((select max(loc_de_munca) from gestcor where gest=@gest), '')
		
		if isnull(@numar, '')=''
		begin
			declare @NrDocFisc int, @fXML xml
			
			set @fXML = '<row/>'
			set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
			set @fXML.modify ('insert attribute tip {sql:variable("@tip")} into (/row)[1]')
			set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')
			set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
			set @fXML.modify ('insert attribute jurnal {sql:variable("@jurnal")} into (/row)[1]')
			
			exec wIauNrDocFiscale @fXML, @NrDocFisc output
			
			if ISNULL(@NrDocFisc, 0)<>0
				set @numar=LTrim(RTrim(CONVERT(char(8), @NrDocFisc)))
		end*/

		SELECT @tipm=@tip, @subtipm=@subtip
		/*IF @tip='MM' and /*@subtip='RE' and */@data<(SELECT mm.Data_miscarii 
			FROM misMF mm WHERE mm.subunitate=@sub and mm.Numar_de_inventar=@nrinv and 
			LEFT(mm.tip_miscare,1)='I') --daca se face impl. ca in MF, tb. si @data<=data impl.!!!
			SELECT @procinch=9, @sub='DENS'*/
		IF @tip='MM' and @subtip in ('MF','TO') and exists (select 1 from mismf where 
			subunitate=@sub and tip_miscare=right(@tip,1)+@subtip and --numar_document=@numar and 
			data_lunii_de_miscare=@datal and numar_de_inventar=@nrinv) 
			UPDATE mfix set cod_de_clasificare=(select 
			(case when 0=0 or @subtip='MF' then gestiune_primitoare else tert end) from mismf where 
			subunitate=@sub and tip_miscare=right(@tip,1)+@subtip and --numar_document=@numar and 
			data_lunii_de_miscare=@datal and numar_de_inventar=@nrinv)
			WHERE subunitate='DENS' and Numar_de_inventar=@nrinv 
		IF @tip='MM' and @subtip in ('MF','TO','TP') and exists (select 1 from mismf where 
			subunitate=@sub and tip_miscare=right(@tip,1)+@subtip and --numar_document=@numar and 
			data_lunii_de_miscare=@datal and numar_de_inventar=@nrinv) 
			UPDATE fisamf set cont_mijloc_fix=isnull((select f.cont_mijloc_fix from fisamf f where 
			f.subunitate = @sub and f.numar_de_inventar = @nrinv and f.felul_operatiei='1' and 
			f.data_lunii_operatiei = dbo.bom(@datal)-1),(select fi.cont_mijloc_fix from fisamf 
			fi where fi.subunitate = @sub and fi.numar_de_inventar = @nrinv 
			and fi.felul_operatiei in ('2','3')))
			WHERE subunitate=@sub and felul_operatiei<>'A' and data_lunii_operatiei=@datal 
			and Numar_de_inventar=@nrinv 
		DELETE from misMF where Subunitate=@sub and Data_lunii_de_miscare=@datal 
			and Tip_miscare=right(@tip,1)+@subtip and Numar_de_inventar=@nrinv 
			and Numar_document=@numar
		IF @tip<>'MI' EXEC MFcalclun @datal=@datal, @nrinv=@nrinv, @categmf=0, @lm=''
		IF @tip='MI' select @nrluni=(case when isnull(@nrluni,0)=0 or @ptupdate=1 and @durata<>@o_durata 
			then (case when abs(@valinv-@valam)<0.01 then 0 when isnull(@durata,0)=0 then dur_min else @durata end)*12 
			else @nrluni end), 
			@durata=(case when isnull(@durata,0)=0 then dur_min else @durata end)
			from codclasif where cod_de_clasificare=@codcl
		IF @tip='MM' SELECT @durata=(case when isnull(@durata,0)=0 then f.Durata else @durata end), 
			@nrluni=(case when @ptupdate=0 and isnull(@nrluni,0)=0 then f.Numar_de_luni_pana_la_am_int else isnull(@nrluni,f.Numar_de_luni_pana_la_am_int) end),
			-- calcul diferenta de amortizare la MRE (sugerarea din CGplus)
			@pret=(case when @subtip='RE' and @ptupdate=0 and @pret=0 and @contlmprim='RC' and Valoare_amortizata<>0 then -Valoare_amortizata else @pret end)	
			FROM fisamf f WHERE f.subunitate = @sub and f.numar_de_inventar = @nrinv 
			and f.felul_operatiei='1' and f.data_lunii_operatiei = @datal
		IF @contcor='' and @tip='MM' and @subtip in ('MF','TO','TP') 
			SELECT @contcor=isnull((select f.cont_mijloc_fix from fisamf f where 
			f.subunitate = @sub and f.numar_de_inventar = @nrinv and f.felul_operatiei='1' and 
			f.data_lunii_operatiei = dbo.bom(@datal)-1),(select fi.cont_mijloc_fix from fisamf 
			fi where fi.subunitate = @sub and fi.numar_de_inventar = @nrinv 
			and fi.felul_operatiei in ('2','3'))) 
		IF nullif(@contgestprim,'') is null and @tip='MM' and @subtip in ('MF','TO','TP') 
			SELECT @contgestprim=isnull((select f.cont_amortizare from fisamf f 
				where f.subunitate = @sub and f.numar_de_inventar = @nrinv and f.felul_operatiei='1' 
				and f.data_lunii_operatiei = dbo.bom(@datal)-1),
			isnull((select fi.cont_amortizare from fisamf fi where fi.subunitate = @sub and fi.numar_de_inventar = @nrinv 
				and fi.felul_operatiei in ('2','3')),isnull(md.cod_de_clasificare,'')))
			FROM mfix m 
				left outer join mfix md	on md.subunitate='DENS' and md.Numar_de_inventar=@nrinv 
			WHERE m.subunitate=@sub and m.Numar_de_inventar=@nrinv 
		IF @contamcomprim is null and @tip in ('MM','ME') and @subtip not in ('TO') 
			SELECT @contamcomprim=isnull((select f.cont_amortizare from fisamf f 
				where f.subunitate = @sub and f.numar_de_inventar = @nrinv and f.felul_operatiei='1' 
				and f.data_lunii_operatiei = @datal),
			isnull((select top 1 fi.cont_amortizare from fisamf fi where fi.subunitate = @sub and fi.numar_de_inventar = @nrinv 
				and fi.felul_operatiei in ('2','3')),''))
			FROM mfix m 
			WHERE m.subunitate=@sub and m.Numar_de_inventar=@nrinv 
/*
			SELECT @contamcomprim=md.cod_de_clasificare
			FROM mfix md WHERE md.subunitate='DENS' and md.Numar_de_inventar=@nrinv 
*/		SELECT @ctamm=md.cod_de_clasificare	--	aceasta variabila este nefolosita
			FROM mfix md WHERE md.subunitate='DENS' and md.Numar_de_inventar=@nrinv 
		IF @tip='MI' 
			SELECT @com=isnull(@com,''), @indbug=isnull(@indbug,'')
		IF @sub='DENS' --and isnull(@contmf,'')='' and @subtip not in ('MF','TO') 
			SELECT @gest=(case when @gest='' then f.gestiune else @gest end), 
			@lm=(case when @lm='' then f.loc_de_munca else @lm end), 
			@com=isnull(@com,left(f.comanda,20)), 
			@indbug=isnull(@indbug,substring(f.comanda,21,20)), 
			@tipmf=f.obiect_de_inventar, @contmf=isnull(@contmf,f.cont_mijloc_fix)
			FROM fisamf f WHERE /*f.subunitate = @sub and */f.numar_de_inventar = @nrinv 
			and f.felul_operatiei in ('2','3') --and f.data_lunii_operatiei = @datal
		IF @tip='MT' SELECT @contgestprim=isnull(@contgestprim,f.gestiune), 
			@contlmprim=isnull(@contlmprim,f.loc_de_munca), 
			@contamcomprim=isnull(@contamcomprim,left(f.comanda,20)), 
			@indbugprim=replace(isnull(@indbugprim,substring(f.comanda,21,20)),'.',''),
			@rezreev=f.Cantitate, @valinv=f.Valoare_de_inventar, @valam=f.Valoare_amortizata, 
			@valamcls8=f.Valoare_amortizata_cont_8045, @gest=f.gestiune, @lm=f.loc_de_munca, 
			@com=left(f.comanda,20), @indbug=substring(f.comanda,21,20)
			FROM fisamf f WHERE f.subunitate = @sub and f.numar_de_inventar = @nrinv 
			and f.felul_operatiei=(select top 1 ft.Felul_operatiei from fisamf ft where 
			ft.subunitate = @sub and ft.numar_de_inventar = @nrinv and ft.felul_operatiei in 
			('1','6') and ft.data_lunii_operatiei = @datal order by ft.Felul_operatiei desc) 
			and f.data_lunii_operatiei = @datal
		IF @tip<>'MI' --and isnull(@contmf,'')='' and @subtip not in ('MF','TO') 
			SELECT @gest=(case when @gest='' then f.gestiune else @gest end), 
			@lm=(case when isnull(@lm,'')='' then f.loc_de_munca else @lm end), 
			@com=isnull(@com,left(f.comanda,20)), 
			@indbug=isnull(@indbug,substring(f.comanda,21,20)), 
			@contmf=isnull(@contmf,f.cont_mijloc_fix)
			FROM fisamf f WHERE f.subunitate = @sub and f.numar_de_inventar = @nrinv 
			and f.felul_operatiei='1' and f.data_lunii_operatiei = @datal
		IF @tip<>'MT' SELECT @contgestprim=ISNULL(@contgestprim,''), 
			@contlmprim=ISNULL(@contlmprim,''), @contamcomprim=isnull(@contamcomprim,''), 
			@indbugprim=replace(isnull(@indbugprim, ''),'.','')
		IF @tip='MI' 
		BEGIN
			IF @subtip='SU' and @reevcontab=1 DELETE from fisamf where subunitate=@sub and 
				numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei='A'
			/*IF not exists (select 1 from fisamf where subunitate=@sub and 
				numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei='A')*/
			IF @subtip='SU' and @reevcontab=1 
				INSERT into fisamf (Subunitate,Numar_de_inventar,Categoria,Data_lunii_operatiei,
				Felul_operatiei,Loc_de_munca,Gestiune,Comanda,Valoare_de_inventar,
				Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,
				Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,
				Obiect_de_inventar,Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate,Cont_amortizare,Cont_cheltuieli)
				select @sub, @nrinv, @categmf, @datal, 'A', @lm, @gest, @com+replace(@indbug,'.',''), 
				0/*@valinv*/, @valamist, @valamist, 0, 0, 0, 0, @durata, @tipmf, @conttva, @nrluni, 0, @contamcomprim, @contcham
			/*	Lucian: pentru intrari am tratat sa se faca scrierea cu felul operatiei=1 doar la calcule lunare. 
				Aici (mai jos) se va scrie doar cu felul operatiei=3.
			DELETE from fisamf where subunitate=@sub and 
				numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei='1'
			/*IF not exists (select 1 from fisamf where subunitate=@sub and 
				numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei='1')*/
			INSERT into fisamf (Subunitate,Numar_de_inventar,Categoria,Data_lunii_operatiei,
				Felul_operatiei,Loc_de_munca,Gestiune,Comanda,Valoare_de_inventar,
				Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,
				Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,
				Obiect_de_inventar,Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate,Cont_amortizare,Cont_cheltuieli)
				select @sub, @nrinv, @categmf, @datal, '1', @lm, @gest, @com+replace(@indbug,'.',''), 
				@valinv, @valam, @valamcls8, @valamneded, @amlun, 0, 0, @durata,
				@tipmf, @contmf, @nrluni, @rezreev, @contamcomprim, @contcham
			*/
			DELETE from fisamf where subunitate=@sub and 
				numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei='3'
			INSERT into fisamf (Subunitate,Numar_de_inventar,Categoria,Data_lunii_operatiei,
				Felul_operatiei,Loc_de_munca,Gestiune,Comanda,Valoare_de_inventar,
				Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,
				Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,
				Obiect_de_inventar,Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate,Cont_amortizare,Cont_cheltuieli)
				select @sub,@nrinv,@categmf,@datal,'3',@lm,@gest,@com+replace(@indbug,'.',''),
				@valinv,@valam,@valamcls8,@valamneded,@amlun,0,0,@durata,
				@tipmf,@contmf, @nrluni,@rezreev,@contamcomprim,@contcham
				/*EXEC scriuFisaMF @sub=@sub,@nrinv=@nrinv,@categmf=@categmf, @datal=@datal, 
				@felop='1', @lm=@lm,@gest=@gest,@com=@com,@indbug=@indbug, @valinv=@valinv,
				@valam=@valam, @valamcls8=@valamcls8, @valamneded=@valamneded,
				@amlun=@amlun, @amluncls8=0, @amlunneded=0, @durata=@durata,
				@tipmf=@tipmf, @contmf=@contmf, @nrluni=@nrluni, @rezreev=@rezreev*/
			/*EXEC scriuMfix @sub,@nrinv,@denmf,@seriemf,@tipam,@codcl,@datapf,@contamcomprim,
				@denalternmf, @prodmf, @modelmf, @nrinmatrmf, @durfunct, @staremf, @datafabr*/
			DELETE from MFix where Numar_de_inventar=@nrinv
			--mfix Subunitate
			set @detaliiMfix=(select @contcham as contcham for xml raw)
			INSERT into mfix (Subunitate,Numar_de_inventar,Denumire,Serie,
				Tip_amortizare,Cod_de_clasificare,Data_punerii_in_functiune,detalii)
				values 
				(@sub,@nrinv,@denmf,@seriemf,@tipam,@codcl,@datapf,@detaliiMfix)
			--mfix DENS
			INSERT into mfix (Subunitate,Numar_de_inventar,Denumire,Serie,
				Tip_amortizare,Cod_de_clasificare,Data_punerii_in_functiune)
				values 
				('DENS',@nrinv,@denalternmf,(case when @evidmfiesite=1 and @tip='MI' and @subtip='AL' 
				and left(@contmf,1)='8' then 'C' when left(@contmf,1)='3' then 'O' else '' end),
				isnull(@patrim,(case when 90=0 and left(@contamcomprim,1)='8' then '1' else '' end)),
				@contamcomprim,(case when @subtip='DO' and left(@contcor,1)<>'7' then '01/01/1902' 
				else '01/01/1901' end))
			--mfix DENS2
			/*INSERT into mfix (Subunitate,Numar_de_inventar,Denumire,Serie,
				Tip_amortizare,Cod_de_clasificare,Data_punerii_in_functiune)
				values 
				('DENS2',@nrinv,@prodmf,@modelmf,'',@nrinmatrmf,'01/01/1901')
			--mfix DENS3
			INSERT into mfix (Subunitate,Numar_de_inventar,Denumire,Serie,
				Tip_amortizare,Cod_de_clasificare,Data_punerii_in_functiune)
				values 
				('DENS3',@nrinv,'',@durfunct,'',@staremf,@datafabr)*/
		END
		
		SET @felop=(case @tip when 'MI' then '3' when 'MM' then '4' when 'ME' then '5' 
			when 'MT' then '6' when 'MC' then '7' when 'MS' then '8' else '9' end)
		IF @tip<>'MM' and @tip<>'MI' --or @tip='MM' and @subtip='RE' --in ('MI','ME')
		BEGIN
			DELETE from fisamf where subunitate=@sub and 
				numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei=@felop
			/*IF not exists (select 1 from fisamf where subunitate=@sub and 
				numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei=@felop)*/
			INSERT into fisamf (Subunitate,Numar_de_inventar,Categoria,Data_lunii_operatiei,
				Felul_operatiei,Loc_de_munca,Gestiune,Comanda,Valoare_de_inventar,
				Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,
				Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,
				Obiect_de_inventar,Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate,Cont_amortizare,Cont_cheltuieli)
				select Subunitate,Numar_de_inventar,Categoria,Data_lunii_operatiei,
				@felop,(case when 90=0 and @tip='MT' then @contlmprim else @lm end),
				(case when 90=0 and @tip='MT' then @contgestprim else @gest end),
				(case when 90=0 and @tip='MT' then @contamcomprim+replace(@indbugprim,'.','') else 
				@com+replace(@indbug,'.','') end)/*Loc_de_munca,Gestiune,Comanda*/,
				(case when @felop<>'5' or Valoare_de_inventar<>0 then valoare_de_inventar else isnull((select valoare_de_inventar from fisamf 
					where subunitate=@sub and numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei='3'),valoare_de_inventar) end),
				Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,
				Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,
				Obiect_de_inventar, Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate,Cont_amortizare,Cont_cheltuieli
				from fisamf where subunitate=@sub and 
				numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei='1'
				/*EXEC scriuFisaMF @sub=@sub,@nrinv=@nrinv,@categmf=@categmf, @datal=@datal, 
				@felop=@felop, @lm=@lm,@gest=@gest,@com=@com,@indbug=@indbug, @valinv=@valinv,
				@valam=@valam, @valamcls8=@valamcls8, @valamneded=@valamneded,
				@amlun=@amlun, @amluncls8=0, @amlunneded=0, @durata=@durata,
				@tipmf=@tipmf, @contmf=@contmf, @nrluni=@nrluni, @rezreev=@rezreev*/
		END
		--SET @comindbug=@contamcomprim+@indbugprim
		IF @tip='MT' UPDATE fisaMF set gestiune=@contgestprim, Loc_de_munca=@contlmprim, 
			Comanda=@contamcomprim+@indbugprim WHERE subunitate=@sub and 
			numar_de_inventar=@nrinv and data_lunii_operatiei>=@datal and 
			data_lunii_operatiei<isnull((select top 1 data_lunii_de_miscare from mismf where 
			subunitate=@sub and numar_de_inventar=@nrinv and data_lunii_de_miscare>=@datal and 
			tip_miscare='TSE' and data_miscarii>=@data+1 order by data_lunii_de_miscare),
			'01/01/2999') and felul_operatiei in ('1','A') /*<>'3'*/

		IF @tip='ME' 
		begin
			DELETE from fisamf where subunitate=@sub and numar_de_inventar=@nrinv 
				and data_lunii_operatiei>@datal --and felul_operatiei in ('1','A')
			UPDATE fisaMF set cantitate=0, Valoare_de_inventar=0,
				Valoare_amortizata=0,Valoare_amortizata_cont_8045=0,Valoare_amortizata_cont_6871=0 
				where subunitate=@sub and 
				numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei='1'
		end

		SET @tipdocCG=(case @tip when 'MI' then (case @subtip when 'AF' then 'RM' else 'AI' end) 
			when 'MM' then (case @subtip when 'EP' then 'AE' when 'FF' then 'RM' else 'AI' end) 
			when 'ME' then (case @subtip when 'SU' then 'AE' when 'VI' then 'AP' else 'AE' end) 
			when 'MT' then (case when @procinch=6 and @subtip='SE' then 'AI' else '' end) 
			else '' end)
		
		IF @tip in ('MI','MM','ME','MT') DELETE pozdoc where subunitate=@sub and tip=@tipdocCG 
			and numar=@Numar and data=@Data and Cod_intrare=@nrinv and Jurnal=@jurnal --and Numar_pozitie=@nrpozitie
		
		set @tiptvam=(case when @tiptva in (4,5) then 0 else @tiptva end)
		if @tip='MT' and (@contcor='' or abs(@valinv-@valam)<0.01 and @contcor not like '482%' and @contcor not like '481%')
			set @farapozdoc=1
		if @tip='MM' and @subtip='TP' 
			set @detaliiPozdoc=(select @contpatrimiesire as contpatrimiesire, @contpatrimintrare as contpatrimintrare for xml raw)
		if @tip='MM' and @subtip='MF' 
			set @detaliiPozdoc=(select @contcham as contcham for xml raw)
		IF @tip in ('MI','MM','ME','MT') and @procinch=6 and @farapozdoc=0
			exec MFscriupozdoc @tip=@tip,@subtip=@subtip,
				@numar=@numar,@data=@data,@nrinv=@nrinv,@contcor=@contcor,@contgestprim=@contgestprim,
				@contlmprim=@contlmprim,@contamcomprim=@contamcomprim,
				@indbugprim=@indbugprim,@gest=@gest,@lm=@lm,@com=@com,
				@indbug=@indbug,@contmf=@contmf,@conttva=@conttva,@tipmf=@tipmf,
				@tert=@tert,@fact=@fact,@datafact=@datafact,@datascad=@datascad,@valinv=@valinv,
				@valam=@valam,@valamcls8=@valamcls8,@valamneded=@valamneded,@rezreev=@rezreev,
				@cotatva=@cotatva,@sumatva=@sumatvam,@tiptva=@tiptvam,@difvalinv=@difvalinv,@pret=@pret,
				@ajust=@ajust,@pretvaluta=@pretvaluta,@valuta=@valuta,@curs=@curs,@cod=@cod,@detaliiPozdoc=@detaliiPozdoc
		
		IF @tip in ('MI') and @subtip in ('AF') and @procinch=6 and @tiptva in (4,5) and @farapozdoc=0
		begin
			set @sumatvam=round(@sumatva/2,2)
			exec MFscriupozdocTVANCN @tip=@tip, @subtip=@subtip, 
				@numar=@numar, @data=@data, @nrinv=@nrinv, @contcor=@contcor, @contgestprim='', 
				@contlmprim='', @contamcomprim='', @indbugprim='', @gest=@gest, @lm=@lm, @com=@com, 
				@indbug=@indbug, @contmf=@contmf, @conttva=@conttva, @tipmf=0,@tert=@tert,@fact=@fact,
				@datafact=@datafact,@datascad=@datascad,@valinv=0,@valam=0,@valamcls8=0,
				@valamneded=0,	@rezreev=0, @cotatva=@cotatva, @sumatva=@sumatvam, @tiptva=@tiptva, 
				@difvalinv=0, @pret=0, @ajust=0, @pretvaluta=0, @valuta=@valuta, @curs=@curs--, @cod=@cod
		end

		IF @tip in ('MI','MM','ME','MT') and @procinch=6 and @farapozdoc=0
		begin
			--if @tipDocCG in ('RM','AP')
			--	exec contTVADocument @Subunitate=@sub, @Tip=@tipDocCG, @Numar=@numar, @Data=@data
			exec faInregistrariContabile @dinTabela=0,@Subunitate=@sub, @Tip=@tipDocCG, @Numar=@numar, @Data=@data
		end
				
		/*SET @tipdocMF=right(@tip,1)+@subtip
		EXEC scriuMisMF @sub=@sub, @datal=@datal, @nrinv=@nrinv, 
			@tipmisc=@tipdocMF,@numar=@numar, @data=@data, @tert=@tert, 
			@fact=@fact, @pret=@pret, @sumatva=@sumatva,
			@contcor=@contcor, @lmprim=@contlmprim, @gestprim=@contgestprim, @difvalinv=@difvalinv,
			@datasfconserv=@datascad, @comprim=@contamcomprim, @indbug=@indbug, @procinch=6*/
		IF @tip not in ('MI','ME','MM') or @sub='DENS' or isnull(@contmf,'')<>''
			INSERT into mismf (Subunitate,Data_lunii_de_miscare,
			Numar_de_inventar,Tip_miscare,Numar_document,Data_miscarii,Tert,Factura,
			Pret,TVA,Cont_corespondent,Loc_de_munca_primitor,Gestiune_primitoare,
			Diferenta_de_valoare,Data_sfarsit_conservare,Subunitate_primitoare,
			Procent_inchiriere)
			select @sub, @datal, @nrinv, right(@tip,1)+@subtip, @numar, @data, 
			(case when 50=0 and @tip='MM' and @subtip='TO' then isnull((select md.cod_de_clasificare from mfix md where md.subunitate='DENS' and md.Numar_de_inventar=@nrinv),'') else @tert end),
			(case	when @tip='MM' and @subtip='RE' then rtrim(convert(char(20),1.00*@ajust))/*+(case when CHARINDEX('.',convert(char(20),@ajust))=0 then '.00' else '' end)*/ 
					when @tip='MM' and @subtip='MF' then @contcham else @fact end), 
			@pret, @sumatva, 
			(case when right(@tip,1)+@subtip in ('MMF','MTO','MTP') then isnull((select cont_mijloc_fix from fisamf where subunitate=@sub and felul_operatiei='1' and data_lunii_operatiei=@datal and Numar_de_inventar=@nrinv),'') else @contcor end), 
			@contlmprim, @contgestprim, @difvalinv, @datascad, 
			(case when @tip in ('ME','MM') and @subtip not in ('MF','TO','TP') 
				then isnull((select f.cont_amortizare from fisamf f 
				where f.subunitate = @sub and f.numar_de_inventar = @nrinv and f.felul_operatiei='1' 
				and f.data_lunii_operatiei = @datal),'')
				else @contamcomprim+replace(@indbugprim,'.','') end), 
			(case when @tip='MC' then 100 else @procinch end)
		IF @tip='MM' and @subtip='TO' 
			UPDATE mfix set serie='O'	WHERE subunitate='DENS' and Numar_de_inventar=@nrinv 
		IF @tip='MM' and @subtip='TP' 
			UPDATE mfix set Tip_amortizare=@patrim WHERE subunitate='DENS' and Numar_de_inventar=@nrinv 
		IF @tip='MM' and @subtip in ('MF','TO','TP') and not (@subtip='MF' and @procinch=3) and (0=0 or @subtip<>'MF' or left(@contgestprim,1)<>'8') 
			UPDATE mfix set cod_de_clasificare=(case when @subtip='MF' then @contamcomprim else '' end) WHERE subunitate='DENS' and Numar_de_inventar=@nrinv 
		IF @tip='MM' and @sub='DENS'
		begin
			DELETE from fisamf where subunitate=@sub and 
				numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei=@felop
		/*IF not exists (select 1 from fisamf where subunitate=@sub and 
			numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei=@felop)*/
			INSERT into fisamf (Subunitate,Numar_de_inventar,Categoria,Data_lunii_operatiei,
				Felul_operatiei,Loc_de_munca,Gestiune,Comanda,Valoare_de_inventar,
				Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,
				Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,
				Obiect_de_inventar,Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate,Cont_amortizare,Cont_cheltuieli)
			select @sub, @nrinv, isnull(@categmf,0), @datal, @felop, @lm, @gest, 
				isnull(@com+replace(@indbug,'.',''),''), 0, @valam, @valamcls8, @valamneded, 
				@amlun, 0, 0, isnull(@durata,0), @tipmf, isnull(@contmf,''), isnull(@nrluni,0), 0, @contamcomprim, @contcham
		end
		IF (@modimpl=0 or @data>@dataimpl) and (@tip='MM' and @sub<>'DENS' or @tip='MT' or @tip='MC') 
			EXEC MFcalclun @datal=@datal, @nrinv=@nrinv, @categmf=0, @lm=''
		IF @tip='MM' and @sub<>'DENS'
		begin
			if @datal=ISNULL((select data_lunii_operatiei from fisamf where subunitate=@sub 
					and numar_de_inventar=@nrinv and felul_operatiei='3'),'01/01/1901')
			UPDATE fisamf set Valoare_de_inventar=Valoare_de_inventar+@difvalinv-@o_difvalinv, 
			Valoare_amortizata=Valoare_amortizata+@pret-@o_pret, 
			Valoare_amortizata_cont_8045=Valoare_amortizata_cont_8045+(case when @subtip='FF' 
				then 0 else @sumatva-@o_sumatva end)
				where subunitate=@sub and numar_de_inventar=@nrinv and data_lunii_operatiei=@datal 
				and felul_operatiei='1'
			UPDATE fisamf set Numar_de_luni_pana_la_am_int=@nrluni, durata=@durata 
				where subunitate=@sub and numar_de_inventar=@nrinv and data_lunii_operatiei=@datal 
				and felul_operatiei in ('1','A')
			IF @tip='MM' and @subtip='MF' UPDATE fisamf set Obiect_de_inventar=@tipmf
				where subunitate=@sub and numar_de_inventar=@nrinv 
				and data_lunii_operatiei=@datal and felul_operatiei in ('1','A')
			IF @tip='MM' and @subtip in ('MF','TO','TP') UPDATE fisamf set cont_mijloc_fix=@contmf
				WHERE subunitate=@sub and Numar_de_inventar=@nrinv 
				and data_lunii_operatiei=@datal and felul_operatiei='1' --tb. sa fie <>'A'!!!!!!!!!!
			DELETE from fisamf where subunitate=@sub and 
				numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei=@felop
			/*IF not exists (select 1 from fisamf where subunitate=@sub and 
				numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei=@felop)*/
			INSERT into fisamf (Subunitate,Numar_de_inventar,Categoria,Data_lunii_operatiei,
				Felul_operatiei,Loc_de_munca,Gestiune,Comanda,Valoare_de_inventar,
				Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,
				Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,Durata,
				Obiect_de_inventar, Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate,Cont_amortizare,Cont_cheltuieli)
				select Subunitate,Numar_de_inventar,Categoria,Data_lunii_operatiei,
				@felop,@lm,@gest,@com+replace(@indbug,'.',''),Valoare_de_inventar,
				Valoare_amortizata,Valoare_amortizata_cont_8045,Valoare_amortizata_cont_6871,
				Amortizare_lunara,Amortizare_lunara_cont_8045,Amortizare_lunara_cont_6871,durata,
				Obiect_de_inventar,Cont_mijloc_fix,Numar_de_luni_pana_la_am_int,Cantitate,Cont_amortizare,isnull(nullif(@contcham,''),Cont_cheltuieli)
				from fisamf where subunitate=@sub and 
				numar_de_inventar=@nrinv and data_lunii_operatiei=@datal and felul_operatiei='1'
				/*EXEC scriuFisaMF @sub=@sub,@nrinv=@nrinv,@categmf=@categmf, @datal=@datal, 
				@felop=@felop, @lm=@lm,@gest=@gest,@com=@com,@indbug=@indbug, @valinv=@valinv,
				@valam=@valam, @valamcls8=@valamcls8, @valamneded=@valamneded,
				@amlun=@amlun, @amluncls8=0, @amlunneded=0, @durata=@durata,
				@tipmf=@tipmf, @contmf=@contmf, @nrluni=@nrluni, @rezreev=@rezreev*/
		end

		IF @tip='MI' 
			exec MFcalclun @datal=@datal,@nrinv=@nrinv,@categmf=0,@lm=''
		/*if @numarGrp is null */ select @tipGrp=@tip, @numarGrp=@numar, @dataGrp=@datal

		fetch next from crspozdocMF into @sub, @datal,@tip,@subtip,@numar,@data,@nrinv,@denmf,@seriemf, @tipam,@codcl,@categmf,@datapf, 
				@tert, @fact, @datafact, @datascad, @valuta, @curs, @pretvaluta, @pret, @cotatva, @sumatva, @tiptva, @ajust, 
				@gest, @lm, @com, @indbug, @indbugprim, --@lmprim,@comprim, @gestprim,
				@valinv, @difvalinv, @valam, @valamcls8, @valamneded, @valamist, @rezreev, @amlun, --@amluncls8, @amlunneded, 
				@tipmf, @subtipmf, @durata, @o_durata, @nrluni, @contmf,@contcor,@contamcomprim, @contcham, @contgestprim, @contlmprim, @conttva, @contpatrimiesire, @contpatrimintrare, --@difam, @difamcls8, 
				@cod, @procinch, @nrpozitie, @patrim, @denalternmf, @prodmf, @modelmf, @nrinmatrmf, @durfunct, @staremf, @datafabr, @o_difvalinv, @o_pret, @o_sumatva, @ptupdate
		set @fetchstatus=@@FETCH_STATUS
	end
	--select @sub,@tipgrp,@numargrp,@dataGrp, @docXMLIaPozdocMF
	set @docXMLIaPozdocMF = '<row subunitate="' + rtrim(@sub) + '" tip="' + rtrim(@tipGrp) + '" numar="' + rtrim(@numarGrp) + '" datal="' + convert(char(10), @dataGrp, 101) +'"/>'
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozdocMFSP2')    
		exec wScriuPozdocMFSP2 '', @sub, @tipGrp, @numarGrp, @dataGrp  
	exec wIaPozdocMF @sesiune=@sesiune, @parXML=@docXMLIaPozdocMF 
	--if @MFria=0 set @cman1=replace(convert(char(10),dbo.bom(@datal),102),'.','/')
	--if @MFria=0 EXEC setare_par 'MF','RIA','RIA',1,0,@cman1
	
	set CONTEXT_INFO 0x00
	
	--COMMIT TRAN
end try
begin catch
	--ROLLBACK TRAN
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch

declare @cursorStatus int
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crspozdocMF' 
	and session_id=@@SPID )
if @cursorStatus=1 
	close crspozdocMF 
if @cursorStatus is not null 
	deallocate crspozdocMF 

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
