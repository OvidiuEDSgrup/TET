--***
create procedure wOPGenerareUnAPdinBK @sesiune varchar(50), @parXML xml 
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPGenerareUnAPdinBKSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPGenerareUnAPdinBKSP @sesiune, @parXML output
	return @returnValue
end

declare /*date de identificare BK:*/@sub varchar(9),@tip varchar(2),@data datetime,@contract varchar(20),@tert varchar(13),
	
	/*parametrii de expeditie:*/ @numedelegat varchar(30),@mijloctp varchar(30),@nrmijtransp varchar(20),@seriabuletin varchar(10),
		@numarbuletin varchar(10),@eliberat varchar(30),
	
	/*parametri pt generare document nou:*/ @numarDoc varchar(13),@dataDoc datetime,@tipDoc varchar(2),@observatii varchar(200),
	
	/*alte variabile necesare:*/@utilizator varchar(20),@lm varchar(13),@gestTr varchar(13),@dinmobile int,@faraMesaje int,
	@input xml,@eroare varchar(250),@gestDest varchar(13),@categPret int,@gestiune varchar(13),@zilescadenta int,
	@punct_livrare varchar(13),@valuta varchar(3),@curs float,@iDoc int,@stare int
begin try
	select
		--date pt identificare BK din care se genereaza TE 
		@tip=ISNULL(@parXML.value('(/*/@tip)[1]', 'varchar(2)'), ''),
		@data=ISNULL(@parXML.value('(/*/@data)[1]', 'datetime'), ''),
		@contract=ISNULL(@parXML.value('(/*/@numar)[1]', 'varchar(20)'), ''),
		@tert=ISNULL(@parXML.value('(/*/@tert)[1]', 'varchar(13)'), ''),
		
		--date pentru expeditie
		@numedelegat=upper(ISNULL(@parXML.value('(/*/@numedelegat)[1]', 'varchar(30)'), '')),
		@mijloctp=ISNULL(@parXML.value('(/*/@mijloctp)[1]', 'varchar(30)'), ''),		
		@nrmijtransp=upper(ISNULL(@parXML.value('(/*/@nrmijltransp)[1]', 'varchar(20)'), '')),		
		@seriabuletin=upper(ISNULL(@parXML.value('(/*/@seriabuletin)[1]', 'varchar(10)'), '')),		
		@numarbuletin=upper(ISNULL(@parXML.value('(/*/@numarbuletin)[1]', 'varchar(10)'), '')),		
		@eliberat=upper(ISNULL(@parXML.value('(/*/@eliberat)[1]', 'varchar(30)'), '')),
		
		--date necesare pt. generare transfer
		@dataDoc=ISNULL(@parXML.value('(/*/@datadoc)[1]', 'datetime'), ''),
		@numarDoc=ISNULL(@parXML.value('(/*/@numardoc)[1]', 'varchar(13)'), ''),
		@observatii=upper(ISNULL(@parXML.value('(/*/@observatii)[1]', 'varchar(50)'), '')),
		@stare=upper(ISNULL(@parXML.value('(/*/@stare)[1]', 'int'), 0)),
		@tipDoc='AP',
		
		--alte date necesare
		@dinmobile=upper(ISNULL(@parXML.value('(/*/@dinmobile)[1]', 'int'),0)),
		@faraMesaje=ISNULL(@parXML.value('(/*/@faramesaje)[1]', 'bit'), 0) -- flag folosit daca nu vrem afisarea de mesaje din procedura

	/*if @stare not in ('6','1','4') and @dinmobile<>1
		raiserror( '    Pentru facturare, comanda de livrare trebuie sa fie in stare "1-Aprobat", sau "6-Facturat"!',11,1)
	*/	
	if ISNULL(@tert,'')=''
		raiserror( '    Pentru facturare, pe comanda de livrare trebuie sa fie definit beneficiarul!',11,1)	
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output --> citire subunitate din proprietati       
  
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output-->identificare utilizator pe baza sesiunii

	--citire date din gridul de operatii
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlPozitiiFactura') IS NOT NULL
		drop table #xmlPozitiiFactura
		
	select cod, cantitate_factura, cantitate_disponibila, cant_aprobata, cant_realizata, subunitate, tip, data, contract, tert, numar_pozitie
	into #xmlPozitiiFactura
	from OPENXML(@iDoc, '/*/DateGrid/row')
	WITH
	(
		cod varchar(13) '@cod',
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
		@categPret=c.Dobanda,
		-->loc de munca: locul de munca din proprietati pe utilizator, altfel locul de munca al gestiunii, altfel loc de munca de pe BK
		@lm=rtrim(c.Loc_de_munca),
		@zilescadenta=c.Scadenta,
		@punct_livrare=c.Punct_livrare,
		@valuta=rtrim(c.valuta),
		@curs= c.curs					
	from con c 
	where c.Subunitate=@sub and c.Tip='BK' and c.Data=@data	and c.contract=@contract and (c.tert='' or c.tert=@tert)  
	  
	
	-- date expeditie in anexafac
	if not exists (select 1 from anexafac where Subunitate=@sub and Numar_factura=@numarDoc)
		insert anexafac
		(Subunitate,Numar_factura,Numele_delegatului,Seria_buletin,Numar_buletin,Eliberat,Mijloc_de_transport,
			Numarul_mijlocului,Data_expedierii,Ora_expedierii,Observatii)
		values (@sub, @numarDoc, @numedelegat, @seriabuletin, @numarbuletin, @eliberat, @mijloctp, 
		    @nrmijtransp, @datadoc, '', @observatii) 
	
	--formare XML pentru apelare wScriuPozdoc    						
	set @input=
		(select rtrim(@sub) as '@subunitate', 'AP' as '@tip', rtrim(@tert) as '@tert',
			rtrim(@numarDoc) as '@numar', convert(varchar(20),@datadoc,101) as '@data', @categpret as '@categpret',
			@lm as '@lm', @gestiune as '@gestiune', rtrim(@contract) as '@contract',
			@zilescadenta as '@zilescadenta', rtrim(@punct_livrare) as '@punctlivrare',
			
			--date pentru pozitiile de AP
			(select convert(varchar(20),p.pret) as '@pvaluta', rtrim(@valuta) as '@valuta',convert(varchar(20),@curs) as '@curs',
					CONVERT(decimal(5,2),p.Discount) as '@discount', @lm as '@lm',
					rtrim(p.cod) as '@cod', 
					rtrim(isnull(x.cantitate_factura,(p.cant_aprobata-p.cant_realizata))) as '@cantitate', @contract as '@contract'
				from pozcon p 
					left join #xmlPozitiiFactura x on x.subunitate=p.Subunitate and x.tip=p.Tip and x.contract=p.Contract 
						and x.data=p.Data and x.tert=p.Tert and x.cod=p.Cod and x.numar_pozitie=p.Numar_pozitie 
				where p.Subunitate=@sub and p.tip='BK' 
					and p.data=@data 
					and p.contract=@contract 
					and (@tert='' or p.tert=@tert )
					and p.cant_aprobata-p.cant_realizata >0.001
					and (x.cantitate_factura is null or x.cantitate_factura>0.001)
			for xml PATH, TYPE)
		for XML PATH, type)	
	
	exec wScriuPozdoc @sesiune=@sesiune,@parXML=@input
		
	-->daca s-a generat factura => comanda de livrare se trece in starea "Facturat", afisam mesaj de finalizare operatie cu succes	
	if exists (select 1 from pozdoc where subunitate='1' and tip='AP' and data=@dataDoc and Numar=@numarDoc and tert=@tert)
	begin
		/*update con set Stare='6'
		where Subunitate=@sub and Tip='BK' and Data=@data and contract=@contract and (tert='' or tert=@tert)
		*/
		if @faraMesaje!=1
			select 'S-a generat cu succes factura cu numarul '+rtrim(@numarDoc)+' din data de  '+ltrim(convert(varchar(20),@dataDoc,103)) as textMesaj for xml raw, root('Mesaje') 
	end
	else -->nu s-a generat factura, se returneaza mesaj corespunzator
		if @faraMesaje!=1
			select 'Verificati datele, nu a fost generata factura!' as textMesaj for xml raw, root('Mesaje')

	begin try 
		if OBJECT_ID('#xmlPozitiiFactura') is not null
			drop table #xmlPozitiiFactura
	end try 
	begin catch end catch   
end try 
begin catch 
	set @eroare='(wOPGenerareAPdinBK): '+ERROR_MESSAGE() 
	raiserror(@eroare, 16, 1)
end catch 
