select T.Fel,* from webConfigSTDTipuri t where t.Meniu='DO' AND isnull(T.Fel,'') NOT IN ('R')
AND t.ProcScriere<>'' and t.tasta='y'