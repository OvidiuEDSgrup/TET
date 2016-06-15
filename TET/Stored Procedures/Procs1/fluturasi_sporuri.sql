--***
/**	fluturasi sporuri	*/
Create procedure fluturasi_sporuri
	@datajos datetime, @datasus datetime, @HostID char(10), @pmarca char(6), @cond1 bit, @cond2 bit, @cond3 bit
as
Begin
	declare @Marca char(6),@ispor_vechime char(6),@ispor_de_noapte char(6),@pSistematic_peste_program float,@pspor_specific float, 
	@pspor_cond_1 float,@pspor_cond_2 float,@pspor_cond_3 float,@pspor_cond_4 float,@pspor_cond_5 float,@pspor_cond_6 float, @pspor_cond_7 float,
	@Spor_vechime float,@Spor_de_noapte float,@Spor_sistematic_peste_program float, @Spor_de_functie_suplimentara float,@Spor_specific float,
	@Spor_cond_1 float,@Spor_cond_2 float,@Spor_cond_3 float, @Spor_cond_4 float,@Spor_cond_5 float,@Spor_cond_6 float,
	@VENIT_TOTAL float,@bSalar_orar float,@Spor_cond_7 float, @Spor_cond_8 float,@Spor_cond_9 float,@Spor_cond_10 float,
	@Ore_sistematic_peste_program float,@Ore__cond_1 float, @Ore__cond_2 float,@Ore__cond_3 float,@Ore__cond_4 float,@Ore__cond_5 float,@Ore__cond_6 float,
	@den_spec char(50), @den_spsistprg char(50), @den_spfunctsupl char(50), 
	@den_sp1 char(50), @den_sp2 char(50), @den_sp3 char(50), @den_sp4 char(50), @den_sp5 char(50), @den_sp6 char(50), @den_sp7 char(50),@den_sp8 char(50),
	@ore char(20), @sp1_ore int, @sp2_ore bit, @sp3_ore int, @sp4_ore bit, @sp5_ore int, @sp6_ore bit, @Spspec_suma int, 
	@sp1_suma int, @sp2_suma bit, @sp3_suma int, @sp4_suma bit, @sp5_suma int, @sp6_suma bit, @Afisare_sporuri_0 int, @cand_scriu int, 
	@Salubris bit, @Colas bit, @Procflds4 bit, @numeprocs4 char(300)

	set @den_spec=dbo.iauParA('PS','SSPEC')
	set @den_spsistprg=dbo.iauParA('PS','SPSISTPRG')
	set @den_spsistprg=(case when @den_spsistprg='' then 'Spor sist peste prg' else @den_spsistprg end)
	set @den_spfunctsupl=dbo.iauParA('PS','SPFCTSUPL')
	set @den_spfunctsupl=(case when @den_spfunctsupl='' then 'Spor functie suplimentara' else @den_spfunctsupl end)
	Exec Luare_date_par 'PS','SCOND1',@sp1_ore output,0,@den_sp1 output
	Exec Luare_date_par 'PS','SCOND2',@sp2_ore output,0,@den_sp2 output
	Exec Luare_date_par 'PS','SCOND3',@sp3_ore output,0,@den_sp3 output
	Exec Luare_date_par 'PS','SCOND4',@sp4_ore output,0,@den_sp4 output
	Exec Luare_date_par 'PS','SCOND5',@sp5_ore output,0,@den_sp5 output
	Exec Luare_date_par 'PS','SCOND6',@sp6_ore output,0,@den_sp6 output
	set @den_sp7=dbo.iauParA('PS','SCOND7')
	set @den_sp8=dbo.iauParA('PS','SCOND8')
	set @Spspec_suma=dbo.iauParL('PS','SSP-SUMA')
	set @sp1_suma=dbo.iauParL('PS','SC1-SUMA')
	set @sp2_suma=dbo.iauParL('PS','SC2-SUMA')
	set @sp3_suma=dbo.iauParL('PS','SC3-SUMA')
	set @sp4_suma=dbo.iauParL('PS','SC4-SUMA')
	set @sp5_suma=dbo.iauParL('PS','SC5-SUMA')
	set @sp6_suma=dbo.iauParL('PS','SC6-SUMA')
	set @Afisare_sporuri_0=dbo.iauParL('PS','FLDAFSP0')
	set @Procflds4=dbo.iauParL('PS','PROCFLDS4')
	set @Salubris=dbo.iauParL('SP','SALUBRIS')
	set @Colas=dbo.iauParL('SP','COLAS')

	if @procflds4=1
	Begin
		Set @numeprocs4='exec fluturasi_sporuri_specific '+char(39)+convert(char(10),@datajos,101)+char(39)+','+char(39)+ convert(char(10),@datasus,101)+
			char(39)+','+@HostID+','+@pmarca+','+rtrim(convert(char(5),@cond1))+','+rtrim(convert(char(5),@cond2))+ ','+rtrim(convert(char(5),@cond3))
		exec (@numeprocs4)
	End
	Else
	Begin
		Declare cursor_fluturasi_sporuri Cursor For
		select a.Marca, ltrim(str(max(i.spor_vechime),3))+'%', ltrim(str(max(i.spor_de_noapte),3))+'%', ltrim(str(max(isnull(j.Sistematic_peste_program,0)),10,2)),
			ltrim(str(max(isnull(j.spor_specific,0)),6,2)), ltrim(str(max(isnull(j.spor_conditii_1,0)),10,2)),ltrim(str(max(isnull(j.spor_conditii_2,0)),10,2)),
			ltrim(str(max(isnull(j.spor_conditii_3,0)),10,2)), ltrim(str(max(round(isnull(j.spor_conditii_4,0),2)),10,2)),ltrim(str(max(isnull(j.spor_conditii_5,0)),10,2)), 
			ltrim(str(max(isnull(j.spor_conditii_6,0)),10,2)),ltrim(str(max(isnull(j.spor_cond_7,0)),10,2)),sum(round(a.Spor_vechime,0)), sum(round(a.Spor_de_noapte,0)),
			sum(round(a.Spor_sistematic_peste_program,0)),sum(round(a.Spor_de_functie_suplimentara,0)), sum(round(a.Spor_specific,0)),
			sum(round(a.Spor_cond_1,0)),sum(round(a.Spor_cond_2,0)),sum(round(a.Spor_cond_3,0)), sum(round(a.Spor_cond_4,0)),sum(round(a.Spor_cond_5,0)),sum(round(a.Spor_cond_6,0)),
			sum(a.VENIT_TOTAL),max(a.Salar_orar), sum(round(a.Spor_cond_7,0)),sum(round(a.Spor_cond_8,0)),sum(a.Spor_cond_9),max(a.Spor_cond_10), sum(a.Ore_sistematic_peste_program),
			sum(a.Ore__cond_1),sum(a.Ore__cond_2),sum(a.Ore__cond_3),sum(a.Ore__cond_4), sum(a.Ore__cond_5),sum(a.Ore__cond_6)
		from tmpfluturi a
			left outer join istpers i on i.data=a.data and i.marca=a.marca
			left outer join (select marca,max(Sistematic_peste_program) as Sistematic_peste_program,max(spor_specific) as spor_specific, 
				max(spor_conditii_1) as spor_conditii_1,max(spor_conditii_2) as spor_conditii_2,max(spor_conditii_3) as spor_conditii_3,
				max(spor_conditii_4) as spor_conditii_4,max(spor_conditii_5) as spor_conditii_5,max(spor_conditii_6) as spor_conditii_6,max(spor_cond_7) as spor_cond_7
		from pontaj where data between @datajos and @datasus and marca=@pmarca group by marca) j on j.marca=a.marca
		where a.Host_ID=@HostID and a.marca=@pmarca
		group by a.data,a.marca

		open cursor_fluturasi_sporuri
		fetch next from cursor_fluturasi_sporuri into
			@Marca,@ispor_vechime,@ispor_de_noapte,@pSistematic_peste_program,@pspor_specific,
			@pspor_cond_1,@pspor_cond_2, @pspor_cond_3,@pspor_cond_4,@pspor_cond_5,@pspor_cond_6,@pspor_cond_7,
			@Spor_vechime,@Spor_de_noapte, @Spor_sistematic_peste_program,@Spor_de_functie_suplimentara,@Spor_specific,
			@Spor_cond_1,@Spor_cond_2,@Spor_cond_3, @Spor_cond_4,@Spor_cond_5,@Spor_cond_6,@VENIT_TOTAL,@bSalar_orar,
			@Spor_cond_7,@Spor_cond_8,@Spor_cond_9, @Spor_cond_10,@Ore_sistematic_peste_program,
			@Ore__cond_1,@Ore__cond_2,@Ore__cond_3,@Ore__cond_4,@Ore__cond_5, @Ore__cond_6
		While @@fetch_status = 0 
		Begin
			if @spor_vechime<>0
				exec scriu_fluturasi @HostID,@marca,'V','Spor vechime',@ispor_vechime,@spor_vechime,@cond1,@cond2, @cond3,0,'V'
			if @spor_de_noapte<>0
				exec scriu_fluturasi @HostID,@marca,'V','Spor de nopate',@ispor_de_noapte,@spor_de_noapte,@cond1, @cond2,@cond3,0,'V'
			if @spor_sistematic_peste_program<>0
				exec scriu_fluturasi @HostID,@marca,'V',@den_spsistprg,'',@spor_sistematic_peste_program,@cond1, @cond2,@cond3,0,'V'
			if @spor_de_functie_suplimentara<>0
				exec scriu_fluturasi @HostID,@marca,'V',@den_spfunctsupl,'',@spor_de_functie_suplimentara,@cond1, @cond2,@cond3,0,'V'
			if @spor_specific<>0 or @Afisare_sporuri_0=1 and @den_spec<>''
			Begin
				Set @ore=(case when @Spspec_suma=1 then '' else ltrim(str(@pspor_specific,10,2))+'%' end)
				Set @cand_scriu = (case when @Afisare_sporuri_0=1 and @den_spec<>'' then 1 else 0 end)
				exec scriu_fluturasi @HostID,@marca,'V',@den_spec,@ore,@spor_specific,@cond1,@cond2,@cond3,@cand_scriu,'V'
			End
			if @spor_cond_1<>0 or @Afisare_sporuri_0=1 and @den_sp1<>''
			Begin
				Set @den_sp1 = rtrim(@den_sp1)+'  '+(case when @sp1_suma=1 or @sp1_ore=0 then '' else ltrim(str(@pspor_cond_1,6,2))+'%' end)
				Set @ore = (case when (@Salubris=1 or @sp1_ore=1) and @ore__cond_1<>0 then str(@ore__cond_1,3)+' ore ' else '' end)+
					(case when @sp1_suma=1 or @sp1_ore=1 then '' else ltrim(str(@pspor_cond_1,10,2))+'%' end)
				Set @cand_scriu = (case when @Afisare_sporuri_0=1 and @den_sp1<>'' then 1 else 0 end)
				exec scriu_fluturasi @HostID,@marca,'V',@den_sp1,@ore,@spor_cond_1,@cond1,@cond2,@cond3,@cand_scriu,'V'
			End
			if @spor_cond_2<>0 or @Afisare_sporuri_0=1 and @den_sp2<>''
			Begin
				Set @den_sp2 = rtrim(@den_sp2)+'  '+(case when @sp2_suma=1 or @sp2_ore=0 then '' else ltrim(str(@pspor_cond_2,6,2))+'%' end)
				Set @ore = (case when (@Salubris=1 or @sp2_ore=1) and @ore__cond_2<>0 then str(@ore__cond_2,3)+' ore ' else '' end)+
					(case when @sp2_suma=1 or @sp2_ore=1 then '' else ltrim(str(@pspor_cond_2,10,2))+'%' end)
				Set @cand_scriu = (case when @Afisare_sporuri_0=1 and @den_sp2<>'' then 1 else 0 end)
				exec scriu_fluturasi @HostID,@marca,'V',@den_sp2,@ore,@spor_cond_2,@cond1,@cond2,@cond3,@cand_scriu,'V'
			End
			if @spor_cond_3<>0 or @Afisare_sporuri_0=1 and @den_sp3<>''
			Begin
				Set @den_sp3 = rtrim(@den_sp3)+'  '+(case when @sp3_suma=1 or @sp3_ore=0 then '' else ltrim(str(@pspor_cond_3,6,2))+'%' end)
				Set @ore = (case when (@Salubris=1 or @sp3_ore=1) and @ore__cond_3<>0 then str(@ore__cond_3,3)+' ore ' else '' end)+
					(case when @sp3_suma=1 or @sp3_ore=1 then '' else ltrim(str(@pspor_cond_3,10,2))+'%' end)
				Set @cand_scriu = (case when @Afisare_sporuri_0=1 and @den_sp3<>'' then 1 else 0 end)
				exec scriu_fluturasi @HostID,@marca,'V',@den_sp3,@ore,@spor_cond_3,@cond1,@cond2,@cond3,@cand_scriu,'V'
			End
			if @spor_cond_4<>0 or @Afisare_sporuri_0=1 and @den_sp4<>''
			Begin
				Set @den_sp4 = rtrim(@den_sp4)+'  '+(case when @sp4_suma=1 or @sp4_ore=0 then '' else ltrim(str(@pspor_cond_4,6,2))+'%' end)
				Set @ore = (case when (@Salubris=1 or @sp4_ore=1) and @ore__cond_4<>0 then str(@ore__cond_4,3)+' ore ' else '' end)+
					(case when @sp4_suma=1 or @sp4_ore=1 then '' else ltrim(str(@pspor_cond_4,10,2))+'%' end)
				Set @cand_scriu = (case when @Afisare_sporuri_0=1 and @den_sp4<>'' then 1 else 0 end)
				exec scriu_fluturasi @HostID,@marca,'V',@den_sp4,@ore,@spor_cond_4,@cond1,@cond2,@cond3,@cand_scriu,'V'
			End
			if @spor_cond_5<>0 or @Afisare_sporuri_0=1 and @den_sp5<>''
			Begin
				Set @den_sp5 = rtrim(@den_sp5)+'  '+(case when @sp5_suma=1 or @sp5_ore=0 then '' else ltrim(str(@pspor_cond_5,6,2))+'%' end)
				Set @ore = (case when (@Salubris=1 or @sp5_ore=1) and @ore__cond_5<>0 then str(@ore__cond_5,3)+' ore ' else '' end)+
					(case when @sp5_suma=1 or @sp5_ore=1 then '' else ltrim(str(@pspor_cond_5,10,2))+'%' end)
				Set @cand_scriu = (case when @Afisare_sporuri_0=1 and @den_sp5<>'' then 1 else 0 end)
				exec scriu_fluturasi @HostID,@marca,'V',@den_sp5,@ore,@spor_cond_5,@cond1,@cond2,@cond3,@cand_scriu,'V'
			End
			if @spor_cond_6<>0 or @Afisare_sporuri_0=1 and @den_sp6<>''
			Begin
				Set @den_sp6 = rtrim(@den_sp6)+'  '+(case when @sp6_suma=1 or @sp6_ore=0 then '' else ltrim(str(@pspor_cond_6,6,2))+'%' end)
				Set @ore = (case when (@Salubris=1 or @sp6_ore=1) and @ore__cond_6<>0 then str(@ore__cond_6,3)+' ore ' else '' end)+
					(case when @sp6_suma=1 or @sp6_ore=1 then '' else ltrim(str(@pspor_cond_6,10,2))+'%' end)
				Set @cand_scriu = (case when @Afisare_sporuri_0=1 and @den_sp6<>'' then 1 else 0 end)
				exec scriu_fluturasi @HostID,@marca,'V',@den_sp6,@ore,@spor_cond_6,@cond1,@cond2,@cond3,@cand_scriu,'V'
			End
			if @spor_cond_7<>0 or @Afisare_sporuri_0=1 and @den_sp7<>''
			Begin
				Set @Ore = ltrim(str(@pspor_cond_7,6,2))+'%'
				Set @cand_scriu = (case when @Afisare_sporuri_0=1 and @den_sp7<>'' then 1 else 0 end)
				exec scriu_fluturasi @HostID,@marca,'V',@den_sp7,@Ore,@spor_cond_7,@cond1,@cond2,@cond3,@cand_scriu,'V'
			End
			if @spor_cond_8<>0 and @Colas=0 and @den_sp8<>''
				exec scriu_fluturasi @HostID,@marca,'V',@den_sp8,'',@spor_cond_8,@cond1,@cond2,@cond3,0,'V'

			fetch next from cursor_fluturasi_sporuri into
				@Marca,@ispor_vechime,@ispor_de_noapte,@pSistematic_peste_program,
				@pspor_specific,@pspor_cond_1,@pspor_cond_2, @pspor_cond_3,@pspor_cond_4,@pspor_cond_5,@pspor_cond_6,@pspor_cond_7,
				@Spor_vechime,@Spor_de_noapte,@Spor_sistematic_peste_program,@Spor_de_functie_suplimentara,@Spor_specific,
				@Spor_cond_1,@Spor_cond_2,@Spor_cond_3,@Spor_cond_4,@Spor_cond_5,@Spor_cond_6,@VENIT_TOTAL,@bSalar_orar,
				@Spor_cond_7,@Spor_cond_8,@Spor_cond_9,@Spor_cond_10, @Ore_sistematic_peste_program,
				@Ore__cond_1,@Ore__cond_2,@Ore__cond_3,@Ore__cond_4,@Ore__cond_5,@Ore__cond_6
		End
		close cursor_fluturasi_sporuri
		Deallocate cursor_fluturasi_sporuri
	End
End
