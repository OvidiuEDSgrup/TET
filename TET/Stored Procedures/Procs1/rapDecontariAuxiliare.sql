--***
create procedure rapDecontariAuxiliare @sesiune varchar(50)=null, 
		@ordBeneficiar varchar(1),@datajos datetime, @datasus datetime,
		@lm_furnizor varchar(30), @cm_furnizor varchar(30), @lm_beneficiar varchar(30), @cm_beneficiar varchar(30),
		@tipcom_furnizor_str varchar(200), @tipcom_beneficiar_str varchar(200)
as
declare @eroare varchar(1000)
begin try
	select --MAX(numar)as numar, MAX(costsql.data) as data, 
		lm_inf as lm_furnizor, comanda_inf as comanda_furnizor,
		lm_sup as lm_beneficiar, (case when comanda_sup='' and tip='DX' then isnull(d.comanda_beneficiar, '') else comanda_sup end) as comanda_beneficiar, 
		SUM(costsql.cantitate) as cantitate, SUM(costsql.cantitate*costsql.valoare) as valoare,
		AVG(costsql.valoare) as pret,(case when @ordBeneficiar='0' then lm_inf else lm_sup end) as lmord,
		(case when @ordBeneficiar='0' then comanda_inf else (case when comanda_sup='' and tip='DX' then isnull(d.comanda_beneficiar, '') else comanda_sup end) end) as comandaord
		, MAX(p.Descriere) as den_comanda_furnizor
		, MAX(cb.Descriere) as den_comanda_beneficiar
		,MAX(lf.Denumire) as den_lm_furnizor
		,MAX(lb.Denumire) as den_lm_beneficiar
	from costsql left outer join comenzi p on costsql.comanda_inf=p.comanda 
		left outer join decaux d on d.comanda_furnizor=comanda_inf and d.l_m_furnizor like rtrim(lm_inf)+'%' 
			and d.numar_document=numar and d.data between @datajos and @datasus
		left outer join comenzi cb on cb.comanda=(case when comanda_sup='' and tip='DX' then isnull(d.comanda_beneficiar, '') else comanda_sup end)
		left join lm lf on lf.Cod=LM_INF
		left join lm lb on lb.Cod=LM_SUP

	where costsql.data between @datajos and @datasus
	and parcurs>1 and not (lm_sup='' and comanda_sup='' and art_sup in ('P','R','S','A','N'))
	and p.tip_comanda in ('T','X') 
		and (@lm_furnizor is null or lm_inf like rtrim(@lm_furnizor)+'%') and (@cm_furnizor is null or comanda_inf=@cm_furnizor)	
				-- loc de munca furnizor, comanda furnizor
		and (@lm_beneficiar is null or lm_sup like rtrim(@lm_beneficiar)+'%') and (@cm_beneficiar is null or (case when comanda_sup='' and tip='DX' then isnull(d.comanda_beneficiar, '') else comanda_sup end)=@cm_beneficiar) 
				-- loc de munca beneficiar, comanda beneficiar
		and CHARINDEX(p.Tip_comanda,@tipcom_furnizor_str)>0
		and CHARINDEX(cb.Tip_comanda,@tipcom_beneficiar_str)>0
				-- tip comanda furnizor/beneficiar
	GROUP BY LM_INF,COMANDA_INF,(case when comanda_sup='' and tip='DX' then isnull(d.comanda_beneficiar, '') else comanda_sup end),LM_SUP,
	(case when @ordBeneficiar='0' then lm_inf else lm_sup end),(case when @ordBeneficiar='0' then comanda_inf else (case when comanda_sup='' and tip='DX' then isnull(d.comanda_beneficiar, '') else comanda_sup end) end)
	order by lmord,comandaord
	
end try
begin catch
	select @eroare=error_message()+' (' + OBJECT_NAME(@@PROCID) +')'
end catch
if len(@eroare)>0
begin
	select @eroare as cont, '<EROARE>' as numar
	raiserror(@eroare,16,1)
end
