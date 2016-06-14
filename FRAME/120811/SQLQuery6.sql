insert webConfigForm
select * from webConfigSTDForm f where f.Nume like '%contr%' 
and f.TipMacheta='D' and f.Tip='BK' and f.Subtip is null
order by f.Nume

select * from webConfigSTDTipuri t where t.Tip='BK'