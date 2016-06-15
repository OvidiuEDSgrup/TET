--***
create procedure wOPModificarePretRM @sesiune varchar(50), @parXML xml 
as  
begin
	/*Procedura primeste datele din grid si vede pretamanunt (editabil) fata de pret_cu_amanuntul (vechiul pret)
	Va trimite la wScriuPreturiNomenclator pentru a modifica preturile.
	*/
	declare @iDoc int,@idPozDoc int,@categpret int,@tipGestiune varchar(1)
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlPreturi') IS NOT NULL
		DROP TABLE #xmlPreturi
	
	select	@idpozdoc=isnull(@parXML.value('(/*/@idpozdoc)[1]','int'),0)
	
	select @categpret=isnull(pr.valoare,0),@tipGestiune=g.tip_gestiune
	from pozdoc p
	left outer join gestiuni g on p.gestiune=g.cod_gestiune
	left outer join proprietati pr on pr.tip='GESTIUNE' and pr.cod_proprietate='CATEGPRET'
	where idPozDoc=@idPozDoc

	if isnull(@categpret,0)=0
		set @categpret=1

	SELECT *
	INTo #xmlPreturi
	FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
	WITH
	(
		catpret int '@catpret',
		oldpret float '@pret_cu_amanuntul',
		newpret float '@pretamanunt',
		data datetime'../../@data',
		subunitate VARCHAR(13) '../../@subunitate'
		,cod VARCHAR(20) '../../@cod'
	)
	EXEC sp_xml_removedocument @iDoc

	declare @subunitate varchar(20),@cod varchar(20),@nF int,@dData varchar(10),@pX xml,@catpret varchar(3),@newpret decimal(12,3),@gestiune varchar(20)
	set @nF=0
	select @subunitate=max(subunitate),@cod=max(cod),@dData=convert(varchar(10),max(data),101) from #xmlPreturi

	declare tmpPreturi cursor for
		select catpret,newpret from #xmlPreturi
		where oldpret!=newpret
	open tmpPreturi
	fetch next from tmpPreturi into @catpret,@newpret
	set @nF=@@fetch_status
	while @nF=0
	begin
		set @pX=(select @cod as '@cod',
			(select 'PR' as '@tip',@catpret as '@catpret','1' as '@tippret',@newpret as '@pret_cu_amanuntul',@dData as '@data_inferioara'
			for xml path,type)
		for xml path,type)
	
		exec wScriuPreturiNomenclator @sesiune=@sesiune,@parXML=@pX
		if @catpret=@categpret and @tipGestiune='A'--Suntem pe categoria de pret atasata gestiunii
			update pozdoc set pret_cu_amanuntul=@newpret where idpozdoc=@idpozdoc
			
		
		fetch next from tmpPreturi into @catpret,@newpret
		set @nF=@@fetch_status
	end

	close tmpPreturi
	deallocate tmpPreturi
	drop table #xmlPreturi
end
