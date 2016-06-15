--***
/**	procedura pentru scriere date in istoric personal pornind de la tabela personal **/
Create procedure scriuistPers 
	(@DataJos datetime, @DataSus datetime, @pMarca char(6), @pLocm char(9), @Stergere int, @Scriere int, @ModifDateSalAmanate int=0, @NrZileAmanare int=0, @DataRegistru datetime='01/01/1901')
as
Begin try
	declare @nLunaInch int, @LunaInchAlfa char(15), @nAnulInch int, @dDataInch datetime, @utilizator varchar(10), @lista_lm int -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @nLunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @nAnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	set @dDataInch=dbo.eom(convert(datetime,str(@nLunaInch,2)+'/01/'+str(@nAnulInch,4)))
	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	if @DataSus<=@dDataInch
		RETURN

	set transaction isolation level read uncommitted
	if object_id('tempdb..#extinfop') is not null drop table #extinfop
	If @Stergere=1
		delete istPers from istPers i 
			left outer join personal p on p.Marca=i.Marca
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca 
		where data between @DataJos and @DataSus and (@pMarca='' or i.Marca=@pMarca) 
			and (@pLocm='' or p.Loc_de_munca like rtrim(@pLocm)+'%') 
			and (@lista_lm=0 or lu.cod is not null)

	If @Scriere=1
	Begin
		select * into #extinfop from 
		(select Marca, Cod_inf, Val_inf, Data_inf, Procent, RANK() over (partition by Marca, Cod_inf order by Data_inf Desc) as ordine
		from extinfop where (@pMarca='' or Marca=@pMarca) and Cod_inf in ('DATAMFCT','DATAMLM','DATAMDCTR','CONDITIIM','SALAR','DATAMRL') and Data_inf<=@DataSus and (Val_inf<>'' or Procent<>0)) a
		where Ordine=1

		insert into istpers 
			(Data, Marca, Nume, Cod_functie, Loc_de_munca, Categoria_salarizare, Grupa_de_munca, Tip_salarizare, Tip_impozitare, Salar_de_incadrare, Salar_de_baza, Indemnizatia_de_conducere, 
			Spor_vechime, Spor_de_noapte, Spor_sistematic_peste_program, Spor_de_functie_suplimentara, Spor_specific, Spor_conditii_1, Spor_conditii_2, Spor_conditii_3, Spor_conditii_4, Spor_conditii_5, Spor_conditii_6, 
			Salar_lunar_de_baza, Localitate, Judet, Strada, Numar, Cod_postal, Bloc, Scara, Etaj, Apartament, Sector, Mod_angajare, Data_plec, Tip_colab, grad_invalid, coef_invalid, alte_surse, Vechime_totala, 
			Activitate)
		select @DataSus, a.Marca, a.Nume, 
		(case when (@ModifDateSalAmanate=0 or @ModifDateSalAmanate=1 and (DateAdd(day,@NrZileAmanare,f.Data_inf)<=@DataRegistru or a.Loc_ramas_vacant=1 and a.Data_plec<=@DataRegistru)) 
			and isnull(f.Val_inf,'')<>'' and isnull(f.Val_inf,'') in (select cod_functie from functii) then f.Val_inf else a.Cod_functie end) as Cod_functie, 
		(case when (@ModifDateSalAmanate=0 or @ModifDateSalAmanate=1 and (DateAdd(day,@NrZileAmanare,l.Data_inf)<=@DataRegistru or a.Loc_ramas_vacant=1 and a.Data_plec<=@DataRegistru)) 
			and isnull(l.Val_inf,'')<>'' and isnull(l.Val_inf,'') in (select Cod from lm) then l.Val_inf else a.Loc_de_munca end) as Loc_de_munca, a.Categoria_salarizare, 
		(case when (@ModifDateSalAmanate=0 or @ModifDateSalAmanate=1 and (DateAdd(day,@NrZileAmanare,g.Data_inf)<=@DataRegistru or a.Loc_ramas_vacant=1 and a.Data_plec<=@DataRegistru)) 
			and isnull(ltrim(rtrim(g.Val_inf)),'')<>'' then upper(isnull(ltrim(rtrim(g.Val_inf)),'')) else a.Grupa_de_munca end) as Grupa_de_munca, 
		a.Tip_salarizare, a.Tip_impozitare, 
		(case when (@ModifDateSalAmanate=0 or @ModifDateSalAmanate=1 and (DateAdd(day,@NrZileAmanare,s.Data_inf)<=@DataRegistru or a.Loc_ramas_vacant=1 and a.Data_plec<=@DataRegistru)) 
			and isnull(s.Procent,0)<>0 then isnull(s.Procent,0) else a.Salar_de_incadrare end) as Salar_de_incadrare, 
		(case when (@ModifDateSalAmanate=0 or @ModifDateSalAmanate=1 and (DateAdd(day,@NrZileAmanare,s.Data_inf)<=@DataRegistru or a.Loc_ramas_vacant=1 and a.Data_plec<=@DataRegistru)) 
			and isnull(s.Procent,0)<>0 then isnull(s.Procent,0) else a.Salar_de_baza end) as Salar_de_baza, 
		a.Indemnizatia_de_conducere, a.Spor_vechime, a.Spor_de_noapte, a.Spor_sistematic_peste_program, a.Spor_de_functie_suplimentara, a.Spor_specific, 
		a.Spor_conditii_1, a.Spor_conditii_2, a.Spor_conditii_3, a.Spor_conditii_4, a.Spor_conditii_5, a.Spor_conditii_6, 
		(case when (@ModifDateSalAmanate=0 or @ModifDateSalAmanate=1 and (DateAdd(day,@NrZileAmanare,r.Data_inf)<=@DataRegistru or a.Loc_ramas_vacant=1 and a.Data_plec<=@DataRegistru)) 
			and isnull(r.Procent,0)<>0 then isnull(r.Procent,0) else a.Salar_lunar_de_baza end) as Salar_lunar_de_baza, 
		a.Localitate, a.Judet, a.Strada, a.Numar, a.Cod_postal, a.Bloc, a.Scara, a.Etaj, a.Apartament, a.Sector, 
		(case when (@ModifDateSalAmanate=0 or @ModifDateSalAmanate=1 and (DateAdd(day,@NrZileAmanare,e.Data_inf)<=@DataRegistru or a.Loc_ramas_vacant=1 and a.Data_plec<=@DataRegistru)) 
			and isnull(e.Val_inf,'')<>'' and isnull(e.Val_inf,'') in ('N','D','T') then e.Val_inf else a.Mod_angajare end) as Mod_angajare, 
		(case when (@ModifDateSalAmanate=0 or @ModifDateSalAmanate=1 and DateAdd(day,@NrZileAmanare,e.Data_inf)<=@DataRegistru) 
			and isnull(e.Val_inf,'')<>'' and (left(isnull(e.Val_inf,''),2)+'/'+substring(isnull(e.Val_inf,''),4,2)+'/'+right(rtrim(isnull(e.Val_inf,'')),4)=rtrim(isnull(e.Val_inf,'')) 
			or left(isnull(e.Val_inf,''),2)+'.'+substring(isnull(e.Val_inf,''),4,2)+'.'+right(rtrim(isnull(e.Val_inf,'')),4)=rtrim(isnull(e.Val_inf,'')))
			and not(a.Loc_ramas_vacant=1 and a.Data_plec<=@DataRegistru) then convert(datetime,isnull(e.Val_inf,''),103) else a.Data_plec end) as Data_plec, 
		a.Tip_colab, a.grad_invalid, a.coef_invalid, a.alte_surse, a.Vechime_totala, a.Activitate
		from personal a
			left outer join infopers b on a.Marca=b.Marca
			left outer join #extinfop f on a.Marca=f.Marca and f.Cod_inf='DATAMFCT' and DateAdd(day,(case when @ModifDateSalAmanate=1 then @NrZileAmanare else 0 end),f.Data_inf) 
				between (case when DATEDIFF(MONTH,@dDataInch,@DataSus)>1 then dbo.BOM(@DataJos-1) else @DataJos end) and @DataSus and ltrim(rtrim(f.Val_inf))<>''
			left outer join #extinfop l on a.Marca=l.Marca and l.Cod_inf='DATAMLM' and DateAdd(day,(case when @ModifDateSalAmanate=1 then @NrZileAmanare else 0 end),l.Data_inf) 
				between (case when DATEDIFF(MONTH,@dDataInch,@DataSus)>1 then dbo.BOM(@DataJos-1) else @DataJos end) and @DataSus and ltrim(rtrim(l.Val_inf))<>''
			left outer join #extinfop e on a.Marca=e.Marca and e.Cod_inf='DATAMDCTR' and DateAdd(day,(case when @ModifDateSalAmanate=1 then @NrZileAmanare else 0 end),e.Data_inf) 
				between (case when DATEDIFF(MONTH,@dDataInch,@DataSus)>1 then dbo.BOM(@DataJos-1) else @DataJos end) and @DataSus and ltrim(rtrim(e.Val_inf))<>''
			left outer join #extinfop g on a.Marca=g.Marca and g.Cod_inf='CONDITIIM' and DateAdd(day,(case when @ModifDateSalAmanate=1 then @NrZileAmanare else 0 end),g.Data_inf) 
				between (case when DATEDIFF(MONTH,@dDataInch,@DataSus)>1 then dbo.BOM(@DataJos-1) else @DataJos end) and @DataSus and ltrim(rtrim(g.Val_inf))<>''
			left outer join #extinfop s on a.Marca=s.Marca and s.Cod_inf='SALAR' and DateAdd(day,(case when @ModifDateSalAmanate=1 then @NrZileAmanare else 0 end),s.Data_inf) 
				between (case when DATEDIFF(MONTH,@dDataInch,@DataSus)>1 then dbo.BOM(@DataJos-1) else @DataJos end) and @DataSus and s.Procent<>0
			left outer join #extinfop r on a.Marca=r.Marca and r.Cod_inf='DATAMRL' and DateAdd(day,(case when @ModifDateSalAmanate=1 then @NrZileAmanare else 0 end),r.Data_inf) 
				between (case when DATEDIFF(MONTH,@dDataInch,@DataSus)>1 then dbo.BOM(@DataJos-1) else @DataJos end) and @DataSus and r.Procent<>0
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=a.Loc_de_munca 
		where (@pMarca='' or a.Marca=@pMarca) and (@pLocm='' or a.loc_de_munca like rtrim(@pLocm)+'%') 
			and a.data_angajarii_in_unitate<=@DataSus 
			and (convert(char(1),a.loc_ramas_vacant)='0' or a.data_plec>=@DataJos or left(isnull(b.loc_munca_nou,''),7)='DETASAT')
			and (@lista_lm=0 or lu.cod is not null)
			and not exists (select 1 from istpers i where i.data=@DataSus and i.Marca=a.Marca)

		if exists (select 1 from syscolumns sc,sysobjects so where so.id=sc.id and so.name='personal' and sc.name='detalii') 
			and exists (select 1 from syscolumns sc,sysobjects so where so.id=sc.id and so.name='istpers' and sc.name='detalii') 
		begin	
			declare @comandaSQL nvarchar(max)
			set @comandaSQL='update i set i.detalii=p.detalii
					from istpers i
						inner join personal p on p.marca=i.marca
						left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca 
					where i.data=@datasus 
						and (@pMarca='''' or i.Marca=@pMarca) and (@pLocm='''' or p.loc_de_munca like rtrim(@pLocm)+'''+'%'+''') 
						and (@lista_lm=0 or lu.cod is not null)'
			if isnull(@comandaSQL,'')<>''
				exec sp_executesql @statement=@comandaSQL, @params=N'@utilizator as varchar(20), @datasus as datetime, @pMarca varchar(6), @pLocm varchar(9), @lista_lm as int',                				
					@utilizator=@utilizator, @datasus=@datasus, @pMarca=@pMarca, @pLocm=@pLocm, @lista_lm=@lista_lm
		end

		if object_id('tempdb..#extinfop') is not null drop table #extinfop
	End
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura scriuistPers (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
