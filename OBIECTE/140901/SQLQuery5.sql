--insert gestiuni (Subunitate,Tip_gestiune,Cod_gestiune,Denumire_gestiune,Cont_contabil_specific,detalii)
select 
Subunitate,Tip_gestiune,replace(Cod_gestiune,'21','71')
,replace(Denumire_gestiune,'BON FISCAL','BON FISCAL INSTALATORI',Cont_contabil_specific,detalii
from gestiuni g where g.Cod_gestiune like '210%'
--AG BON FISCAL PITESTI                      