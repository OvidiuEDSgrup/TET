select distinct Agent,Denumire_agent,Client,Denumire_client,Grupa_produs,Denumire_grupa,Data_lunii,Cantitate_valoare
--into ##importXlsDifTmp
from ##importXlsTmp 
--except
select distinct Agent,Denumire_agent,Client,Denumire_client,Grupa_produs,Denumire_grupa,Data_lunii,Cantitate_valoare
from yso_vIatargetag