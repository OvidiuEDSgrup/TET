SELECT *
from dbo.wfIaTipuriDocumente(NULL) t where isnull(subtip,'')='' 
AND T.meniu='PI' and t.tip='RE'