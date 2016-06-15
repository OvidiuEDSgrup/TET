--***
/**	functie stagiu cm	*/
create 
function stagiu_cm 
	(@datasus datetime, @marca char(6), @data_inceput datetime, @datacm_initial datetime, @continuare int, @Luni_istoric int) 
returns @cm_stagiu table
	(Baza_stagiu1 float, Baza_stagiu2 float, Baza_stagiu3 float, Baza_stagiu4 float, Baza_stagiu5 float, Baza_stagiu6 float, 
	Baza_stagiu7 float, Baza_stagiu8 float, Baza_stagiu9 float, Baza_stagiu10 float, Baza_stagiu11 float, Baza_stagiu12 float, Baza_stagiu float,
	Zile_stagiu1 int, Zile_stagiu2 int, Zile_stagiu3 int, Zile_stagiu4 int, Zile_stagiu5 int,Zile_stagiu6 int, 
	Zile_stagiu7 int, Zile_stagiu8 int, Zile_stagiu9 int, Zile_stagiu10 int, Zile_stagiu11 int, Zile_stagiu12 int, Zile_stagiu int, 
	Zile_lucr1 int, Zile_lucr2 int, Zile_lucr3 int, Zile_lucr4 int, Zile_lucr5 int, Zile_lucr6 int, 
	Zile_lucr7 int, Zile_lucr8 int, Zile_lucr9 int, Zile_lucr10 int, Zile_lucr11 int, Zile_lucr12 int, 
	luna1 datetime, luna2 datetime, luna3 datetime, luna4 datetime, luna5 datetime, luna6 datetime, 
	luna7 datetime, luna8 datetime, luna9 datetime, luna10 datetime, luna11 datetime, luna12 datetime)
