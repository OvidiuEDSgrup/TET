insert webConfigTaburi 
select *
from testov..webConfigTaburi where MeniuSursa='CO' and ('BK'='' or isnull(TipSursa,'')='BK')