if exists (select * from sysobjects where name ='wOPGenerareUnAPdinBKSP')
drop procedure wOPGenerareUnAPdinBKSP
go
--***
create procedure wOPGenerareUnAPdinBKSP @sesiune varchar(50), @parXML xml OUTPUT
as

declare 
	/*date de identificare BK:*/
	@sub varchar(9),@tip varchar(2),@data datetime,@contract varchar(20),@tert varchar(20), @beneficiar varchar(20),
	
	/*parametrii de expeditie:*/ 
	@numedelegat varchar(30),@mijloctp varchar(30),@nrmijtransp varchar(20),@seriebuletin varchar(10),
	@numarbuletin varchar(10),@eliberatbuletin varchar(30),
	@iddelegat varchar(20), @prenumedelegat varchar(30), @ptupdate bit, @delegat varchar(30), 
	@data_expedierii datetime, @ora_expedierii varchar(6),@observatii varchar(200),
	
	/*parametri pt generare document nou:*/ 
	@numarDoc varchar(13),@dataDoc datetime,@tipDoc varchar(2),
	
	/*alte variabile necesare:*/
	@utilizator varchar(20),@lm varchar(13),@gestTr varchar(13),@dinmobile int,@faraMesaje int,
	@input xml,@eroare varchar(250),@gestDest varchar(13),@gestprim varchar(20),@categPret int,@gestiune varchar(13),@valuta varchar(3),@curs float,@iDoc int
	, @zilescadenta int,@punct_livrare varchar(13),@stare int,@aviznefacturat bit
	, @nrformular varchar(10),@modPlata varchar(50), @explicatii varchar(100)
