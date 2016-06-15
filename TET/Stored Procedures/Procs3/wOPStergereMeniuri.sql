--***
create procedure wOPStergereMeniuri @sesiune varchar(50), @parXML xml
as
declare @eroare varchar(max)
select @eroare=''
begin try
	declare @database varchar(1000)
	set @database = db_name()
	if @database in ('ghita','edlia') and @@SERVERNAME='aswdev'
		raiserror('Nu este permisa stergerea de machete pe aceasta baza de date!',16,1)
	declare @meniu varchar(20), @sursa varchar(50), @tip varchar(20), @subtip varchar(20), @export bit, @fortare_stergere bit
	select	@meniu=@parXML.value('(parametri/@meniu)[1]','varchar(20)'),
			@sursa=@parXML.value('(parametri/@sursa)[1]','varchar(50)'),
			@tip=rtrim(isnull(@parXML.value('(parametri/@tip_m)[1]','varchar(20)'),'')),
			@subtip=rtrim(isnull(@parXML.value('(parametri/@subtip_m)[1]','varchar(20)'),'')),
			@export=isnull(@parXML.value('(parametri/@export)[1]','bit'),1)
			,@fortare_stergere=isnull(@parXML.value('(parametri/@fortare_stergere)[1]','bit'),1)
	
	if @meniu is null
		raiserror('Selectati o linie pentru stergere!',16,1)
	
	--> tabela cu lista de configurari de sters:
	if object_id('tempdb..#tipuri') is null
	begin
		create table #tipuri(meniu varchar(20))
		exec wOPGasesteRelatiiConfigurari_tabela @sesiune=@sesiune, @parXML=null
	end
	exec wOPGasesteRelatiiConfigurari @sesiune=@sesiune, @parXML=@parXML
	
	-->	configurarile care nu apartin de meniul de sters, fiind folosite doar prin webconfigtaburi se vor sterge doar daca nu mai sunt folosite altundeva (exemplu de nesters: note contabile):
	--select * from 
	delete t
	from #tipuri t
		where t.tabela='webconfigtipuri_tab'
			--> exista in alte taburi:
			and (
				exists (select 1 from webconfigtaburi w
					where w.meniunou=t.meniu and w.tipnou=t.tip	--> care sa nu existe deja in #tipuri:
						and not exists (select 1 from #tipuri t1 where t1.meniu=w.meniusursa))
				--> exista ca meniu de sine statator:
				or exists (select 1 from webconfigmeniu w
					where w.meniu=t.meniu	--> care sa nu existe deja in #tipuri:
						and not exists (select 1 from #tipuri t1 where t1.meniu=w.meniu and t1.tabela='webconfigmeniu'))
			)

	--> configurarile care apartin de meniul de sters dar sunt folosite in alte locuri - prin webconfigtaburi - vor determina eroare la stergere:
	if @fortare_stergere=0 and exists (select 1 from #tipuri t where t.tabela='webconfigtipuri_reftab')
	begin
		set @eroare='Meniul este folosit prin webconfigtaburi! Consultati tipurile pentru care coloana "tabela" este "webconfigtipuri_reftab" sau folositi bifa de "Fortare stergere"!'
		raiserror(@eroare,16,1)
	end
	
	if @export=1
	begin
		declare @p xml
		select @p=(select @meniu f_meniu, @tip f_tip, @subtip f_subtip for xml raw)
		create table #p(p xml)
		insert into #p
		exec wiaconfiguraremachete @sesiune=@sesiune, @parxml=@p
		select @p=(select p.query('Date/Ierarhie/*') from #p for xml path('parametri'))
		declare @fisier varchar(2000)
		select @fisier=replace(
				replace(
				@parXML.value('(parametri/@nume)[1]','varchar(max)')
				,' ','_')
				,'/','_')
		set @p.modify('insert attribute fisier {sql:variable("@fisier")} into (/parametri)[1]')
		exec wOPExportMachete @sesiune=@sesiune, @parxml=@p
	end
	
	declare @nr_meniu varchar(20), @nr_tipuri varchar(20), @nr_form varchar(20), @nr_grid varchar(20), @nr_filtre varchar(20), @nr_taburi varchar(20)
			,@nr_formmobile varchar(20)
			,@mesaj varchar(max)
--/*		--> stergerea propriu-zisa:

	if db_name() in ('ghita','edlia') and @@SERVERNAME='aswdev'
		raiserror('Nu s-a sters nimic! De pe bazele de date de dezvoltare nu este permisa stergerea!',16,1)
		
	delete w from webconfigmeniu w, #tipuri t  where t.tabela='webconfigmeniu' and w.meniu=t.meniu
	select @nr_meniu=convert(varchar(20),@@ROWCOUNT)
	delete w from webconfigtipuri w, #tipuri t  where t.tabela in ('webconfigtipuri','webconfigtipuri_tab') and w.meniu=t.meniu and (t.tip='' or isnull(w.tip,'')=t.tip) and (t.subtip='' or isnull(w.subtip,'')=t.subtip)
	select @nr_tipuri=convert(varchar(20),@@ROWCOUNT)
	delete w from webconfigform w, #tipuri t  where t.tabela in ('webconfigtipuri','webconfigtipuri_tab') and w.meniu=t.meniu and (t.tip='' or isnull(w.tip,'')=t.tip) and (t.subtip='' or isnull(w.subtip,'')=t.subtip)
	select @nr_form=convert(varchar(20),@@ROWCOUNT)
	delete w from webconfiggrid w, #tipuri t  where t.tabela in ('webconfigtipuri','webconfigtipuri_tab') and w.meniu=t.meniu and (t.tip='' or isnull(w.tip,'')=t.tip) and (t.subtip='' or isnull(w.subtip,'')=t.subtip)
	select @nr_grid=convert(varchar(20),@@ROWCOUNT)
	delete w from webconfigfiltre w, #tipuri t  where t.tabela in ('webconfigtipuri','webconfigtipuri_tab') and w.meniu=t.meniu and (t.tip='' or isnull(w.tip,'')=t.tip) and t.subtip='' --> doar daca nu e filtrat doar la nivel de subtip
	select @nr_filtre=convert(varchar(20),@@ROWCOUNT)
	delete w from webconfigtaburi w, #tipuri t  where t.tabela in ('webconfigtipuri','webconfigtipuri_tab') and w.meniusursa=t.meniu and (t.tip='' or isnull(w.tipsursa,'')=t.tip) and t.subtip=''	--> doar daca nu e filtrat doar la nivel de subtip
	select @nr_taburi=convert(varchar(20),@@ROWCOUNT)
	if exists (select 1 from webconfigformmobile w, #tipuri t  where t.tabela in ('webconfigtipuri','webconfigtipuri_tab') and w.identificator=t.meniu)
	begin
		delete w from webconfigformmobile w, #tipuri t  where t.tabela in ('webconfigtipuri','webconfigtipuri_tab') and w.identificator=t.meniu
		select @nr_formmobile=convert(varchar(20),@@ROWCOUNT)
	end
	
	select @mesaj='Au fost sterse liniile aferente: meniu="'+@meniu+'", tip="'+@tip+'", subtip="'+@subtip+'", in numar de:
webconfigmeniu - '+@nr_meniu+'
webconfigtipuri - '+@nr_tipuri+'
webconfigform - '+@nr_form+'
webconfiggrid - '+@nr_grid+'
webconfigfiltre - '+@nr_filtre+'
webconfigtaburi - '+@nr_taburi+
	(case when @nr_formmobile is not null then '
webconfigformmobile - '+@nr_formmobile else '' end)
--	*/
	select @mesaj as textMesaj for xml raw, root('Mesaje')

end try
begin catch
	select @eroare=error_message()+' (wOPStergereMeniuri)'
end catch

	if object_id('tempdb..#tipuri') is not null drop table #tipuri
if len(@eroare)>0 raiserror(@eroare,16,1)
