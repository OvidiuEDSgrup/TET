	/*
	select 'ST'+right(rtrim(pozdoc.idPozDoc),13)
		,case when st.cod is null then 1 else 0 end
		,case when st.stoc<=-0.001 then 1 else 0 end
		,case when pozdoc.Cod_intrare='' then 1 else 0 end
	,pozdoc.*
	--*/UPDATE pozdoc set cod_intrare='ST'+right(rtrim(pozdoc.idPozDoc),13)
	from pozdoc
	left outer join stocuri st on pozdoc.subunitate=st.subunitate and pozdoc.gestiune=st.cod_gestiune and pozdoc.cod=st.cod and pozdoc.cod_intrare=st.cod_intrare
where pozdoc.Data between '2012-08-01' and '2012-09-07'
	and pozdoc.tip_miscare='E' and pozdoc.cantitate<=-0.001
	--and not (tip='TE' and pozdoc.gestiune=pozdoc.Gestiune_primitoare) -- tentativa de execeptare modificari de pret
	and (
	--st.cod is null 
		--or st.stoc<=-0.001 or 
		pozdoc.Cod_intrare='' 
	--or pozdoc.Pret_de_stoc!=st.Pret 
	--or pozdoc.Cont_de_stoc!=st.Cont 
	--or pozdoc.Pret_amanunt_predator!=st.Pret_cu_amanuntul
	)	