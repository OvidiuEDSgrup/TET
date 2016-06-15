

create procedure wOPSchimbareStareContractSP @sesiune varchar(50),@parXML XML      
as

declare
	@mesaj varchar(max), @tip varchar(2), @idContract int, @stare int, @explicatii varchar(60), @utilizator varchar(100), @xml xml
	, @stareContract int

begin try
	set tran isolation level read uncommitted
	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

	select
		@tip = @parXML.value('(/*/@tip)[1]','varchar(2)'),
		@idContract = @parXML.value('(/*/@idContract)[1]','int'),
		@stare = @parXML.value('(/*/@stare)[1]','int'),
		@explicatii = isnull(@parXML.value('(/*/@explicatii_jurnal)[1]','varchar(60)'),'')
		
	select top (1)
		@stareContract=stare from JurnalContracte j where j.idContract=@idContract order by j.data desc, j.idJurnal desc

	--/*
	if @stare is null
		raiserror('Selectati starea contractului.',16,1)

	if @tip='RN' and @stare>(select top 1 s.stare from StariContracte s where s.tipContract=@tip and s.modificabil=1 order by s.stare)
		raiserror('Un necesar nu poate fi transmis catre sediu decat prin operatia de Operare la sediu!',16,1)
		
	if @tip='RN' and @stare<@stareContract and @stareContract>=5
		raiserror('Un necesar nu mai poate fi modificat odata ce a fost aprobat de catre sediu, decat daca sediul il aduce inapoi in starea Operat!',16,1)
		
	if @tip='RN' and @stare<@stareContract and @stareContract>=-5
	begin
		alter table necesaraprov disable trigger yso_tr_actualizeazaRN
		delete n
		from necesaraprov n join Contracte c on c.tip=@tip and c.numar=n.Numar and c.data=n.Data join PozContracte p on p.idPozContract=n.Numar_pozitie
		where c.idContract=@idContract and n.Stare='0'
		alter table necesaraprov enable trigger yso_tr_actualizeazaRN
		update p set starePoz=@stare
		from PozContracte p where p.idContract=@idContract
	end
--*/

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