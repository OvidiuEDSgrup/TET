select *
from bt 
where bt.Cod_produs like 'RJ-DFF12'

select *
from bp
where bp.Cod_produs like 'RJ-DFF12'

declare @parxml xml
set @parxml=CONVERT(xml,'<row gestiune="211.1" dinRefaceri="1" datajos="05/21/2012" datasus="05/21/2012"/>')
EXEC wdescarcbon 'C2CB88ADB3DE5',@parxml

exec wMutBTBP  1,'MAGAZIN_NT','2012-05-21',2,18,null,null,null,null,0