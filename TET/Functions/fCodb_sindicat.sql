--***
/**	functie fCodb_sindicat	*/
Create function fCodb_sindicat(@marca char(6), @data datetime)
returns varchar(13)
as
begin
	declare @Codb_sindicat varchar(13), @pCodb_sindicat varchar(13)
	Set @pCodb_sindicat=dbo.iauParA('PS','SIND%')

	Select @Codb_sindicat=isnull((select top 1 val_inf from extinfop where marca=@marca 
		and cod_inf='SINDICAT' and Val_inf<>'' and data_inf<=@data order by data_inf desc),@pCodb_sindicat)

	return @Codb_sindicat
end
