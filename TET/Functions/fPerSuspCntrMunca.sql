--***
/**	functie pt. perioade de suspendare a contractului de munca */
Create function fPerSuspCntrMunca 
	(@datajos datetime, @datasus datetime, @pMarca char(6), @pLm char(9), @DinFormular int) 
returns @persuspcm table
	(Data datetime, Marca varchar(6), Tip_suspendare varchar(2), Data_inceput datetime, Data_sfarsit datetime, 
	Zile_lucratoare int, Zile_calendaristice int, Motiv_suspendare varchar(50))
as
Begin
	declare @utilizator varchar(20), @formaJuridica varchar(100), @Grup7 int, 
	@Data datetime, @Marca char(6), @Tip_suspendare char(2), @Data_inceput datetime, @Data_sfarsit datetime, 
	@ZileLucr int, @ZileCalend int, @Motiv_suspendare char(50), @gMarca char(6), @gData_inceput datetime, 
	@gZileLucr int, @gZileCalend int, @AreAnterior int, @AreContinuare int, @Term char(8), @dinSuspendari int, @DataAngajarii datetime

	set @utilizator=dbo.fIaUtilizator(null)
	set @formaJuridica=dbo.iauParA('GE','FJURIDICA')
	set @Grup7=dbo.iauParL('SP','GRUP7')

	Set @Term=isnull((select convert(char(8), abs(convert(int, host_id())))),'')
	--Set @Term='1464'
	if @datajos is Null
		Select @datajos=Data_facturii from avnefac where Terminal=@Term and tip='AD'
	if @datasus is Null
		Select @datasus=Data from avnefac where Terminal=@Term and tip='AD'
	if @pMarca is Null
		Select @pMarca=Numar from avnefac where Terminal=@Term and tip='AD'
	select @gZileLucr=0, @gZileCalend=0
	select @DataAngajarii=Data_angajarii_in_unitate from personal where Marca=@pMarca
	set @datajos=dbo.BOM(@DataAngajarii)

	Declare crsSuspendare Cursor For
	select c.Data, c.Marca, (case when c.Tip_diagnostic='0-' then 'IC' else 'CM' end) as Tip, 
		c.Data_inceput, c.Data_sfarsit, c.Zile_lucratoare, DateDiff(day,Data_inceput,Data_sfarsit)+1,
		(case when c.Tip_diagnostic='0-' then 'Concediu crestere copil' else 'Concediu medical' end), 0
	from conmed c
		left outer join personal p on p.Marca=c.Marca 
		left outer join istpers i on i.Data=c.Data and i.Marca=c.Marca 
	where c.Data between @datajos and @datasus and (@pMarca is null or c.Marca=@pMarca)
		--and (@pMarca is null or exists (select 1 from personal p1 where p1.Cod_numeric_personal=p.Cod_numeric_personal and p1.Marca=@marca))
		and (@pLm is null or i.Loc_de_munca like rtrim(@pLm)+'%')
--	daca forma juridica este configurata foarte probabil se genereaza Revisalul din ASiS si in acest caz suspendarile sunt operate in macheta salariati
		and (c.Tip_diagnostic<>'0-' or @formaJuridica='')
	union all
	select c.Data, c.Marca, (case when c.Tip_concediu='1' then 'FS' else 'NE' end) as Tip, 
		c.Data_inceput, c.Data_sfarsit, c.Zile, DateDiff(day,Data_inceput,Data_sfarsit)+1,
		(case when c.Tip_concediu='1' then 'Concediu fara salar' else 'Absente nemotivate' end), 0
	from conalte c
		left outer join personal p on p.Marca=c.Marca 
		left outer join istpers i on i.Data=c.Data and i.Marca=c.Marca 
	where c.Data between @datajos and @datasus and (@pMarca is null or c.Marca=@pMarca)
		--and (@pMarca is null or exists (select 1 from personal p1 where p1.Cod_numeric_personal=p.Cod_numeric_personal and p1.Marca=@marca))
		and (@pLm is Null or i.Loc_de_munca like rtrim(@pLm)+'%') 
		and (c.Tip_concediu in ('1') or c.Tip_concediu in ('2') and c.Indemnizatie=0)
		and (@formaJuridica='' or @Grup7=1)
	union all 
