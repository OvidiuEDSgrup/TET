--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori ) - aduce semnificatile in dreptul fiecarui
indicator: cele care vor fi reprezentate vizual in cazul graficului Gauge */

CREATE procedure  wIaSemnificatiiIndicator  @sesiune varchar(50), @parXML XML
as
declare @cod varchar(15), @max int, @min int

select @cod = rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(15)'), ''))
/* set @max = (select max(val_max) from semnific where indicator=@cod)
 set @min = (select MIN(val_max) from semnific where indicator=@cod)
*/

select convert(int,isnull((select top 1 isnull(smin.Val_max+1,0) from semnific smin where smin.indicator=smax.Indicator and smin.Val_max<smax.Val_max),0)) as valmin,
convert(int,smax.Val_max) as valmax, rtrim(smax.Semnificatie) as semnificatie from semnific smax
where smax.Indicator=@cod
for xml raw
