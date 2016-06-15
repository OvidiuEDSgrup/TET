--***
create procedure wOPGenerareUnTEdinBK @sesiune varchar(50), @parXML xml 
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPGenerareUnTEdinBKSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPGenerareUnTEdinBKSP @sesiune, @parXML output
	return @returnValue
end

declare /*date de identificare BK:*/
	@sub varchar(9),@tip varchar(2),@data datetime,@contract varchar(20),@tert varchar(13),
	
	/*parametrii de expeditie:*/ 
	@numedelegat varchar(30),@mijloctp varchar(30),@nrmijtransp varchar(20),@seriabuletin varchar(10),
	@numarbuletin varchar(10),@eliberat varchar(30),
	
	/*parametri pt generare document nou:*/ 
	@numarDoc varchar(13),@dataDoc datetime,@tipDoc varchar(2),@observatii varchar(200),
	
	/*alte variabile necesare:*/
	@utilizator varchar(20),@lm varchar(13),@gestTr varchar(13),@dinmobile int,@faraMesaje int,
	@input xml,@eroare varchar(250),@gestDest varchar(13),@gestPrim varchar(13),@categPret int,@gestiune varchar(13),@valuta varchar(3),@curs float,
	@iDoc int
begin try
	select
		--date pt identificare BK din care se genereaza TE 
		@tip=ISNULL(@parXML.value('(/parametri/@tip)[1]', 'varchar(2)'), ''),
		@data=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), ''),
		@contract=ISNULL(@parXML.value('(/parametri/@numar)[1]', 'varchar(20)'), ''),
		@tert=ISNULL(@parXML.value('(/parametri/@tert)[1]', 'varchar(13)'), ''),
		
		--date pentru expeditie
		@numedelegat=upper(ISNULL(@parXML.value('(/parametri/@numedelegat)[1]', 'varchar(30)'), '')),
		@mijloctp=ISNULL(@parXML.value('(/parametri/@mijloctp)[1]', 'varchar(30)'), ''),		
		@nrmijtransp=upper(ISNULL(@parXML.value('(/parametri/@nrmijltransp)[1]', 'varchar(20)'), '')),		
		@seriabuletin=upper(ISNULL(@parXML.value('(/parametri/@seriabuletin)[1]', 'varchar(10)'), '')),		
		@numarbuletin=upper(ISNULL(@parXML.value('(/parametri/@numarbuletin)[1]', 'varchar(10)'), '')),		
		@eliberat=upper(ISNULL(@parXML.value('(/parametri/@eliberat)[1]', 'varchar(30)'), '')),
		
		--date necesare pt. generare transfer
		@dataDoc=ISNULL(@parXML.value('(/parametri/@datadoc)[1]', 'datetime'), ''),
		@numarDoc=ISNULL(@parXML.value('(/parametri/@numardoc)[1]', 'varchar(13)'), ''),
		@gestTr=ISNULL(@parXML.value('(/parametri/@gesttr)[1]', 'varchar(13)'), ''),
		@observatii=upper(ISNULL(@parXML.value('(/parametri/@observatii)[1]', 'varchar(50)'), '')),
		@tipDoc='TE',
		
		--alte date necesare
		@dinmobile=upper(ISNULL(@parXML.value('(/parametri/@dinmobile)[1]', 'int'),0)),
		@faraMesaje=ISNULL(@parXML.value('(/parametri/@faramesaje)[1]', 'bit'), 0) -- flag folosit daca nu vrem afisarea de mesaje din procedura
		
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output --> citire subunitate din parametrii       
  
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output-->identificare utilizator pe baza sesiunii

	if exists (select 1 from con where tip='BK' and subunitate=@sub and data=@data and Contract=@contract and stare not in ('4','1'))
		raiserror( '    Pentru efectuarea transferului, comanda de livrare trebuie sa fie in stare "1-Aprobat"!',11,1)
	
	--citire date din gridul de operatii
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlPozitiiTransport') IS NOT NULL
		drop table #xmlPozitiiTransport
		
	select cod, cantitate_transfer, cantitate_disponibila, cant_aprobata, cant_transferata, subunitate, tip, data, contract, tert, numar_pozitie
	into #xmlPozitiiTransport
	from OPENXML(@iDoc, '/parametri/DateGrid/row')
	WITH
	(
		cod varchar(13) '@cod',
		cantitate_transfer float '@cantitate_transfer',
		cantitate_disponibila float '@cantitate_disponibila',
		cant_aprobata float '@cant_aprobata',
		cant_transferata float '@cant_transferata',
		subunitate varchar(13) '@subunitate',
		tip varchar(2) '@tip',
		data datetime '@data',
		contract varchar(20) '@contract',
		tert varchar(13) '@tert',
		numar_pozitie int '@numar_pozitie'
	)
	exec sp_xml_removedocument @iDoc 	
	--select * from #xmlPozitiiTransport
	
	if exists (select 1 from #xmlPozitiiTransport where cantitate_transfer>cantitate_disponibila)
		raiserror('     Transferul se poate realiza doar in limita cantitatilor disponibile! Verificati cantitatile de transferat introduse!',11,1)
	
	if isnull(@numarDoc,'')=''--daca nu s-a introdus numar pt TE se ia urmatorul numar din plaja
	begin 
		declare @fXML xml, @NrDocFisc varchar(10)
		set @fXML = '<row/>'
		set @fXML.modify ('insert attribute tipmacheta {"O"} into (/row)[1]')
		set @fXML.modify ('insert attribute tip {sql:variable("@tipDoc")} into (/row)[1]')
		set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
		exec wIauNrDocFiscale @parXML=@fXML, @Numar=@NrDocFisc output
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
	
	--formare XML pentru apelare wScriuPozdoc    						
	set @input=
		(select rtrim(@sub) as '@subunitate','TE' as '@tip', rtrim(@numarDoc) as '@numar', convert(varchar(20),@dataDoc,101) as '@data',
			@gestiune as '@gestiune', @GestPrim as '@gestprim', @GestDest as '@contract', @CategPret as '@categpret', @lm as '@lm',	
			rtrim(@contract) as '@factura',
			
			--date pentru expeditie
			rtrim(@numedelegat) as '@numedelegat', rtrim(@mijloctp) as '@mijloctp', rtrim(@nrmijtransp) as '@nrmijloctp', rtrim(@seriabuletin) as '@seriabuletin',
			rtrim(@numarbuletin) as '@numarbuletin', rtrim(@eliberat) as '@eliberat',rtrim(@observatii) as '@observatii',
				
			--date necesare pentru generare pozitii transfer
			(select	rtrim(p.cod) as '@cod', 
				--> in transfer se va duce cantitatea aprobata ramasa netransferata(Pret_promotional->camp refolosit pentru cant. transferata)
				convert(varchar(20),isnull(x.cantitate_transfer,(p.cant_aprobata-p.Pret_promotional))) as '@cantitate', 
				
				-->pretul cu amnuntul se ia din dreptul categoriei de pret
				isnull(convert(varchar(20),(select top 1 pret_cu_amanuntul from preturi where cod_produs=p.cod and um=@CategPret 
					order by data_inferioara desc)),0) as '@pamanunt', 
					
				@lm as '@lm', rtrim(@valuta) as '@valuta', convert(varchar(20),@curs) as '@curs'				
			
			from pozcon p
				left join #xmlPozitiiTransport x on x.subunitate=p.Subunitate and x.tip=p.Tip and x.contract=p.Contract 
					and x.data=p.Data and x.tert=p.Tert and x.cod=p.Cod and x.numar_pozitie=p.Numar_pozitie 
			where p.Subunitate=@sub 
				and p.tip='BK' 
				and p.contract=@contract 
				and (p.tert='' or p.tert=@tert) 
				and p.data=@data
				and p.cant_aprobata-p.Pret_promotional>0.001-->mai exista cantitate aprobata care nu a fost deja transferata
				and (x.cantitate_transfer is null or x.cantitate_transfer>0.001)
			for xml PATH, TYPE)
		for XML PATH, type)
	
	-->apelare wScriuPozdoc pentru scriere TE nou
	--select CONVERT(varchar(max),@input)
	exec wScriuPozdoc @sesiune,@input
	
	-->daca s-a generat transfer
	if exists (select 1 from pozdoc where tip='TE' and data=@dataDoc and Numar=@numarDoc)
	begin
		/*update con set Stare='4'
		where Subunitate=@sub and Tip='BK' and Data=@data and contract=@contract and (tert='' or tert=@tert)
		*/
		if @faraMesaje!=1
			select 'S-a generat cu succes documentul de transfer cu numarul '+rtrim(@numarDoc)+' din data de  '+ltrim(convert(varchar(20),@dataDoc,103)) as textMesaj for xml raw, root('Mesaje') 
	end
	else -->nu s-a generat transfer, se returneaza mesaj corespunzator
		if @faraMesaje!=1
			select 'Verificati datele, nu a fost generat document de transfer!' as textMesaj for xml raw, root('Mesaje')

	begin try 
	if OBJECT_ID('##xmlPozitiiTransport') is not null
		drop table #xmlPozitiiTransport
	end try 
	begin catch end catch   
	   
end try 
begin catch 
	set @eroare='(wOPGenerareTEdinBK): '+ERROR_MESSAGE() 
	raiserror(@eroare, 16, 1)
end catch 
