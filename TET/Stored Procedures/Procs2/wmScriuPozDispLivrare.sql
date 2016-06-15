/***--
Procedura stocata scrie in tabela PozDispScan pozitiile operate.

--***/
CREATE PROCEDURE wmScriuPozDispLivrare @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wmScriuPozDispLivrareSP')
begin 
	declare @returnValue int
	exec @returnValue = wmScriuPozDispLivrareSP @sesiune, @parXML output
	if @parXML is null
		return @returnValue
end

declare @userASiS varchar(50), @mesaj varchar(1000),
		@idPoz int, @idDisp int, @count int,
		@codBare varchar(100), @codProdus varchar(100), @msg varchar(100),--@codLocal varchar(100),
		@actiune varchar(100), @update bit, @locatie varchar(500), @idPozScan int, @cantitate float, @detalii_scan xml
		
begin try
	/*Validare utilizator */
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	
	/*Citeste variabile din parametrii */
	select	@idDisp		= ISNULL(@parXML.value('(/row/@iddisp)[1]', 'int') , 0),
			@idPoz		= ISNULL(@parXML.value('(/row/@idpoz)[1]', 'int') , 0),
			@idPozScan	= ISNULL(@parXML.value('(/row/@idpozscan)[1]', 'int') , 0),
			@codProdus	= @parXML.value('(/row/@cod)[1]', 'varchar(100)'),
			@codBare	= @parXML.value('(/row/@codbare)[1]', 'varchar(100)'),
			@cantitate	= isnull(@parXML.value('(/row/@cantitate)[1]','float'), 0), -- trimisa cand se face update
			@locatie	= @parXML.value('(/row/@locatie)[1]','varchar(13)')
	
	if @idDisp=0
		raiserror('Dispozitia nu poate fi identificata.', 11, 1)
	
	if @idPozScan>0 -- modificare linie scanata
	begin
		if @cantitate<>0
			update PozDispScan
				set cantitate = @cantitate
			where idPozScan=@idPozScan
		else -- la cantitate nula(0), stergem linia
		begin
			--stergere linie scanata
			delete from PozDispScan 
			where idPozScan = @idPozScan
			
			--daca nu mai exista alte scanari pe aceasta pozitie de dispozitie si cantitatea este 0(a fost generate de pe terminal), se sterge si pozitia in PozDispOp
			if not exists(select 1 from PozDispScan where idPoz=@idPoz)
			begin	
				delete from PozDispOp 
				where idPoz = @idPoz
					and idDisp=@idDisp 
					and isnull(cantitate,0)=0
			end		
		end	
	end
	else
	begin
		if not exists (select * from nomencl where cod=@codProdus)
		begin
			set @mesaj='Codul scanat ('+ISNULL(rtrim(@codProdus),'(NULL)')+' nu exista in baza de date.'
			raiserror(@mesaj,11,1)
		end
		
		if exists(select 1 from PozDispOp where idDisp=@idDisp and cod=@codProdus)
			set @idPoz=(select top 1 idpoz from PozDispOp where idDisp=@idDisp and cod=@codProdus)
		else --daca codul scanat nu este in PozDispOp, se adauga acum (va trebui tratat aici cazul in care se porneste de la o comanda de livrare)
		begin
			--select @mesaj= 'Produsul ales ('+RTRIM(n.denumire)+'('+rtrim(n.cod)+') nu exista pe aceasta dispozitie.' from nomencl n where n.Cod=@codProdus
			
			declare @idPozOp TABLE(idPozDisp INT)
			
			insert into PozDispOp(idDisp,cod, utilizator,data_operarii)
			output inserted.idPoz into @idPozOp
			select @idDisp,@codProdus , @userASiS,GETDATE()
			
			set @idPoz=(select top 1 idpozDisp from @idPozOp)
		end
		
		-- daca in XML vin atribute care incep cu '@detalii_', extragem atributele si le inseram in coloana detalii
		set @detalii_scan = '<row />'
		exec adaugaAtributeXml @xmlSursa = @parXML, @xmlDest = @detalii_scan output, @extrageDetalii=1
		
		-- daca nu exista atribute, nu inserez xml gol degeaba...
		SET @count = @detalii_scan.query('count(/row/@*)').value('.','int')
		if @count = 0
			set @detalii_scan=null
		
		--inserare pozitie scanare in PozDispScan
		INSERT INTO PozDispScan(idPoz, barcode, cantitate, locatie, utilizator, detalii)
			select @idPoz, @codBare, @cantitate , @locatie, @userASiS, @detalii_scan
	end
		
		
	select 'back(1)' as actiune for xml raw, root('Mesaje');
	
end try
begin catch
	set @mesaj = ERROR_MESSAGE()+' (wmScriuPozDispLivrare)'
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)

/*
select * from AntDisp

select * from PozDispOp where iddisp=96
select * from PozDispScan 

-- truncate table pozdispscan
select * from codbare
where cod_produs='PERM'



/*tipuri comenzi	bk - livrare
					bf - beneficiari 
					fc - aprovizionare
					fa - furnizori*/

INSERT INTO PozDispScan(idPoz, tipPozitie, barcode, cantitate, locatie, utilizator)
select 7, 'cantSp', null, 2, null, 'mitz'

*/
