
create procedure  wOPSchimbareFurnizor @sesiune varchar(30), @parXML XML
as
	declare
		@mesaj varchar(max), @cod varchar(20), @furnizor varchar(20), @xml xml, @utilizator varchar(50), @pret float

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	select
		@cod = isnull(@parXML.value('(/*/@cod)[1]','varchar(20)'),''),
		@furnizor = isnull(@parXML.value('(/*/@furnizor)[1]','varchar(20)'),'')

	if @cod = ''
		raiserror('Codul articolului nu este completat!',16,1)
	
	select top 1 @pret = pret from ppreturi where tert=@furnizor and cod_resursa=@cod
	update tmpArticoleCentralizator set furnizor=rtrim(@furnizor), pret=@pret where cod=rtrim(@cod) and utilizator=@utilizator

end try
begin catch
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
