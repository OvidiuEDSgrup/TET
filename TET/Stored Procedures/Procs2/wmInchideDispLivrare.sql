/***--
Modifica starea dispozitiiei pt. a bloca scanarea de pe mobil.
La prima apelare, afisez meniul si apoi la confirmare schimb starea.
--***/
CREATE PROCEDURE wmInchideDispLivrare @sesiune varchar(50), @parXML xml
AS
declare @utilizator varchar(50), @mesaj varchar(1000), @idDisp int, @confirmInchiderea char(1), @totalScriptic decimal(12,3), @totalScanat decimal(12,3),
		@xml1 xml, @xml2 xml, @xml3 xml, @tipdisp varchar(50), @gestiune varchar(50), @tert varchar(50), @gestPrim varchar(50), @numarPozDoc varchar(50),
		@contract varchar(50), @antet xml, @xmlPoz xml, @dataStr char(10)
		
begin try
	if exists (select 1 from sysobjects where [type]='P' and [name]='wmInchideDispLivrareSP')
	begin 
		exec wmInchideDispLivrareSP @sesiune=@sesiune, @parXML=@parXML output
		if @parXML is null
			return 
	end

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	/*Citeste variabile din parametrii */
	select	@idDisp	= ISNULL(@parXML.value('(/row/@iddisp)[1]', 'int') , 0),
			@confirmInchiderea	= @parXML.value('(/row/@confirmInchiderea)[1]', 'varchar(1)')
			
	if @idDisp=0
		raiserror('Dispozitia nu poate fi identificata.', 11, 1)
	
	if (select stare from AntDisp where idDisp=@idDisp)='Finalizata'
		raiserror('Aceasta dispozitie a fost deja finalizata.', 11, 1)
	
	if @confirmInchiderea is null -- prima data se afisaza un mesaj de confirmare
	begin
		set @totalScriptic=isnull((select sum(cantitate) from PozDispOp where idDisp=@idDisp),0)
		set @totalScanat = isnull((select sum(ps.cantitate) from PozDispOp po, PozDispScan ps where idDisp=@idDisp and po.idPoz=ps.idPoz),0)
		
		-- aici e sum(cantitate)... nu stiu daca e chiar corect sa afisam asa...
		set @xml1=(select convert(varchar(30), @totalScanat) + (case @totalScriptic when 0 then '' else ' / ' + convert(varchar(30), @totalScriptic) end )denumire, 
					'produse scanate' as info, 'back(0)' actiune
						for xml raw)
		
		set @xml2=
			(select * from
				(select null as cod, 'Confirmati inchiderea dispozitiei?' denumire, 'back(0)' actiune
				union all
					select '1' as cod, 'Da' denumire, null actiune
				union all
					select '0' as cod, 'Nu' denumire, null actiune) x
			for xml raw)
		
		select @xml1, @xml2
		for xml path('')
		
		select	'wmInchideDispLivrare' as _detalii, 'C' as _tipdetalii, 'refresh' as actiune, '@confirmInchiderea' _numeatr
		for xml raw, root('Mesaje');
		
		return 0
	end
	
	if @confirmInchiderea<>'1' -- daca nu alege 'Da' la intrebare, nu mai facem nimic. 
	begin
		select 'back(1)' as actiune for xml raw, root('Mesaje');
		return 0
	end
	
	select	@tipdisp = tipDisp ,
			@gestiune = a.detalii.value('(/*/@gestiune)[1]', 'varchar(50)'),
			@tert = a.detalii.value('(/*/@tert)[1]', 'varchar(50)'),
			@gestPrim = a.detalii.value('(/*/@gestprim)[1]', 'varchar(50)')
	from AntDisp a
	where a.idDisp = @idDisp
	
	/*validare introducere date necesare pe dispozitie*/
	if isnull(@gestiune, '')=''
		raiserror('Gestiune necompletata.',16,1)
	
	if @tipdisp='TE' and isnull(@gestPrim, '')=''
		raiserror('Gestiune primitoare necompletata.',16,1)
	
	if @tipdisp='AP' and isnull(@tert, '')=''
		raiserror('Tert necompletat.',16,1)
	
	begin tran wmInchideDispLivrare
		
	update AntDisp
		set stare='Finalizata'
	where idDisp=@idDisp
	
	--pentru pozitiile adaugate de pe terminal in pozdispop, la inchidere dispozitie se face cantitate=cantitate scanata	
	update po set po.cantitate=p.cantitate
	from PozDispOp po
		cross apply (select ps.idPoz, sum(ps.cantitate) as cantitate from PozDispScan ps where po.idPoz=ps.idPoz group by ps.idPoz) p
	where po.idDisp=@idDisp and isnull(po.cantitate,0)=0	
	
	declare @poz table(detalii xml)
	
	-- incerc sa cumulez pozitiile scanate doar daca in detalii(xml) nu este nimic. 
	if exists (select * from PozDispOp po, PozDispScan ps where po.idDisp=@iddisp and po.idPoz=ps.idPoz and (ps.detalii is not null or po.detalii is not null))
	begin 
		-- Daca detalii nu e null, atributele din XML se trimit mai departe la wScriuPozdoc si pot avea efect diferit
		declare @pozTemp table(cod varchar(20), cantitate decimal(15,3), pret decimal(18,5), detaliiOp xml, detaliiScan xml, detaliiTot xml, id int identity)
		declare @idTemp int
		set @idTemp=0
		
		insert into @pozTemp(cod, cantitate, pret, detaliiScan, detaliiOp)
		select cod, ps.cantitate, po.pret, isnull(po.detalii, '<row />'), isnull(ps.detalii, '<row />')
		from PozDispOp po, PozDispScan ps
		where po.idDisp=@iddisp and po.idPoz=ps.idPoz
		
		/*
			inserez atribute hardcodate
		*/
		UPDATE @pozTemp SET detaliiScan.modify('replace value of /row[1]/@cod with sql:column("cod")') WHERE detaliiScan.exist('(/row[1])/@cod') = 1
		UPDATE @pozTemp SET detaliiScan.modify('insert attribute cod {sql:column("cod")} into /row[1]') WHERE detaliiScan.exist('(/row[1])/@cod') = 0
		
		UPDATE @pozTemp SET detaliiScan.modify('replace value of /row[1]/@cantitate with sql:column("cantitate") ') 
		WHERE detaliiScan.exist('(/row[1])/@cantitate') = 1 and cantitate is not null
		UPDATE @pozTemp SET detaliiScan.modify('insert attribute cantitate {sql:column("cantitate")} into /row[1]')
		WHERE detaliiScan.exist('(/row[1])/@cantitate') = 0 and cantitate is not null
		
		UPDATE @pozTemp SET detaliiScan.modify('replace value of /row[1]/@pret with sql:column("pret")') 
		WHERE detaliiScan.exist('(/row[1])/@pret') = 1 and pret is not null
		UPDATE @pozTemp SET detaliiScan.modify('insert attribute pret {sql:column("pret")} into /row[1]') 
		WHERE detaliiScan.exist('(/row[1])/@pret') = 0  and pret is not null
		---------------------------------
		
		-- unific atributele din detalii pt tabelele PozDispOp si PozDispScan
		while exists(select * from @pozTemp)
		begin
			select top 1 @idTemp=id, @xml1 = p.detaliiOp, @xml2 = p.detaliiScan
			from @pozTemp p
			
			exec adaugaAtributeXml @xmlSursa=@xml1, @xmlDest=@xml2 output
			
			insert into @poz(detalii)
			values(@xml2)
			
			delete from @pozTemp 
			where id=@idTemp
		end
		
	end
	else
	begin -- daca nu exista detalii xml, grupez liniile scanate.
		insert into @poz(detalii)
		select (
			select cod cod, convert(decimal(15,3), sum(ps.cantitate)) cantitate, convert(decimal(18,5), po.pret) pret
			from PozDispOp po, PozDispScan ps
			where po.idDisp=@iddisp and po.idPoz=ps.idPoz
			group by cod, po.pret
			for xml raw)
	end
	
	select @antet = detalii, @dataStr = convert(char(10), getdate(), 101)
	from AntDisp 
	where idDisp=@idDisp
	
	-- momentan dispozitiile au tip dispozitie = tip din pozdoc
	set @xml1 = (select @tipdisp as tip, @utilizator as utilizator for xml raw)
	EXEC wIauNrDocFiscale @parXML = @xml1, @NrDoc = @numarPozDoc OUTPUT
	
	if @antet.value('(/row/@numar)[1]', 'int') is not null                        
		set @antet.modify('replace value of (/row/@numar)[1] with sql:variable("@numarPozDoc")') 
	else
		set @antet.modify ('insert attribute numar {sql:variable("@numarPozDoc")} into (/row)[1]') 
	
	if @antet.value('(/row/@data)[1]', 'int') is not null                        
		set @antet.modify('replace value of (/row/@data)[1] with sql:variable("@dataStr")') 
	else
		set @antet.modify ('insert attribute data {sql:variable("@dataStr")} into (/row)[1]') 
	
	if @antet.value('(/row/@subunitate)[1]', 'varchar(50)') is not null                        
		set @antet.modify('replace value of (/row/@subunitate)[1] with "1"') 
	else
		set @antet.modify ('insert attribute subunitate {"1"} into (/row)[1]') 
	
	if @antet.value('(/row/@returneaza_inserate)[1]', 'varchar(50)') is not null                        
		set @antet.modify('replace value of (/row/@returneaza_inserate)[1] with "0"') 
	else
		set @antet.modify ('insert attribute returneaza_inserate {"0"} into (/row)[1]') 
	
	if @antet.value('(/row/@fara_luare_date)[1]', 'varchar(50)') is not null                        
		set @antet.modify('replace value of (/row/@fara_luare_date)[1] with "1"') 
	else
		set @antet.modify ('insert attribute fara_luare_date {"1"} into (/row)[1]') 
		
	if @antet.value('(/row/@tip)[1]', 'int') is not null                        
		set @antet.modify('replace value of (/row/@tip)[1] with sql:variable("@tipdisp")') 
	else
		set @antet.modify ('insert attribute tip {sql:variable("@tipdisp")} into (/row)[1]') 
	
	--select @xml1 docf,@numarPozDoc
	SET @xml1 = (
		SELECT @antet, 
			(select (select detalii.query('.') from @poz for xml path(''), type) for xml path('pozitii'),type)
		FOR XML path(''), type
		)
	
	SET @xml1.modify('insert /pozitii/* into (/row)[1]')
	SET @xml1.modify('delete /pozitii')
		
	exec wScriuPozdoc @sesiune=@sesiune, @parXML=@xml1
	
	--select * from pozdoc where numar=@numarPozDoc
	
	-- daca exista contract, schimb starea contractului... 
	-- aici ar trebui discutat eventual o solutie mai buna. Pe structuri noi nu vom scrie aceste atribute...
	if @tipdisp='TE'
		select @contract = MAX(detalii.value('/row[1]/@factura', 'varchar(50)')) /* pt TE, contractul se trimite la pozdoc in @factura  */
		from PozDispOp where idDisp = @idDisp
	
	if @tipdisp='AP'
		select @contract = MAX(detalii.value('/row[1]/@contract', 'varchar(50)'))
		from PozDispOp where idDisp = @idDisp
	
	if LEN(ISNULL(@contract,''))>0
	begin
		-- nu am o solutie mai buna momentan...
		declare @stareRealizat varchar(50)
		
		set @stareRealizat = isnull((select rtrim(val_alfanumerica) from par where Tip_parametru='UC' and Parametru='STBKREAL'),'6')
		
		update con 
			set stare=@stareRealizat
		where Subunitate='1' and tip='BK' and contract=@contract
	end
	
	commit tran wmInchideDispLivrare
			
	select 'back(2)' as actiune for xml raw, root('Mesaje');
	
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran wmInchideDispLivrare
	
	set @mesaj = ERROR_MESSAGE()+' (wmInchideDispLivrare)'
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
