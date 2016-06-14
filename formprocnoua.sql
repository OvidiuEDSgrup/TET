select * 
-- delete f
from webConfigForm f where f.TipMacheta='D' and f.Meniu='CO' AND F.Tip='BK' AND F.Subtip='MA'
-- insert webConfigForm
select * from webConfigstdForm f where f.TipMacheta='D' and f.Meniu='CO' AND F.Tip='BF' AND F.Subtip='MA'

-- insert webConfigForm
select IdUtilizator, TipMacheta, Meniu, 'BK', Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL
, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip 
from webConfigForm f where f.TipMacheta='D' and f.Meniu='CO' AND F.Tip='BF' AND F.Subtip='MA'

 --insert webConfigTipuri
select IdUtilizator, TipMacheta, Meniu, 'BK', Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere
, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare
from webConfigTipuri f where f.TipMacheta='D' and f.Meniu='CO' AND F.Tip='BK' AND F.Subtip='MA'