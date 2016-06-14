select * -- update i set e_mail=i.Cont_in_banca3, Cont_in_banca3=observatii
from infotert i where i.Identificator='' --and i.e_mail<>'' and i.e_mail not like '%@%'
and i.Cont_in_banca3 like '%@%' --and i.e_mail<>''