create view tstoc as
select stocuri.tip_gestiune,gestiuni.denumire_gestiune,nomencl.grupa,nomencl.denumire,stocuri.data,
stocuri.stoc_initial,stocuri.intrari,stocuri.iesiri,stocuri.stoc,stocuri.stoc*stocuri.pret as 'ValStoc',
isnull((select max(pret_vanzare) from preturi where cod_produs=stocuri.cod and year(data_superioara)=2999 and tip_pret=1 and um='1'),nomencl.pret_vanzare) as 'Pret1', 
isnull((select max(pret_vanzare) from preturi where cod_produs=stocuri.cod and year(data_superioara)=2999 and tip_pret=1 and um='2'),nomencl.pret_vanzare) as 'Pret2' 
from stocuri,nomencl,gestiuni where 
stocuri.cod=nomencl.cod and stocuri.cod_gestiune=gestiuni.cod_gestiune 
and stocuri.stoc<>0
