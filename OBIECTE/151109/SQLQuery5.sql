select * -- update f set meniu='FILIALE_'+ltrim(rtrim(meniu))
from WebConfigFormulare f where f.meniu in ('DO','PI','AD','CO','BO','N','T','O')

select * -- update f set meniu='FILIALE_'+ltrim(rtrim(meniu))
from docfiscale f where f.meniu in ('DO','PI','AD','CO','BO','N','T','O')

select * -- update f set meniusursa='FILIALE_'+ltrim(rtrim(meniusursa))
from webConfigTaburi f where f.MeniuSursa in ('DO','PI','AD','CO','BO','N','T','O')

select * -- update f set MeniuNou='FILIALE_'+ltrim(rtrim(MeniuNou))
from webConfigTaburi f where f.MeniuNou in ('DO','PI','AD','CO','BO','N','T','O')