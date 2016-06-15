--***
create procedure rapMFnotecontabile(@datajos datetime, @datasus datetime, @ordLM int=1,
	@locm varchar(20)=null,
	@tipNota varchar(2)='MA'	--> 'MA' = note amortizare, 'ME'->'MM'= note miscari
	)
as
begin
	--> (re)organizare filtre:
	declare @userASiS char(20), @filtruLM bit, @tipNotaJos varchar(2), @tipNotaSus varchar(2), @jurnal varchar(3), @subunitate varchar(9)
	
	set @userASiS=dbo.fIaUtilizator(null)
	select @filtruLM=(case when @locm is null then 0 else 1 end), @locm=@locm+'%',@jurnal='MFX',
			@tipNotaJos=(case when @tipNota='MA' then @tipNota else 'ME' end),
			@tipNotaSus=(case when @tipNota='MA' then @tipNota else 'MM' end),
			@subunitate=(select top 1 val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO')
			
	select p.subunitate, p.tip_document, p.numar_document, p.data, p.cont_debitor, p.cont_creditor, p.suma, p.valuta, p.explicatii,
		p.loc_de_munca, rtrim(left(p.comanda,20)) as comanda, p.indbug as indicator, (case when @ordLM=1 then p.loc_de_munca else '' end) as ord1 , p.jurnal,
		lm.Denumire as numeLocm
	from pozincon p
		left join lm on p.Loc_de_munca=lm.Cod
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_de_munca
	where p.subunitate=@subunitate and (p.tip_document between @tipNotaJos and @tipNotaSus or @tipNota<>'MA' and p.tip_document<>'MA' and p.jurnal=@jurnal)
		and p.data between @datajos and @datasus and (@filtruLM=0 or p.loc_de_munca like @locm)
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null) 
	Order by p.subunitate, ord1, p.tip_document, p.numar_document, p.data, p.numar_pozitie
end
