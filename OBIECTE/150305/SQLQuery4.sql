begin tran

--declare @p2 xml
--set @p2=convert(xml,N'<parametri idContract="52" tip="RN" numar="BN910003" data="02/25/2015" gestiune="211.BN" dengestiune="BN SHOWROOM BISTRITA NASAUD" lm="1VZ_BN_00" denlm="BISTRITA NASAUD SHOW-ROOM" denvaluta="RON" explicatii="Salauta SRL" pozitii="1" stare="-15" culoare="" denstare="Introdus" valoare="184.00" valoareRON="184.00" valoarecutva="228.16" o_numar="BN910003" update="1" tipMacheta="D" codMeniu="RN" TipDetaliere="RN" subtip="DR"/>')
--exec wOPDefinitivareContractSP @sesiune='294693812F570',@parXML=@p2

exec sp_executesql N'DELETE FROM TET ..necesaraprov WHERE Numar = @P1 AND Data = @P2 AND Numar_pozitie = @P3',N'@P1 char(8),@P2 datetime,@P3 int','BN910003','2015-02-25 00:00:00',155

/*
exec sp_executesql N'INSERT INTO TET ..tmpSelectie (Terminal , Cod , Selectie ) VALUES ( @P1 , @P2, @P3) ',N'@P1 char(4),@P2 char(27),@P3 bit','6316','BN91000302/25/2015      155',1
update necesaraprov
set stare='1'
from necesaraprov n, tmpselectie t
where t.terminal='6316    ' and t.cod=n.numar+convert(char(10), n.data, 101)+str(n.numar_pozitie, 9)
and t.selectie=1 and n.stare='0'
--*/

SELECT * from PozContracte p join Contracte c on c.idContract=p.idContract
where c.numar='BN910003'

rollback tran