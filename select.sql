SELECT '!$MG_NUME$!' as C001
, max(rtrim(gestiuni.cod_gestiune)+' '+rtrim(gestiuni.denumire_gestiune)) as C002
, max(convert(CHAR(10),pozdoc.data,103)) as C003
, max(rtrim(gestiuni.cod_gestiune)+' '+rtrim(gestiuni.denumire_gestiune)) as C004
, convert(char(20),convert(money,round(sum(pozdoc.cantitate*pozdoc.pret_valuta),2)),1) as C005, max(nomencl.um) as C006, convert(char(19),convert(money,round(sum(pozdoc.cantitate*pozdoc.pret_valuta*pozdoc.cota_tva/100),2)),1) as C007, '' as C008, 'INCREMENT' as C009, (select max(comanda) from stocuri s where s.subunitate=max(pozdoc.subunitate) and s.cod_gestiune=max(pozdoc.gestiune) and cod=max(pozdoc.cod) and cod_intrare=max(pozdoc.cod_intrare)) as C010, rtrim(ltrim(max(left(pozcon.explicatii,40)))) as C011, max(pozdoc.discount) as C012, max(RTRIM(nomencl.cod)+'-'+LTRIM(nomencl.denumire)) as C013, ISNULL((select ltrim(rtrim(max(cod_de_bare))) from codbare c where c.cod_produs= pozdoc.cod),max(pozdoc.barcod)) as C014, convert(char(10),convert(money,round(sum(pozdoc.cantitate),3)),1) as C015, rtrim(ltrim(max(con.explicatii))) as C016, '' as C017, 'FORMXML(AVIZ-Tran)' as C018,'' AS C019,'' AS C020,'' AS C021,'' AS C022,'' AS C023,'' AS C024,'' AS C025,'' AS C026,'' AS C027,'' AS C028,'' AS C029,'' AS C030,'' AS C031,'' AS C032,'' AS C033,'' AS C034,'' AS C035,'' AS C036,'' AS C037,'' AS C038,'' AS C039,'' AS C040,'' AS C041,'' AS C042,'' AS C043,'' AS C044,'' AS C045,'' AS C046,'' AS C047,'' AS C048,'' AS C049,'' AS C050,'' AS C051,'' AS C052,'' AS C053,'' AS C054,'' AS C055,'' AS C056,'' AS C057,'' AS C058,'' AS C059,'' AS C060,'' AS C061,'' AS C062,'' AS C063,'' AS C064,'' AS C065,'' AS C066,'' AS C067,'' AS C068,'' AS C069,'' AS C070,'' AS C071,'' AS C072,'' AS C073,'' AS C074,'' AS C075,'' AS C076,'' AS C077,'' AS C078,'' AS C079,'' AS C080,'' AS C081,'' AS C082,'' AS C083,'' AS C084,'' AS C085,'' AS C086,'' AS C087,'' AS C088,'' AS C089,'' AS C090,'' AS C091,'' AS C092,'' AS C093,'' AS C094,'' AS C095,'' AS C096,'' AS C097,'' AS C098,'' AS C099,'' AS C100 
FROM pozdoc 
INNER JOIN yso.predariPacheteTmp pp ON pp.Subunitate=pozdoc.Subunitate AND pp.tip=pozdoc.tip AND pp.Numar=pozdoc.Numar AND pp.Data=pozdoc.Data and pp.numar_pozitie=pozdoc.numar_pozitie 
INNER JOIN avnefac ON avnefac.Terminal=pp.Terminal AND avnefac.Subunitate=pp.Subunitate AND avnefac.tip=pp.TipAviz AND avnefac.Data=pp.DataAviz AND avnefac.Numar=pp.NumarAviz 
INNER JOIN nomencl ON nomencl.Cod=pozdoc.Cod 
LEFT JOIN con on con.Subunitate=pozdoc.Subunitate and con.Tip='BK' and con.Contract=pp.Contract 
LEFT JOIN pozcon on pozcon.Subunitate=con.Subunitate and pozcon.Tip=con.Tip and pozcon.Contract=con.Contract and pozcon.Cod=pp.CodPachet 
LEFT JOIN lm on pozdoc.Loc_de_munca=lm.cod 
LEFT JOIN gestiuni on gestiuni.cod_gestiune=pozdoc.Gestiune_primitoare 
WHERE avnefac.tip='TE' AND AVNEFAC.TERMINAL='6824' GROUP BY pozdoc.barcod, pozdoc.cod, pozdoc.pret_vanzare, pozdoc.pret_valuta, avnefac.cod_gestiune

SELECT * from avnefac a where a.Terminal='6824'

select * from yso.predariPacheteTmp pp where pp.Terminal='6824'

select * from pozdoc p where p.Tip='TE' and p.Numar='4296'