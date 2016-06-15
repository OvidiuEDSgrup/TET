--***
CREATE procedure wIaArticolePv @sesiune varchar(40), @parXML xml
as
declare @returnValue int, @msgEroare varchar(500)
if exists(select * from sysobjects where name='wIaArticolePvSP1' and type='P')      
begin
	exec @returnValue = wIaArticolePvSP1 @sesiune=@sesiune,@parXML=@parXML output
	if @parXML is null
		return @returnValue 
end

begin try
	declare @grupa varchar(13), @gestiune varchar(20), @gestutiliz varchar(20), @categoriePret int, 
			@cSub char(9), @utilizator varchar(20), @preturi int, @xmlString varchar(max), @indexNext int, @indexPrevious int,
			@nrElemente int, @pagina int, @start int, @nivel smallint, @cuButonUp bit, @cuButonPrevious bit, @cuButonNext bit
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	
	select	@grupa = isnull(@parXML.value('(/row/@grupa)[1]','varchar(80)'),''),
			@nrElemente = isnull(@parXML.value('(/row/@numarvizibil)[1]','int'), 999),
			@nivel = isnull(@parXML.value('(/row/@nivel)[1]','int'), 1), -- nivelul incepe de la 1
			@start = isnull(@parXML.value('(/row/@start)[1]','int'), 1),
			
			@cuButonPrevious=(case when @start<=1 then 0 else 1 end),
			@cuButonUp=(case when @nivel>1 then 1 else 0 end)
	
	/* la calculare nr elemente afisate, verific daca pun butoane */
	select	@nrElemente = @nrElemente - @cuButonUp - @cuButonPrevious,
			@indexPrevious = @start - @nrElemente + 1
	
	set @parXML.modify('replace value of (/row/@numarvizibil)[1] with sql:variable("@nrElemente")')
	
	-- ajunge index=2 cand da back sa ajunga la prima pagina, iar prima pagina nu are butonul de back afisat
	if @indexPrevious<=2
		set @indexPrevious=1
		
	if OBJECT_ID('tempdb..#articolePv') is not null
		drop table #articolePv
	create table #articolePv(rownumber int, xmlData xml)
	
	if @grupa <> '' and not exists(select 1 from grupe where grupa_parinte=@grupa)
		exec wIaNomenclatorPV @sesiune=@sesiune, @parXML=@parXML
	else
		exec wIaGrupeProdusePv @sesiune=@sesiune, @parXML=@parXML

	-- daca produsele ar umple toate pozitiile, sterg ultima pozitie si adaug butonul de next.
	if (select COUNT(*) from #articolePv)=@nrElemente
	begin
		-- salvez in @indexNext linia care trebuie afisata pe urmatoarea pagina, si o trimit la next.
		select @indexNext=MAX(rownumber) from #articolePv
		delete from #articolePv where rownumber=@indexNext
		set @cuButonNext=1
	end

	select @xmlString=isnull(@xmlString,'')+CONVERT(varchar(max), xmlData)
		from #articolePv order by rownumber
		
	set @xmlString=
		(case when @cuButonUp=1 then (select 'up' actiune, '1' goBack, 'Sus' denumire, '/assets/img/sageata-sus.png' poza for xml raw)+CHAR(13) else '' end)+
		(case when @cuButonPrevious=1 then (select @indexPrevious start, 'previous' actiune, 'Stanga' denumire,
			'/assets/img/sageata-stanga.png' poza for xml raw)+CHAR(13) else '' end)+
		@xmlString+
		(case when @cuButonNext=1 then (select @indexNext start, 'next' actiune, 'Dreapta' denumire, 
			'/assets/img/sageata-dreapta.png' poza for xml raw)+CHAR(13) else '' end)
	
	--select * from #articolePv
	
	select convert(xml,@xmlString)
end try
begin catch
set @msgEroare=ERROR_MESSAGE()+'(wIaArticolePv)'
raiserror(@msgEroare,11,1)
end catch	
