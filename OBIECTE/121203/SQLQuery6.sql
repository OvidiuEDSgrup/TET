declare @parXML xml
select @parXML=
(select '10/01/2012' as DataJ,
		'10/31/2012' as DataS,
		1 as IncludRP,
		1 as IncludFF,
		'404.0                                                                                                                                                                                                   ' as CtCorespFF,
		1 as IncludFB,
		'411.3                                                                                                                                                                                                   ' as CtCorespFB,
		1 as IncludAS
for xml raw)

select * 
--into ##rtva7776     
from dbo.rapTVARecap
(@parXML)