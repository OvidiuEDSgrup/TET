begin tran
declare @p2 xml
set @p2=convert(xml,N'<row tip="RE" data="11/06/2015" soldinitial="0" cont="5311.DJ" totalincasari="0" tert="" totalplati="0" efect="" totalsold="0"><row numar="" tert="RO26650988" dentert="INSTALTERMSUD SRL (CF/CNP: RO26650988)" factura="DJ940928" suma="1500" explicatii="" subtip="IB"/></row>')
exec wScriuPozplin @sesiune='6CB59B8F684F6',@parXML=@p2

--select A.TipAsociere,* from docfiscale d left join asocieredocfiscale a on d.id=a.id
--		where TipDoc='RE' and ISNULL(meniu,'')=ISNULL('PI_FILIALE','') and ISNULL(subtip,'')=ISNULL('IB','')
			--and a.tipasociere=''
rollback tran