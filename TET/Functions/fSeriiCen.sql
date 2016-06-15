--***
create function  fSeriiCen(@dDataSus datetime, @cCod char(20), @cGestiune char(20), @cCodi char(20), @cSerie char(20), @GrCod int, @GrGest int, @GrCodi int, @GrSerie int, @cGrupa char(13), @cCont varchar(40)) 
returns @serii table
(
subunitate char(9), 
gestiune char(20), 
tip_gestiune char(1), 
cod char(20), 
cod_intrare char(20), 
serie char(20), 
stoc_initial float, 
intrari float, 
iesiri float, 
stoc float,
cont varchar(40),
data datetime,
data_ultimei_iesiri datetime
)
as
begin

if @GrCod   is null set @GrCod  = 1
if @GrGest  is null set @GrGest = 1
if @GrCodi  is null set @GrCodi = 1
if @GrSerie is null set @GrSerie = 1

insert @serii
select
subunitate, 
max(case when @GrGest=1 then gestiune else '' end), 
max(case when @GrGest=1 then tip_gestiune else '' end), 
max(case when @GrCod=1 then cod else '' end), 
max(case when @GrCodi=1 then cod_intrare else '' end), 
max(case when @GrSerie=1 then serie else '' end), 
sum(round(convert(decimal(15, 5), case when tip_document='SI' then cantitate else 0 end), 3)), 
sum(round(convert(decimal(15, 5), case when tip_document<>'SI' and tip_miscare='I' then cantitate else 0 end), 3)), 
sum(round(convert(decimal(15, 5), case when tip_document<>'SI' and tip_miscare='E' then cantitate else 0 end), 3)), 
sum(round(convert(decimal(15, 5), (case when tip_miscare='E' then -1 else 1 end)*cantitate), 3)),
max(cont), min(data), max(case when tip_miscare='E' then data else '01/01/1901' end)
from dbo.fSerii(null, @dDataSus, @cCod, @cGestiune, @cCodi, @cSerie, @cGrupa, @cCont)
group by subunitate, 
(case when @GrGest=1 then gestiune else '' end), 
(case when @GrCod=1 then cod else '' end), 
(case when @GrCodi=1 then cod_intrare else '' end), 
(case when @GrSerie=1 then serie else '' end), 
(case when @GrGest=1 then tip_gestiune else '' end)

return
end
