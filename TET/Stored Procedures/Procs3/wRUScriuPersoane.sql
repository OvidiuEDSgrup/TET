/** procedura pentru scriere in catalogul RU_persoane **/
--***
Create procedure wRUScriuPersoane @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuPersoaneSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuPersoaneSP @sesiune, @parXML output
	return @returnValue
end

declare	@mesajeroare varchar(500), @utilizator char(10), @id_pers int, @tip varchar(1), @marca varchar(6), 
		@email varchar(200), @telefon_fix varchar(30), @telefon_mobil varchar(30), @openID varchar(100),
		@idmessenger varchar(50), @idfacebook varchar(50), @id_profesie int,
		@diploma varchar(100), @cnp varchar(13), @serie_bi varchar(2), @numar_bi varchar(10),
		@nume varchar(100), @codfunctie varchar(6), @loc_de_munca varchar(9), @judet varchar(15),
		@localitate varchar(30), @strada varchar(50), @numar varchar(5), @cod_postal int,
		@bloc varchar(10), @scara varchar(2), @etaj varchar(2), @apartament varchar(5),
		@sector int, @data_inreg datetime, @detalii xml, @update bit
begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
	
	select 
		@update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
		@id_pers = isnull(@parXML.value('(/row/@id_pers)[1]','int'),0),
		@tip =isnull(@parXML.value('(/row/@tip)[1]','varchar(1)'),''),
		@marca =isnull(@parXML.value('(/row/@marca)[1]','varchar(6)'),''),
		@email= isnull(@parXML.value('(/row/@email)[1]','varchar(200)'),''),
		@telefon_fix= isnull(@parXML.value('(/row/@telefon_fix)[1]','varchar(30)'),''),
		@telefon_mobil= isnull(@parXML.value('(/row/@telefon_mobil)[1]','varchar(30)'),''),
		@openid= isnull(@parXML.value('(/row/@openid)[1]','varchar(100)'),''),
		@idmessenger= isnull(@parXML.value('(/row/@idmessenger)[1]','varchar(50)'),''),
		@idfacebook= isnull(@parXML.value('(/row/@idfacebook)[1]','varchar(50)'),''),
		@id_profesie = isnull(@parXML.value('(/row/@id_profesie)[1]','int'),0),
		@diploma= isnull(@parXML.value('(/row/@diploma)[1]','varchar(100)'),''),
		@cnp= isnull(@parXML.value('(/row/@cnp)[1]','varchar(13)'),''),
		@serie_bi= isnull(@parXML.value('(/row/@serie_bi)[1]','varchar(2)'),''),
		@numar_bi= isnull(@parXML.value('(/row/@numar_bi)[1]','varchar(10)'),''),
		@nume= isnull(@parXML.value('(/row/@nume)[1]','varchar(100)'),''),
		@codfunctie = isnull(@parXML.value('(/row/@codfunctie)[1]','varchar(6)'),0),
		@loc_de_munca = isnull(@parXML.value('(/row/@loc_de_munca)[1]','varchar(9)'),0),
		@judet = isnull(@parXML.value('(/row/@judet)[1]','varchar(15)'),0),
		@localitate = isnull(@parXML.value('(/row/@localitate)[1]','varchar(30)'),0),
		@strada = isnull(@parXML.value('(/row/@strada)[1]','varchar(50)'),0),
		@numar = isnull(@parXML.value('(/row/@numar)[1]','varchar(5)'),0),
		@cod_postal = isnull(@parXML.value('(/row/@cod_postal)[1]','int'),0),
		@bloc = isnull(@parXML.value('(/row/@bloc)[1]','varchar(10)'),0),
		@scara = isnull(@parXML.value('(/row/@sacara)[1]','varchar(2)'),0),
		@etaj = isnull(@parXML.value('(/row/@etaj)[1]','varchar(2)'),0),
		@apartament = isnull(@parXML.value('(/row/@apartament)[1]','varchar(5)'),0),
		@sector = isnull(@parXML.value('(/row/@sector)[1]','int'),0),
		@data_inreg = isnull(@parXML.value('(/row/@data_inreg)[1]','datetime'),0)       
		
	if @update=1
		update RU_persoane set tip=@tip,marca=@marca,email=@email,
			telefon_fix=@telefon_fix,telefon_mobil=@telefon_mobil,openid=@openid,
			idmessenger=@idmessenger,idfacebook=@idfacebook,id_profesie=@id_profesie,
			diploma=@diploma,cnp=@cnp,serie_bi=@serie_bi,numar_bi=@numar_bi,nume=@nume,
			Cod_functie=@codfunctie,loc_de_munca=@loc_de_munca,judet=@judet,localitate=@localitate,
			strada=@strada,numar=@numar,cod_postal=@cod_postal,bloc=@bloc,scara=@scara,
			etaj=@etaj,apartament=@apartament,sector=@sector,data_inreg=@data_inreg
		where id_pers=@id_pers
	else 
		insert into RU_persoane(Tip,Marca,Email,Telefon_fix,Telefon_mobil,OpenID,Idmessenger,Idfacebook,ID_profesie,Diploma,
			CNP,Serie_BI,Numar_BI,Nume,Cod_functie,Loc_de_munca,Judet,Localitate,Strada,Numar,Cod_postal,Bloc,
			Scara,Etaj,Apartament,Sector,Data_inreg ,Detalii)
		select @tip,@marca,@email,@telefon_fix,@telefon_mobil,@openid,@idmessenger,
			@idfacebook,@id_profesie,@diploma,@CNP,@serie_bi,@numar_bi,@nume,@codfunctie,
			@loc_de_munca,@judet,@localitate,@strada,@numar,@cod_postal,@bloc,
			@scara,@etaj,@apartament,@sector,@data_inreg ,null				
end try

begin catch
	set @mesajeroare = '(wRUScriuPersoane) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
