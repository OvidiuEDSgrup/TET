--***
create procedure wOPGenerareUnTEdinBKSP @sesiune varchar(50), @parXML xml OUTPUT
as

declare 
	/*date de identificare BK:*/
	@sub varchar(9),@tip varchar(2),@data datetime,@contract varchar(20),@tert varchar(13),
	
	/*parametrii de expeditie:*/ 
	@numedelegat varchar(30),@mijloctp varchar(30),@nrmijtransp varchar(20),@seriebuletin varchar(10),
	@numarbuletin varchar(10),@eliberatbuletin varchar(30),
	@iddelegat varchar(20), @prenumedelegat varchar(30), @ptupdate bit, @delegat varchar(30),
	@data_expedierii datetime, @ora_expedierii varchar(6),@observatii varchar(200),
	
	/*parametri pt generare document nou:*/ 
	@numarDoc varchar(13),@dataDoc datetime,@tipDoc varchar(2),
	
	/*alte variabile necesare:*/
	@utilizator varchar(20),@lm varchar(13),@gestTr varchar(13),@dinmobile int,@faraMesaje int,
	@input xml,@eroare varchar(250),@gestDest varchar(13),@gestPrim varchar(20),@categPret int,@gestiune varchar(13),@valuta varchar(3),@curs float,@iDoc int
	, @zilescadenta int,@punct_livrare varchar(13),@stare int,@aviznefacturat bit
	, @nrformular varchar(10),@modplata varchar(50), @custodie int
