--***

create procedure pStoc @sesiune varchar(50), @parXML xml
as
/*
	--> Exemplu apel:
	declare @p xml
	select @p=(select @dData dDataSus, @cCod cCod, @GestFiltru cGestiune, 1 GrCod, 1 GrGest, 1 GrCodi, @TipStoc TipStoc
	for xml raw)

		if object_id('tempdb..#docstoc') is not null drop table #docstoc
			create table #docstoc(subunitate varchar(9))
			exec pStocuri_tabela
		 
		exec pstoc @sesiune='', @parxml=@p	
		select * from #docstoc
*/
begin try
	--> creare tabela de transfer
	if object_id('tempdb..#docstoc') is null
	begin
		create table #docstoc(subunitate varchar(9))
		exec pStocuri_tabela
	end
	--> filtre
		--> aducerea continutului din parXML la lower case:
	select @parXML=convert(xml,lower(convert(varchar(max),@parxml)))
	declare @cufStocuri bit
	select @cufStocuri=isnull(@parXML.value('(row/@cufstocuri)[1]','int'),0)	--> flag fstocuri/pstocuri; poate fi trimis fortat prin parxml
	if @cufStocuri=0
		if EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'pStocuri'))
		select @cufStocuri=0
		else select @cufStocuri=1
	
	--> noua metoda
	IF  @cufStocuri=0
	begin
		exec pStocuri @sesiune=@sesiune, @parXML=@parXML
		return
	end
	--> vechea metoda:
	--> extragerea parametrilor din parXML:
	declare @dDataJos datetime, @dDataSus datetime, @cCod varchar(20), @cGestiune varchar(20), @cCodi varchar(20), @cGrupa varchar(13),
		@TipStoc varchar(1), @cCont varchar(40), @Corelatii int, 
		@Locatie varchar(30), @LM varchar(9), @Comanda varchar(40), @Contract varchar(20), @Furnizor varchar(13), @Lot varchar(20)
		, @faraFurnizor bit	--> luarea furnizorului inseamna un efort suplimentar, asa ca unde nu e nevoie se poate evita - atata timp cat filtrul @furnizor nu este completat
		--> parametri pentru partea de fStocuriCen
		,@Cen int			--> daca @cen nu e null/0 atunci cei trei parametri care urmeaza sunt <par>=isnull(<par>,1)
		,@GrCod int	--> daca vreunul din acesti 3 parametri nu e null/0 atunci @Cen va fi 1
		,@GrGest int
		,@GrCodi int

	select @dDataJos=convert(datetime,upper(@parXML.value('(row/@ddatajos)[1]','varchar(1000)'))),
		@dDataSus=convert(datetime,upper(@parXML.value('(row/@ddatasus)[1]','varchar(1000)'))),
		@cCod=@parXML.value('(row/@ccod)[1]','varchar(20)'),
		@cGestiune=@parXML.value('(row/@cgestiune)[1]','varchar(20)'),
		@cCodi=@parXML.value('(row/@ccodi)[1]','varchar(20)'),
		@cGrupa=@parXML.value('(row/@cgrupa)[1]','varchar(13)'),
		@TipStoc=isnull(@parXML.value('(row/@tipstoc)[1]','varchar(1)'),''),
		@cCont=@parXML.value('(row/@ccont)[1]','varchar(40)'),
		@Corelatii=@parXML.value('(row/@corelatii)[1]','int'), 
		@Locatie=@parXML.value('(row/@locatie)[1]','varchar(30)'),
		@LM=@parXML.value('(row/@lm)[1]','varchar(9)'),
		@Comanda=@parXML.value('(row/@comanda)[1]','varchar(40)'),
		@Contract=@parXML.value('(row/@contract)[1]','varchar(20)'),
		@Furnizor=@parXML.value('(row/@furnizor)[1]','varchar(13)'),
		@Lot=@parXML.value('(row/@lot)[1]','varchar(20)'),
		@faraFurnizor=isnull(@parXML.value('(row/@farafurnizor)[1]','bit'),0),	--> luarea furnizorului inseamna un efort suplimentar, asa ca unde nu e nevoie se poate evita - atata timp cat filtrul @furnizor nu este completat
		--> parametri pentru partea de fStocuriCen
		@Cen=@parXML.value('(row/@cen)[1]','int'),	--> daca @cen nu e null/0 atunci cei trei parametri care urmeaza sunt <par>=isnull(<par>,1)
		@GrCod=@parXML.value('(row/@grcod)[1]','int'),	--> daca vreunul din acesti 3 parametri nu e null/0 atunci @Cen va fi 1
		@GrGest=@parXML.value('(row/@grgest)[1]','int'),
		@GrCodi=@parXML.value('(row/@grcodi)[1]','int')
	--> tratare parametri pentru fStocuriCen:
		select @Cen=isnull(@Cen,0)
		if @Cen=1 select @GrCod=isnull(@GrCod,0), @GrGest=isnull(@GrGest,0), @GrCodi=isnull(@GrCodi,0)
		if @cen<>1 and (@GrCod=1 or @GrGest=1 or @GrCodi=1) select @cen=1
		

	-- apel procedura cu continutul fostei functii "fStocuri":
	exec docStocuri @sesiune, @dDataJos, @dDataSus, @cCod, @cGestiune, @cCodi, @cGrupa, @TipStoc, @cCont, @Corelatii, @Locatie, @LM, @Comanda, @Contract, @Furnizor, @Lot, @cen, @GrCod, @GrGest, @GrCodi, @parXML

end try
begin catch
	declare @eroare varchar(2000)
	select @eroare=error_message()+' (pStoc)'
	raiserror(@eroare,16,1)
end catch
