--***
/**	functie zileCM suspendare	*/
Create
function  fPSCalculZileCMSuspendare  (@pMarca char(6), @DataJ datetime, @DataS datetime)
returns @CMSuspendare table (Data datetime, Marca char(6), Zile_CM_suspendare int, Indemniz_CM_suspendare float)
As
Begin
declare @DataJ_1 datetime, @Zile_CM_susp int, @IndCM_susp float
Set @DataJ_1=@DataJ-1
declare @bData datetime, @bMarca char(6), @Data datetime, @Marca char(6), @Tip_diagnostic char(2),@Data_inceput datetime,@Data_sfarsit datetime,@Zile_lucratoare int, @Zile_luna_anterioara int, @Exista_CMlunacrt int, @Datasf_CM_lunacrt datetime, @Exista_CMant int, @Exista_CMant1 int, @DataInc_CMant datetime, @Contor int, @DataInc_somaj datetime, @DataSf_somaj datetime, @vDataSf_somaj datetime, @Data1 datetime, @Data_inceput1 datetime, @Zile_luna_anterioara1 int

declare brutcmsusp cursor for 
select distinct Data, Marca from brut where data between @DataJ and @DataS and (@pMarca='' or brut.marca=@pMarca) 
and ore_concediu_medical<>0
open brutcmsusp
fetch next from brutcmsusp into @bData, @bMarca
While @@fetch_status = 0 
Begin
	Set @Zile_CM_susp=0
	Set @IndCM_susp=0
	Set @Exista_CMant1=0
	declare cmsusp cursor for 
	select a.data, a.marca, a.tip_diagnostic, a.data_inceput, a.data_sfarsit, a.zile_lucratoare, a.zile_luna_anterioara, 
	isnull((select count(1) from conmed b where b.data between @DataS and @DataS and b.marca=@bMarca and 	b.zile_luna_anterioara>0),0), 
	isnull((select top 1 data_sfarsit from conmed b where b.data between @DataS and @DataS and b.marca=@bMarca and 	b.zile_luna_anterioara>0 order by b.data_inceput desc),'01/01/1901'), 
	isnull((select count(1) from conmed b where b.data between @DataJ_1 and @DataS and b.marca=@bMarca and 	b.data_sfarsit=a.data_inceput-1),0)
	from conmed a 
	where a.data between @DataS and @DataS and a.marca=@bMarca and a.tip_diagnostic not in ('0-','7-','8-') 
	and (a.data_inceput=@DataJ or a.zile_luna_anterioara>0 or (select count(1) from conmed c where c.data between @DataJ_1 	and @DataS and c.marca=@bMarca and c.data_sfarsit=dateadd(day,-1,a.data_inceput))>=1)
	Set @Contor=1
	open cmsusp
	fetch next from cmsusp into @Data, @Marca, @Tip_diagnostic, @Data_inceput, @Data_sfarsit, @Zile_lucratoare, 	@Zile_luna_anterioara, @Exista_CMlunacrt, @Datasf_CM_lunacrt, @Exista_CMant
	While @@fetch_status = 0 
	Begin
		if @Contor=1
		Begin
			Set @DataInc_somaj=@Data_inceput
			Set @DataSf_somaj=@Data_sfarsit
		End
		if @Zile_luna_anterioara<>0 or @Exista_CMant<>0
		Begin
			declare cmsusp1 cursor for 
			select a.data, a.data_inceput, a.zile_luna_anterioara, 
			isnull((select count(1) from conmed b where b.data between @DataJ_1 and @DataS and b.marca=@Marca 			and b.data_sfarsit=a.data_inceput-1),0) 
			from conmed a 
			where a.data between @DataJ_1 and @DataS and a.marca=@Marca and a.data_sfarsit<=@Data_inceput 
			order by a.data_sfarsit desc
			open cmsusp1
			fetch next from cmsusp1 into @Data1, @Data_inceput1, @Zile_luna_anterioara1, @Exista_CMant1 
			While @@fetch_status=0 --and not((not(@Exista_CMant1<>0) or @Data_inceput1=dbo.bom(@Data1) and 				@Data_inceput1<>@DataJ))
			Begin
				if (not(@Exista_CMant1<>0) or @Data_inceput1=dbo.bom(@Data1) and 				@Data_inceput1<>@DataJ)
				Begin
					Set @DataInc_CMant=@Data_inceput1
					break
				End
				fetch next from cmsusp1 into @Data1,@Data_inceput1,@Zile_luna_anterioara1,@Exista_CMant1 
			End
			Set @Exista_CMant1=(case when @DataInc_CMant<>'01/01/1901' then 1 else 0 end)
			close cmsusp1
			Deallocate cmsusp1
		End
		Set @Contor=@Contor+1
		fetch next from cmsusp into @Data, @Marca, @Tip_diagnostic, @Data_inceput, @Data_sfarsit, @Zile_lucratoare, 			@Zile_luna_anterioara, @Exista_CMlunacrt, @Datasf_CM_lunacrt, @Exista_CMant
	End
	close cmsusp
	Deallocate cmsusp
	if @Contor>1 and (@Exista_CMant1=0 and (case when @Datasf_CM_lunacrt='01/01/1901' then @DataSf_somaj else @Datasf_CM_lunacrt end)-@DataInc_somaj+1>30 or @Exista_CMant1=1 and @DataInc_CMant+30<=@Data_sfarsit)
	Begin
		Set @vDataSf_somaj=(case when @Data_sfarsit='01/01/1901' then @DataSf_somaj else @Data_sfarsit end)
		Set @Zile_CM_susp=dbo.Zile_lucratoare(@DataInc_somaj,@vDataSf_somaj)
		Set @IndCM_susp=isnull((select sum(indemnizatie_unitate+indemnizatie_cas) from conmed where marca=@bMarca 		and data=@DataS and data_inceput between @DataInc_somaj and @vDataSf_somaj and tip_diagnostic not in 		('0-','7-','8-')),0)
		Select @IndCM_susp=@IndCM_susp+isnull((select sum(indemnizatie_cas) from conmed where marca=@bMarca 
		and data=@DataS and data_inceput>@vDataSf_somaj and tip_diagnostic not in ('0-','7-','8-')),0)
	End
insert into @CMSuspendare Select @bData, @bMarca, @Zile_CM_susp, @IndCM_susp
fetch next from brutcmsusp into @bData, @bMarca
End
return
End
