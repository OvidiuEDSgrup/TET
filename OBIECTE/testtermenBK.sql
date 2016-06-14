DECLARE @Subunitate CHAR(9), @Tip CHAR(2), @Contract CHAR(20), @Tert CHAR(13), @Data DATETIME
SET @Subunitate='1'
SET @Tip='BK'
SET @Contract='52'
SET @Tert='12267509'
SET @Data='12/20/2011'

EXEC yso.CalculTermeneBK @Subunitate, @Tip, @Contract, @Tert, @Data
--SELECT * FROM stocuri s where s.Cod_gestiune='101' and cod='0003000'