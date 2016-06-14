insert webconfigform
select Meniu='CO',Tip=f.Tip,f.Subtip,f.Ordine,f.Nume,f.TipObiect,f.DataField,f.LabelField,f.Latime,f.Vizibil,f.Modificabil,f.ProcSQL,f.ListaValori,f.ListaEtichete,f.Initializare,f.Prompt,f.Procesare,f.Tooltip,f.formula,f.detalii
from webconfigform f left join webconfigform c on c.Meniu='CO' and c.Tip=f.Tip and c.Subtip=f.Subtip and c.DataField=f.DataField
 where f.Tip='BK' and f.Subtip='GT' and f.Meniu='KO' and c.DataField is null