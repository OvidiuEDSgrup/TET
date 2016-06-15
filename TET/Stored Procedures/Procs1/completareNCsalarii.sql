/* operatie pt. scriere inregistrare NC salarii */
Create procedure completareNCsalarii
	@dataJos datetime, @dataSus datetime, @NumarDoc char(8)
As
Begin try
	declare @Sub char(9), @NCIndBug int, @NCLMNivel int, @NCRetDecont int, @lJurnal int, @cJurnal char(9), 
		@nValidareStrictaComenzi int, @ValidareStrictaComenzi int, @ComandaGenerica varchar(20), @DateTichete char(20), @GestiuneTichete char(9), @CodTichete char(20), 
		@Utilizator char(10), @mesajEroare varchar(254)

	select 
		@Sub=max(case when Parametru='SUBPRO' then Val_alfanumerica else '' end),
		@NCIndBug=max(case when Parametru='NC-INDBUG' then Val_logica else 0 end),
		@NCLMNivel=max(case when Parametru='N-C-NIVLM' then Val_logica else 0 end),
		@NCRetDecont=max(case when Parametru='NC-RET-M' then Val_logica else 0 end),
		@lJurnal=max(case when Parametru='JURNAL' then Val_logica else 0 end),
		@cJurnal=max(case when Parametru='JURNAL' then Val_alfanumerica else '' end),
		@nValidareStrictaComenzi=max(case when Parametru='COMANDA' then Val_numerica else 0 end),
		@ComandaGenerica=max(case when Parametru='COMANDAG' then Val_alfanumerica else '' end),
		@DateTichete=max(case when Parametru='NC-TICHM' then Val_alfanumerica else '' end)
	from par 
	where tip_parametru='GE' and parametru in ('SUBPRO','COMANDA','COMANDAG')
		or tip_parametru='PS' and parametru in ('NC-INDBUG','N-C-NIVLM','NC-RET-M','JURNAL','NC-TICHM')

	set @ValidareStrictaComenzi=max(case when @nValidareStrictaComenzi=1 then 1 else 0 end)
	select @cJurnal=(case when @lJurnal=1 then @cJurnal else '' end)
	set @GestiuneTichete=(case when @DateTichete='' then '' else left(@DateTichete,charindex(',',@DateTichete)-1) end)
	set @CodTichete=(case when @DateTichete='' then '' else substring(@DateTichete,charindex(',',@DateTichete)+1,20) end)

	set @Utilizator=dbo.fIaUtilizator(null)
	select @mesajEroare=''

	update #docPozncon set Numar=@NumarDoc
	where Numar=''

	/* completare comanda generica daca sunt pozitii cu comanda necompletate */
	if @ValidareStrictaComenzi=1 and @NCIndBug=0 --and 1=0
	Begin
		update #docPozncon set Comanda=@ComandaGenerica
		where Comanda='' 

		update #docPozplin set Comanda=@ComandaGenerica
		where Comanda='' 
	End

	/* completare jurnal */
	if @lJurnal=1
	begin
		update #docPozncon set Jurnal=@cJurnal
		where Jurnal=''

		update #docPozplin set Jurnal=@cJurnal
		where Jurnal=''
	end

	/* validare loc de munca */
	if exists (select 1 from #docPozncon p left outer join lm on lm.cod=p.Loc_munca where p.Loc_munca<>'' and lm.Denumire is null)
	begin
		select @mesajEroare='Locul de munca '+rtrim(p.Loc_munca)+' nu este valid. Adaugati-l in macheta de locuri de munca sau corectati datele!'
			from #docPozncon p left outer join lm on lm.cod=p.Loc_munca where lm.Denumire is null
		RAISERROR (@mesajEroare, 16, 1)
		return
	end

	/* completare loc de munca de pe nivelul pe care se doreste a se calcula costurile */
	if @NCLMNivel=0
	begin
		--	pun in tabela temporara locurile de munca pe care se doresc a se urmari costuri
		if object_id('tempdb..#lmcosturi') is not null drop table #lmcosturi
		select lm.Nivel, lm.cod as loc_de_munca, strlm.Lungime
		into #lmcosturi
		from lm 
			left outer join strlm on strlm.nivel=lm.nivel
		where strlm.costuri=1 or isnull(strlm.nivel-1,0)=0

		update p set p.Loc_munca=lmc.Loc_de_munca
		from #docPozncon p
			cross apply (select top 1 c.loc_de_munca from #lmcosturi c where left(p.Loc_munca,len(rtrim(c.loc_de_munca)))=c.loc_de_munca order by lungime desc) lmc
		where Suma<>0

		update p set p.Loc_de_munca=lmc.Loc_de_munca
		from #docPozplin p
			cross apply (select top 1 c.loc_de_munca from #lmcosturi c where left(p.Loc_de_munca,len(rtrim(c.loc_de_munca)))=c.loc_de_munca order by lungime desc) lmc
		where Suma<>0
	end
		
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura completareNCsalarii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
