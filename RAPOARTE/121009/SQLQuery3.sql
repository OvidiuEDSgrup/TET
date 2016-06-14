insert into expval select 'MB1','E',c.DATA_LUNII,pp.echipa,lm.denumire,t.denumire,g.denumire,n.denumire,sum(p.Cantitate*p.Pret_vanzare-p.Cantitate*isnull(pk.pret_intrare_pachet,p.Pret_de_stoc)) from pozdoc p inner join calstd c on c.Data=p.Data 
left join (select p.Cod,echipa=max(valoare) from proprietati p where Cod_proprietate='ECHIPA' and tip='TERT' group by p.Cod) pp
 on pp.cod=p.tert 
left join (select pp.Gestiune, Gestiune_primitoare=coalesce(c.gestiune_primitoare,t.gestiune_primitoare,'')
			,pp.cod_intrare,cod_intrare_primitor=coalesce(c.grupa,t.grupa,''), pp.Cod
			,pret_intrare_pachet=SUM(cm.cantitate*cm.Pret_de_stoc)/MAX(pp.cantitate) 
		from pozdoc cm
			inner join pozdoc pp on pp.Subunitate=cm.Subunitate and pp.Data=cm.Data and pp.Numar=cm.Numar and pp.Tip='PP'
			left join pozdoc t on t.Subunitate=pp.Subunitate and t.Gestiune=pp.Gestiune and t.Cod=pp.Cod and t.Cod_intrare=pp.Cod_intrare and t.Tip='TE'
			left join pozdoc c on c.Subunitate=t.Subunitate and c.Tip=t.Tip and c.Gestiune=t.Gestiune_primitoare and c.Cod=t.Cod and c.Cod_intrare=t.Grupa
		where cm.Tip='CM' 
		group by pp.Gestiune,coalesce(c.gestiune_primitoare,t.gestiune_primitoare,'')
			,pp.cod_intrare,coalesce(c.grupa,t.grupa,''), pp.Cod) pk
on pk.cod=p.Cod and p.Gestiune in (pk.gestiune,pk.gestiune_primitoare)
	and p.Cod_intrare in (pk.cod_intrare,pk.cod_intrare_primitor)
left join terti t on t.Subunitate=p.Subunitate and t.Tert=p.Tert left join lm on lm.Cod=p.Loc_de_munca left join nomencl n on n.Cod=p.Cod left join grupe g on g.Grupa=n.Grupa 
where p.tip in ('AP','AS','AC') and c.DATA_LUNII between '10/09/2012' and '10/31/2012' group by c.DATA_LUNII,pp.echipa,lm.denumire,t.denumire,g.denumire,n.denumire                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            