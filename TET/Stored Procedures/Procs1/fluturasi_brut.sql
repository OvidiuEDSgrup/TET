--***
/**	fluturasi brut	*/
Create procedure fluturasi_brut 
	@datajos datetime, @datasus datetime, @Host_ID char(10), @Ordonare char(50), @comp_saln bit 
as
Begin
	declare @Marca char(6),@nume char(50),@cod_functie char(6),@ploc_de_munca char(9),@itip_salarizare char(1),
	@isalar_de_incadrare float,@nloc_de_munca char(9),@Loc_de_munca char(9),@Ore_lucrate__regie int,@Realizat__regie float,
	@Ore_lucrate_acord int, @Realizat_acord float,@Realizat_Prodpan float,@Ore_delegatie int, @Realizat_delegatie float,
	@Ore_s1 int,@Ind_os1 float,@Ore_s2 int,@Ind_os2 float,@Ore_s3 int,@Ind_os3 float,@Ore_s4 int,@Ind_os4 float,@Ore_spor_100 int,@Ind_ore_spor_100 float,
	@Ore_de_noapte int,@Ind_ore_de_noapte float, @Ore_regim_normal int,@Ind_regim_normal float,@Ore_realizate_acord int,
	@Procent_lucrat_acord float,@bSalar_orar float, @tip_salarizare char(1),@Coef_acord float,@Coef_ARL float,
	@contor_marci int,@contor_impar int,@contor_marca int,@extensie_inf int, @forern int, @indici_lm int,
	@AgrirArad int,@Prodpan int,@Velpitar int,@Salubris bit,@Colas int,@ARLCJ int,@glocm char(9),@psupervisor varchar(50),@gsupervisor varchar(50),
	@pden_os1 char(10), @pden_os2 char(10),@pden_os3 char(10),@pden_os4 char(10),
	@proc_os1 float,@proc_os2 float,@proc_os3 float,@proc_os4 float, @den_os1 char(20),@den_os2 char(20),@den_os3 char(20),@den_os4 char(20),
	@denumire char(50),@ore char(20),@valoare float,@cond1 bit,@cond2 bit,@cond3 bit,@cand_scriu bit,@ore_luna int,
	@orem_luna float, @Subtipcor int, @AfisezCorL int, @SupervisorPeMarca int

	Exec Luare_date_par 'PS','FLDETRET',@extensie_inf output,0,0
	Exec Luare_date_par 'PS','FLFARARN',@forern output,0,0
	Exec Luare_date_par 'PS','INDICIPLM',@indici_lm output,0,0
	Exec Luare_date_par 'PS','OSUPL1',0,@proc_os1 output,@pden_os1 output
	Exec Luare_date_par 'PS','OSUPL2',0,@proc_os2 output,@pden_os2 output
	Exec Luare_date_par 'PS','OSUPL3',0,@proc_os3 output,@pden_os3 output
	Exec Luare_date_par 'PS','OSUPL4',0,@proc_os4 output,@pden_os4 output
	Set @ore_luna=dbo.iauParLN(@datasus,'PS','ORE_LUNA')
	Set @orem_luna=dbo.iauParLN(@datasus,'PS','NRMEDOL')
	Set @Subtipcor=dbo.iauParL('PS','SUBTIPCOR')
	Set @AfisezCorL=dbo.iauParL('PS','FLDR-CORL')
	Set @SupervisorPeMarca=dbo.iauParL('PS','SUPERVISO')
	Exec Luare_date_par 'SP','AGRIRARAD',@AgrirArad output,0,0
	Exec Luare_date_par 'SP','PRODPAN',@Prodpan output,0,0
	Exec Luare_date_par 'SP','VELPITAR',@Velpitar output,0,0
	Exec Luare_date_par 'SP','SALUBRIS',@Salubris output,0,0
	Exec Luare_date_par 'SP','COLAS',@Colas output,0,0
	Exec Luare_date_par 'SP','ARLCJ',@ARLCJ output,0,0
	Set @den_os1 = rtrim(@pden_os1)+' '+ltrim(rtrim(str(@proc_os1,6,2)))+'%'
	Set @den_os2 = rtrim(@pden_os2)+' '+ltrim(rtrim(str(@proc_os2,6,2)))+'%'
	Set @den_os3 = rtrim(@pden_os3)+' '+ltrim(rtrim(str(@proc_os3,6,2)))+'%'
	Set @den_os4 = rtrim(@pden_os4)+' '+ltrim(rtrim(str(@proc_os4,6,2)))+'%'
	Set @Contor_marca=0
	Set @Contor_marci=0

	Declare cursor_fluturasi_brut Cursor For
	select a.Marca,max(p.nume),max(i.cod_functie),max(i.loc_de_munca),max(i.tip_salarizare),max(i.salar_de_incadrare),max(n.loc_de_munca),max(a.loc_de_munca),max(isnull(pr.Valoare,'')),
		sum((a.Ore_lucrate__regie-a.Ore_delegatie)/(case when @AgrirArad=1 then (case when a.spor_cond_10=0 then 8.0 else a.spor_cond_10 end) else 1 end)),
		sum(a.Realizat__regie-a.Realizat_delegatie+(case when @Salubris=1 then round(a.Salar_categoria_lucrarii,0) else 0 end)),sum(a.Ore_lucrate_acord),
		sum(a.Realizat_acord),sum((case when @Prodpan=1 then round(a.salar_orar*a.ore_lucrate_acord,0) else 0 end)),
		sum(a.Ore_suplimentare_1),sum(a.Indemnizatie_ore_supl_1),sum(a.Ore_suplimentare_2),sum(a.Indemnizatie_ore_supl_2),
		sum(a.Ore_suplimentare_3),sum(a.Indemnizatie_ore_supl_3),sum(a.Ore_suplimentare_4),sum(a.Indemnizatie_ore_supl_4),
		sum(a.Ore_spor_100),sum(a.Indemnizatie_ore_spor_100),sum(a.Ore_de_noapte),sum(round(a.Ind_ore_de_noapte,0)),
		sum(a.Ore_lucrate_regim_normal),sum(round(a.Ind_regim_normal,0)),sum(a.Ore_realizate_acord),sum(sp_salar_realizat),max(a.Salar_orar),
		sum(a.Ore_delegatie),sum(a.Realizat_delegatie),
		isnull((select max(tip_salarizare) from pontaj j where j.data between @datajos and @datasus and j.marca=a.marca),''),
		isnull((select max(Coeficient_acord) from pontaj j where j.data between @datajos and @datasus and j.marca=a.marca and 
		convert(char(1),j.loc_munca_pentru_stat_de_plata)='1'),0)
	from tmpfluturi a
		left outer join personal p on p.marca=a.marca
		left outer join net n on n.data=a.data and n.marca=a.marca 
		left outer join istpers i on i.data=a.data and i.marca=a.marca
		left outer join proprietati pr on pr.Tip='PERSONAL' and pr.Cod_proprietate='SUPERVISOR' and pr.Cod=a.marca and pr.Valoare<>''
	where a.Host_ID=@Host_ID
	group by a.data,a.marca
	order by (case when @SupervisorPeMarca=1 then max(isnull(pr.Valoare,'')) else '' end), (case when @Ordonare='Nume' then max(i.nume)+a.marca when @Ordonare='Loc de munca; Nume' 
		then max(n.loc_de_munca)+max(i.nume) else max(n.loc_de_munca)+max(i.cod_functie)+a.marca end)

	open cursor_fluturasi_brut
	fetch next from cursor_fluturasi_brut into
		@Marca,@nume,@cod_functie,@ploc_de_munca,@itip_salarizare,@isalar_de_incadrare,@nloc_de_munca,@loc_de_munca,@psupervisor, 
		@Ore_lucrate__regie,@Realizat__regie,@Ore_lucrate_acord,@Realizat_acord,@Realizat_Prodpan,
		@Ore_s1,@Ind_os1,@Ore_s2,@Ind_os2,@Ore_s3,@Ind_os3,@Ore_s4,@Ind_os4,@Ore_spor_100,@Ind_ore_spor_100,
		@Ore_de_noapte,@Ind_ore_de_noapte,@Ore_regim_normal,@Ind_regim_normal,@Ore_realizate_acord,@Procent_lucrat_acord,
		@bsalar_orar,@Ore_delegatie,@Realizat_delegatie,@Tip_salarizare,@Coef_acord 
	While @@fetch_status = 0 
	Begin
		exec fluturasi_conditii_scriere @contor_marci output,@contor_impar output,@nloc_de_munca,@glocm,@psupervisor,@gsupervisor,@Ordonare,@cond1 output,@cond2 output,@cond3 output
		Set @Ore = ltrim(str(@bsalar_orar,10,3))
		exec scriu_fluturasi @Host_ID, @marca,'H',@nume,@ore,@isalar_de_incadrare,@cond1,@cond2,@cond3,1,'V'
		if @comp_saln=0 
		Begin
			if @Ore_lucrate__regie<>0 or @Realizat__regie<>0 
			Begin
				Set @denumire = 'Regie   '+(case when @indici_lm=1 and @coef_acord<>0 then 'coef. '+ltrim(str(@Coef_acord,5,2)) else '' end)
				Set @Ore = str(@ore_lucrate__regie,3)+(case when @AgrirArad=1 then ' zile' else ' ore' end)
				Set @cand_scriu = (case when @Ore_lucrate__regie<>0 or @Realizat__regie<>0 then 1 else 0 end)
				exec scriu_fluturasi @Host_ID,@marca,'V',@denumire,@Ore,@Realizat__regie,@cond1,@cond2,@cond3, @cand_scriu,'V'
			End
			if @Velpitar=1 and @tip_salarizare='4'
			Begin
				Set @Ore = str(@ore_regim_normal,3)+' ore'
				Set @cand_scriu = (case when (@Ore_regim_normal<>0 or @Ind_regim_normal<>0) then 1 else 0 end)
				exec scriu_fluturasi @Host_ID,@marca,'V','Regim normal',@Ore,@Ind_regim_normal,@cond1,@cond2,@cond3, @cand_scriu,'V'
			End
			if @ore_lucrate_acord<>0 or @realizat_acord<>0 or @Procent_lucrat_acord<>0 and @Colas=0 and @AfisezCorL=0
			Begin
				Set @Coef_ARL=(case when @ore_lucrate_acord=0 or @isalar_de_incadrare=0 then 0 else @Realizat_acord/(@ore_lucrate_acord*
				(@isalar_de_incadrare/(case when charindex(@itip_salarizare,'12')<>0 then @ore_luna else @orem_luna end))) end)
				Set @denumire=(case when @Velpitar=1 and @tip_salarizare='4' then 'Dif. ' else '' end)+'Acord '+
					(case when @ARLCJ=1 then '  indice '+ltrim(str(@Coef_ARL,10,3)) else '' end)
				Set @ore = (case when @AgrirArad=1 then str(@ore_lucrate__regie,3)+' zile' else 
					str((case when @Velpitar=1 and @tip_salarizare='4' then @ore_lucrate_acord-@ore_regim_normal 
					else @ore_lucrate_acord end),3) end)+' ore'
				Set @valoare=(case when @Prodpan=1 then @Realizat_Prodpan else @Realizat_acord-
					(case when @Velpitar=1 and @tip_salarizare='4' then @Ind_regim_normal else 0 end)+
					(case when @Realizat_acord=0 and @Procent_lucrat_acord<>0 and @Colas=0 then @Procent_lucrat_acord else 0 end) end)
				Set @cand_scriu=(case when @ore_lucrate_acord<>0 or @realizat_acord<>0 or @Procent_lucrat_acord<>0 then 1 else 0 end)
				exec scriu_fluturasi @Host_ID,@marca,'V','Acord',@Ore,@valoare,@cond1,@cond2,@cond3,@cand_scriu,'V'

