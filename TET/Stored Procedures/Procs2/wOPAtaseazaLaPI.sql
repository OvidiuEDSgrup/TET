create procedure  wOPAtaseazaLaPI @sesiune varchar(50), @parXML xml
as
begin try
declare @nrdoc varchar(30), @platiincasari int, @fdataAntet datetime, @stare int
select @nrdoc=isnull(@parXML.value('(/parametri/@numar)[1]','varchar(30)'),''),
	   @fdataAntet=isnull(@parXML.value('(/parametri/@fDataAntet)[1]','datetime'),'1900-01-01'),
	   @stare=isnull(@parXML.value('(/parametri/@stare)[1]','int'),0)
	   
if @stare!='1'
	raiserror('Ordinul de plata nu este in starea Generat!',16,1)
if @nrdoc='' 
	raiserror('Selectati o pozitie!',16,1)
update generareplati set val3=1 where data=@fdataAntet and Numar_document=@nrdoc
end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare='(wOPAtaseazaLaPI)'+ERROR_MESSAGE()
	raiserror(@mesajEroare,16,1)
end catch