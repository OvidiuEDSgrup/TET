 --update m set id=100392 from webConfigMeniu m where m.id=392 and m.idParinte=1
 SELECT * from webConfigSTDGrid g where g.Meniu='DO' and g.Tip='AP' --and g.Subtip='AP'
 and g.InPozitii=1 and g.Subtip is null
 and g.NumeCol like '%val%'
 order by g.Ordine
 
 SELECT * from webConfigGrid g where g.Meniu='DO' and g.Tip='AP' --and g.Subtip='AP'
 and g.InPozitii=0 and g.Subtip is null
 and g.NumeCol like '%val%'
 order by g.Ordine
 
 select * from webConfigSTDForm f where f.Meniu='do' and f.Tip='AP' and f.Nume like '%val%'