begin try
--/*sp
	declare @procid int=@@procid, @objname sysname
	set @objname=object_name(@procid)
	EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
--sp*/
	select
		--date pt identificare BK din care se genereaza TE 
		@tip=ISNULL(@parXML.value('(/*/@tip)[1]', 'varchar(2)'), ''),
		@data=ISNULL(@parXML.value('(/*/@data)[1]', 'datetime'), ''),
		@contract=ISNULL(@parXML.value('(/*/@numar)[1]', 'varchar(20)'), ''),
		@tert=ISNULL(@parXML.value('(/*/@tert)[1]', 'varchar(13)'), ''),
		@gestprim=ISNULL(@parXML.value('(/row/@gestprim)[1]', 'varchar(13)'), ''),
		
		--date pentru expeditie
		@iddelegat=upper(ISNULL(@parXML.value('(/*/@iddelegat)[1]', 'varchar(20)'), '')),
		@numedelegat=upper(ISNULL(@parXML.value('(/*/@numedelegat)[1]', 'varchar(30)'), '')),		
		@prenumedelegat=upper(ISNULL(@parXML.value('(/*/@prenumedelegat)[1]', 'varchar(30)'), '')),		
		@nrmijtransp=upper(ISNULL(@parXML.value('(/*/@nrmijltransp)[1]', 'varchar(20)'), '')),
		@mijloctp=ISNULL(@parXML.value('(/*/@mijloctp)[1]', 'varchar(30)'), ''),		
		@seriebuletin=upper(ISNULL(@parXML.value('(/*/@seriebuletin)[1]', 'varchar(10)'), '')),		
		@numarbuletin=upper(ISNULL(@parXML.value('(/*/@numarbuletin)[1]', 'varchar(10)'), '')),		
		@eliberatbuletin=upper(ISNULL(@parXML.value('(/*/@eliberatbuletin)[1]', 'varchar(30)'), '')),
		@ora_expedierii= replace(left(isnull(@parXML.value('(/*/@ora_expedierii)[1]','varchar(10)'),convert(varchar,getdate(),114)),8),':',''),
		@data_expedierii= isnull(@parXML.value('(/*/@data_expedierii)[1]','datetime'),GETDATE()),
		@observatii=upper(ISNULL(@parXML.value('(/*/@observatii)[1]', 'varchar(50)'), '')),
		
		--date necesare pt. generare transfer
		@tipDoc='TE',@dataDoc=ISNULL(@parXML.value('(/*/@datadoc)[1]', 'datetime'), ''),
		@numarDoc=ISNULL(@parXML.value('(/*/@numardoc)[1]', 'varchar(13)'), ''),
		@stare=upper(ISNULL(@parXML.value('(/*/@stare)[1]', 'int'), 0)),
		@gestTr=ISNULL(@parXML.value('(/*/@gesttr)[1]', 'varchar(13)'), ''),
		
		--alte date necesare
		@dinmobile=upper(ISNULL(@parXML.value('(/*/@dinmobile)[1]', 'int'),0)),
		@faraMesaje=ISNULL(@parXML.value('(/*/@faramesaje)[1]', 'bit'), 0) -- flag folosit daca nu vrem afisarea de mesaje din procedura
		,@modplata=ISNULL(@parXML.value('(/*/@modplata)[1]', 'varchar(50)'), '')
		,@nrformular=upper(ISNULL(@parXML.value('(/*/@nrformular)[1]', 'varchar(10)'), ''))
		
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output --> citire subunitate din parametrii       
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output-->identificare utilizator pe baza sesiunii

	if exists (select 1 from con where tip='BK' and subunitate=@sub and data=@data and Contract=@contract and stare not in ('4','1'))
		raiserror( '    Pentru efectuarea transferului, comanda de livrare trebuie sa fie in stare "1-Aprobat"!',11,1)
	
	--citire date din gridul de operatii
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlDateGenDoc') IS NOT NULL
		drop table #xmlDateGenDoc
		
	select cod, gestiune, cant_doc, cant_disponibila, cant_aprobata, cant_generata, subunitate, tip, data, contract, tert, numar_pozitie
	into #xmlDateGenDoc
	from OPENXML(@iDoc, '/*/DateGrid/row')
	WITH
	(
		cod varchar(20) '@cod',
		gestiune varchar(20) '@gestiune',
		cant_doc float '@cant_doc',
		cant_disponibila float '@cant_disponibila',
		cant_aprobata float '@cant_aprobata',
		cant_generata float '@cant_generata',
		subunitate varchar(13) '@subunitate',
		tip varchar(2) '@tip',
		data datetime '@data',
		contract varchar(20) '@contract',
		tert varchar(13) '@tert',
		numar_pozitie int '@numar_pozitie'
	)
	exec sp_xml_removedocument @iDoc 	
	--select * from #xmlDateGenDoc
	
	if exists (select 1 from #xmlDateGenDoc where cant_doc>cant_disponibila)
		raiserror('     Transferul se poate realiza doar in limita cantitatilor disponibile! Verificati cantitatile de transferat introduse!',11,1)
		
	IF NOT EXISTS (SELECT 1 FROM #xmlDateGenDoc where abs(cant_doc) > 0.001) -- se pot factura si cantitati negative...
		RAISERROR ('Nu exista pozitii cu cantitate nenula pentru care sa fie generat transfer!', 11, 1)
	
	exec yso_validezDateGenDoc @sesiune, @parXML OUTPUT
	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRAN wOPGenerareUnTEdinBKSP
	
	if isnull(@numarDoc,'')=''--daca nu s-a introdus numar pt TE se ia urmatorul numar din plaja
	begin 
		declare @fXML xml, @NrDocFisc varchar(10)
		set @fXML = '<row/>'
		set @fXML.modify ('insert attribute tipmacheta {"O"} into (/row)[1]')
		set @fXML.modify ('insert attribute tip {sql:variable("@tipDoc")} into (/row)[1]')
		set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
		exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocFisc output
		set @numarDoc=@NrDocFisc
	end
		
	--parcurgere con pentru a lua date necesare de pe BK 
	select @gestiune=RTRIM(c.gestiune),
		-->daca se completeaza gestiune de transport atunci gestiunea primitoare=gestiunea de transport introdusa, altfel gestprim=gestiune primitoare de pe BK  
		@gestPrim=case when isnull(@GestTr,'')<>'' then rtrim(@GestTr) else rtrim(c.Cod_dobanda) end,
		-->daca se completeaza gestiune de transport atunci gestiunea dest=gestiunea primitoare de pe BK, altfel gest. dest=''
		@gestDest=case when isnull(@GestTr,'')<>'' then rtrim(c.Cod_dobanda) else '' end,
		-->categoria de pret se ia din proprietati pe gestiunea primitoare, altfel va fi 1
		@categPret=isnull((select top 1 rtrim(valoare) from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' 
				and cod= (case when isnull(@GestTr,'')<>'' then @GestTr else c.Cod_dobanda end)), 1),
		-->loc de munca: locul de munca din proprietati pe utilizator <=> lmfiltrare, altfel locul de munca al gestiunii, altfel loc de munca de pe BK
		@lm=rtrim(case when dbo.f_arelmfiltru(@utilizator)=1 then (select top 1 cod from lmfiltrare lu where lu.utilizator=@utilizator) 
				  else case when  isnull((select MAX(Loc_de_munca) from gestcor where Gestiune=c.gestiune),'')<>''
						then (select MAX(Loc_de_munca) from gestcor where Gestiune=c.gestiune)
					else c.Loc_de_munca end end),	
		@valuta=rtrim(c.valuta),
		@curs= c.curs						
	from con c 
	where c.Subunitate=@sub and c.Tip='BK' and c.Data=@data	and c.contract=@contract and (c.tert='' or c.tert=@tert)  
	
	if isnull(@gestPrim,'')=''
		raiserror('    Pentru efectuarea transferului, comanda de livrare trebuie sa aiba completata gestiunea primitoare!',11,1) 
	
	/** Daca gestiunea primitoare este una de tip custodii vom trimite clientul in locatie**/
	select top 1 @custodie=isnull(detalii.value('(/*/@custodie)[1]', 'int'),0) from gestiuni where cod_gestiune=@gestPrim
	
	--formare XML pentru apelare wScriuPozdoc    						
	set @input=
		(select rtrim(@sub) as '@subunitate','TE' as '@tip', rtrim(@numarDoc) as '@numar', convert(varchar(20),@dataDoc,101) as '@data',
			@gestiune as '@gestiune', @GestPrim as '@gestprim', @GestDest as '@contract', @CategPret as '@categpret', @lm as '@lm',	
			rtrim(@contract) as '@factura',rtrim(@tert) as '@comanda',
			
			--date pentru expeditie
			rtrim(@numedelegat) as '@numedelegat', rtrim(@mijloctp) as '@mijloctp', rtrim(@nrmijtransp) as '@nrmijloctp', rtrim(@seriebuletin) as '@seriebuletin',
			rtrim(@numarbuletin) as '@numarbuletin', rtrim(@eliberatbuletin) as '@eliberatbuletin',rtrim(@observatii) as '@observatii',
				
			--date necesare pentru generare pozitii transfer
			(select	rtrim(p.cod) as '@cod',x.gestiune as '@gestiune', 
				--> in transfer se va duce cantitatea aprobata ramasa netransferata(Pret_promotional->camp refolosit pentru cant. transferata)
				convert(varchar(20),isnull(x.cant_doc,(p.cant_aprobata-p.Pret_promotional))) as '@cantitate', 
				rtrim(convert(decimal(17,5),p.pret)) as '@pvaluta',CONVERT(decimal(5,2),p.Discount) as '@discount',
				
				-->pretul cu amnuntul se ia din dreptul categoriei de pret
				--isnull(convert(varchar(20),(select top 1 pret_cu_amanuntul from preturi where cod_produs=p.cod and um=@CategPret 
				--	order by data_inferioara desc)),0) as '@pamanunt',
				rtrim(convert(decimal(17,5),p.pret*(1-p.Discount/100)*(1+isnull(nullif(p.Cota_TVA,0),n.Cota_TVA)/100))) as '@pamanunt',
					
				@lm as '@lm', rtrim(@valuta) as '@valuta', convert(varchar(20),@curs) as '@curs',
				(case when @custodie=1 then @tert else null end) as '@locatie'
			
			from pozcon p
				inner join nomencl n on n.Cod=p.Cod
				left join #xmlDateGenDoc x on x.subunitate=p.Subunitate and x.tip=p.Tip and x.contract=p.Contract 
					and x.data=p.Data and x.tert=p.Tert and x.cod=p.Cod and x.numar_pozitie=p.Numar_pozitie 
			where p.Subunitate=@sub 
				and p.tip='BK' 
				and p.contract=@contract 
				and (p.tert='' or p.tert=@tert) 
				and p.data=@data
				--and p.cant_aprobata-p.Pret_promotional>0.001-->mai exista cantitate aprobata care nu a fost deja transferata
				and abs(isnull(x.cant_doc,0))>=0.001
			for xml PATH, TYPE)
		for XML PATH, type)
	if @sesiune='' select @input
	
	-->apelare wScriuPozdoc pentru scriere TE nou
	if exists (select * from sysobjects where name ='wScriuDoc')
		exec wScriuDoc @sesiune=@sesiune, @parXML=@input OUTPUT
	else 
	if exists (select * from sysobjects where name ='wScriuDocBeta')
		exec wScriuDocBeta @sesiune=@sesiune, @parXML=@input OUTPUT
	else 
		raiserror('Eroare configurare: aceasta procedura necesita folosirea procedurii wScriuDoc(beta).', 16, 1)
	
	-->daca s-a generat transfer
	if exists (select 1 from pozdoc where tip='TE' and data=@dataDoc and Numar=@numarDoc)
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
		COMMIT TRAN wOPGenerareUnTEdinBKSP
		
		if @nrformular<>'' and @@TRANCOUNT<=0
		begin
			declare @paramXmlString xml 
			set @paramXmlString= (select 'TE' as tip, @nrformular as nrform, @tert as tert, rtrim(@numarDoc) as numar, @dataDoc as data for xml raw )
			exec wTipFormular @sesiune, @paramXmlString
		end
		else 
			if @faraMesaje!=1
				select 'S-a generat cu succes documentul de transfer cu numarul '+rtrim(@numarDoc)+' din data de  '+ltrim(convert(varchar(20),@dataDoc,103)) as textMesaj for xml raw, root('Mesaje') 
	end
	else -->nu s-a generat transfer, se returneaza mesaj corespunzator
		if @faraMesaje!=1
			select 'Verificati datele, nu a fost generat document de transfer!' as textMesaj for xml raw, root('Mesaje')

	begin try 
	if OBJECT_ID('##xmlDateGenDoc') is not null
		drop table #xmlDateGenDoc
	end try 
	begin catch end catch   
	   
end try 
begin catch 
	IF EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'wOPGenerareUnTEdinBKSP')            
		ROLLBACK TRANSACTION wOPGenerareUnTEdinBKSP
	set @eroare='(wOPGenerareUnTEdinBKSP): '+ERROR_MESSAGE() 
	raiserror(@eroare, 16, 1)
end catch 
