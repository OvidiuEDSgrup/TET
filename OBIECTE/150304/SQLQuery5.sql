begin tran
declare @p2 xml
set @p2=convert(xml,N'<parametri idContract="64" tip="RN" numar="GL910003" data="03/02/2015" gestiune="211.GL" dengestiune="GL SHOWROOM  GALATI" lm="1VZ_GL_00" denlm="GALATI SHOW-ROOM" denvaluta="RON" explicatii="" pozitii="3" stare="1" culoare="" denstare="Introdus" valoare="1521.20" valoareRON="1521.20" valoarecutva="1886.29" o_numar="GL910003" o_stare="0" update="1" explicatii_jurnal="" tipMacheta="D" codMeniu="RN" TipDetaliere="RN" subtip="SS"/>')
exec wOPSchimbareStareContractSP @sesiune='6FD54E1817E66',@parXML=@p2
rollback tran