--	apelare procedura specifica (pt. inceput se va folosi la Remarul - sesizarea 235055)
				if exists (select * from sys.objects WHERE object_id = OBJECT_ID(N'fluturasi_brutSP1') and type='P')
					exec fluturasi_brutSP1 @Host_ID,@marca,'Acord',@Ore,@valoare,@cond1,@cond2,@cond3,@cand_scriu,@datajos,@datasus,@cod_functie,@ploc_de_munca,@itip_salarizare
			End

			if @Prodpan=1 
			Begin
				Set @denumire = 'Coef. acord '+(case when @coef_acord<>0 then ltrim(str(@Coef_acord,10,5)) else '' end)
				Set @valoare=@Realizat_acord-@Realizat_Prodpan
				exec scriu_fluturasi @Host_ID,@marca,'V',@denumire,'',@valoare,@cond1,@cond2,@cond3,0,'V'
			End
			if (@Ore_delegatie<>0 or @Realizat_delegatie<>0)
			Begin
				Set @denumire = 'Delegatie   '
				Set @Ore = str(@Ore_delegatie,3)+' ore'
				Set @cand_scriu = (case when @Ore_delegatie<>0 or @Realizat_delegatie<>0 then 1 else 0 end)
				exec scriu_fluturasi @Host_ID,@marca,'V',@denumire,@Ore,@Realizat_delegatie,@cond1,@cond2,@cond3, @cand_scriu,'V'
			End
			if @Ind_os1<>0 
			Begin
				Set @Ore = str(@ore_s1,3)+' ore'
				exec scriu_fluturasi @Host_ID,@marca,'V',@den_os1,@Ore,@Ind_os1,@cond1,@cond2,@cond3,0,'V'
			End
			if @Ind_os2<>0 
			Begin
				Set @Ore = str(@ore_s2,3)+' ore'
				exec scriu_fluturasi @Host_ID,@marca,'V',@den_os2,@Ore,@Ind_os2,@cond1,@cond2,@cond3,0,'V'
			End
			if @Ind_os3<>0 
			Begin
				Set @Ore = str(@ore_s3,3)+' ore'
				exec scriu_fluturasi @Host_ID,@marca,'V',@den_os3,@Ore,@Ind_os3,@cond1,@cond2,@cond3,0,'V'
			End
			if @Ind_os4<>0 
			Begin
				Set @Ore = str(@ore_s4,3)+' ore'
				exec scriu_fluturasi @Host_ID,@marca,'V',@den_os4,@Ore,@Ind_os4,@cond1,@cond2,@cond3,0,'V'
			End
			if @Ind_ore_spor_100<>0 
			Begin
				Set @Ore = str(@ore_spor_100,3)+' ore'
				exec scriu_fluturasi @Host_ID,@marca,'V','Ore spor 100',@Ore,@Ind_ore_spor_100,@cond1,@cond2,@cond3,0, 'V'
			End
			if @Ind_ore_de_noapte<>0 
			Begin
				Set @Ore = str(@ore_de_noapte,3)+' ore'
				exec scriu_fluturasi @Host_ID,@marca,'V','Ore de noapte',@Ore,@Ind_ore_de_noapte,@cond1,@cond2,@cond3, 0,'V'
			End
			if @extensie_inf=1 and @forern=0
			Begin
				Set @Ore = str(@ore_regim_normal,3)+' ore'
				exec scriu_fluturasi @Host_ID,@marca,'V','Regim normal',@Ore,@Ind_regim_normal,@cond1,@cond2,@cond3,0, 'V'
			End
			exec fluturasi_timp_nelucrat @datajos,@datasus,@Host_ID,@marca,@cond1,@cond2,@cond3
			if @Subtipcor=0
				exec fluturasi_corectii @datajos,@datasus,@Host_ID,@marca,@cond1,@cond2,@cond3
			else 
				exec fluturasi_subtipuri_corectii @datajos,@datasus,@Host_ID,@marca,@cond1,@cond2,@cond3, ''

			exec fluturasi_sporuri @datajos,@datasus,@Host_ID,@marca,@cond1,@cond2,@cond3
			exec fluturasi_net @datajos,@datasus,@Host_ID,@marca,@cond1,@cond2,@cond3
		End
		If @comp_saln=1
			exec fluturasi_comp_saln @datajos,@datasus,@Host_ID,@marca,@cond1,@cond2,@cond3
		Set @glocm=@nloc_de_munca
		Set @gsupervisor=@psupervisor

		fetch next from cursor_fluturasi_brut into
			@Marca,@nume,@cod_functie,@ploc_de_munca,@itip_salarizare,@isalar_de_incadrare,@nloc_de_munca,@loc_de_munca,@psupervisor, 
			@Ore_lucrate__regie,@Realizat__regie,@Ore_lucrate_acord,@Realizat_acord,@Realizat_Prodpan,
			@Ore_s1,@Ind_os1,@Ore_s2,@Ind_os2,@Ore_s3,@Ind_os3,@Ore_s4,@Ind_os4,@Ore_spor_100,@Ind_ore_spor_100,@Ore_de_noapte,@Ind_ore_de_noapte, 
			@Ore_regim_normal,@Ind_regim_normal,@Ore_realizate_acord,@Procent_lucrat_acord,@bsalar_orar,@Ore_delegatie,@Realizat_delegatie,@Tip_salarizare,@Coef_acord 
	End
	Close cursor_fluturasi_brut
	Deallocate cursor_fluturasi_brut
End
