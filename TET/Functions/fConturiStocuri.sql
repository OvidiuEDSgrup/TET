--***
create FUNCTION dbo.fConturiStocuri()
RETURNS VARCHAR(MAX) AS BEGIN
DECLARE @p VARCHAR(MAX) ;
           SET @p = '' ;
        SELECT @p = @p + rtrim(Cont)+ ','
          FROM conturi
         WHERE Sold_credit=3
RETURN @p
END
