execute as login='TET\magazin.is'
begin tran
declare @p2 xml
set @p2=convert(xml,N'<date><document aplicatie="PV" tip="PV" casamarcat="10" data="12/11/2013" inXML="0" UID="21E9CB5E-29EC-7EBE-6B41-E074C2CEAF57" categoriePret="1" tert="2620723224506" tipdoc="AC" numarDoc="1" pentruValidare="1" ora="0902" totaldocument="0.26" totalincasari="0.26" descarcarePrioritara="0"><pozitii><row contract="IS980035" data="12/11/2013" punctLivrare="" tert="2620723224506" explicatii="IS980035-CAPSUC DANIELA" cod="25003103" denumire="TRUST-Clema simpla D25, PPR" cantitate="1" um="BUC" pretcatalog="0.26" cotatva="24" discount="0" lm="1VZ_IS_00" gestiune="211.IS" pret="0.26" valoare="0.26" tipLinie="Produs" tip="21" o_pretcatalog="0.2600000000" valoarefaradiscount="0.26" tva="0.05" pretftva="0.21" valftva="0.21" observatii="1 BUC x 0.26" nrlinie="1"/><row denumire="Numerar" tipLinie="Incasare" tip="31" pret="0.26" cantitate="1" valoare="0.26" nrlinie="2"/></pozitii></document></date>')
exec wScriuDatePV @sesiune='',@parXML=@p2
SELECT * from antetBonuri a where a.IdAntetBon=3904
rollback tran
revert