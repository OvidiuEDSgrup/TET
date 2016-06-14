select max(d.detalii.value('(/row/@modPlata)[1]','varchar(50)')) 
from doc d where d.Numar like '10000036'
--insert webconfigfor