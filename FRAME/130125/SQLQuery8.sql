--insert tet..webconfigform
select * from webconfigform f where f.Meniu='CO' and f.Tip='BK' and f.Subtip='GT' and f.DataField='@numardoc'

select * --update tt set descriere=t.descriere
from webConfigTipuri t inner join tet..webConfigTipuri tt on tt.Meniu=t.Meniu and tt.Tip=t.Tip and t.Subtip=tt.Subtip
where t.Meniu='CO' and t.Tip='BK' and t.Subtip='GT' 
and tt.Descriere<>t.Descriere