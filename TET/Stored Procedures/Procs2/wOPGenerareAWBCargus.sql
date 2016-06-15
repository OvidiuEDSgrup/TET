	
create procedure wOPGenerareAWBCargus @sesiune varchar(50), @parXML xml 
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
		@existaContCargus bit, @idContract int, @AWB varchar(200), @err varchar(1000), @dateAWB XML

	exec luare_date_par 'AR','AWBCARGUS',@existaContCargus OUTPUT,0,''

	IF ISNULL(@existaContCargus,0)=0
		RAISERROR('Nu este setat lucrul cu Cargus Web Express. Verificati parametri specifici (cont, utilizator si parola Cargus)',15,1)

	SELECT
		@idContract = @parXML.value('(/*/@idContract)[1]','int')
		

	-- S-ar mai putea face ceva procesari inainte, vedem
	select @dateAWB=@parXML

	exec wApelWSGenerareAWBCargus @sesiune=@sesiune, @parXML=@dateAWB OUTPUT
	select @AWB=@dateAWB.value('(/row/@awb)[1]','varchar(500)')


	IF @awb IS NOT NULL
	begin
		declare 
			@docJurnal xml

		update Contracte set AWB=@AWB where idContract=@idContract

		set @docJurnal=(select 'Generat AWB Cargus '+@AWB as explicatii, @idContract idContract,  GETDATE() AS data for xml raw, type)
		EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal
		
		select 'S-a generat cu succes in sistemul Cargus AWB-ul cu numarul: '+@AWB textMesaj, 'Notificare succes' titluMesaj for xml raw, root('Mesaje')
	end
end try
BEGIN CATCH
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