as
begin
	declare @Bc_stagiu float, @Bc_st1 float, @Bc_st2 float, @Bc_st3 float, @Bc_st4 float, @Bc_st5 float, @Bc_st6 float,
	@Bc_st7 float, @Bc_st8 float, @Bc_st9 float, @Bc_st10 float, @Bc_st11 float, @Bc_st12 float,
	@Z_st float, @Z_st1 float, @Z_st2 float, @Z_st3 float, @Z_st4 float, @Z_st5 float, @Z_st6 float, @Z_st7 float,
	@Z_st8 float, @Z_st9 float, @Z_st10 float, @Z_st11 float, @Z_st12 float,
	@dl1 datetime, @dl2 datetime, @dl3 datetime, @dl4 datetime, @dl5 datetime, @dl6 datetime, @dl7 datetime, @dl8 datetime, 
	@dl9 datetime, @dl10 datetime, @dl11 datetime, @dl12 datetime,
	@Z_l int, @Z_l1 int, @Z_l2 int, @Z_l3 int, @Z_l4 int, @Z_l5 int, @Z_l6 int, @Z_l7 int, @Z_l8 int, @Z_l9 int, @Z_l10 int, 
	@Z_l11 int,@Z_l12 int
	
	if /*@datacm_initial='01/01/1901' and*/ @continuare=1
		set @datacm_initial=dbo.data_inceput_cm(@datasus, @marca, @data_inceput, 1)
	else 	
		set @datacm_initial=@data_inceput

	declare @cm_st table (d_st datetime, Bc_st float, Z_lc int, Z_st int)
	Set @dl1=dbo.eom(dateadd(month,-1,@datacm_initial))
	Set @dl2=dbo.eom(dateadd(month,-2,@datacm_initial))
	Set @dl3=dbo.eom(dateadd(month,-3,@datacm_initial))
	Set @dl4=dbo.eom(dateadd(month,-4,@datacm_initial))
	Set @dl5=dbo.eom(dateadd(month,-5,@datacm_initial))
	Set @dl6=dbo.eom(dateadd(month,-6,@datacm_initial))
	Set @dl7=dbo.eom(dateadd(month,-7,@datacm_initial))
	Set @dl8=dbo.eom(dateadd(month,-8,@datacm_initial))
	Set @dl9=dbo.eom(dateadd(month,-9,@datacm_initial))
	Set @dl10=dbo.eom(dateadd(month,-10,@datacm_initial))
	Set @dl11=dbo.eom(dateadd(month,-11,@datacm_initial))
	Set @dl12=dbo.eom(dateadd(month,-12,@datacm_initial))

	insert @cm_st (d_st, Bc_st, Z_lc, Z_st)
	select data, sum(baza_cci_plaf), sum(round(Zile_asig,2)-round(ore_concediu_medical/regim_lucru,0)),
	sum(round(Zile_asig,2))
	from dbo.fistoric_cm (@datasus, @marca, '', @data_inceput, @continuare, 0, @Luni_istoric)
	group by data

	Set @Bc_st1=isnull((select Bc_st from @cm_st where d_st=@dl1),0)
	Set @Bc_st2=isnull((select Bc_st from @cm_st where d_st=@dl2),0)
	Set @Bc_st3=isnull((select Bc_st from @cm_st where d_st=@dl3),0)
	Set @Bc_st4=isnull((select Bc_st from @cm_st where d_st=@dl4),0)
	Set @Bc_st5=isnull((select Bc_st from @cm_st where d_st=@dl5),0)
	Set @Bc_st6=isnull((select Bc_st from @cm_st where d_st=@dl6),0)
	Set @Bc_st7=isnull((select Bc_st from @cm_st where d_st=@dl7),0)
	Set @Bc_st8=isnull((select Bc_st from @cm_st where d_st=@dl8),0)
	Set @Bc_st9=isnull((select Bc_st from @cm_st where d_st=@dl9),0)
	Set @Bc_st10=isnull((select Bc_st from @cm_st where d_st=@dl10),0)
	Set	@Bc_st11=isnull((select Bc_st from @cm_st where d_st=@dl11),0)
	Set @Bc_st12=isnull((select Bc_st from @cm_st where d_st=@dl12),0)
	Set @Z_st1=isnull((select Z_st from @cm_st where d_st=@dl1),0)
	Set @Z_st2=isnull((select Z_st from @cm_st where d_st=@dl2),0)
	Set @Z_st3=isnull((select Z_st from @cm_st where d_st=@dl3),0)
	Set @Z_st4=isnull((select Z_st from @cm_st where d_st=@dl4),0)
	Set @Z_st5=isnull((select Z_st from @cm_st where d_st=@dl5),0)
	Set @Z_st6=isnull((select Z_st from @cm_st where d_st=@dl6),0)
	Set @Z_st7=isnull((select Z_st from @cm_st where d_st=@dl7),0)
	Set @Z_st8=isnull((select Z_st from @cm_st where d_st=@dl8),0)
	Set @Z_st9=isnull((select Z_st from @cm_st where d_st=@dl9),0)
	Set @Z_st10=isnull((select Z_st from @cm_st where d_st=@dl10),0)
	Set @Z_st11=isnull((select Z_st from @cm_st where d_st=@dl11),0)
	Set @Z_st12=isnull((select Z_st from @cm_st where d_st=@dl12),0)
	/*Set @Z_l1=isnull((select Z_lc from @cm_st where d_st=@dl1),0)
	Set @Z_l2=isnull((select Z_lc from @cm_st where d_st=@dl2),0)
	Set @Z_l3=isnull((select Z_lc from @cm_st where d_st=@dl3),0)
	Set @Z_l4=isnull((select Z_lc from @cm_st where d_st=@dl4),0)
	Set @Z_l5=isnull((select Z_lc from @cm_st where d_st=@dl5),0)
	Set @Z_l6=isnull((select Z_lc from @cm_st where d_st=@dl6),0)
	Set @Z_l7=isnull((select Z_lc from @cm_st where d_st=@dl7),0)
	Set @Z_l8=isnull((select Z_lc from @cm_st where d_st=@dl8),0)
	Set @Z_l9=isnull((select Z_lc from @cm_st where d_st=@dl9),0)
	Set @Z_l10=isnull((select Z_lc from @cm_st where d_st=@dl10),0)
	Set @Z_l11=isnull((select Z_lc from @cm_st where d_st=@dl11),0)
	Set @Z_l12=isnull((select Z_lc from @cm_st where d_st=@dl12),0)*/
	Set @Z_l1=round(dbo.iauParLN (@dl1,'PS','ORE_LUNA')/8,0)
	Set @Z_l2=round(dbo.iauParLN (@dl2,'PS','ORE_LUNA')/8,0)
	Set @Z_l3=round(dbo.iauParLN (@dl3,'PS','ORE_LUNA')/8,0)
	Set @Z_l4=round(dbo.iauParLN (@dl4,'PS','ORE_LUNA')/8,0)
	Set @Z_l5=round(dbo.iauParLN (@dl5,'PS','ORE_LUNA')/8,0)
	Set @Z_l6=round(dbo.iauParLN (@dl6,'PS','ORE_LUNA')/8,0)
	Set @Z_l7=round(dbo.iauParLN (@dl7,'PS','ORE_LUNA')/8,0)
	Set @Z_l8=round(dbo.iauParLN (@dl8,'PS','ORE_LUNA')/8,0)
	Set @Z_l9=round(dbo.iauParLN (@dl9,'PS','ORE_LUNA')/8,0)	
	Set @Z_l10=round(dbo.iauParLN (@dl10,'PS','ORE_LUNA')/8,0)
	Set @Z_l11=round(dbo.iauParLN (@dl11,'PS','ORE_LUNA')/8,0)
	Set @Z_l12=round(dbo.iauParLN (@dl12,'PS','ORE_LUNA')/8,0)
	/*Set @Z_l=@Z_l1+@Z_l2+@Z_l3+@Z_l4+@Z_l5+@Z_l6+@Z_l7+@Z_l8+@Z_l9+@Z_l10+@Z_l11+@Z_l12*/

	insert @cm_stagiu
	select @Bc_st1, @Bc_st2, @Bc_st3, @Bc_st4, @Bc_st5, @Bc_st6, @Bc_st7, @Bc_st8, @Bc_st9, @Bc_st10, @Bc_st11, @Bc_st12, @Bc_st1+@Bc_st2+@Bc_st3+@Bc_st4+@Bc_st5+@Bc_st6 as baza_stagiu, 
		@Z_st1, @Z_st2, @Z_st3, @Z_st4, @Z_st5, @Z_st6, @Z_st7, @Z_st8, @Z_st9, @Z_st10, @Z_st11, @Z_st12, @Z_st1+@Z_st2+@Z_st3+@Z_st4+@Z_st5+@Z_st6 as zile_stagiu, 
		@Z_l1, @Z_l2, @Z_l3, @Z_l4, @Z_l5, @Z_l6, @Z_l7, @Z_l8, @Z_l9, @Z_l10, @Z_l11, @Z_l12, @dl1, @dl2, @dl3, @dl4, @dl5, @dl6, @dl7, @dl8, @dl9, @dl10, @dl11, @dl12

	return
end
