
CREATE PROCEDURE wOPPrefiltrareEtichete @sesiune VARCHAR(50), @parXML XML
AS

	declare 
		@denumire varchar(100), @grupa varchar(20), @utilizator varchar(100),@datajos datetime,@datasus datetime, @listeaza bit,
		@gestiune varchar(100), @stocExistent bit, @categorie varchar(20),@inperioada int,@pretvechidifpretnou int,@inpromotie varchar(1),@cod varchar(20),
		@cale_raport varchar(1000)

	select
		@inperioada=isnull(@parXML.value('(/*/@inperioada)[1]','int'),0),
		@datajos=@parXML.value('(/*/@datajos)[1]','datetime'),
		@datasus=@parXML.value('(/*/@datasus)[1]','datetime'),
		@denumire=NULLIF(@parXML.value('(/*/@denumire)[1]','varchar(100)'),''),
		@cod=NULLIF(@parXML.value('(/*/@cod)[1]','varchar(20)'),''),
		@gestiune=NULLIF(@parXML.value('(/*/@gestiune)[1]','varchar(100)'),''),
		@grupa=NULLIF(@parXML.value('(/*/@grupa)[1]','varchar(100)'),''),	
		@categorie=NULLIF(@parXML.value('(/*/@categpret)[1]','varchar(100)'),''),		
		@listeaza=ISNULL(@parXML.value('(/*/@listeaza)[1]','bit'),0),
		@stocExistent=ISNULL(@parXML.value('(/*/@stoc)[1]','bit'),0),
		@pretvechidifpretnou=ISNULL(@parXML.value('(/*/@pretvechidifpretnou)[1]','bit'),0),
		@cale_raport=ISNULL(@parXML.value('(/*/@cale_raport)[1]','varchar(1000)'),0),
		@inpromotie=ISNULL(@parXML.value('(/*/@inpromotie)[1]','varchar(1)'),0)

	if @categorie IS NULL
	begin
		raiserror('Acest program necesita obligatoriu precizarea unei categorii de pret!!!',16,1)
		return
	end

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	/*Tabele temporare cu datele nefiltrate din punct de vedere nomencl*/
	IF OBJECT_ID('tempdb.dbo.#temp_ListareCodBare') IS NOT NULL
		drop table #temp_ListareCodBare
	create table #temp_ListareCodBare (cod varchar (20))

	/* Daca nu am filtre pe categorie de pret sau gestiune*/
	delete temp_ListareCodBare where utilizator=@utilizator

	insert into temp_ListareCodBare(utilizator,cod,pret,pretvechi)
	select distinct
		@utilizator,RTRIM(n.cod),0,0
	from nomencl n
	left outer join stocuri s on s.cod_gestiune=@gestiune and s.cod=n.cod and abs(s.stoc)>0.01
	left outer join preturi p on p.um=@categorie and n.cod=p.cod_produs and ((p.Data_inferioara between @datajos and @datasus) or (p.Data_superioara between @datajos and @datasus))
	where 
		(@cod is null or n.cod=@cod)
		and (@denumire is null or n.denumire like '%'+@denumire+'%')
		and (@grupa is null or n.grupa=@grupa) 
		and (@gestiune is null or s.cod is not null)
		and (@inperioada=0 or p.cod_produs is not null)


	/*Inseram in tabelul pe utilizator*/
	insert into temp_ListareCodBare(utilizator,cod)	
	select @utilizator, l.cod 
	from #temp_ListareCodBare l

	create table #preturi(cod varchar(20),umprodus varchar(3),nestlevel int)
	
	insert into #preturi(cod,umprodus,nestlevel)
	select cod,'',@@NESTLEVEL
	from temp_ListareCodBare
	where utilizator=@utilizator

	exec CreazaDiezPreturi

	declare @parXMLPreturi xml
	select @parXMLPreturi= @parXML

	select @parxml
	exec wIaPreturi @sesiune=@sesiune, @parXML=@parXMLPreturi

	delete from #preturi where isnull(pret_amanunt,0)=0

	update t set pret=p.pret_amanunt_discountat,pretvechi=(case when p.inPromotie=1 and pret_amanunt_vechi>p.pret_amanunt_discountat then p.pret_amanunt_vechi else 0 end)
	from temp_ListareCodBare t
	inner join #preturi p on t.cod=p.cod
	where t.utilizator=@utilizator

	delete t
	from temp_ListareCodBare t 
	where t.utilizator=@utilizator and isnull(pret,0)=0


	if @pretvechidifpretnou=1
		delete from temp_ListareCodBare where isnull(pretvechi,0)=0


	if @inpromotie='D'
		delete t
		from temp_ListareCodBare t
		inner join #preturi p on t.cod=p.cod
		where t.utilizator=@utilizator and isnull(p.inpromotie,0)=0
	else if @inpromotie='N'
		delete t
		from temp_ListareCodBare t
		inner join #preturi p on t.cod=p.cod
		where t.utilizator=@utilizator and isnull(p.inpromotie,0)=1
	
	
	/* Iese si raportul daca s-a selectat*/
	if @listeaza=1
	begin
		declare @pXMLRap xml
		set @pXMLRap=(select 'EAN13' tip_cod,@cale_raport as 'cale_raport' for xml raw)
		exec wOPListareEticheteNomencl @sesiune=@sesiune, @parXML=@pXMLRap
	end
