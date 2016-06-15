
Create PROCEDURE wOPInlocuireCont_p @sesiune VARCHAR(50), @parXML XML
AS
begin try

	declare @cont_vechi varchar(20)

	select @cont_vechi=@parXML.value('(/*/@cont)[1]','varchar(20)')
	select 
		@cont_vechi cont_vechi,
		@parXML.value('(/*/@dencont)[1]','varchar(200)') dencont_vechi
	for xml raw, root('Date')

	if exists (select 1 from Conturi where cont=@cont_vechi and are_analitice=1)
			raiserror('Contul selectat are analitice!',16,1)
	if @cont_vechi IS NULL
		raiserror('Selectat un cont din tabel pe care doriti sa il inlocuiti!',16,1)

end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	select '1' as inchideFereastra for xml raw, root('Mesaje')

	raiserror (@mesaj, 15, 1)
end catch
