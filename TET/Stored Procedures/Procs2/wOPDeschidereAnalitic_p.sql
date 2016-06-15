
CREATE PROCEDURE wOPDeschidereAnalitic_p @sesiune varchar(50), @parXML xml
as
begin try
	declare 
		@cont varchar(20), @dencont varchar(200), @cont_analitic varchar(20), @denumire_analitic varchar(200)

	select
		@cont=@parXML.value('(/*/@cont)[1]','varchar(20)'),
		@dencont=@parXML.value('(/*/@dencont)[1]','varchar(200)')
	
	select @cont_analitic = @cont, @denumire_analitic = @dencont
	
	select 
		@cont_analitic cont_analitic, @cont cont, @dencont dencont, @denumire_analitic denumire_analitic
	for xml raw, root('Date')

	IF EXISTS (select 1 from Conturi where cont=@cont and Are_analitice=1)
		raiserror ('Contul selectat are analitice!',16,1)
	IF @cont IS NULL
		raiserror ('Selectati un cont pentru care se va deschide analitic!',16,1)

end try
begin catch
	select '1' as inchideFereastra
	for xml raw, root('Mesaje')

	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch 
