select * from con where Contract='TESTEANT'
stocuri from gestiuni
select * from par where Denumire_parametru like '%IFO%'
select * from con where tip='BK'
select * from pozcon where Contract='25'
judete
select * from pozdoc where tip='te' and factura='25'
select * from con where Contract='21'
pozcontr
select * from stocuri where cod='0003003A'

exec sp_executesql N'SELECT Subunitate,Tip_gestiune,Cod_gestiune,Locatie,Contract,Lot,Data_expirarii,Cod,Data,Stoc,Cod_intrare,Pret,Cont,TVA_neexigibil,Pret_cu_amanuntul FROM TET..stocuri 
WHERE Subunitate = @P1 AND Contract = @P2 AND Cod = @P3 AND Data < DATEADD (day, 1, @P4) AND Stoc >= @P5 AND (Tip_gestiune not in (''F'', ''T'')) 
ORDER BY Subunitate ASC ,Tip_gestiune ASC ,Cod_gestiune ASC ,Cod ASC ,Data ASC ,Cod_intrare ASC '
,N'@P1 char(9),@P2 char(20),@P3 char(20),@P4 datetime,@P5 float'
,'1        ','21                  ','0003003A            ','2012-01-31 00:00:00',0.001
--orice gest dar cu contract completat

exec sp_executesql N'SELECT Subunitate,Tip_gestiune,Cod_gestiune,Locatie,Contract,Lot,Data_expirarii,Cod,Data,Stoc,Cod_intrare,Pret,Cont,TVA_neexigibil,Pret_cu_amanuntul FROM TET..stocuri 
WHERE Subunitate = @P1 AND Tip_gestiune = @P2 AND Cod_gestiune = @P3 AND Contract = @P4 AND Cod = @P5 
AND Data < DATEADD (day, 1, @P6) AND Stoc >= @P7    AND (Tip_gestiune not in (''F'', ''T'')) 
ORDER BY Subunitate ASC ,Tip_gestiune ASC ,Cod_gestiune ASC ,Cod ASC ,Data ASC ,Cod_intrare ASC '
,N'@P1 char(9),@P2 char(1),@P3 char(20),@P4 char(20),@P5 char(20),@P6 datetime,@P7 float'
,'1        ','C','300                 ','                    ','0003003A            ','2012-01-31 00:00:00',0.001
--gestiunea de pe bk dar fara contract completat

exec sp_executesql N'SELECT Subunitate,Tip_gestiune,Cod_gestiune,Locatie,Contract,Lot,Data_expirarii,Cod,Data,Stoc,Cod_intrare,Pret,Cont,TVA_neexigibil,Pret_cu_amanuntul FROM TET..stocuri WHERE Subunitate = @P1 AND Tip_gestiune = @P2 AND Cod_gestiune = @P3 AND Contract = @P4 AND Cod = @P5 AND Data < DATEADD (day, 1, @P6) AND Stoc >= @P7    AND (Tip_gestiune not in (''F'', ''T'')) ORDER BY Subunitate ASC ,Tip_gestiune ASC ,Cod_gestiune ASC ,Cod ASC ,Data ASC ,Cod_intrare ASC ',N'@P1 char(9),@P2 char(1),@P3 char(20),@P4 char(20),@P5 char(20),@P6 datetime,@P7 float'
,'1        ','C','300                 ','21                  ','0003003A            ','2012-01-31 00:00:00',0.001
--gestiunea de pe bk dar cu contract completat

exec sp_executesql N'SELECT Subunitate,Tip_gestiune,Cod_gestiune,Locatie,Contract,Lot,Data_expirarii,Cod,Data,Stoc,Cod_intrare,Pret,Cont,TVA_neexigibil,Pret_cu_amanuntul FROM TET..stocuri WHERE Subunitate = @P1 AND Tip_gestiune = @P2 AND Cod_gestiune = @P3 AND Contract = @P4 AND Cod = @P5 AND Data < DATEADD (day, 1, @P6) AND Stoc >= @P7    AND (Tip_gestiune not in (''F'', ''T'')) ORDER BY Subunitate ASC ,Tip_gestiune ASC ,Cod_gestiune ASC ,Cod ASC ,Data ASC ,Cod_intrare ASC ',N'@P1 char(9),@P2 char(1),@P3 char(20),@P4 char(20),@P5 char(20),@P6 datetime,@P7 float'
,'1        ','A','211                 ','21                  ','0003003A            ','2012-01-31 00:00:00',0.001
--gest a 2a rezervari 

exec sp_executesql N'SELECT Subunitate,Tip_gestiune,Cod_gestiune,Locatie,Contract,Lot,Data_expirarii,Cod,Data,Stoc,Cod_intrare,Pret,Cont,TVA_neexigibil,Pret_cu_amanuntul FROM TET..stocuri WHERE Subunitate = @P1 AND Tip_gestiune = @P2 AND Cod_gestiune = @P3 AND Contract = @P4 AND Cod = @P5 AND Data < DATEADD (day, 1, @P6) AND Stoc >= @P7    AND (Tip_gestiune not in (''F'', ''T'')) ORDER BY Subunitate ASC ,Tip_gestiune ASC ,Cod_gestiune ASC ,Cod ASC ,Data ASC ,Cod_intrare ASC ',N'@P1 char(9),@P2 char(1),@P3 char(20),@P4 char(20),@P5 char(20),@P6 datetime,@P7 float'
,'1        ','C','300                 ','21                  ','0003003A            ','2012-01-31 00:00:00',0.001
--gestiunea 1 rezervari