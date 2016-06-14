--/*
select *
--*/update g set formula='Math.round((Number(1)*Number(2))+Number(3))' 
--'Math.round((Number(row.@pvanzare)*Number(row.@cantitate))+Number(row.@sumatva))' 
from webConfigGrid g where 
g.Meniu='DO' and g.InPozitii=1 and g.Tip='AP'  and g.DataField like '@test'
--g.formula is not null
--Math.round((Number(row.@pvanzare)*Number(row.@cantitate))-Number(row.@sumatva))

--/*
select *
--*/update f set formula='Math.round((Number(row.@pvanzare)*Number(row.@cantitate))+Number(row.@sumatva))'  
--'Math.round((Number(row.@pvanzare)*Number(row.@cantitate))+Number(row.@sumatva))' 
from webConfigstdForm f where 
f.Meniu='DO' and F.Tip='AP' and isnull(f.Subtip,'')='' --and f.DataField like '@detalii%' and f.Subtip='AP' 