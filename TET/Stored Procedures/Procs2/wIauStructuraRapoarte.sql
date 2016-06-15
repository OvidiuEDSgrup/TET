--***
CREATE procedure wIauStructuraRapoarte @sesiune varchar(50),@parXML xml as
begin
	declare @eroare varchar(1000)
	begin try
		declare @bdrep varchar(100), @areSuperDrept bit, @utilizator VARCHAR(100)
		select @bdrep=rtrim(val_alfanumerica) from par where tip_parametru='AR' and parametru='REPSRVBAZ'
		set @bdrep=(case when @bdrep is null or @bdrep='' then 'ReportServer' else @bdrep end)
		if not exists (select 1 from sys.databases where name=@bdrep)
		begin
			set @eroare='Baza de date pentru Reporting ("'+@bdrep+'") nu se afla pe server!'
			raiserror(@eroare,16,1)
		end
		declare @comanda varchar(4000)
		
		EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
		SET @areSuperDrept = dbo.wfAreSuperDrept(@utilizator)

		set @comanda=
		'select [Type] as ''@tipnumeric'', (case [Type] when 1 then ''Director'' else ''Raport'' end) as ''@tip'', 
			  [Path] as ''@cale'', [Name] as ''@nume'', ItemId as ''@Id'', parentid,
			  convert(xml,null) as tree, 0 as gata into #tmp from ['+@bdrep+'].dbo.Catalog r
		where exists (select 1 from ['+@bdrep+']..catalog r1 where r1.path like rtrim(r.path)+''%'' and r1.Type=2)
			
		if '+convert(char(1),@areSuperDrept)+' != 1
			delete t from #tmp t where [@tipnumeric]<>1 and 
			not exists(select 1 from webConfigRapoarte w inner join fIaGrupeUtilizator('''+@utilizator+''') f on w.utilizator=f.grupa
			where rtrim(t.[@cale]) collate SQL_Latin1_General_CP1_CI_AS=rtrim(w.caleRaport) collate SQL_Latin1_General_CP1_CI_AS)

		declare @i int
		set @i=1
		update t set gata=1 from #tmp t where not exists (select 1 from #tmp t1 where t.[@id]=t1.parentid)
		while exists (select 1 from #tmp where gata=0)
		begin
			set @i=@i+1
			update t set gata=1,tree=
					(select [@tipnumeric], [@tip], [@cale], [@nume], [@ID], (select [tree])
						from #tmp t1 where t.[@id]=t1.parentid and ([tree] is not null or [@tipnumeric]=2)
					order by [@cale] FOR XML PATH (N''row''), TYPE)
				from #tmp t where not exists 
					(select 1 from #tmp t1 where t.[@id]=t1.parentid and gata=0)
		end

		select [@tipnumeric], [@tip], [@cale], [@nume], [@ID], (select [tree]) from #tmp where [@cale]=''''
				order by [@cale]
			FOR XML PATH (N''row''), TYPE

		drop table #tmp'
		print @comanda
		exec (@comanda)
	end try
	begin catch
		set @eroare='wIauStructuraRapoarte (linia '+convert(varchar(20),ERROR_LINE())+'):'+CHAR(10)+
				ERROR_MESSAGE()
		raiserror(@eroare,16,1)
	end catch
end
