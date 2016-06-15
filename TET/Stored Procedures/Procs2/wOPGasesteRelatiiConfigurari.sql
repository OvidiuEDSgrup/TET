--***
create procedure wOPGasesteRelatiiConfigurari @sesiune varchar(50), @parXML xml
as

if object_id('tempdb..#tipuri') is null
begin
	create table #tipuri(meniu varchar(20))
	exec wOPGasesteRelatiiConfigurari_tabela @sesiune=@sesiune, @parXML=null
end
--select * from #tipuri
	declare @meniu varchar(20), @sursa varchar(50), @siIndirecte bit, @tip varchar(20), @subtip varchar(20)
	select	@meniu=isnull(@parXML.value('(parametri/@meniu)[1]','varchar(20)'),''),
			@sursa=@parXML.value('(parametri/@sursa)[1]','varchar(50)'),
			@siIndirecte=isnull(@parXML.value('(parametri/@siIndirecte)[1]','bit'),'1'),
			@tip=rtrim(isnull(@parXML.value('(parametri/@tip_m)[1]','varchar(20)'),'')),
			@subtip=rtrim(isnull(@parXML.value('(parametri/@subtip_m)[1]','varchar(20)'),''))
	select @meniu=(case when @meniu<>'' then ','+@meniu+',' else '' end)	--> se va face cu charindex deoarece se va folosi si la generare populare de meniuri multiple

	if @sursa is null
	select @sursa=(case when @tip<>'' then 'webconfigtipuri' else 'webconfigmeniu' end)
	--> se adauga meniurile (daca este cazul, adica daca nivelul de stergere este webconfigmeniu); cu while ca sa nu depinda de numarul de nivele:
	if @sursa='webconfigmeniu'
	begin
		insert into #tipuri(meniu, tip, subtip, tabela, denumire)
		select meniu, '', '', 'webconfigmeniu', rtrim(w.nume)
		from webconfigmeniu w
		where charindex(','+isnull(rtrim(w.meniu),'')+',',@meniu)>0 or @meniu=''
		declare @nranterior int, @nrcurent int
		select @nranterior=1, @nrcurent=0
