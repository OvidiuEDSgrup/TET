--***
create procedure [dbo].[wOPPopularePlanificare] (@sesiune varchar(50), @parXML xml)
as
begin try
	declare @rl_start int, @rl_stop int, @data_start datetime, @data_stop datetime,
			@utilaj varchar(20), @data_min datetime, @ore int, @subunitate char(9), @numar_fisa char(8),
			@comanda varchar(30), @stergere int,
			@nrpoz int
	select	@comanda=@parXML.value('(/parametri/@comanda)[1]','varchar(30)'),
			@stergere=isnull(@parXML.value('(/parametri/@stergere)[1]','int'),0)
			
	if (@stergere=1)	delete from planificare where Comanda=@comanda
	
	select @rl_start=8, @rl_stop=17, @data_start='1901-1-1', @nrpoz=0,
		@data_min=DATEADD(HOUR,datepart(hour,getdate())+1,
			convert(datetime,CONVERT(varchar(10),GETDATE(),120)))
				/**	aici, @data_min este data de la care se incepe lucrul pe un utilaj neplanificat pana acum*/
	if not exists (select 1 from lansman where Comanda=@comanda)
		raiserror('Nu exista date in lansman pentru comanda trimisa!',16,1)
	if exists (select 1 from planificare where Comanda=@comanda)
		raiserror('Comanda trimisa are deja date in tabela planificare!',16,1)
	set @subunitate=(select max(l.Subunitate) from lansman l where l.Comanda=@comanda)

	select
	comanda as lucrare, ceiling(cantitate_necesara) as ore, numar_de_inventar as utilaj, l.Numar_operatie as ordine,
		l.Numar_fisa
	into #lansman
	from lansman l 
	where Comanda=@comanda

	--select l.utilaj, max(isnull(p.Data_stop,@data_min)) from #lansman l inner join planificare p on l.utilaj=p.Utilaj

	--declare cr cursor for
	select l.utilaj,l.data_min into #liber from
		(select l.utilaj, 
			max(convert(datetime,isnull(
					CONVERT(datetime,
						convert(varchar(10),p.data_stop,120)--+' '+
						+' '+substring(p.ora_stop,1,2)+':'+substring(p.ora_stop,3,2)+':'+substring(p.ora_stop,5,2))
				,@data_min))) data_min
			from #lansman l left join planificare p on l.utilaj=p.Utilaj
			group by l.utilaj
		) l

	declare cr cursor for select l.utilaj, l.ore, l.numar_fisa, b.data_min from #lansman l, #liber b where l.utilaj=b.utilaj order by ordine
	/* cursor pe liniile din lansmat*/
	select top 0 Subunitate, Comanda, Tip, Numar_fisa, Numar_pozitie, Data_start, Ora_start, Data_stop, Ora_stop, Utilaj, Marca, Loc_de_munca, 24 ore
		into #planificare
		from planificare
		
	open cr
	fetch next from cr into @utilaj, @ore, @numar_fisa, @data_min
	while @@FETCH_STATUS=0
	begin		/**	de facut: fragmentare pe zile in functie de program de lucru(?)!*/
		--set @data_start=
		set @data_start=(case when @data_min>@data_start then @data_min else @data_start end)
		while @ore>0
		begin
			/* daca s-a terminat programul de lucru incep de a doua zi:	*/
			if (@data_start>=DATEADD(HOUR,@rl_stop-datepart(HOUR,@data_start),@data_start))
				set @data_start=dateadd(day,1,DATEADD(HOUR,@rl_start-datepart(HOUR,@data_start),@data_start))
			/* daca depasesc programul de lucru ma opresc la sfarsitul acestuia:	*/
			if dateadd(HOUR,@ore,@data_start)>DATEADD(HOUR,@rl_stop-datepart(HOUR,@data_start),@data_start)
			set @data_stop=DATEADD(HOUR,@rl_stop-datepart(HOUR,@data_start),@data_start)
			else set @data_stop=DATEADD(HOUR,@ore,@data_start)
--			select @ore,@data_start, @data_stop
/*			if (datepart(HOUR,@data_stop)>@rl_stop)		/*	tratez depasirea programului de lucru**/
			begin
				set @data_start=dateadd(day,1,DATEADD(HOUR,@rl_start-datepart(HOUR,@data_start),@data_start))
				set @data_stop=DATEADD(HOUR,@ore,@data_start)
			end*/
			
			set @nrpoz+=1
			insert into #planificare (Subunitate, Comanda, Tip, Numar_fisa, Numar_pozitie, Data_start, Ora_start, Data_stop, Ora_stop, Utilaj, Marca, Loc_de_munca, ore)
			select	@subunitate subunitate, @comanda comanda, 'U' Tip, @numar_fisa Numar_fisa,
					@nrpoz Numar_pozitie,
					convert(datetime,CONVERT(varchar(10),@data_start,120)),
					replace(CONVERT(varchar(10),@data_start,108),':',''),
					--@data_start,
					convert(datetime,CONVERT(varchar(10),@data_stop,120)),
					replace(CONVERT(varchar(10),@data_stop,108),':',''),
					--@data_stop,
					@utilaj utilaj, '' Marca, '' loc_de_munca
					,@ore
			set @ore=@ore-DATEDIFF(HOUR,@data_start,@data_stop)
			set @data_start=@data_stop
		end
		fetch next from cr into @utilaj, @ore, @numar_fisa, @data_min
	end
	
	insert into planificare (Subunitate, Comanda, Tip, Numar_fisa, Numar_pozitie, Data_start, Ora_start, Data_stop, Ora_stop, Utilaj, Marca, Loc_de_munca)
	select Subunitate, Comanda, Tip, Numar_fisa, Numar_pozitie, Data_start, Ora_start, Data_stop, Ora_stop, Utilaj, Marca, Loc_de_munca from #planificare
	/*	De facut: tratare planificare partiala a comenzii*/
	close cr
	deallocate cr
	--select * from #lansman order by l.ordine
	--select * from #liber
	drop table #lansman
	drop table #liber
	drop table #planificare
	select 'Comanda a fost planificata.' as textMesaj, 'Succes!' as titluMesaj for xml raw, root('Mesaje')
end try
begin catch
	IF OBJECT_ID('tempdb..#lansman') IS NOT NULL drop table #lansman
	IF OBJECT_ID('tempdb..#liber') IS NOT NULL drop table #liber
	IF OBJECT_ID('tempdb..#planificare') IS NOT NULL drop table #planificare
	--select ERROR_MESSAGE()
	declare @eroare varchar(1000)
	set  @eroare='popularePlanificare (linia '+convert(varchar(20),ERROR_LINE())+'):'+CHAR(10)+
			ERROR_MESSAGE()
	raiserror(@eroare,16,1)
end catch
