--insert webConfigForm
select
IdUtilizator,TipMacheta,Meniu,'TE',Subtip,Ordine,Nume,TipObiect,DataField,LabelField,Latime,Vizibil,Modificabil,ProcSQL,ListaValori
,ListaEtichete,Initializare,Prompt,Procesare,Tooltip 
from webConfigForm f where f.TipMacheta='D' and f.Meniu='DO' and f.Tip='AP' and ISNULL(f.Subtip,'')='' 
and (f.Nume like '%val%' or f.Nume like '%TVA%' COLLATE Latin1_General_BIN)

select * from webConfigForm f where f.TipMacheta='D' and f.Meniu='DO' and f.Tip='TE' and ISNULL(f.Subtip,'')='' 
and (f.Nume like '%val%' or f.Nume like '%tva%')