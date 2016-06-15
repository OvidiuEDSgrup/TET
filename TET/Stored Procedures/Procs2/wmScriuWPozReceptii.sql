/***--
Procedura stocata scrie in tabela PozDispScan pozitiile operate.

--***/
CREATE PROCEDURE wmScriuWPozReceptii @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wmScriuWPozReceptiiSP')
begin 
	declare @returnValue int
	exec @returnValue = wmScriuWPozReceptiiSP @sesiune, @parXML output
	if @parXML is null
		return @returnValue
end

declare @userASiS varchar(50), @mesaj varchar(1000),
		@idPoz int, @cantOk float, @cantSparta float, @idDisp int,
		@codBare varchar(100), @codProdus varchar(100), @msg varchar(100),--@codLocal varchar(100),
		@actiune varchar(100), @update bit, @locatie varchar(500), @idPozScan int, @cantitate float
		
begin try
	/*Validare utilizator */
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	
	/*Citeste variabile din parametrii */
	select	@idDisp		= ISNULL(@parXML.value('(/row/@iddisp)[1]', 'int') , 0),
			@idPoz		= ISNULL(@parXML.value('(/row/@idpoz)[1]', 'int') , 0),
			@idPozScan	= ISNULL(@parXML.value('(/row/@idpozscan)[1]', 'int') , 0),
			@codProdus	= @parXML.value('(/row/@cod)[1]', 'varchar(100)'),
			@codBare	= @parXML.value('(/row/@codbare)[1]', 'varchar(100)'),
			@cantOk		= ISNULL(@parXML.value('(/row/@cant_ok)[1]', 'float'), 0),
			@cantSparta = ISNULL(@parXML.value('(/row/@cant_sparta)[1]','float'), 0),
			@cantOk		= ISNULL(@parXML.value('(/row/@cant_ok)[1]', 'float'), 0),
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
			
			if not exists(select 1 from PozDispScan where idPoz=@idPoz)
				--daca nu mai exista alte scanari pe aceasta pozitie de dispozitie si cantitatea este 0(a fost generate de pe terminal), se sterge si pozitia in PozDispOp
			begin	
				delete from PozDispOp 
				where idPoz = @idPoz
					and idDisp=@idDisp 
					and cantitate=0
			end		
		end	
	end
	else
	begin
		if exists (select * from nomencl where cod=@codProdus)
		--daca codul scanat este in nomenclator
			if not exists(select 1 from PozDispOp where idDisp=@idDisp and cod=isnull(@codProdus,''))-- and @cantitate=0
			--daca codul scanat nu este pe dispozitie, se adauga si pe dispozitie
			begin
				--select @mesaj= 'Produsul ales ('+RTRIM(n.denumire)+'('+rtrim(n.cod)+') nu exista pe aceasta dispozitie.' from nomencl n where n.Cod=@codProdus
				IF OBJECT_ID('tempdb..#idpozDisp') IS NOT NULL
					DROP TABLE #idPozDisp

				CREATE TABLE #idPozDisp (idPozDisp INT)
				
				--in coloana detalii se scrie cantitate_diferenta=0, pentru a fi mai usor de intretinut mai apoi in wscriupozdispAW
				insert into PozDispOp(idDisp,cod,cantitate,pret,utilizator,data_operarii,detalii)
				output inserted.idPoz into #idPozDisp
				select @idDisp,@codProdus,0,0,@userASiS,GETDATE(),convert(xml,'<row cantitate_diferenta="0" />')
				
				set @idPoz=(select top 1 idpozDisp from #idpozDisp)
			end
			else
			begin
				-- Daca codul este pe dispozitia de receptie, identificam idpoz
				set @idPoz=(select top 1 idpoz from PozDispOp where idDisp=@idDisp and cod=@codProdus)
			end	
		else
		begin	
			--daca codul scanat nu se gaseste in nomenclator, se returneaza mesaj de eroarea
			set @mesaj='Codul scanat ('+ISNULL(rtrim(@codProdus),'(NULL)')+' nu exista in baza de date.'
		end
		if len(@mesaj)>0
			raiserror(@mesaj,11,1)
		--inserare pozitie scanare in PozDispScan
		INSERT INTO PozDispScan(idPoz, tipPozitie, barcode, cantitate, locatie, utilizator)
			select @idPoz, 'cantOk', @codBare, @cantOk , @locatie, @userASiS
				where @cantOk<>0
		union all
			select @idPoz, 'cantSp', @codBare, @cantSparta, @locatie, @userASiS
				where @cantSparta<>0
	end
		
		
	select 'back(1)' as actiune for xml raw, root('Mesaje');
	
end try
begin catch
	set @mesaj = ERROR_MESSAGE()+' (wmScriuWPozReceptii)'
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)

/*
select * from AntDisp

select * from PozDispOp
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
