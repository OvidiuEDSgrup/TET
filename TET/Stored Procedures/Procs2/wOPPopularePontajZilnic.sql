--***
create procedure wOPPopularePontajZilnic @sesiune varchar(50), @parXML XML  
as
declare
	@utilizator varchar(20), @mesaj varchar(max), @stergere int, @lm varchar(10), @marca varchar(20), @datajos datetime, @datasus datetime, @detalii xml

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	select
		@stergere = isnull(@parXML.value('(/*/@stergere)[1]','int'),0),
		@lm = @parXML.value('(/*/@lm)[1]','varchar(10)'),
		@marca = nullif(@parXML.value('(/*/@marca)[1]','varchar(20)'),''),
		@datajos = @parXML.value('(/*/@datajos)[1]','datetime'),
		@datasus = @parXML.value('(/*/@datasus)[1]','datetime')
	
	if @parXML.exist('(/row/detalii/row)[1]') = 1
		set @detalii = @parXML.query('(/row/detalii/row)[1]')

	if @stergere=1
		delete pz
		from pontaj_zilnic pz
			left outer join personal p on p.marca=pz.marca
			left outer join istpers i on i.marca=pz.marca and i.data=@datasus
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=isnull(i.Loc_de_munca,p.loc_de_munca)
		where pz.data between @datajos and @datasus
			and (@marca is null or pz.marca=@marca)
			and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)

	/*	Pentru Diferit in procedura SP preiau orele din realcom. */
	if exists (select * from sysobjects where name ='wOPPopularePontajPeZileSP1')
		exec wOPPopularePontajPeZileSP1 @sesiune=@sesiune, @parXML=@parXML

	exec GenerareConcediiDinSuspendari @datajos=@datajos, @datasus=@datasus, @pMarca=@marca, @pLocm=@lm, @stergere=1, @generare=1

	if object_id('tempdb..#regimlucru') is not null drop table #regimlucru
	select marca, rl into #regimlucru
	from fDate_pontaj_automat (@datajos, @datasus, @datasus, 'RL', isnull(@marca,''), 0, 0) po

	/*	Populare pontaj zilnic pentru ore nelucrate:  concedii medicale, concedii de odihna, concedii fara salar, nemotivare, invoiri, operate prin machetele de concedii. */
	insert into pontaj_zilnic (data, marca, loc_de_munca, tip_ore, ore, detalii)
	select po.data_inceput, po.marca, p.Loc_de_munca, tip, po.zile*rl.RL, null
	from fDate_pontaj_automat (@datajos, @datasus, @datasus, 'TC', isnull(@marca,''), 0, 1) po	--TC -> returneaza toate concediile
		left outer join personal p on p.marca=po.marca
		left outer join #regimlucru rl on rl.marca=po.marca
	where not exists (select 1 from pontaj_zilnic pz where pz.data=po.data_inceput and pz.marca=po.marca)

	/*	Populare pontaj zilnic pentru ore lucrate. */
	insert into pontaj_zilnic (data, marca, loc_de_munca, tip_ore, ore, detalii)
	select fc.data, p.marca, p.Loc_de_munca, 'OL', 
	(case when fc.Zi_alfa in ('Sambata','Duminica') or fc.data in (select data from calendar) 
		then 0 else isnull(nullif(p.Salar_lunar_de_baza,0),8) end), @detalii
	from personal p 
		left outer join fCalendar(@datajos, @datasus) fc on 1=1
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca
	where (@marca is null or p.marca=@marca)
		and (nullif(@lm,'') is null or p.loc_de_munca like rtrim(@lm)+'%')
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
		and fc.data>=p.Data_angajarii_in_unitate
		and (p.Loc_ramas_vacant=0 or fc.data<p.Data_plec)
		--and fc.Zi_alfa not in ('Sambata','Duminica') and fc.data not in (select data from calendar)
		and not exists (select 1 from pontaj_zilnic pz where pz.data=fc.data and pz.marca=p.marca)

end try

begin catch
	set @mesaj = error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 11, 1)
end catch
