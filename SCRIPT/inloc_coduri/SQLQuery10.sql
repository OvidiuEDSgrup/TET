select *, -- update p set 
Explicatii=left('DIF. DE CONV.'+RTRIM(p.Valuta)+':'+RTRIM(p.Factura_dreapta)+' '+RTRIM(t.Denumire),50)
from pozadoc p join terti t on t.tert=p.tert where p.Tip='FF' and p.Data  between '2014-06-01' and '2014-06-30'
--alter table pozadoc alter column Explicatii varchar(500)
--pozincon