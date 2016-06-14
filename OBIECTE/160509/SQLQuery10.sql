declare @p2 xml
set @p2=convert(xml,N'<row cod="537DZ033" denumire="ACVS-Electrod Prestige 24-32" cantitate="1.00" explicatii="211.SV                                  0000/00/00" idContractCorespondent="1351" idPozContractCorespondent="541937" idContract="-63744" idPozContract="-442175" tipMacheta="D" codMeniu="YSO_FA" tip="FA" TipDetaliere="FA" subtip="GT"/>')
exec wOPGenerareTransferFundamenteComanda_p @sesiune='7FC598934F8B5',@parXML=@p2
--select @p2