--	daca forma juridica este configurata foarte probabil se genereaza Revisalul din ASiS si in acest caz suspendarile sunt operate in macheta salariati
	select s.Data, s.Marca, (case when s.Temei_legal='Art54' then 'FS' when s.Temei_legal='Art51Alin2' then 'NE' 
		when s.Temei_legal='Art51Alin1LiteraA' then 'IC' when s.Temei_legal='Art52Alin1LiteraA' then 'CD'
		when s.Temei_legal='Art51Alin1LiteraD' then 'FP' else '' end) as Tip, 
		s.Data_inceput, s.Data_sfarsit, dbo.zile_lucratoare(s.data_inceput, s.data_sfarsit), DateDiff(day,s.Data_inceput,s.Data_sfarsit)+1,
		(case when s.Temei_legal='Art54' then 'Concediu fara salar' when s.Temei_legal='Art51Alin2' then 'Absente nemotivate' 
		when s.Temei_legal='Art51Alin1LiteraA' then 'Concediu crestere copil' when s.Temei_legal='Art52Alin1LiteraA' then 'Cercetare disciplinara'
		when s.Temei_legal='Art51Alin1LiteraD' then 'Formare profesionala' else '' end), 1
	from fRevisalSuspendari (@dataJos, @dataSus, @pMarca) s
		left outer join personal p on p.Marca=s.Marca 
	where (@pLm is Null or p.Loc_de_munca like rtrim(@pLm)+'%') 
		and not(@formaJuridica='' or @Grup7=1)
	order by Marca, /*Data,*/ Data_inceput

	open crsSuspendare
	fetch next from crsSuspendare into @Data, @Marca, @Tip_suspendare, @Data_inceput, @Data_sfarsit, @ZileLucr, @ZileCalend, @Motiv_suspendare, @dinSuspendari

	set @gMarca=@Marca
	set @gData_inceput=@Data_inceput
	While @@fetch_status=0 
	Begin
		if @dinSuspendari=1
			select @AreAnterior=0, @AreContinuare=0
		if @Tip_suspendare in ('CM') and @dinSuspendari=0
		Begin
			Select @AreAnterior=isnull(count(1),0) from conmed where marca=@marca and data_sfarsit=@Data_inceput-1 and Tip_diagnostic<>'0-'
			Select @AreContinuare=isnull(count(1),0) from conmed where marca=@marca and data_inceput=@Data_sfarsit+1 and Tip_diagnostic<>'0-'
		End
		if @Tip_suspendare in ('IC') and @dinSuspendari=0
		Begin
			Select @AreAnterior=isnull(count(1),0) from conmed where marca=@marca and data_sfarsit=@Data_inceput-1 and Tip_diagnostic='0-'
			Select @AreContinuare=isnull(count(1),0) from conmed where marca=@marca and data_inceput=@Data_sfarsit+1 and Tip_diagnostic='0-'
		End
		if @Tip_suspendare in ('FS') and @dinSuspendari=0
		Begin
			Select @AreAnterior=isnull(count(1),0) from conalte where marca=@marca and data_sfarsit=@Data_inceput-1 and tip_concediu='1'
			Select @AreContinuare=isnull(count(1),0) from conalte where marca=@marca and data_inceput=@Data_sfarsit+1 and tip_concediu='1'
		End
		if @Tip_suspendare in ('NE') and @dinSuspendari=0
		Begin
			Select @AreAnterior=isnull(count(1),0) from conalte where marca=@marca and data_sfarsit=@Data_inceput-1 and tip_concediu='2'
			Select @AreContinuare=isnull(count(1),0) from conalte where marca=@marca and data_inceput=@Data_sfarsit+1 and tip_concediu='2'
		End
		if @gMarca<>@Marca or @AreContinuare=0 and @AreAnterior=0
			select @gData_inceput=@Data_inceput

		if @AreContinuare=0 
			insert into @persuspcm values (@Data, @Marca, @Tip_suspendare, @gData_inceput, @Data_sfarsit, @gZileLucr+@ZileLucr, @gZileCalend+@ZileCalend, rtrim(@Motiv_suspendare))
-->	la schimbare sau daca nu exista continuare se reseteaza anumite valori
		if @gMarca<>@Marca or @AreContinuare=0 --and @AreAnterior=0
			select @gZileLucr=0, @gZileCalend=0

		Set @gMarca=@Marca
		if @AreContinuare=1 and @AreAnterior=0
			Set @gData_inceput=@Data_inceput
-->	daca exista continuare se cumuleaza zilele.
		if @AreContinuare=1
		begin
			set @gZileLucr=@gZileLucr+@ZileLucr
			set @gZileCalend=@gZileCalend+@ZileCalend
		end

		fetch next from crsSuspendare into @Data, @Marca, @Tip_suspendare, @Data_inceput, @Data_sfarsit, @ZileLucr, @ZileCalend, @Motiv_suspendare, @dinSuspendari
	End
	close crsSuspendare
	Deallocate crsSuspendare
	return
End

/*
	select * from fPerSuspCntrMunca (Null, Null, Null, Null, 1) 
*/
