
Create procedure wOPFisierImport @sesiune varchar(50), @parXML xml
as

declare @mesaj varchar(500), @cale_fisier varchar(2000), @database varchar(50), @cmdShellCommand varchar(300),
		@importXML xml, @selSelectare varchar(1), @selSuprascriere bit,
		@codMeniu varchar(100)

begin try
	set @database = db_name()
	if @database in ('edlia') and @@SERVERNAME='aswdev'
		raiserror('Nu este permis importul de machete pe aceasta baza de date!',16,1)
	if exists (select 1 from sys.objects where name='webconfigmeniu' and type='V')
		raiserror('O tabela de configurari este view! Nu este permis importul de machete in aceasta situatie!',16,1)
	select	@cale_fisier = isnull(@parXML.value('(/*/@cale_fisier)[1]','varchar(2000)'),''),
			@selSelectare= isnull(@parXML.value('(/*/@selSelectare)[1]','varchar(1)'),''),
			@selSuprascriere = isnull(@parXML.value('(/*/@selSuprascriere)[1]','bit'),''),
			@codMeniu = isnull(@parXML.value('(/*/@codMeniu)[1]','varchar(200)'),'')

	if @cale_fisier = ''
	begin
		set @mesaj = 'Nu s-a ales niciun fisier pentru import machete.'
		raiserror(@mesaj,16,1)
	end

	declare @caleform varchar(1000)
	select @caleform=rtrim(val_alfanumerica)+(case when left(reverse(rtrim(val_alfanumerica)),1)='\' then '' else '\' end)+'uploads\'
		from par where tip_parametru='AR' and parametru='caleform'

	declare @comanda nvarchar(4000)
	select @comanda='SELECT @importXML = convert(XML,x)
	FROM OPENROWSET
     (BULK '''+@caleform+@cale_fisier+''',
      SINGLE_BLOB) AS T(X)'
      
    EXEC sp_executesql @comanda, N'@importXML XML OUTPUT', @importXML OUTPUT;

	if isnull(@importXML.value('count(/machete/meniuri)','int'),0)=0 and isnull(@importXML.value('count(/machete/tipuri)','int'),0)=0
	begin
		set @mesaj = 'Nu exista machete de importat.'
		raiserror(@mesaj,16,1)
	end

	select 'Selectare machete' nume, @codMeniu codmeniu, 'SM' tip, 'SM' subtip, 'O' tipmacheta, (select @importXML, @selSelectare selSelectare, @selSuprascriere selSuprascriere for xml raw, type) dateInitializare
	for xml raw('deschideMacheta'), root('Mesaje')

end try

begin catch
	set @mesaj = error_message() + ' (wOPFisierImport)'
	raiserror(@mesaj, 11, 1)
end catch
