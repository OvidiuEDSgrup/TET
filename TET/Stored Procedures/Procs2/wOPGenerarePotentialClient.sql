CREATE procedure wOPGenerarePotentialClient @sesiune varchar(50), @parXML xml  
as 
begin try

	declare 
		@xmlPotential xml, @xmlContact xml, @xmlOportunitate xml, @cod_fiscal varchar(20), @dentert varchar(200), @localitate varchar(20), @note varchar(200), @contact varchar(100), @email varchar(100), @telefon varchar(100),
		@topic varchar(200), @descriere varchar(200), @probabilitate int, @idPotential int, @idLead int, @idContact int

	select
		@cod_fiscal=@parXML.value('(/*/@codfiscal)[1]','varchar(20)'),
		@dentert=@parXML.value('(/*/@dentert)[1]','varchar(200)'),
		@localitate=@parXML.value('(/*/@localitate)[1]','varchar(100)'),
		@note=@parXML.value('(/*/@note)[1]','varchar(200)'),
		@contact=@parXML.value('(/*/@contact)[1]','varchar(100)'),
		@email=@parXML.value('(/*/@email)[1]','varchar(100)'),
		@telefon=@parXML.value('(/*/@telefon)[1]','varchar(100)'),
		@topic=@parXML.value('(/*/@topic)[1]','varchar(200)'),
		@descriere=@parXML.value('(/*/@descriere)[1]','varchar(200)'),
		@probabilitate=@parXML.value('(/*/@probabilitate)[1]','int'),
		@idLead=@parXML.value('(/*/@idLead)[1]','int')



	set @xmlPotential=
	(
		select
			@cod_fiscal cod_fiscal, @dentert dentert, @note note, @localitate localitate
		for xml raw
	)

	exec wScriuPotential @sesiune=@sesiune, @parXML=@xmlPotential

	select @idPotential=IDENT_CURRENT('Potentiali')

	set @xmlOportunitate=
	(
		select
			@idPotential idPotential, @topic topic,@descriere descriere, @probabilitate probabilitate
		for xml raw
	)

	exec wScriuOportunitate @sesiune=@sesiune, @parXML=@xmlOportunitate

	set @xmlContact=
	(
		select
			@contact nume, @email email, @telefon telefon
		for xml raw
	)
	
	exec wScriuContacte @sesiune =@sesiune, @parXML=@xmlContact

	select @idPotential=IDENT_CURRENT('Contacte')

	declare @xmlleg xml
	set @xmlleg = (select @idContact idContact, @idPotential idPotential for xml raw)
	exec wScriuLegaturiCRM @sesiune=@sesiune, @parXML=@xmlleg

	exec wScriuContacte @sesiune=@sesiune, @parXML=@parXML
	delete from LEaduri where idLead=@idLead

end try

begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
