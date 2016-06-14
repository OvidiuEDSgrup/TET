BEGIN TRAN
declare @p2 xml
set @p2=convert(xml,N'<parametri cod="537DZ033" denumire="ACVS-Electrod Prestige 24-32" gestiune="101" gestiune_primitoare="211.SV" cantitate="1.00" explicatii="211.SV                                  0000/00/00" idContractCorespondent="1351" idPozContractCorespondent="541937" idContract="-63744" idPozContract="-442175" o_gestiune="101" o_gestiune_primitoare="211.SV" o_explicatii="211.SV                                  0000/00/00" update="1" data="05/10/2016" dengestiune="101" dengestiune_primitoare="211.SV" tip="FA" tipMacheta="D" codMeniu="YSO_FA" TipDetaliere="FA" subtip="GT"><o_DateGrid><row idContract="1351" idPozContract="541937" gestiune="101" cod="537DZ033" denumire="ACVS-Electrod Prestige 24-32" cantitate="1.000" in_curs="0.000" rezervat="0.000" stoc="1.000" detransferat="1.000"/></o_DateGrid><DateGrid><row idContract="1351" idPozContract="541937" gestiune="101" cod="537DZ033" denumire="ACVS-Electrod Prestige 24-32" cantitate="1.000" in_curs="0.000" rezervat="0.000" stoc="1.000" detransferat="1.000"/></DateGrid></parametri>')
exec wOPGenerareTransfer @sesiune='40C4724B9A0D6',@parXML=@p2

select top (10) * 
from pozdoc p join LegaturiContracte l on l.idPozDoc=p.idPozDoc join PozContracte pt on pt.idPozContract=l.idPozContract join Contracte c on c.idContract=pt.idContract
where p.Subunitate='1' and p.Tip='TE' and p.Cantitate=1
order by p.idPozDoc desc

IF @@TRANCOUNT>0
	ROLLBACK TRAN