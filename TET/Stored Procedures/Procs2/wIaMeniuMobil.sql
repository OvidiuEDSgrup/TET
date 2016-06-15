--***
	
create procedure wIaMeniuMobil @sesiune varchar(50), @parXML xml as

-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wIaMeniuMobilSP')
begin 
	declare @returnValue int
	exec @returnValue = wIaMeniuMobilSP @sesiune, @parXML output
	return @returnValue
end

declare @limba varchar(50), @modul varchar(50), @parinte varchar(50), @utilizator varchar(255), @actiune varchar(50),
		@msgEroare varchar(4000), @areSuperDrept bit
/* de tratat luarea modulului din XML daca se mai foloseste */
--Set @modul= isnull(@parXML.value('(/row/@modul)[1]','varchar(80)'),'')
	

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
if @utilizator is null
return -1

--set @limba= dbo.wfProprietateUtilizator('LIMBA',@utilizator);
set @parinte = ISNULL(@parXML.value('(/row/@meniuParinte)[1]', 'varchar(50)'), 'Mobile');
set @areSuperDrept=dbo.wfAreSuperDrept(@utilizator)

begin try	
	if OBJECT_ID('tempdb..#meniu') is not null
		drop table #meniu
	if OBJECT_ID('tempdb..#webConfigMeniuUtiliz') is not null
		drop table #webConfigMeniuUtiliz
	
	if not exists (select 1 from webconfigmeniu w where w.meniu=@parinte)
		and not exists (select 1 from webconfigmeniu w where w.meniuparinte=@parinte)
		raiserror ('Meniurile de mobile nu sunt configurate corect! Verificati existenta meniului Mobile si a subalternilor acestuia!',16,1)
		
	select w.Meniu,
		(case when max(charindex('S',w.Drepturi))>0 then 'S' else '' end)+
		(case when max(charindex('A',w.Drepturi))>0 then 'A' else '' end)+
		(case when max(charindex('M',w.Drepturi))>0 then 'M' else '' end)+
		(case when max(charindex('F',w.Drepturi))>0 then 'F' else '' end)+
		(case when max(charindex('O',w.Drepturi))>0 then 'O' else '' end)
		drepturi
	into #webConfigMeniuUtiliz
	from webConfigMeniuUtiliz w 
	inner join fIaGrupeUtilizator(@utilizator) f on w.IdUtilizator=f.grupa
	group by w.Meniu


	create table #meniu( denumire varchar(100), poza varchar(500), cod varchar(50), 
			parinte varchar(50), procDetalii varchar(100), nrordine decimal(7,2) constraint PK_meniu primary key(cod) )

	insert into #meniu (denumire, poza, cod, parinte, procDetalii, nrordine)
	select distinct RTRIM(wP.Nume) as denumire,'server://'+Icoana as poza,wP.meniu as cod,
			rtrim(wP.meniuParinte) as parinte, rtrim(wT.ProcDate) as procdetalii, wp.nrordine
		from webConfigMeniu wP
		left join #webConfigMeniuUtiliz mu on mu.Meniu = wP.Meniu
		inner join webconfigtipuri wT on wP.Meniu=wT.Meniu -- and wP.TipMacheta='L'
		where 
		wp.meniuParinte=@parinte and ISNULL(wp.vizibil,0)=1
		and (@areSuperDrept=1 or mu.Meniu is not null)
		
		order by wP.nrordine

	if ((select COUNT(1) from #meniu) = 1)
	begin
		declare @statement nvarchar(1000), @paramDef nvarchar(1000), @procDate varchar(100)
		set @procDate = (select top 1 procDetalii from #meniu)
		select  @statement = N'exec ' + @procDate + ' @sesiune=@sesiune, @parXML=@parXML',
				@paramDef = N'@sesiune varchar(50), @parXML XML',
				@parinte = isnull(nullif((select top 1 cod from #meniu),''),'wIaMeniuMobil') -- apelare recursiva pt. meniu ierarhic
		
		drop table #meniu

		if (@parXML.value('(/row/@meniuParinte)[1]','varchar(50)')) is null
			set @parXML.modify('insert attribute meniuParinte {sql:variable("@parinte")} into (/row)[1]')
		else
			set @parXML.modify('replace value of (/row/@meniuParinte)[1] with sql:variable("@parinte")')
			
		exec sp_executesql @statement, @paramDef, @sesiune = @sesiune, @parXML = @parXML

		/*nu conteaza detaliile atata timp cat exista la nivel de linie procdetalii*/
		select @procDate as detalii
		for xml raw,Root('Mesaje')
	end
	else
	begin
		select denumire as denumire, poza as poza, cod as cod, parinte as parinte, procDetalii as procdetalii
		from #meniu
			order by nrordine
		for xml raw
			
		/*nu conteaza detaliile atata timp cat exista la nivel de linie procdetalii*/
		select 'wmIaTerti' as detalii,'Meniu' as titlu , '@meniuParinte' as _numeAtr
		for xml raw,Root('Mesaje')
	
		select '@meniuParinte,@searchText' as atribute for xml raw('atributeRelevante'),root('Mesaje')
	end
	
	
end try

begin catch
	set @msgEroare='(wIaMeniuMobil)'+ERROR_MESSAGE();
end catch

if OBJECT_ID('tempdb..#meniu') is not null
		drop table #meniu;

if (len(@msgEroare) > 0)
	raiserror (@msgEroare, 11, 1)
