--insert yso_DetTabInl 
SELECT     Tip, Numar_tabela, Camp_Magic, Camp_SQL, Conditie_de_inlocuire
FROM         testov..yso_DetTabInl AS d
WHERE     EXISTS
                          (insert yso_TabInl SELECT     Tip, Numar_tabela, Denumire_magic, Denumire_SQL, Camp1, Camp2, Inlocuiesc
                            FROM          testov..yso_TabInl AS t
                            WHERE      (Denumire_SQL IN ('docsters', 'proprietati', 'stoclim')) and tip=-1)
                            and tip=-1