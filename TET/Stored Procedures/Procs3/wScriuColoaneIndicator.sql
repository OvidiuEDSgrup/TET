/* Prelucreaza descrierea coloanelor unui indicatori */
CREATE procedure wScriuColoaneIndicator  @sesiune varchar(50), @parXML XML
as

declare @codInd varchar(20), @update smallint, @nivel smallint, @denumire varchar(50), @tipGrafic smallint, @proceduraDate varchar(200), @o_nivel smallint,
		@tipSortare smallint

begin try

	select	@update = @parXML.value('(/row/row/@update)[1]', 'smallint'),
			@codInd = @parXML.value('(/row/@cod)[1]', 'varchar(20)'),
			@nivel = isnull(@parXML.value('(/row/row/@nivel)[1]', 'smallint'),-1),
			@o_nivel = isnull(@parXML.value('(/row/row/@o_nivel)[1]', 'smallint'),-1),
			@denumire = @parXML.value('(/row/row/@denumire)[1]', 'varchar(50)'),
			@tipGrafic = isnull(@parXML.value('(/row/row/@tipgrafic)[1]', 'smallint'),-1),
			@proceduraDate = @parXML.value('(/row/row/@procedura)[1]', 'varchar(200)'),
			@tipSortare = isnull(@parXML.value('(/row/row/@tipsortare)[1]', 'smallint'),0)
			
	-- nu mai validez nivel. La indicatori cu procedura pot fi oricate nivele...
	--if not (@nivel between 0 and 5)
		--raiserror('Nivelul introdus este invalid. Nivelul poate fi intre 0 si 5, 0 fiind de tip ''Data''.',11,1)
	
	if not (@tipGrafic between 0 and 3)
		raiserror('Tipul de grafic ales este invalid.',11,1)
	
	if not exists(select 1 from indicatori i where i.Cod_Indicator=@codInd)
		raiserror('Indicator invalid,',11,1)
	
	if isnull(len(@denumire),0)=0
		raiserror('Nu ati completat denumirea elementului.',11,1)
		
	set @proceduraDate=(case when LEN(rtrim(@proceduraDate))>2 then @proceduraDate else null end)

	if @update=1
	begin
		-- verific sa nu se faca replace la alt element...
		if @nivel<>@o_nivel and exists (select 1 from colind c where c.Cod_indicator = @codInd and c.Numar=@nivel)
			raiserror('Noul nivel ales este deja configurat!',11,1)
		
		update colind
			set Numar=@nivel, Denumire = @denumire, Tip_grafic = @tipGrafic,Procedura=@proceduraDate, tipSortare=@tipSortare
		where Cod_indicator = @codInd and Numar = @nivel
	end
	else
	begin
		if exists (select 1 from colind c where c.Cod_indicator = @codInd and c.Numar=@nivel)
			raiserror('Nivelul introdus este deja configurat!',11,1)
		
		insert colind(Cod_indicator, Numar, Denumire, Tip_grafic, Procedura, tipSortare)
			select @codInd, @nivel, @denumire, @tipGrafic, @proceduraDate, @tipSortare
	end
end try
begin catch
	declare @msgEroare varchar(2000)
	set @msgEroare=ERROR_MESSAGE()+'(wScriuColoaneIndicator)'
	raiserror (@msgEroare, 11, 1)
end catch
