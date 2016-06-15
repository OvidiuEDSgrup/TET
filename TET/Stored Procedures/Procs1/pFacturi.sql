--***
create procedure pFacturi @sesiune varchar(50), @parXML xml
as
begin try

	declare @Subunitate char(9), @FurnBenef char(1), @dDataJos datetime, @dDataSus datetime, @Tert char(13),
		@gtert varchar(100),
		@Factura char(20), @ContFactura varchar(40), @SoldMin float, @SemnSold int, 
		@StrictPerioada int, @locm varchar(20), @cen int, @GrTert int, @GrFact int, @GrCont int,
		@dDImpl datetime, @nAnImpl int, @nLunaImpl int, @nAnInitFact int, @IstFactImpl int, @dDataIncDoc datetime, @nAnImplMF int,@nLunaImplMF int, @dDataIncDocMF datetime, 
		@Bugetari int, @Ignor4428Avans int, @Ignor4428DocFF int, @ConturiDocFF varchar(200), @DVI int, @AccImpDVI int, @CtFactVamaDVI int, @GenisaUnicarm int, @PrimariaTM int,
		@DocSchimburi int, @LME int, @IFN int, --@FactBil int, 
		@userASiS varchar(30), @filtrareUser bit, @prelContTVA int, 
		@efecteAchitate bit	--> sa fie aduse facturile achitate prin efecte: 0, null = nu se tine cont, 1 = se aduc cele cu efecte neachitate ca fiind pe sold
		, @lDPreImpl int, @dDPreImpl datetime  -- o setare care spune ca am date initiale anterioare factimpl, tinute in istfact 
		,@indicator varchar(1000)
		,@furn_benef_bin binary(1)	-->	valoarea binara a @furnBenef pt join cu facturi
		,@grupare varchar(4000)	--> grupare custom, experiment; nu se utilizeaza inca
		,@inclFacturiNe bit 

	select	@FurnBenef=isnull(@parXML.value('(row/@furnbenef)[1]','varchar(1)'),'')
			, @dDataJos=@parXML.value('(row/@datajos)[1]','datetime')
			, @dDataSus=@parXML.value('(row/@datasus)[1]','datetime')
			, @Tert=@parXML.value('(row/@tert)[1]','varchar(20)') 
			, @Factura=@parXML.value('(row/@factura)[1]','varchar(20)')
			, @ContFactura=@parXML.value('(row/@contfactura)[1]','varchar(40)')
			, @SoldMin=@parXML.value('(row/@soldmin)[1]','float')
			, @SemnSold=@parXML.value('(row/@semnsold)[1]','int')
			, @StrictPerioada=isnull(@parXML.value('(row/@strictperioada)[1]','int'),0)
			, @locm=@parXML.value('(row/@locm)[1]','varchar(20)')
			--@sesiune=@parXML.value('(row/@sesiune)[1]','varchar(50)')
			, @efecteAchitate=isnull(@parXML.value('(row/@efecteachitate)[1]','bit'),0)
			, @cen=isnull(@parXML.value('(row/@cen)[1]','int'),0)
			, @GrTert=@parXML.value('(row/@grtert)[1]','int')
			, @GrFact=@parXML.value('(row/@grfactura)[1]','int')
			, @GrCont=ISNULL(@parXML.value('(row/@grcont)[1]','int'),0)
			, @prelContTVA=isnull(@parXML.value('(row/@prelconttva)[1]','int'),0)
			, @indicator=@parXML.value('(row/@indicator)[1]','varchar(1000)')
			, @grupare=isnull(@parXML.value('(row/@grupare)[1]','varchar(4000)'),'')
			, @inclFacturiNe=isnull(@parXML.value('(row/@inclfacturine)[1]','bit'),1)
			, @gtert=@parXML.value('(row/@gtert)[1]','varchar(100)')
	select @userASiS=dbo.fIaUtilizator(@sesiune)
	select @filtrareUser=dbo.f_areLMFiltru(@userASiS)
	select @furn_benef_bin=(case when @furnbenef='F' then 0x54 else 0x46 end)
	
	declare @LFact int
	set @LFact=isnull((select c.length from sysobjects o, syscolumns c where o.name='facturi' and o.id=c.id and c.name='factura'), 0)

	declare @q_cuFltLocmStilVechi int, @locmV varchar(20)	--> se alege tipul filtrarii pe loc de munca in functie de setare
	select @q_cuFltLocmStilVechi=0, @locmV=@locm+'%'
	if isnull(@locm,'')<>'' and exists(select 1 from par where Tip_parametru='GE' and Parametru='FLTTRTLM' and Val_logica=1) -- o factura are un singur loc de munca si anume cel din tabela [facturi]
	begin
		set @locm='%' -- se va filtra pe locul de munca din facturi
		select @q_cuFltLocmStilVechi=1
		set @filtrareUser=0
	end
	else 
		set @locm=ISNULL(@locm,'')+'%'

	if @dDataJos is null set @dDataJos='01/01/1901'
	if @dDataJos is null OR YEAR(@dDataJos)<1921 set @dDataJos='01/01/1901'
	if @dDataSus is null set @dDataSus='01/01/2999'

	select @Subunitate=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'),''),
		@nAnImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULIMPL'),1901),
		@nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAIMPL'),0),
		@dDImpl=dateadd(day,-1,dateadd(month,@nLunaImpl,dateadd(year,@nAnImpl-1901,'01/01/1901'))),
		@nAnInitFact=(select max(val_numerica) from par where tip_parametru='GE' and parametru='ULT_AN_IN'), 
		@lDPreImpl=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='PREIMPL'),0), 
		@dDPreImpl=isnull((select max(convert(datetime,val_alfanumerica)) from par where tip_parametru='GE' and parametru='PREIMPL'),'1901-01-01')

	if isnull(@nAnInitFact,0)<1901
		set @nAnInitFact=@nAnImpl
	-- cazuri de apelare procedura pFacturi:
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
	-- de aici ma ocup de fisa ante-implementare
	if @lDPreImpl=1 -- am date initiale anterioare factimpl, tinute in istfact = fisa terti pe perioade anteimplementare 
		and (@dDataSus<=@dDImpl or @dDataJos>'01/01/1921' and @dDataJos<@dDImpl)
	begin
		set @IstFactImpl=1 -- istfact
		set @dDataIncDoc=@dDPreImpl
	end
	-- pana aici fisa ante-implementare
	-- daca se doreste returnarea documentelor dintr-o perioada, fara analiza soldului: nu mai conteaza data inc. doc.
	if @StrictPerioada=1 and @dDataIncDoc<=@dDataJos
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

	select @Bugetari=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='BUGETARI'),0),
		@Ignor4428Avans=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='NEEXAV'),0),
		@Ignor4428Avans=(case when isnull(@Ignor4428Avans, 0)=0 then 1 else 0 end),
		@Ignor4428DocFF=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='NEEXDOCFF'),0),
		@Ignor4428DocFF=(case when isnull(@Ignor4428DocFF, 0)=0 then 1 else 0 end),
		@ConturiDocFF=isnull(nullif((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='NEEXDOCFF'),''),'408,418'),
		@DVI=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='DVI'),0),
		@AccImpDVI=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='ACCIMP'),0),
		@CtFactVamaDVI=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='CONTFV'),0),
		@GenisaUnicarm=(case when exists (select 1 from par where tip_parametru='SP' and parametru in ('GENISA','UNICARM') and val_logica=1) then 1 else 0 end),
		@PrimariaTM=(case when exists (select 1 from par where tip_parametru='SP' and parametru='PRIMTIM' and val_logica=1) then 1 else 0 end),
		@DocSchimburi=isnull((select max(case when val_logica=1 and val_numerica=0 then 1 else 0 end) from par where tip_parametru='GE' and parametru='DOCPESCH'),0),
		--@FactBil=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='FACTBIL'),0),
		@LME=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='COMPPRET'),0),
		@IFN=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='IFN'),0)

	select @FurnBenef=isnull(@FurnBenef,''),
		@Tert=isnull(@Tert,'%'),
		@gtert=isnull(rtrim(@gtert),'%'),
		@Factura=isnull(@Factura,'%'),
		@ContFactura=isnull(@ContFactura,''),
		@SoldMin=isnull(@SoldMin,0),
		@SemnSold=isnull(@SemnSold,0)

	if object_id('tempdb..#docfac') is not null
		drop table #docfac
	create table #docfac (furn_benef char(1))
	exec CreazaDiezFacturi @numeTabela='#docfac'

	/*	preluare date din vechile functii fFacturiF si fFacturiB */
	/*	Preluare facturi furnizori */
	if (@FurnBenef='' or @FurnBenef='F')
	begin
		insert #docfac (subunitate,tert,factura,tip,numar,data,valoare,tva,achitat,valuta,curs,total_valuta,achitat_valuta,loc_de_munca,comanda,
			cont_de_tert,fel,cont_coresp,explicatii,numar_pozitie,gestiune,data_facturii,data_scadentei,nr_dvi,barcod,contTVA,cod,cantitate,contract,efect,idPozitieDoc,tabela,determinant)
		select i.subunitate, i.tert, i.factura, 'SI' tip, i.factura numar, i.data, i.valoare, i.tva_11+i.tva_22 tva, i.achitat, i.valuta, i.curs,
				i.valoare_valuta as total_valuta, i.achitat_valuta, i.loc_de_munca, i.comanda, 
				i.cont_de_tert, '1' fel, '' cont_coresp, 'Sold initial' explicatii, 0 numar_pozitie, '' gestiune, i.data data_facturii,
				i.data_scadentei, '' nr_dvi, '' barcod, '' as contTVA, '' as cod, 0 as cantitate, '' as contract, '' efect, 0 as idPozitieDoc, 'istfact' as tabela, 0
		from istfact i 
			left outer join terti t on i.subunitate=t.subunitate and i.tert=t.tert
			left join lmfiltrare pr on pr.cod=i.loc_de_munca and pr.utilizator=@userASiS
			left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=i.subunitate and f.tip=@furn_benef_bin and f.factura=i.factura and f.tert=i.tert
		where @IstFactImpl=1 and i.subunitate=@Subunitate and i.tip='F' and i.data_an=@dDataIncDoc and i.tert like rtrim(@Tert) and t.grupa like @gtert and i.factura like rtrim(@Factura) and i.cont_de_tert like rtrim(@ContFactura)+'%'
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
	/*	Am scos pentru bugetari filtrarea pe loc de munca in momentul selectarii datelor, pentru a functiona spargerea platilor/incasarilor anterioare anului 2014 pe indicatori bugetari 
		si daca se filtreaza pe loc de munca. S-a mutat filtrarea pe loc de munca, pentru acest caz dupa spargerea pe indicatori.	*/
			and (@bugetari=1 or @locm='%' or convert(char(9),i.Loc_de_munca) like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		union all
		select fi.subunitate,fi.tert,fi.factura,'SI',fi.factura,@dDImpl,fi.valoare,fi.tva_11+fi.tva_22,fi.achitat,fi.valuta,fi.curs,fi.valoare_valuta,
				fi.achitat_valuta,fi.loc_de_munca,fi.comanda,fi.cont_de_tert,'1','','Sold initial',0,'',fi.data,fi.data_scadentei,'','','' as contTVA,
				'' as cod,0 as cantitate, '' as contract, '' efect, 0 as idPozitieDoc, 'factimpl' as tabela, 0
		from factimpl fi 
			left outer join terti t on fi.subunitate=t.subunitate and fi.tert=t.tert
			left join lmfiltrare pr on pr.cod=fi.loc_de_munca and pr.utilizator=@userASiS
			left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=fi.subunitate and f.tip=@furn_benef_bin and f.factura=fi.factura and f.tert=fi.tert
		where @IstFactImpl=2 and fi.subunitate=@Subunitate and fi.tip=0x54 and fi.tert like rtrim(@Tert) and t.grupa like @gtert and fi.factura like rtrim(@Factura) and fi.cont_de_tert like rtrim(@ContFactura)+'%'
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or convert(char(9),fi.Loc_de_munca)  like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		union all
		select p.subunitate,p.tert,p.factura,p.tip,p.numar,p.data,
			(case when p.valuta='' then round(convert(decimal(18,5),cantitate*round(pret_valuta*(1+
				(case when abs(p.discount+p.cota_TVA*100.00/(p.cota_TVA+100.00))<0.01 then convert(decimal(12,4),-p.cota_TVA*100.00/(p.cota_TVA+100.00)) 
				else convert(decimal(12,4),p.discount) end)/100),5)),2) when p.tip='RP' then cantitate*pret_valuta else 
				round(convert(decimal(18,5),cantitate*round(convert(decimal(18,5),pret_valuta*p.curs*(case when numar_dvi='' or p.tip='RS' then 
				(1+convert(decimal(18,5),discount/100)) else 1 end)),5)),2) end),
			(case when not ((numar_DVI<>'' and p.tip='RM') or 
				((numar_DVI='' and p.tip='RM' or p.tip in ('RP','RS')) and procent_vama = 1)) then tva_deductibil else 0 end),
			0,p.valuta,p.curs,
			--valoare valuta:
			(case when p.valuta<>'' and isnull(t.tert_extern,0)=1 then round(convert(decimal(18,5),cantitate*(case when p.tip='RP' then pret_de_stoc else pret_valuta end)
				*(1+(case when p.tip='RS' or p.numar_DVI='' then discount else 0 end)/100)
			-- TVA valuta: 
			+(case when /*cota_tva in (9,11,19,22) and*/ not ((numar_DVI<>'' and p.tip='RM') or ((numar_DVI='' and p.tip='RM' or p.tip in ('RP','RS')) and procent_vama = 1)) and p.curs > 0 
				then (case /*when 1=0 and p.tip='RP' then round(convert(decimal(18,5),p.pret_de_stoc*p.cota_TVA/100),2)*/ when isnumeric(p.grupa)=1 then convert(float,p.grupa) 
					else convert(decimal(17,5),p.tva_deductibil/p.curs) end) else 0 end)),2) else 0 end),
			0 as achitat_valuta,p.loc_de_munca,
			left(p.comanda,20)+space(20),	--	indicatorul bugetar se va completa prin procedura indbugPozitieDocument.
			p.cont_factura,'2',p.cont_de_stoc,left(isnull(mfix.denumire, isnull(n.denumire,'Intrari')),50),p.numar_pozitie,
			p.gestiune,p.data_facturii,p.data_scadentei,(case when p.tip='RM' and p.valuta<>'' and p.numar_DVI<>'' then left(p.numar_DVI,13) else '' end),'',
			p.Cont_venituri as contTVA, p.Cod as cod, p.Cantitate as cantitate, (case when p.Tip in ('RM','RS') then p.Contract else '' end) contract, '' efect, 
			p.idPozDoc as idPozitieDoc, 'pozdoc' as tabela, isnull(p.detalii.value('(/row/@_determinant)[1]','int'),0)
		from pozdoc p 
			left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
			left outer join nomencl n on n.cod=p.cod
			left outer join mfix on isnull(n.tip, '')='F' and mfix.subunitate=p.subunitate and mfix.numar_de_inventar=p.cod_intrare
			left join lmfiltrare pr on pr.cod=p.loc_de_munca and pr.utilizator=@userASiS
			left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=p.subunitate and f.tip=@furn_benef_bin and f.factura=p.factura and f.tert=p.tert
		where p.data between @dDataIncDoc and @dDataSus and p.subunitate=@Subunitate and p.tip in ('RM','RP','RQ','RS') 
			and p.cont_factura<>'' 
			and p.tert like rtrim(@Tert) and t.grupa like @gtert and p.factura like rtrim(@Factura) and p.cont_factura like rtrim(@ContFactura)+'%'
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or convert(char(9),p.Loc_de_munca)  like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		union all
		select p.subunitate,p.tert,p.factura,p.plata_incasare,p.numar,p.data,0,0,
				(case when p.plata_incasare in ('PS','IS') then-1 else 1 end)*(p.suma-p.suma_dif)
								-(case when p.plata_incasare='PF' and @Ignor4428Avans=0 /*and left(p.Cont_corespondent,3) in ('409','451','232','167')*/ then p.TVA22 else 0 end),
				p.valuta,p.curs,0,
				(case when p.valuta='' or isnull(t.tert_extern,0)=0 then 0 when plata_incasare in ('PS','IS') then-1 else 1 end)*p.achit_fact,p.loc_de_munca,
				left(p.comanda,20)+space(20),
				p.cont_corespondent,'3',p.cont,p.explicatii,/*p.numar_pozitie*/p.idpozplin,left(p.comanda,9),p.data,p.data,'','','' as contTVA,
				'' as cod,0 as cantitate, '' contract, p.efect, p.idPozplin as idPozitieDoc, 'pozplin' as tabela, isnull(p.detalii.value('(/row/@_determinant)[1]','int'),0)
		from pozplin p 
			left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
			left join lmfiltrare pr on pr.cod=p.loc_de_munca and pr.utilizator=@userASiS
			left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=p.subunitate and f.tip=@furn_benef_bin and f.factura=p.factura and f.tert=p.tert
		where p.subunitate=@Subunitate and p.plata_incasare in ('PF','PR','IS') and p.data between @dDataIncDoc and @dDataSus and p.tert like rtrim(@Tert) and t.grupa like @gtert and p.factura like rtrim(@Factura) 
			and p.cont_corespondent like rtrim(@ContFactura)+'%'
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or convert(char(9),p.Loc_de_munca)  like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		union all 
		select p.subunitate,p.tert,p.factura_stinga,(case when p.tip='SF' then 'SX' when p.tip='CF' then 'FX' else p.tip end),p.numar_document,p.data,
				0,0,suma+(case when (1=1 or p.tip<>'C3') then (case when cont_dif like '6%' or cont_dif like '308%' then -suma_dif else suma_dif end) 
							else 0 end)+(case when p.tip='SF' and p.stare<>1 then tva22-dif_tva else 0 end),p.valuta,p.curs,0,
				(case when p.valuta<>'' and isnull(t.tert_extern,0)=1 then achit_fact+
					(case	when p.tip='SF' and p.stare<>1 and isnumeric(p.tert_beneficiar)=1 and p.TVA22<>0 
							then convert(float,p.tert_beneficiar)*(1.00-p.dif_TVA/p.TVA22) else 0 end) else 0 end),
				p.loc_munca,p.comanda,p.cont_deb,'4',p.cont_cred,p.explicatii,p.numar_pozitie,'',p.data_fact,p.data_scad,'','','' as contTVA,
				'' as cod,0 as cantitate, '' contract, '' efect, p.idPozadoc as idPozitieDoc, 'pozadoc' as tabela, isnull(p.detalii.value('(/row/@_determinant)[1]','int'),0)
		from pozadoc p 
			left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
			left join lmfiltrare pr on pr.cod=p.loc_munca and pr.utilizator=@userASiS
			left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=p.subunitate and f.tip=@furn_benef_bin and f.factura=p.factura_stinga and f.tert=p.tert
		where p.subunitate=@Subunitate and p.tip in ('SF','CO','CF','C3') and p.data between @dDataIncDoc and @dDataSus and p.tert like rtrim(@Tert) and t.grupa like @gtert
			and p.factura_stinga like rtrim(@Factura) and p.cont_deb like rtrim(@ContFactura)+'%'
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or convert(char(9),p.Loc_munca) like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		union all
		select p.subunitate,p.tert,p.factura_dreapta,p.tip,p.numar_document,p.data,
				(case when p.tip='CF' then 0 else suma+
					(case when 1=0 and p.tip='SF' and (cont_dif like '6%' or cont_dif like '308%') then suma_dif else 0 end) end),
				(case when p.tip='CF' or p.stare=1 then 0 else tva22 end),
				(case when p.tip='CF' then -suma+(case when @Ignor4428Avans=0 and charindex(left(p.Cont_cred,3),@conturiDocFF)=0 then p.TVA22 else 0 end) else 0 end),p.valuta,p.curs,
				(case when p.valuta='' or isnull(t.tert_extern,0)=0 then 0 when p.tip='CF' then 0 else suma_valuta+
					(case	when p.tip='FF' and p.stare<>1 then dif_tva 
							when p.tip='SF' and p.stare<>1 and isnumeric(p.tert_beneficiar)=1 then convert(float,p.tert_beneficiar) else 0 end) end),
				(case when p.valuta='' or isnull(t.tert_extern,0)=0 then 0 when p.tip='CF' then -suma_valuta else 0 end),p.loc_munca,
				left(p.comanda,20)+space(20),
				p.cont_cred,'4',p.cont_deb,p.explicatii,p.numar_pozitie,'',p.data_fact,p.data_scad,'','',p.Tert_beneficiar as contTVA,
				'' as cod,0 as cantitate, '' as contract, '' efect, p.idPozadoc as idPozitieDoc, 'pozadoc' as tabela, isnull(p.detalii.value('(/row/@_determinant)[1]','int'),0)
		from pozadoc p 
			left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
			left join lmfiltrare pr on pr.cod=p.loc_munca and pr.utilizator=@userASiS
			left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=p.subunitate and f.tip=@furn_benef_bin and f.factura=p.factura_dreapta and f.tert=p.tert
		where p.subunitate=@Subunitate and p.tip in ('SF','FF','CF') and p.data between @dDataIncDoc and @dDataSus and p.tert like rtrim(@Tert) and t.grupa like @gtert and p.factura_dreapta like rtrim(@Factura) 
			and p.cont_cred like rtrim(@ContFactura)+'%'
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or convert(char(9),p.Loc_munca) like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		union all
		select p.subunitate,p.tert,(case when cod_intrare='' then 'AVANS' else left(cod_intrare,@LFact) end),'RX',p.numar,p.data,0,0,
				round(convert(decimal(18,5),cantitate*round(convert(decimal(18,5),pret_valuta*(case when p.valuta<>'' then p.curs else 1 end)*(1+discount/100)),5)),2)+
					round(convert(decimal(18,5),(case when @Ignor4428Avans=0 and charindex(left(p.Cont_de_stoc,3),@ConturiDocFF)=0 
							or @Ignor4428DocFF=0 and charindex(left(p.Cont_de_stoc,3),@ConturiDocFF)<>0 then 0 else 1 end)
						*(case when (numar_DVI<>'' and p.tip='RM') or ((numar_DVI='' and p.tip='RM' or p.tip in ('RP','RS')) and procent_vama=1) then 0 else 1 end)*p.tva_deductibil),2)
						+isnull(p.detalii.value('(/row/@_difcursav)[1]','float'),0), 
				p.valuta,p.curs,0,
				(case when p.valuta<>'' and p.curs>0 
						then	round(convert(decimal(18,5),cantitate*round(convert(decimal(18,5),pret_valuta),5)),2)*(1+discount/100)+
								round(convert(decimal(18,5),(case when @Ignor4428Avans=0 and charindex(left(p.Cont_de_stoc,3),@ConturiDocFF)=0 
										or @Ignor4428DocFF=0 and charindex(left(p.Cont_de_stoc,3),@ConturiDocFF)<>0 then 0 else 1 end)
									*(case when (numar_DVI<>'' and p.tip='RM') or ((numar_DVI='' and p.tip='RM' or p.tip in ('RP','RS')) and procent_vama=1) then 0 else 1 end)
										*p.tva_deductibil/p.curs),2) else 0 end),
				p.loc_de_munca,p.comanda,cont_de_stoc,'4',cont_factura,left(isnull(n.denumire,''),50),numar_pozitie,'',p.data_facturii,
				p.data_scadentei,'','',p.Cont_venituri as contTVA, p.cod as cod, p.Cantitate as cantitate,
				(case when p.Tip in ('RM','RS') then p.Contract else '' end) contract, '' efect, p.idPozdoc as idPozitieDoc, 'pozdoc' as tabela, 0
		from pozdoc p 
			inner join conturi c on c.subunitate=p.subunitate and c.cont=p.cont_de_stoc and c.sold_credit=1
			left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
			left outer join nomencl n on n.cod=p.cod
			left join lmfiltrare pr on pr.cod=p.loc_de_munca and pr.utilizator=@userASiS
			left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=p.subunitate and f.tip=@furn_benef_bin
					and f.factura=(case when p.cod_intrare='' then 'AVANS' else left(p.cod_intrare,@LFact) end) and f.tert=p.tert
		where p.subunitate=@Subunitate and p.tip in ('RM','RS') and p.data between @dDataIncDoc and @dDataSus and p.tert like rtrim(@Tert) and t.grupa like @gtert
			and (case when cod_intrare='' then 'AVANS' else left(cod_intrare,20) end) like rtrim(@Factura) 
			and cont_de_stoc like rtrim(@ContFactura)+'%'
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or convert(char(9),p.Loc_de_munca)  like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		union all
		select	m.subunitate,m.tert,m.factura,'M'+left(m.tip_miscare,1),m.numar_document,m.data_miscarii,
				(case when tip_miscare='MFF' then diferenta_de_valoare else pret end),m.tva,0,left(m.gestiune_primitoare,3),0,
				(case when tip_miscare='IAF' and gestiune_primitoare<>'' and isnull(t.tert_extern,0)=1 then diferenta_de_valoare else 0 end),0,
				m.loc_de_munca_primitor,'',m.cont_corespondent,'2',
				isnull((select max(cont_mijloc_fix) from fisamf where subunitate=@Subunitate and numar_de_inventar=m.numar_de_inventar and felul_operatiei='3'),'212'),	
				'Miscare MF',0,'',m.data_miscarii,m.data_miscarii,'','','' as contTVA, m.Numar_de_inventar as cod,0 as cantitate,
					'' as contract, '' efect, 0 as idPozitieDoc, 'mismf' as tabela, 0
		from mismf m 
			left outer join terti t on m.subunitate=t.subunitate and m.tert=t.tert 
			left join lmfiltrare pr on pr.cod=m.loc_de_munca_primitor and pr.utilizator=@userASiS
			left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=m.subunitate and f.tip=@furn_benef_bin and f.factura=m.factura and f.tert=m.tert
		where m.procent_inchiriere not in (1,6,9) and m.subunitate=@Subunitate and m.tip_miscare in ('IAF','MFF') and m.data_miscarii between @dDataIncDocMF and @dDataSus and m.tert like rtrim(@Tert)
			and t.grupa like @gtert
			and m.factura like rtrim(@Factura) and m.cont_corespondent like rtrim(@ContFactura)+'%'
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or m.Loc_de_munca_primitor like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		-------------> DVI:	
		union all
		select a.subunitate,b.tert_cif,b.factura_cif,a.tip,a.numar,a.data,b.valoare_cif_lei,b.tva_cif,0,b.valuta_cif,b.curs,(case when b.valuta_cif='' then 0 else b.valoare_cif end),0,
				a.loc_munca,a.comanda,b.cont_cif,'2','','CIF',0,a.cod_gestiune,b.data_cif,isnull(nullif(nullif(b.data_comis,''),'01/01/1901'),b.data_cif),a.numar_DVI,'', '' as contTVA,'' as cod,0 as cantitate,'' contract, '' efect, 
				0 as idPozitieDoc, 'doc' as tabela, 0
		from doc a 
			inner join dvi b on a.subunitate=b.subunitate and a.numar=b.numar_receptie and a.data=b.data_dvi
			left join lmfiltrare pr on pr.cod=a.loc_munca and pr.utilizator=@userASiS
			left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=b.subunitate and f.tip=@furn_benef_bin and f.factura=b.factura_cif and f.tert=b.tert_cif
			left join terti t on b.subunitate=t.subunitate and b.tert_cif=t.tert
		where a.subunitate=@Subunitate and a.tip='RM' and a.data between @dDataIncDoc and @dDataSus and b.tert_cif<>'' and b.tert_cif like rtrim(@Tert) and t.grupa like @gtert
			and b.factura_cif like rtrim(@Factura) 
			and b.cont_cif like rtrim(@ContFactura)+'%' and (b.valoare_cif_lei<>0 or b.tva_cif<>0)
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or a.Loc_munca like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		union all
		/*	Renuntam la citirea setarilor, si vom aduce pozitii separate pentru fiecare componenta a DVI-ului. Din acest motiv nu mai cumulam pe selectul de mai jos comisionul vamal si TVA-ul.*/
		select a.subunitate,b.tert_vama,b.factura_vama,a.tip,a.numar,b.data_DVI,b.suma_vama+b.suma_suprataxe+b.dif_vama+
				(case when @AccImpDVI=1 then b.valoare_accize+b.tva_11 else 0 end)+(case when /*(@CtFactVamaDVI=1 or b.cont_vama<>b.cont_tert_vama) and*/ 1=0 then b.suma_com_vam+b.dif_com_vam else 0 end),
				(case when /*(@CtFactVamaDVI=1 or b.cont_vama<>b.cont_tert_vama) and b.total_vama<>1 and*/ 1=0 then b.tva_22 else 0 end),0,'',0,0,0,a.loc_munca,a.comanda,
				(case when b.cont_tert_vama<>b.cont_vama and b.cont_tert_vama<>'' then b.cont_tert_vama else b.cont_vama end),
				'2','','taxe vamale',0,a.cod_gestiune,b.data_receptiei,convert(datetime,b.tert_comis,103),a.numar_DVI,'', '' as contTVA,'' as cod,0 as cantitate,'' contract, '' efect, 
				0 as idPozitieDoc, 'doc' as tabela, 0
		from doc a 
			inner join dvi b on a.subunitate=b.subunitate and a.numar=b.numar_receptie and a.data=b.data_dvi 
			left join lmfiltrare pr on pr.cod=a.loc_munca and pr.utilizator=@userASiS
			left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=a.subunitate and f.tip=@furn_benef_bin and f.factura=b.factura_vama and f.tert=b.tert_vama
			left join terti t on b.subunitate=t.subunitate and b.tert_vama=t.tert
		where a.subunitate=@Subunitate and a.tip='RM' and b.data_DVI between @dDataIncDoc and @dDataSus and b.tert_vama like rtrim(@Tert)
			and t.grupa like @gtert and b.factura_vama like rtrim(@Factura) 
			and (case when b.cont_tert_vama<>b.cont_vama and b.cont_tert_vama<>'' then b.cont_tert_vama else b.cont_vama end) like rtrim(@ContFactura)+'%' 
			and b.factura_comis in ('','D') 
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or a.Loc_munca like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		union all
		select a.subunitate,b.tert_vama,isnull(nullif(b.detalii.value('(/row/@facturacomis)[1]','varchar(20)'),''),b.Factura_vama),a.tip,a.numar,b.data_DVI,b.suma_com_vam+b.dif_com_vam,0,0,'',0,0,0,a.loc_munca,
				a.comanda,isnull(nullif(b.cont_com_vam,''),(case when b.cont_tert_vama<>b.cont_vama and b.cont_tert_vama<>'' then b.cont_tert_vama else b.cont_vama end)),
				'2','','comision vamal',0,a.cod_gestiune,b.data_receptiei,convert(datetime,b.tert_comis,103),a.numar_DVI,'',
				'' as contTVA,'' as cod,0 as cantitate,'' contract, '' efect, 0 as idPozitieDoc, 'doc' as tabela, 0
		from doc a 
			inner join dvi b on a.subunitate=b.subunitate and a.numar=b.numar_receptie and a.data=b.data_dvi
			left join lmfiltrare pr on pr.cod=a.loc_munca and pr.utilizator=@userASiS
			left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=a.subunitate and f.tip=@furn_benef_bin 
				and f.factura=isnull(nullif(b.detalii.value('(/row/@facturacomis)[1]','varchar(20)'),''),b.Factura_vama) and f.tert=b.tert_vama
			left join terti t on b.subunitate=t.subunitate and b.tert_vama=t.tert
		where /*not (@CtFactVamaDVI=1 or b.cont_vama<>b.cont_tert_vama) and - Renuntam la citirea setarilor, si vom aduce pozitii separate pentru fiecare componenta a DVI-ului. */
			a.subunitate=@Subunitate and a.tip='RM' and b.data_DVI between @dDataIncDoc and @dDataSus and b.tert_vama like rtrim(@Tert) 
			and t.grupa like @gtert
			and isnull(nullif(b.detalii.value('(/row/@facturacomis)[1]','varchar(20)'),''),b.Factura_vama) like rtrim(@Factura) 
			and isnull(nullif(b.cont_com_vam,''),(case when b.cont_tert_vama<>b.cont_vama and b.cont_tert_vama<>'' then b.cont_tert_vama else b.cont_vama end)) like rtrim(@ContFactura)+'%' 
			and b.factura_comis in ('','D')
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or a.Loc_munca like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		union all
		select a.subunitate,b.tert_vama,isnull(nullif(b.Factura_TVA,''),b.Factura_vama),a.tip,a.numar,b.data_DVI,0,(case when b.total_vama<>1 then b.tva_22 else 0 end),0,'',0,0,0,a.loc_munca,
				a.comanda,(case when b.Factura_TVA<>'' and b.Factura_TVA=Factura_vama 
					then (case when b.cont_tert_vama<>b.cont_factura_TVA and b.cont_tert_vama<>'' then b.cont_tert_vama else b.cont_factura_TVA end) 
					else isnull(nullif(b.cont_factura_TVA,''),(case when b.cont_tert_vama<>b.cont_vama and b.cont_tert_vama<>'' then b.cont_tert_vama else b.cont_vama end)) end),
				'2','','tva vama',0,a.cod_gestiune,b.data_receptiei,convert(datetime,b.tert_comis,103),a.numar_DVI,'',
				'' as contTVA,'' as cod,0 as cantitate,'' contract, '' efect, 0 as idPozitieDoc, 'doc' as tabela, 0
		from doc a 
			inner join dvi b on a.subunitate=b.subunitate and a.numar=b.numar_receptie and a.data=b.data_dvi 
			left join lmfiltrare pr on pr.cod=a.loc_munca and pr.utilizator=@userASiS
			left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=a.subunitate and f.tip=@furn_benef_bin 
				and f.factura=isnull(nullif(b.Factura_TVA,''),b.Factura_vama) and f.tert=b.tert_vama
			left join terti t on b.subunitate=t.subunitate and b.tert_vama=t.tert
		where /*not (@CtFactVamaDVI=1 or b.cont_vama<>b.cont_tert_vama) and - Renuntam la citirea setarilor, si vom aduce pozitii separate pentru fiecare componenta a DVI-ului. */
			a.subunitate=@Subunitate and a.tip='RM' and b.data_DVI between @dDataIncDoc and @dDataSus and b.tert_vama like rtrim(@Tert) 
			and t.grupa like @gtert
			and isnull(nullif(b.Factura_TVA,''),b.Factura_vama) like rtrim(@Factura) 
			and (case when b.Factura_TVA<>'' and b.Factura_TVA=Factura_vama 
					then (case when b.cont_tert_vama<>b.cont_factura_TVA and b.cont_tert_vama<>'' then b.cont_tert_vama else b.cont_factura_TVA end) 
					else isnull(nullif(b.cont_factura_TVA,''),(case when b.cont_tert_vama<>b.cont_vama and b.cont_tert_vama<>'' then b.cont_tert_vama else b.cont_vama end)) end) like rtrim(@ContFactura)+'%' 
			and b.factura_comis in ('','D')
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or a.Loc_munca like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
			
			/**	data platii se ia din fFacturiB pentru IB-uri, in rest data_platii=data */
		update #docfac set furn_benef='F', data_platii=data, punct_livrare='', achitare_efect_in_curs=0 where furn_benef is null
	end

	/*	Preluare facturi beneficiari */	
	if (@FurnBenef='' or @FurnBenef='B')
	begin
		declare @contTvaDeductibil varchar(40)
		select @contTvaDeductibil=rtrim(isnull((select val_alfanumerica from par where tip_parametru='GE' and parametru='CCTVA'),'4427'))

		insert #docfac (subunitate,tert,factura,tip,numar,data,valoare,tva,achitat,valuta,curs,total_valuta,achitat_valuta,loc_de_munca,comanda,
			cont_de_tert,fel,cont_coresp,explicatii,numar_pozitie,gestiune,data_facturii,data_scadentei,nr_dvi,barcod,contTVA,cod,cantitate,contract,efect,data_platii,idPozitieDoc,tabela, determinant)
		select i.subunitate,i.tert,i.factura,'SI' tip ,i.factura numar,i.data,i.valoare,i.tva_11+i.tva_22 tva,i.achitat ,i.valuta, i.curs, i.valoare_valuta total_valuta, i.achitat_valuta,
				i.loc_de_munca, i.comanda, i.cont_de_tert, '1' fel, '' cont_coresp, 'Sold initial' explicatii, 0 numar_pozitie, '' gestiune, i.data data_facturii, i.data_scadentei,
				isnull((select top 1 left(d.gestiune_primitoare,5) from doc d where d.subunitate=i.subunitate and d.tip in ('AP','AS') and d.factura=i.factura and d.cod_tert=i.tert), '') punct_livrare, 
				'' barcod, '' contTVA,'' as cod,0 as cantitate,
				'' contract, '' efect, i.data as data_platii, 0 as idPozitieDoc, 'istfact' as tabela, 0
		from istfact i
			left outer join terti t on i.subunitate=t.subunitate and i.tert=t.tert 
			left join lmfiltrare pr on pr.cod=i.loc_de_munca and pr.utilizator=@userASiS
			left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=i.subunitate and f.tip=@furn_benef_bin and f.factura=i.factura and f.tert=i.tert
		where @IstFactImpl=1 and i.subunitate=@Subunitate and i.tip='B' and i.data_an=@dDataIncDoc
			and (@tert='%' or i.tert like rtrim(@Tert)) and t.grupa like @gtert
			and (@factura='%' or i.factura like rtrim(@Factura)) and (@ContFactura='' or i.Cont_de_tert like rtrim(@ContFactura)+'%')
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or convert(char(9),i.Loc_de_munca)  like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		union all 
		select fi.subunitate,fi.tert,fi.factura,'SI',fi.factura,@dDImpl,fi.valoare,fi.tva_11+fi.tva_22,fi.achitat,fi.valuta,fi.curs,fi.valoare_valuta,
				fi.achitat_valuta,fi.loc_de_munca,fi.comanda,fi.cont_de_tert,'1','','Sold initial',0,'',fi.data,fi.data_scadentei,
				COALESCE(fi.punct_livrare, (select top 1 left(d.gestiune_primitoare,5) from doc d where d.subunitate=fi.subunitate and d.tip in ('AP','AS') and d.factura=fi.factura and d.cod_tert=fi.tert), 
					(select top 1 i.serie_doc from incfact i where i.subunitate=fi.subunitate and i.numar_factura=fi.factura and i.tert=fi.tert), ''),
				'','' contTVA,'' as cod,0 as cantitate, '' contract, '' efect, fi.data, 0 as idPozitieDoc, 'factimpl' as tabela, 0
		from factimpl fi 
			left join lmfiltrare pr on pr.cod=fi.loc_de_munca and pr.utilizator=@userASiS
			left outer join terti t on fi.subunitate=t.subunitate and fi.tert=t.tert 
			left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=fi.subunitate and f.tip=@furn_benef_bin and f.factura=fi.factura and f.tert=fi.tert
		where @IstFactImpl=2 and fi.subunitate=@Subunitate and fi.tip=0x46 
			  and (@tert='%' or fi.tert like rtrim(@Tert)) and t.grupa like @gtert
			  and (@factura='%' or fi.factura like rtrim(@Factura)) and (@ContFactura='' or fi.Cont_de_tert like rtrim(@ContFactura)+'%')
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or convert(char(9),fi.Loc_de_munca)  like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		union all 
		select p.subunitate,p.tert,p.factura,p.tip,numar,p.data,round(convert(decimal(18,5),cantitate*p.pret_vanzare),2),
				(case when not (p.tip in ('AP','AS') and @GenisaUnicarm=0 and (@DocSchimburi=0 or p.tip='AS') and p.procent_vama in (1, 2)) then tva_deductibil else 0 end),0,p.valuta,p.curs,
				(case when p.valuta<>'' and isnull(t.tert_extern,0)=1 
					then round(convert(decimal(18,5),cantitate*(pret_valuta+(case when @LME=1 and p.tip='AP' then p.suprataxe_vama/1000 else 0 end))*(1-discount/100))
						+convert(decimal(18,5),case when not (p.tip in ('AP','AS') and @GenisaUnicarm=0 and (@DocSchimburi=0 or p.tip='AS') and p.procent_vama in (1, 2)) and p.curs>0 then TVA_deductibil/p.curs else 0 end),2) else 0 end),
				0,p.loc_de_munca,left(p.comanda,20)+space(20), 
				p.cont_factura,'2',(case when n.tip='S' and p.Jurnal<>'MFX' then p.Cont_de_stoc else p.cont_venituri end),left(isnull(mfix.denumire, isnull(n.denumire,'Iesiri')),50),numar_pozitie,
				p.gestiune,data_facturii,p.data_scadentei,substring(p.numar_dvi, 14, 5),p.barcod,
				(case when p.tip in ('AP','AS') then p.grupa  else p.cont_venituri end) as contTVA,p.cod as cod,p.Cantitate as cantitate, 
				(case when p.Tip in ('AP','AS') then p.Contract else '' end) contract, '' efect, p.data, p.idPozdoc as idPozitieDoc, 'pozdoc' as tabela, isnull(p.detalii.value('(/row/@_determinant)[1]','int'),0)
		from pozdoc p 
		left join lmfiltrare pr on pr.cod=p.loc_de_munca and pr.utilizator=@userASiS
		left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
		left outer join nomencl n on n.cod=p.cod
		left outer join mfix on isnull(n.tip, '')='F' and mfix.subunitate=p.subunitate and mfix.numar_de_inventar=p.cod_intrare
		left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=p.subunitate and f.tip=@furn_benef_bin and f.factura=p.factura and f.tert=p.tert
		where p.subunitate=@Subunitate and p.tip in ('AP','AS') and p.cont_factura<>'' 
			and p.data between @dDataIncDoc and @dDataSus 
			and (@tert='%' or p.tert like rtrim(@Tert)) and t.grupa like @gtert
			and (@factura='%' or p.factura like rtrim(@Factura)) and (@ContFactura='' or p.cont_factura like rtrim(@ContFactura)+'%')
			and (@filtrareUser=0 or pr.utilizator=@userASiS	)
			and (@bugetari=1 or @locm='%' or convert(char(9),p.Loc_de_munca) like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		union all 
		select p.subunitate,p.tert,p.factura,p.plata_incasare,p.numar,p.data,0,0,
				(case when p.plata_incasare in ('PS','IS') then -1 else 1 end)*(p.suma-suma_dif)
					-(case when p.plata_incasare='IB' and @Ignor4428Avans=0 /*and left(p.Cont_corespondent,3) in ('419','451','461')*/ then p.TVA22 else 0 end),
				p.valuta,p.curs,0,
				(case when p.valuta='' or isnull(t.tert_extern,0)=0 then 0 when plata_incasare in ('PS','IS') then -1 else 1 end)*achit_fact,p.loc_de_munca,
				left(p.comanda,20)+space(20),
				p.cont_corespondent,'3',p.cont,explicatii,/*p.numar_pozitie*/p.idpozplin,left(p.comanda,9),p.data,p.data,
				'','','' contTVA, '' as cod,0 as cantitate, '' contract, isnull(p.efect,'') efect, isnull(p.detalii.value('(/row/@dataplatii)[1]','datetime'),p.Data) as data_platii, 
				p.idPozplin as idPozitieDoc, 'pozplin' as tabela, isnull(p.detalii.value('(/row/@_determinant)[1]','int'),0)
		from pozplin p 
		left join lmfiltrare pr on pr.cod=p.loc_de_munca and pr.utilizator=@userASiS
		left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
		left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=p.subunitate and f.tip=@furn_benef_bin and f.factura=p.factura and f.tert=p.tert
		where p.subunitate=@Subunitate and p.plata_incasare in ('IB','IR','PS')
			and p.data between @dDataIncDoc and @dDataSus 
			and (@tert='%' or p.tert like rtrim(@Tert)) and t.grupa like @gtert
			and (@factura='%' or p.factura like rtrim(@Factura)) and (@ContFactura='' or p.Cont_corespondent like rtrim(@ContFactura)+'%')
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or convert(char(9),p.Loc_de_munca) like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		--
		union all 
		select	p.subunitate,p.tert,factura_stinga,p.tip,p.numar_document,p.data,(case when p.tip='CB' then 0 else suma end),
				(case when p.tip='CB' or p.stare in (1, 2) then 0 else tva22 end),
				(case when p.tip='CB' then -suma+(case when @Ignor4428Avans=0 and charindex(left(p.Cont_deb,3),@conturiDocFF)=0 then p.TVA22 else 0 end) else 0 end),
				p.valuta,p.curs,
				(case when p.valuta='' or isnull(t.tert_extern,0)=0 or p.tip='CB' then 0 else suma_valuta+
					(case	when p.tip in ('IF','FB') and p.stare=1 then 0 when p.tip='FB' then dif_TVA 
							when p.tip='IF' then convert(float,tert_beneficiar) else 0 end) end),
				(case when p.valuta='' or isnull(t.tert_extern,0)=0 then 0 when p.tip='CB' then -suma_valuta else 0 end),loc_munca,
				left(p.comanda,20)+space(20),
				cont_deb,'4',cont_cred,explicatii,numar_pozitie,'',data_fact,data_scad,'','',
				(case when p.tip='IF' then @contTvaDeductibil else p.tert_beneficiar end)
				contTVA, '' as cod, 0 as cantitate,'' contract, '' efect, p.data, p.idPozadoc as idPozitieDoc, 'pozadoc' as tabela, isnull(p.detalii.value('(/row/@_determinant)[1]','int'),0)
		from pozadoc p 
		left join lmfiltrare pr on pr.cod=p.loc_munca and pr.utilizator=@userASiS
		left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
		left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=p.subunitate and f.tip=@furn_benef_bin and f.factura=p.factura_stinga and f.tert=p.tert
		where p.subunitate=@Subunitate and p.tip in ('CB','FB','IF') and p.data between @dDataIncDoc and @dDataSus
			and (@tert='%' or p.tert like rtrim(@Tert)) and t.grupa like @gtert
			and (@factura='%' or p.Factura_stinga like rtrim(@Factura)) and (@ContFactura='' or p.Cont_deb like rtrim(@ContFactura)+'%')
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or convert(char(9),p.Loc_munca) like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		union all 
		select p.subunitate,p.tert,factura_dreapta,(case when p.tip='IF' then 'IX' when p.tip='CB' then 'BX' else p.tip end),numar_document,p.data,
				0,0,suma+(case when p.tip in ('CB','IF') then (case when left(cont_dif,1)='6' then suma_dif else -suma_dif end) else 0 end)+
					(case when p.tip='IF' and p.stare not in (1, 2) then TVA22-dif_TVA else 0 end),p.valuta,p.curs,0,
				(case when p.valuta<>'' and isnull(t.tert_extern,0)=1 then achit_fact+
					(case when p.tip='IF' and p.stare<>1 and isnumeric(p.tert_beneficiar)=1 and p.TVA22<>0 
							then convert(float,tert_beneficiar)*(1.00-p.dif_TVA/p.TVA22) else 0 end) else 0 end),loc_munca,p.comanda,cont_cred,'4',
				cont_deb,explicatii,numar_pozitie,'',data_fact,data_scad,'','','' contTVA, '' as cod,0 as cantitate, '' contract, '' efect, p.data, 
				p.idPozadoc as idPozitieDoc, 'pozadoc' as tabela, isnull(p.detalii.value('(/row/@_determinant)[1]','int'),0)
		from pozadoc p 
		left join lmfiltrare pr on pr.cod=p.loc_munca and pr.utilizator=@userASiS
		left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
		left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=p.subunitate and f.tip=@furn_benef_bin and f.factura=p.factura_dreapta and f.tert=p.tert
		where p.subunitate=@Subunitate and p.tip in ('CB','CO','IF') and p.data between @dDataIncDoc and @dDataSus
			and (@tert='%' or p.tert like rtrim(@Tert)) and t.grupa like @gtert
			and (@factura='%' or p.Factura_dreapta like rtrim(@Factura)) and (@ContFactura='' or p.Cont_cred like rtrim(@ContFactura)+'%')
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or convert(char(9),p.Loc_munca) like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		union all 
		select p.subunitate,p.tert_beneficiar,p.factura_dreapta,p.tip,numar_document,p.data,0,0,suma,p.valuta,p.curs,0,
				(case when p.valuta<>'' and isnull(t.tert_extern,0)=1 then achit_fact else 0 end),loc_munca,p.comanda,cont_cred,'4',cont_deb,explicatii,
				numar_pozitie,'',data_fact,data_scad,'','','' contTVA, '' as cod,0 as cantitate,'' contract, '' efect, p.data, p.idPozadoc as idPozitieDoc, 'pozadoc' as tabela, isnull(p.detalii.value('(/row/@_determinant)[1]','int'),0)
		from pozadoc p 
		left join lmfiltrare pr on pr.cod=p.loc_munca and pr.utilizator=@userASiS
		left outer join terti t on p.subunitate=t.subunitate and p.tert_beneficiar=t.tert 
		left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=p.subunitate and f.tip=@furn_benef_bin and f.factura=p.factura_dreapta and f.tert=p.tert_beneficiar
		where p.subunitate=@Subunitate and p.tip='C3' and p.data between @dDataIncDoc and @dDataSus
			and (@tert='%' or p.Tert_beneficiar like rtrim(@Tert)) and t.grupa like @gtert
			and (@factura='%' or p.Factura_dreapta like rtrim(@Factura)) and (@ContFactura='' or p.Cont_cred like rtrim(@ContFactura)+'%')
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or (p.Loc_munca) like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		union all 
		select m.subunitate,m.tert,m.factura,'M'+left(tip_miscare,1),numar_document,data_miscarii,pret,tva,0,'',0,0,0,
			isnull((select max(loc_de_munca) from fisaMF where subunitate=@Subunitate and numar_de_inventar=m.numar_de_inventar and felul_operatiei='5'),''),
			isnull((select max(comanda) from fisaMF where subunitate=@Subunitate and numar_de_inventar=m.numar_de_inventar and felul_operatiei='5'),''),
			loc_de_munca_primitor,'2',gestiune_primitoare,'miscare mijloc fix: '+left(tip_miscare,1),0,'',data_miscarii,data_miscarii,'','','' contTVA,
			m.Numar_de_inventar as cod,0 as cantitate, '' contract, '' efect, m.Data_miscarii, 0 as idPozitieDoc, 'mismf' as tabela, 0
		from misMF m
		left join lmfiltrare pr on pr.cod=m.loc_de_munca_primitor and pr.utilizator=@userASiS
		left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=m.subunitate and f.tip=@furn_benef_bin and f.factura=m.factura and f.tert=m.tert
		left join terti t on m.subunitate=t.subunitate and m.tert=t.tert
		where procent_inchiriere not in (1,6,9) and m.subunitate=@Subunitate and tip_miscare='EVI' and data_miscarii between @dDataIncDocMF and @dDataSus
			and (@tert='%' or m.tert like rtrim(@Tert)) and t.grupa like @gtert
			and (@factura='%' or m.Factura like rtrim(@Factura)) and (@ContFactura='' or m.Loc_de_munca_primitor like rtrim(@ContFactura)+'%')
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or (m.Loc_de_munca_primitor) like @locm)
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)
		union all							
		select p.subunitate,p.tert,(case when p.cod_intrare='' then 'AVANS' 
					else p.cod_intrare end)	--< aici era left(p.cod_intrare,@LFact) in loc de p.cod_intrare; modificat cu ocazia optimizarii
				,'AX',numar,p.data,0,0,	
				round(convert(decimal(18,5),cantitate*p.pret_vanzare),2)
				+(case when @Ignor4428Avans=0 and charindex(left(p.Cont_de_stoc,3),@ConturiDocFF)='' or @Ignor4428DocFF=0 and charindex(left(p.Cont_de_stoc,3),@ConturiDocFF)<>0 then 0 else 1 end)
					*(case when p.tip in ('AP','AS') and @GenisaUnicarm=0 and (@DocSchimburi=0 or p.tip='AS') and p.procent_vama in (1, 2) then 0 else 1 end)*tva_deductibil
				+isnull(p.detalii.value('(/row/@_difcursav)[1]','float'),0),
				p.valuta,p.curs,0,(case when p.valuta<>'' and p.curs>0 then round(convert(decimal(18,5),cantitate*pret_valuta*(1-p.discount/100)),2)+
						round(convert(decimal(18,5),(case when @Ignor4428Avans=0 and charindex(left(p.Cont_de_stoc,3),@ConturiDocFF)='' 
								or @Ignor4428DocFF=0 and charindex(left(p.Cont_de_stoc,3),@ConturiDocFF)<>0 then 0 else 1 end)
							*(case when p.tip in ('AP','AS') and @GenisaUnicarm=0 and (@DocSchimburi=0 or p.tip='AS') and p.procent_vama in (1, 2) then 0 else 1 end)*tva_deductibil/p.curs),2) else 0 end),	
				p.loc_de_munca,p.comanda,cont_de_stoc,'4',cont_corespondent,left(isnull(n.denumire,''),50),numar_pozitie,'',p.data_facturii,
				p.data_scadentei,substring(p.numar_dvi, 14, 5),p.barcod,'' contTva, p.cod as cod,p.cantitate as cantitate, 
				(case when p.Tip in ('AP','AS') then p.Contract else '' end), '' efect, p.Data, p.idPozdoc as idPozitieDoc, 'pozdoc' as tabela, 0
		from pozdoc p 
		left join lmfiltrare pr on pr.cod=p.loc_de_munca and pr.utilizator=@userASiS
		inner join conturi c on c.subunitate=p.subunitate and c.cont=p.cont_de_stoc and c.sold_credit=2
		left outer join nomencl n on n.cod=p.cod
		left join facturi f on @q_cuFltLocmStilVechi=1 and f.loc_de_munca like @locmV and f.subunitate=p.subunitate and f.tip=@furn_benef_bin
			and f.factura=(case when p.cod_intrare='' then 'AVANS' else p.cod_intrare end) and f.tert=p.tert
		left join terti t on p.subunitate=t.subunitate and p.tert=t.tert
		where p.subunitate=@Subunitate and p.tip in ('AP','AS') and p.data between @dDataIncDoc and @dDataSus
			and (@tert='%' or p.tert like rtrim(@Tert)) and t.grupa like @gtert
			and (@factura='%' or (case when p.cod_intrare='' then 'AVANS' else left(p.cod_intrare,20) end) like rtrim(@Factura))
				and (@ContFactura='' or p.Cont_de_stoc like rtrim(@ContFactura)+'%')
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
			and (@bugetari=1 or @locm='%' or convert(char(9),p.Loc_de_munca) like @locm)	--*/--*/--*/--*/
			and (@q_cuFltLocmStilVechi=0 or f.factura is not null)			

		update #docfac set furn_benef='B', punct_livrare=nr_dvi, achitare_efect_in_curs=0 where furn_benef is null

		if exists (select 1 from sysobjects o where o.type='TF' and o.name='fBenefUA')
			insert #docfac (furn_benef,subunitate,tert,factura,tip,numar,data,valoare,tva,achitat,valuta,curs,total_valuta,achitat_valuta,loc_de_munca,comanda,cont_de_tert,fel,
				cont_coresp,explicatii,numar_pozitie,gestiune,data_facturii,data_scadentei,nr_dvi,barcod,contTVA,cod,cantitate,contract,efect,data_platii,punct_livrare,achitare_efect_in_curs)
			select 'B', f.subunitate,f.tert,f.factura,f.tip,f.numar,f.data,f.valoare,f.tva,f.achitat,f.valuta,f.curs,f.total_valuta,f.achitat_valuta,f.loc_de_munca,f.comanda,
				f.cont_de_tert,f.fel,f.cont_coresp,f.explicatii,f.numar_pozitie,f.gestiune,f.data_facturii,f.data_scadentei,'',f.barcod,'','',0,'','',f.data,f.punct_livrare,0
			from dbo.fBenefUA(@Subunitate,@dDataIncDoc,@dDataSus,@Tert,@Factura,@ContFactura,@LFact) f	--*/
				left join facturi fa on @q_cuFltLocmStilVechi=1 and fa.loc_de_munca like @locmV and fa.subunitate=f.subunitate and fa.tip=@furn_benef_bin and fa.factura=f.factura and fa.tert=f.tert
			where (@q_cuFltLocmStilVechi=0 or fa.factura is not null)
				
	end

	-- daca nu are sume se sterge pozitia 
	delete #docfac where valoare=0 and tva=0 and achitat=0 and total_valuta=0 and achitat_valuta=0


	if exists (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'pFacturiSP1') AND type='P')
		exec pFacturiSP1 @sesiune=@sesiune, @parXML=@parXML

	IF @inclFacturiNe = 0
		delete #docfac where charindex(left(cont_de_tert,3),@ConturiDocFF)<>0
	
	if @Bugetari=1 and exists (select * from sysobjects where name ='indbugPozitieDocument' and xtype='P')
	begin
		select furn_benef, tabela, idPozitieDoc, indbug into #indbugPozitieDoc from #docfac
		exec indbugPozitieDocument @sesiune=@sesiune, @parXML=@parXML

		update df set df.indbug=ib.indbug, df.comanda=isnull(left(df.comanda,20)+ib.indbug,df.comanda)
		from #docfac df
			left outer join #indbugPozitieDoc ib on ib.tabela=df.tabela and ib.idPozitieDoc=df.idPozitieDoc

		update #docfac set indbug=(case when /*furn_benef='F' and*/ tabela in ('factimpl','istfact') then substring(comanda,21,20) else '' end) where indbug is null

		/*	apelez din nou indbugPozitieDocument pentru pozitiile pe care nu s-a reusit completarea indicatorului bugetar (apelare pFacturi dinspre RefacereFacturi). 
			Este vorba de spre compensari, sosire factura, intocmire factura. La refacere nu exista pozitii in tabela facturi. */
		/* Cristy - nu e logic sa le refaca din tabela de facturi pe ceva de genul max(comanda) se vor sparge proportional */
		/*
		declare @ramase int
		set @ramase=1
		if @parXML.value('(/row/@ramase)[1]', 'int') is null
			set @parXML.modify ('insert attribute ramase {sql:variable("@ramase")} into (/row)[1]') 
		if @parXML.value('(/row/@ramase)[1]', 'int') = 0
			set @parXML.modify('replace value of (/row/@ramase)[1] with sql:variable("@ramase")')
		exec indbugPozitieDocument @sesiune=@sesiune, @parXML=@parXML
		*/
		select pozitie,furn_benef,tert,factura,tabela,idPozitieDoc,indbug,achitat as achitat
		into #nebug
		from #docfac where (fel=3 or fel=4 and tip in ('CF','FX','CB','BX','CO','C3')) and indbug=''

		select df.furn_benef,df.tert,df.factura,df.indbug,sum(df.valoare+df.tva) as valf
		into #nebugr
		from #docfac df 
		where indbug<>'' and exists (select 1 from #nebug n where n.tert=df.tert and n.factura=df.factura and n.furn_benef=df.furn_benef)
		group by df.furn_benef,df.tert,df.factura,df.indbug
		--having abs(sum(df.valoare+df.tva))>0.1

		alter table #nebugr add ratie float

		update #nebugr set ratie=(case when abs(valtotal)<0.01 then 1 else valf/valtotal end)
		from #nebugr n
		inner join (
			select df.furn_benef,df.tert,df.factura,sum(valf) as valtotal
			from #nebugr df 
			group by df.furn_benef,df.tert,df.factura) ft on n.furn_benef=ft.furn_benef and n.tert=ft.tert and n.factura=ft.factura

		select df.*
		into #desters
		from #docfac df
		inner join #nebug nb on df.pozitie=nb.pozitie

		delete df
		from #docfac df
		inner join #nebug nb on df.pozitie=nb.pozitie

		alter table #desters drop column pozitie

		insert into #docfac(furn_benef,subunitate,tert,factura,tip,numar,data,valoare,tva,achitat,valuta,curs,total_valuta,achitat_valuta,loc_de_munca,comanda,
			cont_de_tert,fel,cont_coresp,explicatii,numar_pozitie,gestiune,data_facturii,data_scadentei,nr_dvi,barcod,contTVA,cod,cantitate,contract,efect,idPozitieDoc,tabela,indbug)
		select ds.furn_benef,ds.subunitate,ds.tert,ds.factura,ds.tip,ds.numar,ds.data,ds.valoare,ds.tva,
		round(convert(decimal(17,5),ds.achitat*isnull(nb.ratie,1)),2),
		ds.valuta,ds.curs,ds.total_valuta,ds.achitat_valuta,ds.loc_de_munca,left(ds.comanda,20)+isnull(left(nb.indbug,20),''),ds.cont_de_tert,ds.fel,ds.cont_coresp,ds.explicatii,ds.numar_pozitie,
		ds.gestiune,ds.data_facturii,ds.data_scadentei,ds.nr_dvi,ds.barcod,ds.contTVA,ds.cod,ds.cantitate,ds.contract,ds.efect,ds.idPozitieDoc,ds.tabela,
		isnull(nb.indbug,'')
		from #desters ds
		--de vazut daca apar probleme pentru facturi cu valf<0. Am pus sa ia in calcul si pozitiile cu valf<0 pentru cazul compensarilor.
		left join #nebugr nb on nb.furn_benef=ds.furn_benef and nb.tert=ds.tert and nb.factura=ds.factura and (ratie<>1 or valf<>0)	

		/* reglare diferente rezultate din repartizare pe indicatori */
		--	tabela temporara cu sumele repartizate pe indicatori, centralizate pe furn_benef,tert,factura,idPozitieDoc
		select df.furn_benef,df.tert,df.factura,df.tabela,df.idPozitieDoc,sum(df.achitat) as achitat 
		into #docfacrep	
		from #docfac df
		inner join #nebug n on n.furn_benef=df.furn_benef and n.tert=df.tert and n.factura=df.factura and n.tabela=df.tabela and n.idPozitieDoc=df.idPozitieDoc	
		group by df.furn_benef,df.tert,df.factura,df.tabela,df.idPozitieDoc

		--	tabela temporara cu sumele dinainte de repartizarea pe indicatori, centralizate pe furn_benef,tert,factura,idPozitieDoc
		select furn_benef,tert,factura,tabela,idPozitieDoc,sum(achitat) as achitat
		into #docfacnerep
		from #nebug
		group by furn_benef,tert,factura,tabela,idPozitieDoc

		--	tabela temporara care indica pozitiile pe care se va face reglarea
		select furn_benef,tert,factura,tabela,idPozitieDoc,pozitie
		into #docfacDeReglat
		from 
			(select df.furn_benef,df.tert,df.factura,df.tabela,df.idPozitieDoc,df.pozitie,
				ROW_NUMBER() over (partition by df.furn_benef,df.tert,df.factura,df.tabela,df.idPozitieDoc order by df.Achitat Desc) as ordine 
			from #docfac df
			inner join #nebug n on n.furn_benef=df.furn_benef and n.tert=df.tert and n.factura=df.factura and n.tabela=df.tabela and n.idPozitieDoc=df.idPozitieDoc) a
		where Ordine=1

		/* calculez diferentele separat pentru a functiona mai rapid update-ul */
		select dr.furn_benef,dr.tert,dr.factura,dr.tabela,dr.idPozitieDoc,dr.pozitie,isnull(n.Achitat,0)-isnull(r.Achitat,0) as diferenta
		into #diferente
		from #docfacDeReglat dr
			inner join #docfacnerep n on n.furn_benef=dr.furn_benef and n.tert=dr.tert and n.factura=dr.factura and n.tabela=dr.tabela and n.idPozitieDoc=dr.idPozitieDoc	
			inner join #docfacrep r on r.furn_benef=dr.furn_benef and r.tert=dr.tert and r.factura=dr.factura and r.tabela=dr.tabela and r.idPozitieDoc=dr.idPozitieDoc

		update df set df.Achitat=df.Achitat+isnull(dr.diferenta,0)
		from #docfac df
			inner join #diferente dr on dr.pozitie=df.pozitie
			
		--> filtrarea pe indicator:
		if @indicator is not null
			delete #docfac where indbug not like @indicator
		--> filtrarea pe loc de munca bugetari:
		if @locm<>'%'
			delete #docfac where loc_de_munca not like @locm
	end

/*	apelare procedura pentru completare cont TVA. Contul de TVA nu se mai stocheaza in tabelele de documente. */
	if @prelContTVA=1
	begin
		select tip as tip,(case when @FurnBenef<>'' then @FurnBenef else (case when tip in ('RM','RS','FF','SF') then 'F' else 'B' end) end) tipf,tert,factura,tabela,idPozitieDoc,'' as tip_tva,conttva,convert(varchar(100),'') as sursaf
		into #contTVAPozitieDoc
		from #docfac
		where tip in ('RM','RS','AP','AS','FF','SF','FB','IF')

		declare @parXMLTva xml
		select @parXMLTva=(select @furnbenef as furnbenef, @dDataJos datajos, @dDataSus datasus, 
			1 dinpfacturi	--> "dinpfacturi" pentru a se evita apelul recursiv al pFacturi - genereaza eroare datorita tabelelor temporare folosite
			for xml raw)
		exec contTVAPozDocument @sesiune=null, @parXML=@parXMLTva

		update df set df.contTVA=ctva.contTVA
		from #docfac df 
			inner join #contTVAPozitieDoc ctva on ctva.tabela=df.tabela and ctva.idPozitieDoc=df.idPozitieDoc
	end

	--> modificare inregistrari cu efecte incasate:
	if @efecteAchitate>0
		update d set achitare_efect_in_curs=d.achitat
		from #docfac d 
			inner join conturi c on d.cont_coresp=c.cont and c.sold_credit='8'
			inner join efecte e on e.subunitate='1' and d.tert=e.tert and d.efect=e.nr_efect and e.tip='I'
				and (e.data_decontarii<@dDataSus and abs(e.sold)>0.01 or e.data_decontarii>@dDataSus or e.Valoare=0)
		where fel='3'-- and (e.sold=0 or e.valoare=0)

/*	if @q_cuFltLocmStilVechi=1
		delete ft
			from #docfac ft 
			left outer join facturi f on f.subunitate=ft.subunitate and f.tert=ft.tert and f.factura=ft.factura and ft.furn_benef=(case when f.tip=0x54 then 'F' else 'B' end)
			where f.loc_de_munca not like @locmV
*/
	if @ContFactura<>''
		delete #docfac where cont_de_tert not in (select cont from dbo.arbConturi(@ContFactura))

	if @SoldMin <> 0 
		delete #docfac 
		from (select furn_benef as ffurn_benef, tert as ttert, factura as ffactura, sum(isnull(achitare_efect_in_curs,0)) achitare_efect_in_curs, rtrim(max(isnull(efect,''))) efect from #docfac 
			group by furn_benef, tert, factura 
			having abs(sum(round(convert(decimal(17,5), valoare), 2) + round(convert(decimal(17,5), tva), 2) - round(convert(decimal(17,5), achitat), 2))) < @SoldMin 
				or sign(sum(round(convert(decimal(17,5), valoare), 2) + round(convert(decimal(17,5), tva), 2) - round(convert(decimal(17,5), achitat), 2)))*@SemnSold < 0
			) a 
		where furn_benef=a.ffurn_benef and tert=a.ttert and factura=a.ffactura
			--> daca se tine cont de achitare prin efecte: se verifica existenta efectului de incasare si liniile cu efecte neincasate:
			and (@efecteAchitate=0 or @efecteAchitate=1 and abs(a.achitare_efect_in_curs)<0.001)

	update #docfac
	set valuta='', curs=0, total_valuta=0, achitat_valuta=0
	from #docfac d 
	where not exists (select 1 from terti t where t.subunitate=@Subunitate and d.tert=t.tert and t.tert_extern=1)
		or @IFN=1 and d.furn_benef='B' and abs(d.total_valuta)<0.01 and abs(d.achitat_valuta)<0.01

	if exists (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'pFacturiSP2') AND type='P')
		exec pFacturiSP2 @sesiune=@sesiune, @parXML=@parXML

	/*	@cen=1 <- vechea functie fFacturiCen */
	if @cen=1
	begin
		if @GrTert is null set @GrTert = 1
		if @GrFact is null set @GrFact = 1

		select furn_benef,subunitate,tert,factura,tip,numar,data,valoare,tva
			,(case when abs(achitare_efect_in_curs)>0 and achitat>0 then 0 else achitat end) achitat--> daca se tine cont de achitarea efectelor, un efect neachitat determina ca factura sa fie considerata neachitata
			,valuta,curs,total_valuta,achitat_valuta,
			loc_de_munca,comanda,cont_de_tert,fel,cont_coresp,explicatii,numar_pozitie,gestiune,data_facturii,data_scadentei,
			nr_dvi,pozitie,
			subunitate+furn_benef+tert+factura as grp,
			(case when determinant=1 then '0' when tip in ('SI','AP','AS','RM','RS','RP','RQ','SF','IF') then '1' when tip in ('FF','FB') then '2' else '3' end)
				+convert(char(8),99999999-convert(int,convert(char(8),data,112)))+str(numar_pozitie) as ordine,
			(case when valuta<>'' and curs<>0 then '2' when valuta<>'' then '1' else '0' end)
				+(case when tip in ('SI','AP','AS','RM','RP','RQ','RS','SF','IF') then '1' when tip in ('FF','FB') then '2' else '0' end)
				+convert(char(8),data,112)+str(numar_pozitie) as ordine_valuta,
			convert(datetime,'01/01/2999',101) as dataFact, convert(datetime,'01/01/2999',101) as dataScadFact, space(40) as contFact, 
			space(3) as valutaFact, convert(float,0) as cursFact, space(13) as lmFact, space(40) as comFact, data_platii--, contract
		into #tmpdocfac
		from #docfac

		-- data, data scadentei, valuta, curs, loc munca: se iau in functie de tip doc, data si numar pozitie
		-- mai sus au fost initializate cu valori implicite 
		-- mai jos se vor inlocui aceste valori pe pozitiile care dau valoare finala (ex. RM da locul de munca, indiferent de loc m. de pe PF)
		update d
		set 
			dataFact=(case when d.ordine=d1.ordine then d.data_facturii else d.dataFact end), 
			dataScadFact=(case when d.ordine=d1.ordine then d.data_scadentei else d.dataScadFact end),
			contFact=(case when d.ordine=d1.ordine then d.cont_de_tert else d.contFact end), 
			valutaFact=(case when d.ordine_valuta=d1.ordine_valuta then d.valuta else d.valutaFact end), 
			cursFact=(case when d.ordine_valuta=d1.ordine_valuta then d.curs else d.cursFact end),
			lmFact=(case when d.ordine=d1.ordine then d.loc_de_munca else d.lmFact end),
			comFact=(case when d.ordine=d1.ordine then d.comanda else d.comFact end)
			/* tratat mai jos ca achitarile cu minus (stornari de avans) sa nu afecteze ordinea, pentru a nu duce in factura cursul de pe stornare */
		from #tmpdocfac d, (select d2.grp, min(d2.ordine) as ordine, max(case when d2.Achitat<0 and isnull(d2.tip,'')<>'SI' then '' else d2.ordine_valuta end) as ordine_valuta from #tmpdocfac d2 group by d2.grp) d1
		where d.grp=d1.grp and (d.ordine=d1.ordine or d.ordine_valuta=d1.ordine_valuta)

		/* Am tratat aici cazul achitarilor cu minus pentru AX,RX care nu au document initial (Avansul). */
		update a set a.valutaFact = a.valuta, a.cursFact = a.curs
		from #tmpdocfac a join terti b on a.subunitate=b.subunitate and a.tert = b.Tert
		where a.Tip in ('AX','RX','PF') and a.valutaFact='' and a.cursFact = 0 and b.Tert_extern=1 and a.valuta<>'' 
		and a.achitat_valuta<0 
		and not exists (Select 1 from #tmpdocfac x where (a.tip = x.tip or x.tip='SI') and a.Tert = x.Tert and a.factura = x.factura and x.Achitat_valuta>0)

		if exists (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'pFacturiCenSP') AND type='P')
			exec pFacturiCenSP @sesiune=@sesiune, @parXML=@parXML

		if OBJECT_ID('tempdb..#pfacturi') is null
		begin
			create table #pfacturi (subunitate varchar(9))
			exec CreazaDiezFacturi @numeTabela='#pfacturi'
		end

		insert into #pfacturi
		select
			subunitate, max(lmFact) loc_de_munca, (case when furn_benef='B' then 0x46 else 0x54 end) tip,
			max(case when @GrFact=1 then factura else '' end) factura,
			max(case when @GrTert=1 then tert else '' end) tert,
			min(dataFact) data, min(dataScadFact) data_scadentei,
			sum(round(convert(decimal(17,5), valoare), 2)) valoare,
			sum(round(convert(decimal(17,5), tva), 2)) tva,
			max(valutaFact) valuta, max(cursFact) curs,
			sum(round(convert(decimal(17,5), total_valuta), 2)) valoare_valuta,
			sum(round(convert(decimal(17,5), achitat), 2)) achitat,
			sum(round(convert(decimal(17,5), valoare), 2)+round(convert(decimal(17,5), tva), 2)-round(convert(decimal(17,5), achitat), 2)) sold,			
			max(contFact) cont_factura,
			sum(round(convert(decimal(17,5), achitat_valuta), 2)) achitat_valuta,
			sum(round(convert(decimal(17,5), total_valuta), 2)-round(convert(decimal(17,5), achitat_valuta), 2)) sold_valuta,
			max(isnull(isnull(comFact,comanda),'')) comanda, max(case when abs(achitat)>=0.01 or abs(achitat_valuta)>=0.01 then data else '01/01/1901' end) data_ultimei_achitari,
			sum(round(convert(decimal(17,5), (case when data>=@dDataJos and data<=@ddatasus then achitat else 0 end)), 2)) achitat_interval ,
			sum(round(convert(decimal(17,5), (case when isnull(data_platii,data)>=@dDataJos and isnull(data_platii,data)<=@ddatasus then achitat else 0 end)), 2)) achitat_interval_plata,
			max(explicatii)
			--,max(contract) contract
		from #tmpdocfac
		group by subunitate, furn_benef,
			(case when @GrFact=1 then factura else '' end),
			(case when @GrTert=1 then tert else '' end),
			(case when @GrCont=1 then cont_de_tert else '' end)

		if exists (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'pFacturiCenSP1') AND type='P')
			exec pFacturiCenSP1 @sesiune=@sesiune, @parXML=@parXML
	end
	else 
	Begin
		if object_id('tempdb..#docfacturi') is null 
		begin
			create table #docfacturi (furn_benef char(1))
			exec CreazaDiezFacturi @numeTabela='#docfacturi'
		end
			--> un picut de sql dinamic sa centralizeze/condenseze datele, daca se cere dinspre apelant (experiment, atata timp cat @grupare e null va merge ca pana acum):
		declare @comanda_sql nvarchar(max)
			--> varianta necentralizata (cea default, pe care functioneaza ca si pana acum):
		if @grupare=''
		select @comanda_sql='
		insert into #docfacturi
		select furn_benef, subunitate, tert, factura, tip, numar, data, valoare, tva, achitat, valuta, curs, total_valuta, achitat_valuta, loc_de_munca, comanda, cont_de_tert, 
			fel, cont_coresp, explicatii, numar_pozitie, gestiune, data_facturii, data_scadentei, nr_dvi, barcod, contTVA, cod, cantitate, contract, efect, pozitie,
			data_platii, punct_livrare, achitare_efect_in_curs,tabela,indbug
		from #docfac'
		else
			--> experimentul:
		select @comanda_sql='
		insert into #docfacturi
		select max(furn_benef), max(subunitate), max(tert), max(factura), max(tip), max(numar), max(data), sum(valoare), sum(tva), sum(achitat), max(valuta), avg(curs), sum(total_valuta), sum(achitat_valuta),
			max(loc_de_munca), max(comanda), max(cont_de_tert),
			max(fel), max(cont_coresp), max(explicatii), max(numar_pozitie), max(gestiune), max(data_facturii), max(data_scadentei), max(nr_dvi), max(barcod), max(contTVA), max(cod),
			sum(cantitate), max(contract), max(efect), max(pozitie),
			max(data_platii), max(punct_livrare), sum(achitare_efect_in_curs), max(tabela), max(indbug)
		from #docfac
		group by '+@grupare
		exec (@comanda_sql)
	End

end try

begin catch
	declare @mesaj varchar(2000)
	set @mesaj = ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 11, 1)
end catch