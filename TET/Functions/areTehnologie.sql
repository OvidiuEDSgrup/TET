create function [dbo].[areTehnologie](@codMaterial varchar(50))
returns int
as
begin
	if (select COUNT(1) from nomencl where cod=@codMaterial and tip='P' ) > 0
		if (select COUNT(1) from tehnologii where codNomencl=@codMaterial)>0
			return (select id from pozTehnologii where tip='T' and idp is null and 
					cod=(select top 1 cod from tehnologii where codNomencl=@codMaterial))
	return -1
end
