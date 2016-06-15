
create procedure  wOPAdaugareFurnizor   @sesiune varchar(30), @parXML XML
as

	declare
		@mesaj varchar(max), @cod varchar(20), @tert varchar(20), @pstoc float, @codfurn varchar(20), @datapret datetime, @nrzile int, @cantmin float, @xml xml,
		@utilizator varchar(100)

begin try
	select
		@cod = rtrim(isnull(@parXML.value('(/*/@cod)[1]','varchar(20)'),'')),
		@tert = rtrim(isnull(@parXML.value('(/*/@tert)[1]','varchar(20)'),'')),
		@pstoc = isnull(@parXML.value('(/*/@pstoc)[1]','float'),0.0),
		@codfurn = rtrim(isnull(@parXML.value('(/*/@codf)[1]','varchar(20)'),'')),
		@datapret = isnull(@parXML.value('(/*/@datapret)[1]','datetime'),convert(varchar(10),getdate(),101)),
		@nrzile = isnull(@parXML.value('(/*/@nrzilelivr)[1]','int'),0),
		@cantmin = isnull(@parXML.value('(/*/@cantmin)[1]','float'),0.0)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	set	@xml = (select @cod as cod, @tert as tert, @pstoc as pstoc, @codfurn as codf, @datapret as datapret, @nrzile as nrzilelivr, @cantmin as cantmin for xml raw, type)

	exec wScriuFurnizoriArticol @sesiune=@sesiune,@parXML=@xml

	update tmpArticoleCentralizator 
		set furnizor=@tert, pret=@pstoc
	where cod=@cod and utilizator=@utilizator

end try
begin catch
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
