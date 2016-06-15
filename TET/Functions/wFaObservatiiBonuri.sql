--***
/* returneaza lista de bonuri pentru facturi din bonuri, concatenata cu observatiile introduse de vanzator */
CREATE FUNCTION wFaObservatiiBonuri (@factura varchar(50),@data datetime)
RETURNS VarChar(8000)
AS
BEGIN
	Declare @buffer VarChar(8000), @obs varchar(500)
	Select   @buffer = IsNull(@buffer + ', ', '') + 'nr '+ convert(varchar,numar_bon )+' din '+convert(varchar,data_bon,104)
				From    antetBonuri
				Where factura = @factura and data_facturii=@data and chitanta=1
	select @obs = isnull(( select max(observatii) from antetBonuri where factura=@factura and data_facturii=@data and chitanta=0 ),'')
	set @buffer = rtrim(@obs) + isnull(' Achitat cu bon fiscal '+@buffer,'')
	RETURN isnull(@buffer,'')
END

