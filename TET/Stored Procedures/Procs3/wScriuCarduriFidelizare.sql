--***
create procedure wScriuCarduriFidelizare @sesiune varchar(50), @parXML xml
as

declare @eroare varchar(1000)
set @eroare=''
begin try
	
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuCarduriFidelizareSP1')
		exec wScriuCarduriFidelizareSP1 @sesiune=@sesiune, @parXML=@parXML output
	if @parxml is null
		return 0

	declare @uid varchar(36), @tert varchar(20), @punctlivrare varchar(20), @persoanacontact varchar(20), @mijloctransport varchar(20), @blocat bit,
			@numeposesor varchar(200), @telposesor varchar(20), @emailposesor varchar(254), @update bit, @o_uid varchar(36), @detalii xml
	
	declare @utilizator varchar(100)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	select @uid=@parXML.value('(/row/@uid)[1]','varchar(36)'),
		@tert=@parXML.value('(/row/@tert)[1]','varchar(20)'),
		@punctlivrare=@parXML.value('(/row/@punctlivrare)[1]','varchar(20)'),
		@persoanacontact=@parXML.value('(/row/@persoanacontact)[1]','varchar(20)'),
		@mijloctransport=@parXML.value('(/row/@mijloctransport)[1]','varchar(20)'),
		@numeposesor=@parXML.value('(/row/@numeposesor)[1]','varchar(200)'),
		@telposesor=@parXML.value('(/row/@telposesor)[1]','varchar(20)'),
		@emailposesor=@parXML.value('(/row/@emailposesor)[1]','varchar(254)'),
		@update=isnull(@parXML.value('(/row/@update)[1]','bit'),0),
		@blocat=isnull(@parXML.value('(/row/@blocat)[1]','bit'),0),
		@o_uid = @parXML.value('(/row/@o_uid)[1]','varchar(36)'),
		@detalii = @parXML.query('/row/detalii/row')

	if isnull(@uid,'') = ''
		raiserror('Completati numarul unic de identificare al cardului!',16,1)

	if isnull(@numeposesor,'') = ''
		raiserror('Completati numele posesorului cardului!',16,1)
	
	-- insert-ul
	if @update=0
	begin
		if (isnull(@uid,'')='')	select @uid=newid()	--> numar nou de identificare (daca nu s-a furnizat unul)
		if exists (select 1 from CarduriFidelizare c where c.UID=@uid)
			raiserror('Numarul unic de identificare s-a folosit deja! Incercati din nou sau nu il completati!',16,1)
		insert into CarduriFidelizare(UID, Tert, Punct_livrare, Id_Persoana_contact, Mijloc_de_transport, Nume_posesor_card, Telefon_posesor_card, Email_posesor_card, detalii, utilizator, blocat)
			select @uid, @tert, @punctlivrare, @persoanacontact, @mijloctransport, @numeposesor, @telposesor, @emailposesor, @detalii, @utilizator, @blocat
	end
	--> modificarea
	else
	begin
		if (isnull(@uid,'')='') 
			raiserror('Numarul unic de indentificare nu este valid!',16,1)
		if (@uid<>@o_uid) 
			raiserror('Numarul unic de identificare nu este modificabil!',16,1)
		if not exists (select 1 from CarduriFidelizare c where c.UID=@uid) 
			raiserror ('Linia de modificat nu exista!',16,1)
		
		update CarduriFidelizare set uid=@uid, tert=@tert, Punct_livrare=@punctlivrare, Id_Persoana_contact=@persoanacontact, Mijloc_de_transport=@mijloctransport,
			Nume_posesor_card=@numeposesor, Telefon_posesor_card=@telposesor, Email_posesor_card=@emailposesor, detalii = @detalii, utilizator=@utilizator, blocat=@blocat
		where UID=@uid
	end
end try
begin catch
	set @eroare=ERROR_MESSAGE() + ' (wScriuCarduriFidelizare)'
end catch

if len(@eroare)>0 
	raiserror(@eroare,16,1)
