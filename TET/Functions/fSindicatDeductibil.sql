Create function fSindicatDeductibil (@dataJos datetime, @dataSus datetime)
returns @sindicatDeductibil table 
	(data datetime, marca varchar(6), sindicatDeductibil decimal(12,2))
as
Begin
	Declare @utilizator varchar(20), @lista_lm int, @CodSindicat char(13), @SindicatProcentual int, @ProcentSindicat float

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	select	@SindicatProcentual=max(case when Parametru='SIND%' then Val_logica else 0 end),
			@ProcentSindicat=max(case when Parametru='SIND%' then Val_numerica else 0 end),
			@CodSindicat=max(case when Parametru='SIND%' then Val_alfanumerica else '' end)
	from par 
	where Tip_parametru='PS' and Parametru in ('SIND%')

	insert into @sindicatDeductibil
	select r.Data, r.Marca, 
	sum(round(r.retinut_la_lichidare*(case when @SindicatProcentual=1 and r.Procent_progr_la_lichidare>1 then 1/r.Procent_progr_la_lichidare else 1 end),0)) as SindicatDeductibil
	from resal r 
		left outer join istPers i on i.Marca=r.Marca and i.Data=r.Data
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
	where r.data between @dataJos and @dataSus 
		and r.cod_beneficiar in (dbo.fCodb_sindicat(r.marca,r.data),@CodSindicat) 
		and (@lista_lm=0 or lu.cod is not null) 
		and i.grupa_de_munca in ('N','D','S','C') and i.tip_colab=''
	group by r.Data, r.Marca

	return
End
