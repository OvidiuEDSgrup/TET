

create procedure wOPSchimbareStareContract @sesiune varchar(50),@parXML XML      
as

declare
	@mesaj varchar(max), @tip varchar(2), @idContract int, @stare int, @explicatii varchar(60), @utilizator varchar(100), @xml xml

begin try
	
	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

	select
		@tip = @parXML.value('(/*/@tip)[1]','varchar(2)'),
		@idContract = @parXML.value('(/*/@idContract)[1]','int'),
		@stare = @parXML.value('(/*/@stare)[1]','int'),
		@explicatii = isnull(@parXML.value('(/*/@explicatii_jurnal)[1]','varchar(60)'),'')


	/*
	if (select top 1 
		isnull(s.inchisa,0)
	from JurnalContracte j
		inner join StariContracte s on j.stare=s.stare and s.tipContract=@tip	
	where idContract=@idContract 
	order by data desc)=1
		raiserror('Starea unui contract inchis nu poate fi schimbata.',16,1)
*/

	if @stare is null
		raiserror('Selectati starea contractului.',16,1)

	select @xml =
		(select
			@idContract as idContract,
			getdate() as data,
			rtrim(@explicatii) as explicatii,
			@stare as stare
		for xml raw)

	exec wScriuJurnalContracte @sesiune=@sesiune, @parXML=@xml

end try

begin catch
	set @mesaj=error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 16, 1)
end catch
