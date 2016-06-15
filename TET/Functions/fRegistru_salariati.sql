--***
Create function dbo.fRegistru_salariati 
	(@dataJos datetime, @dataSus datetime, @lLoc_de_munca int, @cLoc_de_munca char(9), @nStrict int, 
	@lMarca int, @cMarca char(6), @are_drept_cond int, @clista_cond char(1), @ltip_stat int, @ctip_stat char(200),
	@lFiltru_dataang int, @Dataang datetime, @lAdeverinta int, @lModif_date_pers int)
returns @regpers table
	(crt int, data datetime, marca char(6), nr_contract char(20), nume char(50), localitate char(30), 
	buletin char(30), CNP char(13), data_ang datetime, mod_angajare char, luni_proba float(8), 
	cod_functie char(6), functie char(30), loc_de_munca char(30), salar float, data_plec datetime, 
	explicatii varchar(200), mDuratacntr char(30), mFunctie char(30), mLocm char(30), mRegimL char(30))
as
begin
	declare @utilizator varchar(20), @marca char(6), @nr_contract as char(20), @nume char(50), @localitate as char(15), @Buletin char (30), @CNP as varchar(13), @data_ang as datetime, @mod_ang as varchar, 
	@zile_absente as float, @LM char(9), @cod_functie char(6), @functie char(30), @salar_de_baza as float, @regim_de_lucru as float, @data as datetime, @data_plec as datetime, @plecat int, @CRT INT
	declare @gnume char(50), @glocm char(9), @gSalar_de_baza float, @gRegim_de_lucru float, @nfetch int, @gMarca char(6), @gFunctie char(30), @gmod_ang char, @expl varchar(200), @gData_plec datetime, 
	@mDuratacntr char(30), @mFunctie char(30), @mLocm char(30), @mRegimL char(30), @gbuletin char(30), @ldrept_conducere int
	set @ldrept_conducere=dbo.iauParL('PS','DREPTCOND')

	set @utilizator=dbo.fIaUtilizator(null)

	declare regpers cursor for 
	select a.data,a.marca, c.nr_contract, a.nume, p.localitate, (case when (select top 1 val_inf from extinfop,campsit
		where extinfop.cod_inf=campsit.cod and campsit.tip_lista='Regpers' and campsit.ordine='4' and extinfop.data_inf>=a.data and a.marca=extinfop.marca order by extinfop.data_inf) is null 
		then p.copii else (select top 1 val_inf from extinfop,campsit where extinfop.cod_inf=campsit.cod and campsit.tip_lista='Regpers' and campsit.ordine='4' and extinfop.data_inf>=a.data 
		and a.marca=extinfop.marca order by extinfop.data_inf) end), 
	p.cod_numeric_personal, p.data_angajarii_in_unitate, a.mod_angajare, p.zile_absente_an, isnull(a.loc_de_munca,''), isnull(a.cod_functie,0),
	isnull(d.denumire,''), isnull(a.salar_de_baza,0), isnull(a.salar_lunar_de_baza,0), (case when a.Mod_angajare='D' then a.data_plec else p.Data_plec end), p.Loc_ramas_vacant 
	from istpers a 
		left outer join personal p on p.Marca=a.Marca
		left outer join infopers c on c.Marca=a.Marca
		left join functii d on a.cod_functie=d.cod_functie
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca
	where (@lLoc_de_munca=0 or a.Loc_de_munca like rtrim(@cLoc_de_munca)+(case when @nStrict=0 then '%'else '' end)) 
		and (@lMarca=0 or exists (select 1 from personal p1 where p1.Cod_numeric_personal=p.Cod_numeric_personal and p1.Marca=@cMarca)) 
		--and (@lMarca=0 or a.marca=@cMarca) 
		and a.data between (case when @lModif_date_pers=1 or @lAdeverinta=1 and @dataSus<>dbo.eom(@dataJos) then @dataJos when @lAdeverinta=1 then '01/01/1901' else '03/01/2003' end) 
		and @dataSus and (@ldrept_conducere=0 or (@are_drept_cond=1 and (@clista_cond='T' or @clista_cond='C' and p.pensie_suplimentara=1 or @clista_cond='S' and p.pensie_suplimentara<>1)) 
			or (@are_drept_cond=0 and p.pensie_suplimentara<>1)) 
		and a.grupa_de_munca<>'O' and (@ltip_stat=0 or c.religia=@ctip_stat) and (@lFiltru_dataang=0 or p.data_angajarii_in_unitate>=@Dataang)
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
	order by p.data_angajarii_in_unitate, a.marca, a.data
	open regpers

	fetch next from regpers
	into @data, @marca, @nr_contract, @nume, @localitate, @buletin, @CNP, @data_ang, @mod_ang, @zile_absente,@LM, @cod_functie, @functie, @salar_de_baza, @regim_de_lucru, @data_plec, @plecat

	insert into @regpers values (1,@data, @marca, @nr_contract, @nume, @localitate, @buletin, @CNP, @data_ang, @mod_ang, 
	@zile_absente, @cod_functie, @functie, rtrim(@lm), @salar_de_baza, @data_plec, '', '', '', '', '')

	set @CRT=2
	set @nFetch=@@fetch_status
	while @nFetch=0
	begin	
		set @glocm=@lm
		set @gFunctie=@cod_functie
		set @gsalar_de_baza=@salar_de_baza
		set @gregim_de_lucru=@regim_de_lucru
		set @gmod_ang=@mod_ang
		set @gData_plec=@data_plec
		set @gMarca=@marca
		set @gnume=@nume 
		set @gbuletin=@buletin
		if (@marca=@gMarca and @gsalar_de_baza=@salar_de_baza and (@lModif_date_pers=0 or @gregim_de_lucru=@regim_de_lucru and @lModif_date_pers=1) 
			and @gmod_ang=@mod_ang and @glocm=@lm and @gFunctie=@cod_functie and @gnume=@nume and @gbuletin=@buletin and @nFetch=0)
		begin
			fetch next from regpers
			into @data, @marca, @nr_contract, @nume, @localitate, @buletin, @CNP, @data_ang, @mod_ang,@zile_absente, @LM, @cod_functie, @functie, @salar_de_baza,  @regim_de_lucru, @data_plec, @plecat
			set @nFetch=@@fetch_status
		end	
		if @marca<>@gMarca 
		begin
			insert into @regpers values (@CRT,@data,@marca, @nr_contract, @nume, @localitate, @buletin, 
			@CNP, @data_ang, @mod_ang, @zile_absente, @cod_functie, @functie, rtrim(@lm), @salar_de_baza, @data_plec, '', '', '', '', '')
			set @crt=@crt+1
		end
		else
		begin
			set @expl=''
			set @mDurataCntr=''
			set @mFunctie=''
			set @mLocm=''
			set @mRegimL=''
			if @glocm<>@lm and @lAdeverinta=0
			Begin
				set @expl=rtrim(@expl)+'loc de munca,' 
				set @mLocm='Modificare loc de munca' 
			End
			if @gfunctie<>@cod_functie
			Begin
				set @expl=rtrim(@expl)+'functie ,'
				set @mFunctie='Modificare functie'
			End
			if @gsalar_de_baza<>@salar_de_baza
				set @expl=rtrim(@expl)+'salar,'
			if @gregim_de_lucru<>@regim_de_lucru and @lModif_date_pers=1
			Begin
				set @expl=rtrim(@expl)+'regim de lucru, '
				set @mRegimL='Modificare regim de lucru'
			End
			if @gmod_ang<>@mod_ang or @mod_ang='D' and @gData_plec<>@data_plec
			Begin
				set @expl=rtrim(@expl)+'durata,'
				set @mDuratacntr='Modificare durata contract'
			End
			if @gbuletin <>@buletin
				set @expl=rtrim(@expl)+' schim. buletin'
			if @gnume<>@nume
				set @expl=rtrim(@expl)+' nume'
			if @nfetch=0 and rtrim(@expl)<>''
			begin
				set @expl=left(@expl,len(rtrim(@expl))-1)
				insert into @regpers values (0,@data, @marca, @nr_contract, @nume, @localitate,	@buletin, @CNP, @data_ang, @mod_ang, @zile_absente, 
				@cod_functie, @functie, rtrim(@lm),	@salar_de_baza, @data_plec, @expl, @mDuratacntr, @mFunctie, @mLocm, @mRegimL)
			end
		
			if @nfetch=0 and month(@data_plec)= month(@data) and year(@data_plec)=year(@data) and @plecat=1
				insert into @regpers values (0,@data, @marca, @nr_contract, @nume, @localitate,	@buletin, @CNP, @data_ang, @mod_ang, @zile_absente, 
				@cod_functie, @functie, rtrim(@lm),	@salar_de_baza, @data_plec, '', '', '', '', '')
		End
	End
	return
End

/*
	select crt, data, marca, nr_contract, nume, localitate, buletin, CNP, data_ang, mod_angajare, luni_proba, cod_functie, functie, loc_de_munca, salar, data_plec, explicatii, 
		mDuratacntr, mFunctie, mLocm, mRegimL 
	from dbo.fRegistru_salariati ('01/01/2012', '01/31/2012', 0, '', 0, 1, '84657', 1, 'T', 0, '', 0, '01/01/1901', 1, 0)
*/
