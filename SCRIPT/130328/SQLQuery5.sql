SELECT rtrim(max(con.valuta)) as 
C001, (select val_alfanumerica as 
nume from par where tip_parametru='GE' and parametru='NUME') as 
C002, max(terti.denumire) as 
C003, (Select max(gestiuni.denumire_gestiune) from gestiuni where gestiuni.cod_gestiune=max(con.gestiune)) as 
C004, (select val_alfanumerica from par where tip_parametru = 'GE' and parametru = 'ORDREG') as 
C005, ltrim(max(con.contract)) as 
C006, max(terti.localitate) as 
C007, max(terti.judet) as 
C008, max(convert(char(12),con.data,104)) as 
C009, ltrim(rtrim(CASE max(p.valuta) WHEN '' THEN '' ELSE convert(char(16),convert(money,MAX(CON.CURS))) END)) as 
C010, (select val_alfanumerica as 
cif from par where tip_parametru = 'GE' and parametru = 'CODFISC') as 
C011, max(terti.cont_in_banca) as 
C012, (select val_alfanumerica from par where tip_parametru='GE' and parametru = 'CONTBC') as 
C013, ltrim(max(con.contract)) as 
C014, max(terti.cod_fiscal) as 
C015, max(terti.banca) as 
C016, (select val_alfanumerica from par where tip_parametru='GE' and parametru = 'BANCA') as 
C017, max(terti.adresa) as 
C018, (select val_alfanumerica from par where tip_parametru='GE' and parametru = 'ADRESA') as 
C019, max(nomencl.um) as 
C020, left(convert(char(16),convert(money,round(max(p.Suma_TVA),2)),2),15) as 
C021, convert(char(15),convert(money,max(p.valcudisc)),1) as 
C022, left(convert(char(16),convert(money,round(max(p.pret*(1-p.Discount/100.00)),2)),2),15) as 
C023, left(convert(char(16),convert(money,round(max(p.pret*(1-p.Discount/100.00)*(1-p.DiscDoi/100.00)),2)),2),15) as 
C024, left(convert(char(16),convert(money,round(max(convert(decimal(17,5),p.pret)),2)),2),15) as 
C025, convert(char(15),convert(money,max(p.pretdisc)),1) as 
C026, convert(char(15),convert(money,max(p.valdisc)),1) as 
C027, left(convert(char(16),convert(money,round(max(p.discount),2)),2),15) as 
C028, max(nomencl.denumire) as 
C029, (case when max(p.tip)='FC' and exists (select codfurn from ppreturi where p.cod=ppreturi.cod_resursa and max(p.tert)=ppreturi.tert) then (select codfurn from ppreturi where p.cod=ppreturi.cod_resursa and max(p.tert)=ppreturi.tert) else p.cod end) as 
C030, left(convert(char(16),convert(money,round(sum(p.cantitate),2)),2),15) as 
C031, convert(char(15),convert(money,sum(sum(p.valtva)) over(partition by p.contract)),1) as 
C032, convert(char(15),convert(money,sum(sum(p.valfrtva)) over(partition by p.contract)),1) as 
C033, convert(char(15),convert(money,sum(sum(p.valcutva)) over(partition by p.contract)),1) as 
C034, (select rtrim(Max(valoare)) from proprietati where TIP='UTILIZATOR' and cod_proprietate='EMAIL' and cod= max(p.utilizator)) as 
C035, convert(char(15),convert(money,sum(sum(p.valdisc)) over(partition by p.contract)),1) as 
C036, (select Max(Nume) from utilizatori where ID= max(p.utilizator)) as 
C037, convert(char(15)
,convert(money,sum(sum(round(p.valcudisc*(con.val_reziduala/100),2))) over(partition by p.contract)),1) as C038
,'' AS C039,'' AS C040,'' AS C041,'' AS C042,'' AS C043,'' AS C044,'' AS C045,'' AS C046,'' AS C047,'' AS C048,'' AS C049,'' AS C050,'' AS C051,'' AS C052,'' AS C053,'' AS C054,'' AS C055,'' AS C056,'' AS C057,'' AS C058,'' AS C059,'' AS C060,'' AS C061,'' AS C062,'' AS C063,'' AS C064,'' AS C065,'' AS C066,'' AS C067,'' AS C068,'' AS C069,'' AS C070,'' AS C071,'' AS C072,'' AS C073,'' AS C074,'' AS C075,'' AS C076,'' AS C077,'' AS C078,'' AS C079,'' AS C080,'' AS C081,'' AS C082,'' AS C083,'' AS C084,'' AS C085,'' AS C086,'' AS C087,'' AS C088,'' AS C089,'' AS C090,'' AS C091,'' AS C092,'' AS C093,'' AS C094,'' AS C095,'' AS C096,'' AS C097,'' AS C098,'' AS C099,'' AS C100 
FROM avnefac 
JOIN con ON avnefac.subunitate=con.subunitate and avnefac.tip=con.tip and avnefac.contractul=con.contract and avnefac.cod_tert=con.tert and avnefac.data=con.data 
JOIN yso.pozconexp p ON p.subunitate=con.subunitate and p.tip=con.tip and p.contract=con.contract and p.data=con.data and p.tert=con.tert 
LEFT JOIN terti ON terti.subunitate=con.subunitate and terti.tert=con.tert 
LEFT JOIN nomencl ON nomencl.cod=p.cod 
WHERE p.Listare='' AND AVNEFAC.TERMINAL='6028' 
GROUP BY avnefac.tip, avnefac.numar, avnefac.data, p.cod,con.loc_de_munca, P.TERT, TERTI.TERT, p.CONTRACT