begin try
--/*sp
	declare @procid int=@@procid, @objname sysname
	set @objname=object_name(@procid)
	EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
--sp*/
	select
		--date pt identificare BK din care se genereaza AP
		@tip=ISNULL(@parXML.value('(/*/@tip)[1]', 'varchar(2)'), ''),
		@data=ISNULL(@parXML.value('(/*/@data)[1]', 'datetime'), ''),
		@contract=ISNULL(@parXML.value('(/*/@numar)[1]', 'varchar(20)'), ''),
		@tert=ISNULL(@parXML.value('(/*/@tert)[1]', 'varchar(20)'), ''),
		@beneficiar=ISNULL(@parXML.value('(/*/@beneficiar)[1]', 'varchar(20)'), ''),
		@gestprim=ISNULL(@parXML.value('(/row/@gestprim)[1]', 'varchar(13)'), ''),
		
		--date pentru expeditie
		@iddelegat=upper(ISNULL(@parXML.value('(/*/@iddelegat)[1]', 'varchar(20)'), '')),
		@numedelegat=upper(ISNULL(@parXML.value('(/*/@numedelegat)[1]', 'varchar(20)'), '')),		
		@prenumedelegat=upper(ISNULL(@parXML.value('(/*/@prenumedelegat)[1]', 'varchar(30)'), '')),		
		@nrmijtransp=upper(ISNULL(@parXML.value('(/*/@nrmijltransp)[1]', 'varchar(10)'), '')),		
		@mijloctp=ISNULL(@parXML.value('(/*/@mijloctp)[1]', 'varchar(30)'), ''),
		@seriebuletin=upper(ISNULL(@parXML.value('(/*/@seriebuletin)[1]', 'varchar(10)'), '')),		
		@numarbuletin=upper(ISNULL(@parXML.value('(/*/@numarbuletin)[1]', 'varchar(10)'), '')),		
		@eliberatbuletin=upper(ISNULL(@parXML.value('(/*/@eliberatbuletin)[1]', 'varchar(30)'), '')),
		@ora_expedierii= replace(left(isnull(@parXML.value('(/*/@ora_expedierii)[1]','varchar(10)'),convert(varchar,getdate(),114)),8),':',''),
		@data_expedierii= isnull(@parXML.value('(/*/@data_expedierii)[1]','datetime'),GETDATE()),
		@observatii=upper(ISNULL(@parXML.value('(/*/@observatii)[1]', 'varchar(50)'), '')),
		
		--date necesare pt. generare factura
		@tipDoc='AP',@dataDoc=ISNULL(@parXML.value('(/*/@datadoc)[1]', 'datetime'), ''),
		@numarDoc=ISNULL(@parXML.value('(/*/@numardoc)[1]', 'varchar(13)'), ''),
		@stare=upper(ISNULL(@parXML.value('(/*/@stare)[1]', 'int'), 0)),
		@aviznefacturat=ISNULL(@parXML.value('(/*/@aviznefacturat)[1]', 'bit'), 0),
		
		--alte date necesare
		@dinmobile=upper(ISNULL(@parXML.value('(/*/@dinmobile)[1]', 'int'),0)),
		@faraMesaje=ISNULL(@parXML.value('(/*/@faramesaje)[1]', 'bit'), 0) -- flag folosit daca nu vrem afisarea de mesaje din procedura
		,@modPlata=ISNULL(@parXML.value('(/*/@modPlata)[1]', 'varchar(50)'), '')
		,@nrformular=upper(ISNULL(@parXML.value('(/*/@nrformular)[1]', 'varchar(10)'), ''))
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output --> citire subunitate din proprietati       
  
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output-->identificare utilizator pe baza sesiunii

	if ISNULL(@beneficiar,'')=''
		raiserror( '    Pentru facturare, pe comanda de livrare trebuie sa fie definit beneficiarul!',11,1)	

	--citire date din gridul de operatii
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlPozitiiFactura') IS NOT NULL
		drop table #xmlPozitiiFactura
		
	select cod, gestiune, cantitate_factura, cantitate_disponibila, cant_aprobata, cant_realizata, subunitate, tip, data, contract, tert, numar_pozitie,
		gest_antet
	into #xmlPozitiiFactura
	from OPENXML(@iDoc, '/*/DateGrid/row')
	WITH
	(
		gest_antet varchar(20) '../../@gestiune',
		
		cod varchar(20) '@cod',
		gestiune varchar(20) '@gestiune',
		cantitate_factura float '@cantitate_factura',
		cantitate_disponibila float '@cantitate_disponibila',
		cant_aprobata float '@cant_aprobata',
		cant_realizata float '@cant_realizata',
		subunitate varchar(13) '@subunitate',
		tip varchar(2) '@tip',
		data datetime '@data',
		contract varchar(20) '@contract',
		tert varchar(13) '@tert',
		numar_pozitie int '@numar_pozitie'
	)
	exec sp_xml_removedocument @iDoc 	
	
	if exists (select 1 from #xmlPozitiiFactura where cantitate_factura>cantitate_disponibila) and @dinmobile<>1
		raiserror('Nu se pot factura cantitati mai mari decat cantitatile disponibile! Verificati cantitatile de facturat introduse!',11,1)
		
	IF NOT EXISTS (SELECT 1 FROM #xmlPozitiiFactura where abs(cantitate_factura) > 0.001) -- se pot factura si cantitati negative...
		RAISERROR ('Nu exista pozitii cu cantitate nenula pentru care sa fie generata factura!', 11, 1)
	
	if exists (select top (1) 1 from pozcon p inner join #xmlPozitiiFactura x on x.subunitate=p.Subunitate and x.tip=p.Tip and x.contract=p.Contract 
		and x.data=p.Data and x.tert=p.Tert and x.cod=p.Cod and x.numar_pozitie=p.Numar_pozitie
		and p.Pret<0.01)
		RAISERROR ('Exista pozitii fara pret pentru care nu poate sa fie generata factura!', 11, 1)
	
	--if exists (select top (1) 1 from pozcon p inner join #xmlPozitiiFactura x on x.subunitate=p.Subunitate and x.tip=p.Tip and x.contract=p.Contract 
	--	and x.data=p.Data and x.tert=p.Tert and x.cod=p.Cod and x.numar_pozitie=p.Numar_pozitie)
	--	RAISERROR ('Exista pozitii cu discount pentru care nu poate sa fie generata factura!', 11, 1)

	declare @codstocinsuficient varchar(20), @stocinsuficient float, @msgErr nvarchar(2048)
			,@lRezStocBK bit, @cListaGestRezStocBK CHAR(200)
	EXEC luare_date_par @tip='GE', @par='REZSTOCBK', @val_l=@lRezStocBK OUTPUT, @val_n=0, @val_a=@cListaGestRezStocBK OUTPUT

	select @msgErr=isnull(@msgErr+CHAR(13),'')+RTRIM(max(n.denumire))+' ('+RTRIM(p.Cod)+')'
			+', lipsa: '+ rtrim(CONVERT(decimal(10,2),MAX(isnull(x.cantitate_factura,p.Cantitate))-SUM(isnull(s.Stoc,0))))
	FROM pozcon p 
		inner join con c on c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert and c.Data=p.Data
		inner join #xmlPozitiiFactura x on x.subunitate=p.Subunitate and x.tip=p.Tip and x.contract=p.Contract 
						and x.data=p.Data and x.tert=p.Tert and x.cod=p.Cod and x.numar_pozitie=p.Numar_pozitie 
		left join nomencl n on n.Cod=p.Cod
		left JOIN stocuri s 
			ON p.Subunitate=s.Subunitate and p.Cod=s.Cod and s.Stoc>=0.001 
				and s.Cod_gestiune=isnull(x.gest_antet,x.gestiune)
	WHERE p.Subunitate=@Sub and p.Tip='BK' and p.Contract=@contract and p.Data=@data and p.Tert=@beneficiar
		AND n.Tip<>'S'
		AND (s.Stoc is null 
			or s.Tip_gestiune NOT IN ('F','T') and (s.contract=p.contract 
				or s.contract<>p.contract 
					and (@lRezStocBK=0 or CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(@cListaGestRezStocBK)+';')<=0)))
	GROUP BY p.Cod
	having SUM(isnull(s.Stoc,0))<MAX(isnull(x.cantitate_factura,p.Cantitate))-max(p.Cant_realizata)
	
	if len(@msgErr)>0
	begin
		set @msgErr='Stoc insuficient la articolele: '++CHAR(13)+@msgErr	
		raiserror(@msgErr,16,1)
	end
	
	declare @valFactura float=0, @soldmaxim float, @sold float, @zileScadDepasite bit
	
	select	@valFactura = 
		sum(round(round(convert(decimal(17,5),p.pret*(1-p.discount/100)*(1-isnull(pe.pret,0)/100)*(1-isnull(pe.cantitate,0)/100))
		*(1+(p.cota_tva-case when isnull(gp.tip_gestiune,'') in ('A','V') then p.cota_tva else 0 end)/100),2)
		*(p.Cantitate-(case when @tip='TE' then p.Pret_promotional else p.cant_realizata end)),2))
	from pozcon p 
		left outer join pozcon pe on pe.Subunitate='EXPAND' and pe.Tip=p.Tip and pe.Contract=p.Contract 
			and pe.Tert=p.Tert and pe.Data=p.Data and pe.Cod=p.Cod      
		--inner join #xmlPozitiiFactura x on x.subunitate=p.Subunitate and x.tip=p.Tip and x.contract=p.Contrac and x.data=p.Data and x.tert=p.Tert and x.cod=p.Cod and x.numar_pozitie=p.Numar_pozitie	
		left outer join gestiuni gp on gp.cod_gestiune = p.Punct_livrare
	where p.Subunitate=@sub and p.Tip='BK' and p.Contract=@contract and p.Data=@data and p.Tert=@beneficiar 
	
	if @valFactura > 0.001
		and isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='BLOCTERT'),0)=1
	begin
		IF OBJECT_ID('tempdb.dbo.#validSold') IS NOT NULL
			DROP TABLE #validSold	
				
		select @beneficiar tert, @valFactura valoare, 0 sold, 0 sold_max
		into #validSold

		exec validSoldTert		
		--declare @xml xml
		--set @xml=(select @beneficiar tert for xml raw)
		--exec wIaSoldTert @sesiune='', @parXML=@xml output
		
		---- procedura returneaza null daca nu trebuie validat soldul
		--if @xml is not null
		--begin 
		--	select	@sold=@xml.value('(/row/@sold)[1]','float'),
		--			@soldmaxim=@xml.value('(/row/@soldmaxim)[1]','float'),
		--			@zileScadDepasite= @xml.value('(/row/@zilescadentadepasite)[1]','bit')
			
		--	if @zileScadDepasite=1
		--		set @msgErr = isnull(@msgErr+CHAR(13),'')+'Tertul are facturi cu scadenta depasita.'
			
		--	if @xml.value('(/row/@soldmaxim)[1]','float') is not null and @sold+@valFactura>@soldmaxim
		--		set @msgErr = isnull(@msgErr+CHAR(13),'')+'Generarea facturii ar cauza depasirea soldului maxim pentru acest tert.'
		--			+CHAR(13)+ 'Soldul maxim permis este '+ CONVERT(varchar(30), convert(decimal(12,2), @soldmaxim)) + ' RON.'
		--			+CHAR(13)+ 'Soldul anterior este '+ CONVERT(varchar(30), convert(decimal(12,2), @sold)) + ' RON.'
		--			+CHAR(13)+ 'Valoarea pozitiei (modificarii) curente '+ CONVERT(varchar(30), convert(decimal(12,2), @valFactura)) + ' RON.'
			
		--	if len(@msgErr)>0
		--	begin
		--		raiserror(@msgErr,11,1)
		--	end
		--end
	end

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRAN wOPGenerareUnAPdinBKSP
	
	if isnull(@numarDoc,'')=''--daca nu s-a introdus numar pt TE se ia urmatorul numar din plaja
	begin 
		declare @fXML xml, @NrDocFisc varchar(10),@tipPentruNr varchar(2)
		set @tipPentruNr=@tipDoc
		if @aviznefacturat=1
			set @tipPentruNr='AN' 
			
		set @fXML = '<row/>'
		set @fXML.modify ('insert attribute tipmacheta {"O"} into (/row)[1]')
		set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
		set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
		exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocFisc output
		set @numarDoc=@NrDocFisc
	end
	
	--parcurgere con pentru a lua date necesare de pe BK 
	select top (1) --@gestiune=RTRIM(c.gestiune),
		--@categPret=c.Dobanda,
		-->loc de munca: locul de munca din proprietati pe utilizator, altfel locul de munca al gestiunii, altfel loc de munca de pe BK
		@lm=rtrim(c.Loc_de_munca),
		@zilescadenta=nullif(c.scadenta,0),
		@punct_livrare=c.Punct_livrare,
		@valuta=rtrim(c.valuta),
		@curs= c.curs					
		,@explicatii=RTRIM(c.Explicatii)
	from con c where c.Subunitate=@sub and c.Tip='BK' and c.Data=@data and c.Contract=@contract and c.Tert=@beneficiar
	  
	if @zilescadenta is null 
		set @zilescadenta=isnull((select convert(int, isnull(it.discount, 0)) 
		from terti t inner join infotert it on it.subunitate=t.subunitate and it.tert=t.tert and it.identificator='' 
		where t.Subunitate=@sub and t.tert=@beneficiar),0)
	
	--formare XML pentru apelare wScriuPozdoc    						
	set @input=
		(select rtrim(@sub) as '@subunitate', 'AP' as '@tip', rtrim(@beneficiar) as '@tert',
			rtrim(@numarDoc) as '@numar', convert(varchar(20),@datadoc,101) as '@data', @categpret as '@categpret',
			@lm as '@lm'
			--, @gestiune '@gestiune'
			, rtrim(@contract) as '@contract',
			@zilescadenta as '@zilescadenta', DATEADD(day,@zilescadenta,@datadoc) as '@datascadentei'
			, rtrim(@punct_livrare) as '@punctlivrare',
			@aviznefacturat as '@aviznefacturat', 
			detalii=(select modPlata=@modPlata, explicatii=@explicatii for xml raw, type),
			--date pentru pozitiile de AP
			(select convert(varchar(20),p.pret) as '@pvaluta', rtrim(@valuta) as '@valuta',convert(varchar(20),@curs) as '@curs',
					CONVERT(decimal(5,2),p.Discount) as '@discount', @lm as '@lm', ISNULL(x.gest_antet, x.gestiune) as '@gestiune',
					rtrim(p.cod) as '@cod', 
					rtrim(isnull(x.cantitate_factura,(p.cantitate-p.cant_realizata))) as '@cantitate', @contract as '@contract'
					,detalii=(select explicatii=RTRIM(p.Explicatii) for xml raw, type)
				from pozcon p 
					inner join #xmlPozitiiFactura x on x.subunitate=p.Subunitate and x.tip=p.Tip and x.contract=p.Contract 
						and x.data=p.Data and x.tert=p.Tert and x.cod=p.Cod and x.numar_pozitie=p.Numar_pozitie 
				where p.Subunitate=@sub and p.tip='BK' 
					and p.data=@data 
					and p.contract=@contract 
					and p.tert=@tert
					and abs(p.cantitate-p.cant_realizata)>0.001
					and (x.cantitate_factura is null or abs(x.cantitate_factura)>0.001)
			for xml PATH, TYPE)
		for XML PATH, type)	

	if exists (select * from sysobjects where name ='wScriuDoc')
		exec wScriuDoc @sesiune=@sesiune, @parXML=@input OUTPUT
	else 
	if exists (select * from sysobjects where name ='wScriuDocBeta')
		exec wScriuDocBeta @sesiune=@sesiune, @parXML=@input OUTPUT
	else 
		raiserror('Eroare configurare: aceasta procedura necesita folosirea procedurii wScriuDoc(beta).', 16, 1)

	exec ProcGenAPBK 'AP',@numarDoc,@datadoc
	
	-->daca s-a generat factura => comanda de livrare se trece in starea "Facturat", afisam mesaj de finalizare operatie cu succes	
	if exists (select 1 from pozdoc where subunitate='1' and tip='AP' and data=@dataDoc and Numar=@numarDoc and tert=@beneficiar)
	begin
		if @parXML.value('(/*/@numardoc)[1]','varchar(20)') is null
			set @parxml.modify ('insert attribute numardoc {sql:variable("@numardoc")} into (/*)[1]')
		else
			set @parXML.modify('replace value of (/*/@numardoc)[1] with sql:variable("@numardoc")')

		if @parXML.value('(/*/@tipdoc)[1]','varchar(2)') is null
			set @parxml.modify ('insert attribute tipdoc {sql:variable("@tipdoc")} into (/*)[1]')
		else
			set @parXML.modify('replace value of (/*/@tipdoc)[1] with sql:variable("@tipdoc")')

		exec yso_salvezExpedGenDoc @sesiune, @parXML OUTPUT
		
		update c set factura=@numarDoc from con c where c.Subunitate=@sub and c.Tip=@tip and c.Data=@data and c.Contract=@contract and c.Tert=@tert
		COMMIT TRAN wOPGenerareUnAPdinBKSP
		
		if @nrformular<>'' and @@TRANCOUNT<=0
		begin
			declare @paramXmlString xml 
			set @paramXmlString= (select 'AP' as tip, @nrformular as nrform, @beneficiar as tert, rtrim(@numarDoc) as numar, 
					rtrim(@numarDoc) as factura, @dataDoc as data for xml raw )
			exec wTipFormular @sesiune, @paramXmlString
		end
		else 
			if @faraMesaje!=1
				select 'S-a generat cu succes factura cu numarul '+rtrim(@numarDoc)+' din data de  '+ltrim(convert(varchar(20),@dataDoc,103)) as textMesaj for xml raw, root('Mesaje') 
	end
	else -->nu s-a generat factura, se returneaza mesaj corespunzator
	begin
		ROLLBACK TRAN wOPGenerareUnAPdinBKSP
		if @faraMesaje!=1
			select 'Verificati datele, nu a fost generata factura!' as textMesaj for xml raw, root('Mesaje')
	end
	
	--delete from pozdoc where subunitate='1' and tip='AP' and data=@dataDoc and Numar=@numarDoc and tert=@tert

	begin try 
		if OBJECT_ID('#xmlPozitiiFactura') is not null
			drop table #xmlPozitiiFactura
	end try 
	begin catch end catch   
end try 
begin catch 
	IF EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'wOPGenerareUnAPdinBKSP')            
		ROLLBACK TRANSACTION wOPGenerareUnAPdinBKSP
	set @eroare='(wOPGenerareUnAPdinBKSP): '+ERROR_MESSAGE() 
	raiserror(@eroare, 16, 1)
end catch 
