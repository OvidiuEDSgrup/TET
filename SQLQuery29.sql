set transaction isolation level read uncommitted select rtrim('INCREMENT') as [NRCRT], rtrim(max(RTRIM(nomencl.cod)+'-'+LTRIM(nomencl.denumire))) as [DEN], rtrim((select max(comanda) from stocuri s where s.subunitate=max(pozdoc.subunitate) and s.cod_gestiune=max(pozdoc.gestiune) and cod=max(pozdoc.cod) and cod_intrare=max(pozdoc.cod_intrare))) as [LOT], rtrim(max(nomencl.um)) as [UM], rtrim(convert(char(10),convert(money,round(sum(pozdoc.cantitate),3)),1)) as [CANT], rtrim('') as [PRET], rtrim(max(pozdoc.discount)) as [DISC], rtrim(convert(char(20),convert(money,round(sum(pozdoc.cantitate*pozdoc.pret_valuta),2)),1)) as [VAL], rtrim(convert(char(19),convert(money,round(sum(pozdoc.cantitate*pozdoc.pret_valuta*pozdoc.cota_tva/100),2)),1)) as [TVA], rtrim(ISNULL((select ltrim(rtrim(max(cod_de_bare))) from codbare c where c.cod_produs= pozdoc.cod),'')) as [CODBARE], rtrim(rtrim(ltrim(max(left(pozcon.explicatii,40))))) as [EXPLPOZ], rtrim(rtrim(ltrim(max(con.explicatii)))) as [EXPLANTET] --into ##raspOVIDIU FROM pozdoc INNER JOIN yso.predariPacheteTmp pp ON pp.Subunitate=pozdoc.Subunitate AND pp.tip=pozdoc.tip AND pp.Numar=pozdoc.Numar AND pp.Data=pozdoc.Data and pp.numar_pozitie=pozdoc.numar_pozitie INNER JOIN avnefac ON avnefac.Terminal=pp.Terminal AND avnefac.Subunitate=pp.Subunitate AND avnefac.Tip=pp.tipaviz AND avnefac.Data=pp.DataAviz AND avnefac.Numar=pp.NumarAviz INNER JOIN nomencl ON nomencl.Cod=pozdoc.Cod LEFT JOIN con on con.Subunitate=pozdoc.Subunitate and con.Tip='BK' and con.Contract=pp.Contract and con.Tert=pp.Tert LEFT JOIN pozcon on pozcon.Subunitate=con.Subunitate and pozcon.Tip=con.Tip and pozcon.Contract=con.Contract and pozcon.Tert=pp.Tert and pozcon.Cod=pp.CodPachet LEFT JOIN lm on pozdoc.Loc_de_munca=lm.cod WHERE avnefac.tip in ('AP','AC') and avnefac.terminal='OVIDIU' GROUP BY pozdoc.barcod, pozdoc.cod, pozdoc.pret_vanzare, pozdoc.pret_valuta, avnefac.cod_gestiuneselect * from yso.predariPacheteTmp pp where pp.terminal='OVIDIU'