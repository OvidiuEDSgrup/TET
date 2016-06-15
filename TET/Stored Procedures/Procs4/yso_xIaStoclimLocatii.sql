CREATE PROCEDURE yso_xIaStoclimLocatii as
select Tip_gestiune, Cod_gestiune, Cod, Locatie 
from stoclim where data='2999-12-31'