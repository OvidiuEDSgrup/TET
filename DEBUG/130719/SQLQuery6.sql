select * from yso.pozconexp p 
where p.Contract='9840618'

select * from pozcon 
LEFT join (select t.Subunitate,t.Tert,tip_tva=isnull(ttva.tip_tva,(case when isnull(TipTVA.tip_tva,'P')='I' then 'I' else 'P' end)) from terti t 
		left join (select top 1 tip_tva from TvaPeTerti where TipF='B' and Tert is null and dela<=GETDATE() order by dela desc) tipTva on 1=1
		outer apply (select top 1 t.tert,tv.tip_tva as tip_tva
					from TvaPeTerti tv 
					where tv.tipf='F' and t.tert=tv.tert
					order by dela desc
					) ttva) t on t.Subunitate=pozcon.Subunitate and t.Tert=pozcon.Tert 
where Contract='9840618'