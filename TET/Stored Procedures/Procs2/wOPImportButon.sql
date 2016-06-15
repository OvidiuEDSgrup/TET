
create procedure wOPImportButon @sesiune varchar(50), @parXML xml
as

declare
	@mesaj varchar(max), @fis_buton varchar(500)

begin try
	select @fis_buton=@parXML.value('(/row/@fis_buton)[1]','varchar(500)')

	if isnull(@fis_buton,'')=''
		raiserror('Incarcati fisierul pentru import.',16,1)

	declare @caleform varchar(1000), @importXML xml
	select @caleform=rtrim(val_alfanumerica)+(case when left(reverse(rtrim(val_alfanumerica)),1)='\' then '' else '\' end)+'uploads\'
		from par where tip_parametru='AR' and parametru='caleform'

	declare @comanda nvarchar(4000)
	select @comanda='SELECT @importXML = convert(XML,x)
	FROM OPENROWSET
     (BULK '''+@caleform+@fis_buton+''',
      SINGLE_BLOB) AS T(X)'
      
    exec sp_executesql @comanda, N'@importXML XML OUTPUT', @importXML output

	declare
		@codButon varchar(50), @activ bit, @ordine int, @label varchar(500), @culoare varchar(50), @tipButon varchar(500), @ctrlKey bit, @tasta varchar(50),
		@procesarePeServer bit, @apareInPV bit, @apareInOperatii bit, @tipIncasare varchar(50), @meniu varchar(50), @tip varchar(50), @subtip varchar(50), @utilizator varchar(50)

	select
		@codButon = @importXML.value('(/row/@codButon)[1]','varchar(50)'),
		@activ = @importXML.value('(/row/@activ)[1]','bit'),
		@ordine = @importXML.value('(/row/@ordine)[1]','int'),
		@label = @importXML.value('(/row/@label)[1]','varchar(500)'),
		@culoare = @importXML.value('(/row/@culoare)[1]','varchar(50)'),
		@tipButon = @importXML.value('(/row/@tipButon)[1]','varchar(500)'),
		@ctrlKey = @importXML.value('(/row/@ctrlKey)[1]','bit'),
		@tasta = @importXML.value('(/row/@tasta)[1]','varchar(50)'),
		@procesarePeServer = @importXML.value('(/row/@procesarePeServer)[1]','bit'),
		@apareInPV = @importXML.value('(/row/@apareInPV)[1]','bit'),
		@apareInOperatii = @importXML.value('(/row/@apareInOperatii)[1]','bit'),
		@tipIncasare = @importXML.value('(/row/@tipIncasare)[1]','varchar(50)'),
		@meniu = @importXML.value('(/row/@meniu)[1]','varchar(50)'),
		@tip = @importXML.value('(/row/@tip)[1]','varchar(50)'),
		@subtip = @importXML.value('(/row/@subtip)[1]','varchar(50)'),
		@utilizator = @importXML.value('(/row/@utilizator)[1]','varchar(50)')

	if isnull(@codbuton,'')=''
		raiserror('Nu s-a putut identifica codul butonului.',16,1)

	if exists(select 1 from butoanePv where codButon=rtrim(@codButon))
		raiserror('Exista deja un buton cu acest cod.',16,1)

	insert into butoanePV(codButon,activ,ordine,label,culoare,tipButon,ctrlKey,tasta,procesarePeServer,apareInPV,apareInOperatii,tipIncasare,meniu,tip,subtip,utilizator)
	select @codButon,@activ,@ordine,@label,@culoare,@tipButon,@ctrlKey,@tasta,@procesarePeServer,@apareInPV,@apareInOperatii,@tipIncasare,@meniu,@tip,@subtip,@utilizator
end try

begin catch
	set @mesaj=error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 11, 1)
end catch
