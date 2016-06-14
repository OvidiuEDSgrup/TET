select * from webConfigSTDMeniu m where m.Nume like '%plaj%'
select * from webConfigSTDTipuri t where t.Meniu='pj' and t.Tip='DF'  and ISNULL(t.Subtip,'')='' and ISNULL(t.Fel,'')=''