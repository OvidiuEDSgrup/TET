--/*
select 
--*/update pozdoc set 
lot=(case when p.tip='RM' then cont_corespondent when p.tip in ('PP','AI') then grupa end)
--,*
		from pozdoc p
			JOIN proprietati pr on pr.Tip='NOMENCL' and pr.Cod_proprietate='ARESERII' and pr.Cod=p.Cod and pr.Valoare='DA' and pr.Valoare_tupla=''
		where subunitate='1' and p.tip in ('RM','PP','AI') 
			and isnull(lot,'')<>(case when p.tip='RM' then cont_corespondent when p.tip in ('PP','AI') then grupa end)
			and isnull((case when p.tip='RM' then cont_corespondent when p.tip in ('PP','AI') then grupa end),'')<>''
			--and (@tip is null or p.Tip=@Tip) and (@numar is null or Numar=@Numar) 
			--and data between @datajos and @datasus