--		select * from #tipuri
		while (@nranterior<>@nrcurent)
		begin
			select @nranterior=@nrcurent
			insert into #tipuri(meniu, tip, subtip, tabela, denumire)
			select meniu, '', '', 'webconfigmeniu', max(rtrim(w.nume))
			from webconfigmeniu w
			where (@siIndirecte=1 and 
					(exists (select 1 from #tipuri w1 where /*w1.meniuparinte=@meniu and*/ w.meniuparinte=w1.meniu) --<-- daca @meniu e meniu parinte
						--or exists (select 1 from #tipuri w1 where /*w1.meniuparinte=@meniu and*/ w.meniuparinte=w1.meniu)
					)
				and not exists (select 1 from #tipuri t where t.meniu=w.meniu))
			group by w.meniu
			select @nrcurent=count(1) from #tipuri
		end	--*/
	end

	--> se adauga configurarile din tipurile direct subordonate in cazul in care se doreste stergerea configurarilor subalterne sau suntem la nivel de tip/subtip:
	if @siIndirecte=1 or @tip<>''
	insert into #tipuri(meniu, tip, subtip, tabela, denumire)
		select meniu, isnull(tip,''), isnull(subtip,''), 'webconfigtipuri', rtrim(t.nume)
		from webconfigtipuri t
		where (--isnull(t.meniu,'')=@meniu
				charindex(','+isnull(rtrim(t.meniu),'')+',',@meniu)>0
				or
					--@siIndirecte=1 and
						--exists (select 1 from webconfigmeniu w where w.meniuparinte=@meniu and w.meniu=t.meniu)) --<-- daca @meniu e meniu parinte
						exists (select 1 from #tipuri w where t.meniu=w.meniu))
			and ((@tip='' and @siIndirecte=1 or isnull(t.tip,'')='') or @tip=isnull(t.tip,''))
			and ((@subtip='' and (@siIndirecte=1 or isnull(t.subtip,'')=''))
					or @subtip=isnull(t.subtip,''))
/*	if (select count(1) from #tipuri)=0 and @sursa='webconfigmeniu'
		insert into #tipuri(meniu, tip, subtip, tabela)
		select @meniu,'','','webconfigmeniu'
*/	
	--> marcarea configurarilor asociate/subalterne:
	if @siIndirecte=1
	begin
			
		--declare @nrcurent int, @nranterior int
		select @nranterior=0, @nrcurent=0
		select @nrcurent=count(1) from #tipuri
		
		--> se identifica acele taburi referite de configurari
		while /*@nrcurent>0 and*/ @nranterior<@nrcurent and @subtip='' --		and @nrcurent<100
		begin
			insert into #tipuri(meniu, tip, subtip, tabela, denumire)
			select distinct a.meniunou, isnull(a.tipnou,''), '', 'webconfigtipuri_tab', rtrim(a.NumeTab)
			from webconfigtaburi a inner join #tipuri t on a.meniusursa=t.meniu and a.tipsursa=t.tip
				and not exists (select 1 from #tipuri ta where ta.meniu=isnull(a.meniunou,'') and ta.tip=isnull(a.tipnou,''))
				
			insert into #tipuri(meniu, tip, subtip, tabela, denumire)
			select distinct t.meniu, isnull(t.tip,''), t.subtip, 'webconfigtipuri_tab', rtrim(t.Descriere)
			from webconfigtipuri t inner join #tipuri ti
				on  t.meniu=ti.meniu and
					(ti.tip='' or isnull(t.tip,'')=ti.tip) and
					ti.subtip=''
			where not exists (select 1 from #tipuri ta where ta.meniu=isnull(t.meniu,'') and ta.tip=isnull(t.tip,'') and ta.subtip=isnull(t.subtip,''))
			
			select @nranterior=@nrcurent, @nrcurent=count(1) from #tipuri
		end
	--test	select * from #tipuri
		--> completare cu tipuri si pentru cataloage "prea smechere" - cele cu tip necompletat:
		insert into #tipuri(meniu, tip, subtip, tabela, denumire)
		select t.meniu, t.meniu, '', t.tabela, t.denumire from #tipuri t where t.tip=''
			and not exists (select 1 from #tipuri tt where t.meniu=tt.meniu and tt.tip=t.meniu)

	--	--> daca meniul e folder sterg si meniurile din el:
/*
		delete w from webconfigmeniu w where meniuparinte=@meniu and @meniu<>''
		delete w from webconfigtipuri w inner join #tipuri t on w.meniu=t.meniu and isnull(w.tip,'')=t.tip and isnull(w.subtip,'')=t.subtip
		delete w from webconfigform w inner join #tipuri t on w.meniu=t.meniu and isnull(w.tip,'')=t.tip and isnull(w.subtip,'')=t.subtip
		delete w from webconfiggrid w inner join #tipuri t on w.meniu=t.meniu and isnull(w.tip,'')=t.tip and isnull(w.subtip,'')=t.subtip
		delete w from webconfigfiltre w inner join #tipuri t on w.meniu=t.meniu and isnull(w.tip,'')=t.tip --and t.subtip=''
		delete w from webconfigtaburi w inner join #tipuri t on w.meniusursa=t.meniu and isnull(w.tipsursa,'')=t.tip --and t.subtip=''
--*/
	end
	--> configurarile folosite in alte locuri, care nu au legatura directa prin meniu/tip/subtip:
		
	insert into #tipuri(meniu, tip, subtip, tabela, denumire)
	select a.meniusursa, a.tipsursa, '', 'webconfigtipuri_reftab', a.NumeTab
	from webconfigtaburi a
	where --isnull(a.meniunou,'')=@meniu
		charindex(','+isnull(rtrim(a.meniunou),'')+',',@meniu)>0
		and (@tip='' and (@siIndirecte=1 or isnull(a.tipnou,'')='') or @tip=isnull(a.tipnou,''))
		and exists (select 1 from #tipuri t where t.meniu=a.meniunou and t.tip=a.tipnou)
		and not exists (select 1 from #tipuri ta where ta.meniu=isnull(a.meniusursa,'') and ta.tip=isnull(a.tipsursa,''))

	--test /*	select * from #tipuri
