
create procedure wScriuButoanePV @sesiune varchar(50), @parXML xml
as

declare
	@mesaj varchar(max), @codButon varchar(50), @activ bit, @ordine int, @label varchar(500), @culoare varchar(50), @tipButon varchar(500),
	@ctrlKey bit, @tasta varchar(50), @procesarePeServer bit, @apareInPv bit, @apareInOperatii bit, @tipIncasare varchar(50), @meniu varchar(50),
	@tip varchar(50), @subtip varchar(50), @utilizator varchar(50), @update bit, @o_codButon varchar(50)

begin try
	select
		@codButon = @parXML.value('(/row/@codButon)[1]','varchar(50)'),
		@activ = isnull(@parXML.value('(/row/@activ)[1]','bit'),0),
		@ordine = @parXML.value('(/row/@ordine)[1]','int'),
		@label = @parXML.value('(/row/@label)[1]','varchar(500)'),
		@culoare = @parXML.value('(/row/@culoare)[1]','varchar(50)'),
		@tipButon = @parXML.value('(/row/@tipButon)[1]','varchar(500)'),
		@ctrlKey = isnull(@parXML.value('(/row/@ctrlkey)[1]','bit'),0),
		@tasta = nullif(@parXML.value('(/row/@tasta)[1]','varchar(50)'),''),
		@procesarePeServer = @parXML.value('(/row/@procServer)[1]','bit'),
		@apareInPv = isnull(@parXML.value('(/row/@aparePV)[1]','bit'),0),
		@apareInOperatii = isnull(@parXML.value('(/row/@apareOP)[1]','bit'),0),
		@tipIncasare = nullif(@parXML.value('(/row/@tipIncasare)[1]','varchar(50)'),''),
		@meniu = @parXML.value('(/row/@meniuPV)[1]','varchar(50)'),
		@tip = @parXML.value('(/row/@tipPV)[1]','varchar(50)'),
		@subtip = @parXML.value('(/row/@subtipPV)[1]','varchar(50)'),
		@utilizator = @parXML.value('(/row/@utilizator)[1]','varchar(50)'),
		@update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
		@o_codButon = @parXML.value('(/row/@o_codButon)[1]','varchar(50)')

	if exists(select 1 from butoanePV where codButon=@codButon) and @update=0
		raiserror('Exista deja un buton cu acest cod!',16,1)

	if isnull(@codButon,'')=''
		raiserror('Completati campul cod buton!',16,1)

	if isnull(@tipButon,'')=''
		raiserror('Completati campul tip buton!',16,1)

	if isnull(@ordine,'')=''
		raiserror('Completati campul ordine!',16,1)

	if @update=1
	begin
		update butoanePv
		set
			codButon=@codButon,
			activ=@activ,
			ordine=@ordine,
			label=@label,
			culoare=@culoare,
			tipButon=@tipButon,
			ctrlKey=@ctrlKey,
			tasta=@tasta,
			procesarePeServer=@procesarePeServer,
			apareInPv=@apareInPV,
			apareInOperatii=@apareInOperatii,
			tipIncasare=@tipIncasare,
			meniu=nullif(left(@meniu,20),''),
			tip=nullif(left(@tip,2),''),
			subtip=nullif(left(@subtip,2),''),
			utilizator=nullif(@utilizator,'')
		where codButon=@o_codButon
	end
	else
	begin
		insert into butoanePv
		select @codButon, @activ, @ordine, @label, @culoare, @tipButon, @ctrlKey, @tasta, @procesarePeServer, @apareInPv, @apareInOperatii, @tipIncasare,
		nullif(left(@meniu,20),''), nullif(left(@tip,2),''), nullif(left(@subtip,2),''), nullif(@utilizator,'')
	end
end try

begin catch
	set @mesaj=error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 11, 1)
end catch
