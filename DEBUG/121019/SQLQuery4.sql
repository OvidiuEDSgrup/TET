--insert into expval 
select 'stocprop','E',c.data_lunii,isnull(g.Denumire_gestiune,g.gestiune),'','','','',sum (s.stoc*s.pret) from calstd c 
cross apply dbo.fStocuriCen(c.data_lunii,null,null,null,1,1,0,null,null,null,null,null,null,null,null,null) s
left join gestiuni g on g.subunitate=s.subunitate and g.Tip_gestiune=s.tip_gestiune and g.Cod_gestiune=s.gestiune
where c.Data=c.Data_lunii 
	and c.Data_lunii between (select min(Data_lunii) from istoricstocuri) and dateadd(day,-day(getdate()),dateadd(month,1,GETDATE())) where c.data_lunii between '01/01/2012' and '10/31/2012' group by c.data_lunii,isnull(g.Denumire_gestiune,g.gestiune)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         