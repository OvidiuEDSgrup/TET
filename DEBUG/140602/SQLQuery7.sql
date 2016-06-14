declare @p2 xml
set @p2=convert(xml,N'<parametri idantetbon="5309" stergere="1" generare="0"/>')
use TESTOV
exec wOPRefacACTE '','<parametri idantetbon="5309" stergere="1" generare="0"/>'
exec wDescarcBon '','<row idAntetBon="5309"/>'
exec raportGestiune '2014-05-27','2014-05-27','210.NT','A','0'
 NT10002 	Valoare v.5601.31 disc. 622.21
  exec raportGestiune '2014-05-27','2014-05-27','210.IS','A','0'