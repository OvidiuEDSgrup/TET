select * from webConfigForm f where f.Meniu='PJ'
select * from webConfigSTDTipuri t where t.Meniu='PJ'
select * from webConfigSTDForm f where f.Meniu='PJ' AND f.Tip='AS'

select * from webConfigSTDTipuri t where isnull(T.procPopulare,'')<>'' and ISNULL(t.Subtip,'')=''