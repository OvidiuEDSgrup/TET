create function [dbo].[iauUtilizatorCurent]()
returns char(10)
as begin

declare @Utilizator char(10)
if exists (select 1 from sysobjects where name='sysunic') 
	select top 1 @Utilizator=utilizator from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc

if @Utilizator is null and exists (select 1 from sysobjects where name='utilizatori')
	select @Utilizator=id from utilizatori where observatii=SUSER_name()
	
if @Utilizator is null 
	set @Utilizator=''

return @Utilizator
end
