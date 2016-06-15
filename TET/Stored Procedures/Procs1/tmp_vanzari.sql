create procedure tmp_vanzari as
SELECT     Data, Cod, Tert, Gestiune, LEFT(Loc_de_munca, 6) AS judet, Loc_de_munca AS agent, Cantitate, Cantitate * Pret_vanzare AS 'ValFTVA', 
                      Cantitate * (Pret_vanzare - Pret_de_stoc) AS 'Marja'
FROM         dbo.pozdoc AS p
WHERE     (Tip IN ('AP', 'AS', 'AC'))