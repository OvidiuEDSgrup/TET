CREATE PROCEDURE yso_impIaIstoricStocuri AS

select --rtrim(Subunitate)+convert(varchar,Data_lunii,126)+rtrim(Tip_gestiune)+rtrim(Cod_gestiune)+rtrim(Cod)+rtrim(Cod_intrare) as _cheieunica
*
from istoricstocuri i
