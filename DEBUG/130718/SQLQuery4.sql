exec sp_executesql N'SELECT Subunitate,Tip_gestiune,Cod_gestiune,Locatie,Contract,Lot,Data_expirarii,Cod,Data,Stoc,Cod_intrare,Pret,Cont,TVA_neexigibil,Pret_cu_amanuntul 
FROM TESTOV ..stocuri WHERE Subunitate = @P1 AND Contract = @P2 AND Cod = @P3 AND Stoc >= @P4    AND (Tip_gestiune not in (''F'', ''T'')) 
ORDER BY Subunitate ASC ,Tip_gestiune ASC ,Cod_gestiune ASC ,Cod ASC ,Data ASC ,Cod_intrare ASC '
,N'@P1 char(9),@P2 char(20),@P3 char(20),@P4 float'
,'1        ','13390               ','4300102006021       ',0.001

exec sp_executesql N'SELECT Subunitate,Tip_gestiune,Cod_gestiune,Locatie,Contract,Lot,Data_expirarii,Cod,Data,Stoc,Cod_intrare,Pret,Cont,TVA_neexigibil,Pret_cu_amanuntul 
FROM TESTOV ..stocuri WHERE Subunitate = @P1 AND Tip_gestiune = @P2 AND Cod_gestiune = @P3 AND Cod = @P5 AND Stoc >= @P6    AND (Tip_gestiune not in (''F'', ''T'')) ORDER BY Subunitate ASC ,Tip_gestiune ASC ,Cod_gestiune ASC ,Cod ASC ,Data ASC ,Cod_intrare ASC '
,N'@P1 char(9),@P2 char(1),@P3 char(20),@P4 char(20),@P5 char(20),@P6 float'
,'1        ','C','101                 ','                    ','4300102006021       ',0.001

select isnull(nullif(p.Contract,''),p.Factura),p.Gestiune_primitoare,* from pozdoc p where 
'101' in (p.Gestiune,p.Gestiune_primitoare)
and '4300102006021'=p.Cod
and 'IMPL1' in (p.Cod_intrare,p.Grupa)
and '1031574' in (p.Contract,p.Factura)
order by p.Data, p.Tip_miscare desc

select p.Contract,* from istoricstocuri p where 
'101' in (p.Cod_gestiune)
and '4300102006021'=p.Cod
and 'IMPL1' in (p.Cod_intrare)
order by p.Data 

select p.Gestiune_primitoare,p.Contract,* from pozdoc p where '1031574             ' in (p.Contract,p.Factura) and '101' in (p.Gestiune,p.Gestiune_primitoare)
and '4300102006021'=p.Cod
order by p.Data, p.Tip_miscare desc