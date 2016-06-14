select s.Cod_gestiune,SUM(s.Stoc) from stocuri s where s.stoc<0
group by s.Cod_gestiune
order by SUM(s.Stoc) 

select s.data_lunii,s.Cod_gestiune,SUM(s.Stoc) from istoricstocuri s where s.stoc<0
group by s.data_lunii,s.Cod_gestiune
order by s.data_lunii,SUM(s.Stoc) 