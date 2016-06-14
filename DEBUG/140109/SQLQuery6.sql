declare @p2 xml
set @p2=convert(xml,N'<row numar="" data="01/09/2014" tert="2620723224506" dentert="CAPSUC DANIELA (CF/CNP: 2620723224506)" explicatii="" gestiune="211.BV" dengestiune="BV SHOWROOM BRASOV" lm="1VZ_BV_02" denlm="BRASOV2" gestprim="" contractcor="" info5="0" termen="01/09/2014" denstare="" comanda="" tip="BK"><row cod="537D3020" codfarastoc="0" cantitate="1" pret="0" discount="" explicatii="0" termen="01/09/2014" subtip="BK"/></row>')
exec wScriuPozCon @sesiune='F99849E354E72',@parXML=@p2

--select * from con c where c.Tert='2620723224506' order by Contract desc