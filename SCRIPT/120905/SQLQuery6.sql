insert romfulda..webConfigForm
Select * from webConfigSTDForm f where f.Meniu='KO' and f.Nume like '%contr%' and f.Tip='BK' and f.DataField='@contractcor'
INSERT romfulda..webConfigMeniu
select * from webConfigMeniu m where m.Meniu='KO'