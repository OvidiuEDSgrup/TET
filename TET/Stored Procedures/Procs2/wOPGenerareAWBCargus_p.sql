	
create procedure wOPGenerareAWBCargus_p @sesiune varchar(50), @parXML xml 
as
begin try	
		/*
			
			Setarile specifice pt. cei care lucreaza cu Cargus Web Express
				
				INSERT INTO PAR (tip_parametru, parametru, denumire_parametru, val_logica, val_numerica, val_alfanumerica)
				SELECT 'AR','AWBCARGUS','Lucreaza cu Cargus WebExpress',1,0,'' union
				SELECT 'AR','CNTCARGUS','Contul de acces Cargus',0,0,'TSD' union
				SELECT 'AR','USRCARGUS','Utilizatorul Cargus',0,0,'cargus_test' union
				SELECT 'AR','PASCARGUS','Parola Cargus',0,0,'123' 
				
		*/
	declare 
		@existaContCargus bit, @idContract int, @AWB varchar(200), @err varchar(1000), @utilizator varchar(500)

	exec luare_date_par 'AR','AWBCARGUS',@existaContCargus OUTPUT,0,''

	IF ISNULL(@existaContCargus,0)=0
		RAISERROR('Nu este setat lucrul cu Cargus Web Express. Verificati parametri specifici (cont, utilizator si parola Cargus)',15,1)

	SELECT
		@idContract = @parXML.value('(/*/@idContract)[1]','int')
		
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	SELECT @AWB= AWB from Contracte where idContract=@idContract
	IF ISNULL(@AWB,'')<>''
	begin
		select @err='Comanda selectata are asociat deja un AWB ( '+@AWB+' )'
		raiserror(@err, 15, 1)
	end

	/*
		Valori prepopulate
	*/
	declare
		@firma varchar(200), @adresa varchar(400), @judet varchar(20), @oras varchar(500), @destinatar varchar(200), @email varchar(20),@telefon_dest varchar(200),
		@cod_postal varchar(200), @adresa_dest varchar(300), @cod_postal_dest varchar(100), @oras_dest varchar(200), @judet_dest varchar(200), @telefon_exp varchar(200)

	select 
		@destinatar=rtrim(t.denumire),
		@adresa_dest=rtrim(adresa),
		@cod_postal_dest=t.detalii.value('(/*/@cod_postal)[1]','varchar(6)'), 
		@oras_dest=rtrim(localitate), 
		@judet_dest=rtrim(judet),
		@telefon_dest=rtrim(Telefon_fax )
	from terti t join contracte c on c.idContract=@idContract and c.tert=t.tert
	
	exec luare_date_par 'GE','ADRESA',0,0,@adresa OUTPUT
	exec luare_date_par 'GE','EMAIL',0,0,@email OUTPUT
	exec luare_date_par 'GE','JUDET',0,0,@judet OUTPUT
	exec luare_date_par 'GE','SEDIU',0,0,@oras OUTPUT
	exec luare_date_par 'GE','ADRESA',0,0,@adresa OUTPUT
	exec luare_date_par 'GE','NUME',0,0,@firma OUTPUT
	exec luare_date_par 'GE','CODPOSTAL',0,0,@cod_postal OUTPUT
	exec luare_date_par 'GE','TELFAX',0,0,@telefon_exp OUTPUT

	select top 1 @judet=rtrim(cod_judet) from judete where denumire=rtrim(@judet)
	
	IF len(@judet_dest)>2
		select top 1 @judet_dest=rtrim(cod_judet) from judete where denumire=rtrim(@judet_dest)

	select @utilizator=rtrim(nume) from utilizatori where id=@utilizator

	IF OBJECT_ID('tempdb.dbo.#populare_awb') IS NOT NULL
		drop table #populare_awb

	select 
		rtrim(@destinatar) destinatar,
		rtrim(@destinatar) dendestinatar, 
		rtrim(@firma) expeditor,
		rtrim(@adresa) adresa_exp,
		rtrim(@judet) judet_exp,
		rtrim(@oras) oras_exp,
		rtrim(@oras) denoras_exp,
		RTRIM(@email ) email_exp,
		RTRIM(@cod_postal) zip_exp,
		RTRIM(@adresa_dest) adresa_dest,
		RTRIM(@cod_postal_dest) zip_dest,
		RTRIM(@judet_dest) judet_dest,
		rtrim(@oras_dest) oras_dest,
		rtrim(@oras_dest) denoras_dest,
		RTRIM(@utilizator) contact_exp,
		RTRIm(@telefon_exp) telefon_exp,
		RTRIM(@telefon_dest ) telefon_dest
	INTO #populare_awb

	/*
		Procedura specifica va lucra cu tabelul #populare_awb pt. a completa reguli specifice
			(ex. 
				se poate popula valoare asigurata sau valoarea ramburs cu valoarea din comanda
				poate exista "conventii" cu tertii: unii platesc ramburs intotdeauna, altii vor retur de documente
				SAMD
			)

	*/
	IF EXISTS (select 1 from sysobjects where name='wOPGenerareAWBCargus_pSP' )
		exec wOPGenerareAWBCargus_pSP @sesiune=@sesiune, @parXML=@parXML


	select * from #populare_awb for xml raw, root('Date')

end try
BEGIN CATCH
	select '1' as inchideFereastra for xml raw, root('Mesaje')
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
