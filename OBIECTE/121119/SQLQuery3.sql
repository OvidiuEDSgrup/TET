select top 1 dbo.eom(rtrim(anul)+'-'+rtrim(luna)+'-01') from 
	(select anul=a.Val_numerica,luna=l.val_numerica from par l inner join par a on a.Tip_parametru=l.Tip_parametru 
		and a.Parametru='ANULINC' where l.Tip_parametru='GE' and l.Parametru='LUNAINC'
	union 
	select a.Val_numerica,l.val_numerica from par l inner join par a on a.Tip_parametru=l.Tip_parametru 
		and a.Parametru='ANULBLOC' where l.Tip_parametru='GE' and l.Parametru='LUNABLOC') par
	where isdate(rtrim(anul)+'-'+rtrim(luna)+'-01')=1
order by anul desc, luna desc