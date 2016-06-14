declare @p2 xml
set @p2=convert(xml,N'<row aplicatie="PV" tip="PV" casamarcat="1" data="08/24/2012" inXML="0" UID="5531A4EA-64CE-6DF4-ED72-58A31AAF08B6" categoriePret="4" tert="1550829270616" comanda="9810302" cod="311530" cantitate="1"><tert cod="1550829270616" denumire="NECHITA IOAN" cod_fiscal="1550829270616" NrORC="NT508726" localitate="9625" judet="NT" adresa="STR.BUREBISTA , NR.7,BL.L4,SC.B,ET 2,AP.31" telefon_fax="0729/292416" banca="" cont_in_banca="" zileScad="0" categorie_pret="4" cautaCoduriNomencl="0" nrcomenzi="1"/></row>')
exec wUnCodNomenclator @sesiune='94C7BD3E3A7C1',@parXML=@p2
go
select * from preturi p where p.Cod_produs like '311530'
go
declare @p2 xml
set @p2=convert(xml,N'<row aplicatie="PV" tip="PV" casamarcat="1" data="08/24/2012" inXML="0" UID="5531A4EA-64CE-6DF4-ED72-58A31AAF08B6" categoriePret="4" tert="1550829270616" comanda="9810302" searchText=""/>')
exec wACNomenclatorPv @sesiune='94C7BD3E3A7C1',@parXML=@p2